class TicketController < Ramaze::Controller
  map '/ticket'
  layout '/page'
  
  MIN_PRIORITY = 1
  MAX_PRIORITY = 3
  
  def index
  end
  
  def list
    @tickets = Ticket.all
    @user = session[ :user ]
  end
  
  def view( ticket_id )
    ticket_id = ticket_id.to_i
    @t = Ticket[ ticket_id ]
    @user = session[ :user ]
    
    if request.post?
      # New comment
      
      comment_data = {
        :ticket_id => ticket_id,
        :text => request[ 'text' ]
      }
      if @user
        comment_data[ :author_id ] = @user.id
        author_name = @user.username
      else
        author_name = request[ 'author-name' ]
        if author_name.nil? or author_name.strip.empty?
          author_name = 'Anonymous'
        end
        comment_data[ :author_name ] = author_name
      end
      
      # Check against Akismet first
      akismet_key = Configuration.get( 'akismet_key' )
      http = SimpleHttp.new "#{akismet_key}.rest.akismet.com/1.1/comment-check"
      http.request_headers[ 'User-Agent' ] = 'LinisTrac/0.1.0 | LinisTrac/0.1.0'
      post_params = {
        'blog' => 'http://linis.purepistos.net',
        'user_ip' => request.env[ 'REMOTE_ADDR' ],
        'user_agent' => request.env[ 'HTTP_USER_AGENT' ],
        'referrer' => request.env[ 'HTTP_REFERER' ],
        'comment_type' => 'comment',
        'comment_author' => author_name,
        'comment_content' => comment_data[ :text ],
        # and all request.env
        #'permalink' => '',
        #'comment_author_email' => '',
        #'comment_author_url' => '',
      }
      akismet_result = http.post( post_params )
      
      if akismet_result == 'true' 
        @error = "Your comment seems to be spam; it must be approved before becoming visible."
        comment_data[ :is_spam ] = true
      end
      
      begin
        new_comment = Comment.create( comment_data )
      rescue DBI::Error => e
        case e.message
          when /text_length/
            'Comment text too short.'
          when /value too long for type/
            @error = 'Text too long.'
          else
            raise e
        end
      end
    end
  end
  
  def create
    @severities = Severity.sort_by { |s| s.ordinal }
    @priorities = (MIN_PRIORITY..MAX_PRIORITY)
    @status = Status.initial
    @groups = TicketGroup.all
    
    @description = c request[ 'description' ]
    @title = c request[ 'title' ]
    @tags = c request[ 'tags' ]
    @group_id = request[ 'group_id' ] ? request[ 'group_id' ].to_i : nil
    @severity = request[ 'severity_id' ] ? Severity[ request[ 'severity_id' ].to_i ] : Severity.default
    @priority = request[ 'priority' ] ? request[ 'priority' ].to_i : 2
    if @priority < MIN_PRIORITY
      @priority = MIN_PRIORITY
    elsif @priority > MAX_PRIORITY
      @priority = MAX_PRIORITY
    end
    
    @user = session[ :user ]
    if @user
      @creator_name = @user.username
    else
      @creator_name = 'Anonymous'
    end
    
    if request.post?
      new_ticket = nil
      
      ticket_data = {
        :severity_id => @severity.id,
        :priority => @priority,
        :creator_id => @user ? @user.id : nil,
        :group_id => @group_id,
        :status_id => @status.id,
        :title => @title,
        :description => @description,
        :tags => @tags,
      }
      
      # Check against Akismet first
      akismet_key = Configuration.get( 'akismet_key' )
      http = SimpleHttp.new "#{akismet_key}.rest.akismet.com/1.1/comment-check"
      http.request_headers[ 'User-Agent' ] = 'LinisTrac/0.1.0 | LinisTrac/0.1.0'
      post_params = {
        'blog' => 'http://linis.purepistos.net',
        'user_ip' => request.env[ 'REMOTE_ADDR' ],
        'user_agent' => request.env[ 'HTTP_USER_AGENT' ],
        'referrer' => request.env[ 'HTTP_REFERER' ],
        'comment_type' => 'ticket',
        'comment_author' => @creator_name,
        'comment_content' => ticket_data[ :description ],
        'ticket_title' => ticket_data[ :title ],
        'ticket_tags' => ticket_data[ :tags ],
        # and all request.env
        #'permalink' => '',
        #'comment_author_email' => '',
        #'comment_author_url' => '',
      }
      akismet_result = http.post( post_params )
      
      if akismet_result == 'true' 
        @error = "Your ticket seems to be spam; it must be approved before becoming visible."
        ticket_data[ :is_spam ] = true
      end
      
      begin
        new_ticket = Ticket.create( ticket_data )
      rescue DBI::Error => e
        case e.message
          when /title_length/
            @error = 'Title too short.'
          when /description_length/
            @error = 'Description too short.'
          when /value too long for type/
            @error = 'Text too long.'
          else
            raise e
        end
      end
      if new_ticket
        if @error.nil?
          @success = "Created <a href='/ticket/view/#{new_ticket.id}'>ticket ##{new_ticket.id}</a>."
        end
      elsif @error.nil?
        @error = "Failed to create new ticket."
      end
    end
  end
  
  def delete
  end
end