class TicketController < Ramaze::Controller
  map '/ticket'
  layout '/page'
  
  include AuthAC
  helper :partial
  
  MIN_PRIORITY = 1
  MAX_PRIORITY = 3
  
  def index
  end
  
  def list
    @user = session[ :user ]
    @tickets = Ticket.where( :is_spam => false )
  end
  
  def view( ticket_id )
    ticket_id = ticket_id.to_i
    @t = Ticket[ ticket_id ]
    
    if @t.nil?
      @error = "No such ticket (##{ticket_id})."
      return
    end
    
    @user = session[ :user ]
    @resolutions = Resolution.all
    @statuses = Status.all
    @priorities = (MIN_PRIORITY..MAX_PRIORITY).to_a
    @severities = Severity.all_sorted
    @groups = TicketGroup.all
    
    ss = TicketSnapshot.where( :ticket_id => @t.id ).sort_by { |s| s.time_snapshot }
    @deltas = @t.comments.elements
    ss.each_with_index do |s,i|
      next if i == 0
      @deltas << TicketDelta.new( ss[ i - 1 ], s )
    end
    @deltas = @deltas.sort_by { |d| d.time }
  end
  
  def comment_add( ticket_id )
    ticket_id = ticket_id.to_i
    @t = Ticket[ ticket_id ]
    @user = session[ :user ]
    
    if @t.nil?
      flash[ :error ] = "No such ticket (##{ticket_id})."
      redirect Rs( :list )
    elsif request.post?
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
      
      akismet_result = Akismet.check_comment(
        comment_data.merge( { :author_name => author_name } ),
        request
      )
      
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
    
      redirect Rs( :view, ticket_id )
    end
  end
  
  def create
    @severities = Severity.sort_by { |s| s.ordinal }
    @priorities = (MIN_PRIORITY..MAX_PRIORITY)
    @status = Status[ Configuration.get( 'initial_status_id' ) ]
    @resolution = Resolution[ Configuration.get( 'initial_resolution_id' ) ]
    @groups = TicketGroup.all
    
    @description = c request[ 'description' ]
    @title = c request[ 'title' ]
    @tags = c request[ 'tags' ]
    @group = request[ 'group_id' ] ? TicketGroup[ request[ 'group_id' ].to_i ] : TicketGroup.default
    @severity = request[ 'severity_id' ] ? Severity[ request[ 'severity_id' ].to_i ] : Severity.default
    @priority = normalized_priority( request[ 'priority' ] ? request[ 'priority' ].to_i : 2 )
    
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
        :group_id => @group.id,
        :status_id => @status.id,
        :resolution_id => @resolution.id,
        :title => @title,
        :description => @description,
        :tags => @tags,
      }
      
      # Check against Akismet first
      akismet_result = Akismet.check_ticket(
        ticket_data.merge( :author_name => @creator_name ),
        request
      )
      
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
          TicketSnapshot.snapshoot( new_ticket, @user || User.one )
          flash[ :success ] = "Created ticket."
          redirect Rs( :view, new_ticket.id )
        end
      elsif @error.nil?
        @error = "Failed to create new ticket."
      end
    end
  end
  
  def delete
  end
  
  def update( ticket_id )
    require_login
    
    if request.post?
      ticket_id = ticket_id.to_i
      t = Ticket[ ticket_id ]
      if t
        old_ticket = t.to_h
        resolution = Resolution[ request[ 'resolution_id' ].to_i ]
        status = Status[ request[ 'status_id' ].to_i ]
        priority = normalized_priority( request[ 'priority' ].to_i )
        severity = Severity[ request[ 'severity_id' ].to_i ]
        group = TicketGroup[ request[ 'group_id' ].to_i ]
        
        update_hash = {
          :resolution_id => ( resolution.id if resolution ),
          :status_id => ( status.id if status ),
          :priority => priority,
          :severity_id => ( severity.id if severity ),
          :group_id => ( group.id if group ),
          :title => ( request[ 'title' ] if not request[ 'title' ].empty? ),
          :tags => ( request[ 'tags' ] if not request[ 'tags' ].empty? ),
        }.delete_if { |k,v| v.nil? }
        
        t.set update_hash
        new_ticket = t.to_h
        # TODO: Spam check again?  NULL time_moderated?
        if not old_ticket.diff( new_ticket ).empty?
          snapshot = TicketSnapshot.snapshoot( t, session[ :user ] )
          flash[ :success ] = "Ticket ##{t.id} updated."
        else
          flash[ :notice ] = "Ticket ##{t.id} not modified."
        end
      end
    end
    
    redirect Rs( :view, ticket_id )
  end
  
  private
  
  def normalized_priority( priority )
    if priority < MIN_PRIORITY
      MIN_PRIORITY
    elsif priority > MAX_PRIORITY
      MAX_PRIORITY
    else
      priority
    end
  end
end