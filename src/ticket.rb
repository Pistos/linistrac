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
      if @user
        author_id = @user.id
      end
      begin
        new_comment = Comment.create(
          :ticket_id => ticket_id,
          :author_id => author_id,
          :text => request[ 'text' ]
        )
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
      begin
        new_ticket = Ticket.create(
          :severity_id => @severity.id,
          :priority => @priority,
          :creator_id => @user ? @user.id : nil,
          :group_id => @group_id,
          :status_id => @status.id,
          :title => @title,
          :description => @description,
          :tags => @tags
        )
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
        @success = "Created <a href='/ticket/view/#{new_ticket.id}'>ticket ##{new_ticket.id}</a>."
      elsif @error.nil?
        @error = "Failed to create new ticket."
      end
    end
  end
  
  def delete
  end
end