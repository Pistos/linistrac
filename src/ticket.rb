class TicketController < Ramaze::Controller
  map '/ticket'
  layout '/page'
  
  MIN_PRIORITY = 1
  MAX_PRIORITY = 3
  
  def index
  end
  
  def list
  end
  
  def view
  end
  
  def create
    @severities = Severity.sort_by { |s| s.ordinal }
    @priorities = (MIN_PRIORITY..MAX_PRIORITY)
    @default_priority = 2
    @status = Status.initial
    @groups = TicketGroup.all
    
    @user = session[ :user ]
    if @user
      @creator_name = @user.username
    else
      @creator_name = 'Anonymous'
    end
    
    if request.post?
      priority = request[ 'priority' ].to_i
      if priority < MIN_PRIORITY
        priority = MIN_PRIORITY
      elsif priority > MAX_PRIORITY
        priority = MAX_PRIORITY
      end
      new_ticket = nil
      begin
        new_ticket = Ticket.create(
          :severity_id => request[ 'severity_id' ].to_i,
          :priority => priority,
          :creator_id => @user ? @user.id : nil,
          :group_id => request[ 'group_id' ].to_i,
          :status_id => @status.id,
          :title => request[ 'title' ],
          :description => request[ 'description' ],
          :tags => request[ 'tags' ]
        )
      rescue Object => e
        case e.message
          when /title_length/
            @error = 'Title too short.'
          when /description_length/
            @error = 'Description too short.'
          else
            raise e
        end
      end
      if new_ticket
        @success = "Created ticket ##{new_ticket.id}."
      elsif @error.nil?
        @error = "Failed to create new ticket."
      end
    end
  end
  
  def delete
  end
end