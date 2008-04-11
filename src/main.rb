class MainController < Ramaze::Controller
  layout '/page'
  
  def index
    @user = session[ :user ]
  end
end