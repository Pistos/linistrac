class TicketController < Ramaze::Controller
  map '/ticket'
  layout '/page'
  
  def index
  end
  
  def list
  end
  
  def view
  end
  
  def create
    @severities = Severity.sort_by { |s| s.ordinal }
    if request.post?
    end
  end
  
  def delete
  end
end