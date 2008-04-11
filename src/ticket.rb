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
    @status = Status.initial.name
    @groups = TicketGroup.all
    
    @user = session[ :user ]
    if @user
      @creator_name = @user.username
    else
      @creator_name = 'Anonymous'
    end
    
    if request.post?
    end
  end
  
  def delete
  end
end