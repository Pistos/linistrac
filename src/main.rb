class MainController < Ramaze::Controller
  layout '/page' => [ :index, :account, :error ]
  
  include AuthAC
  
  
  def index
    @user = session[ :user ]
  end
  
  def error
    @error = %{
      Gosh golly gee willakers!  Something went wrong.  If you're feeling particularly noble
      at the moment, you can
      <a href="/ticket/create">file a new ticket</a> about it, describing what you think happened,
      steps to reproduce the issue, blah blah... you know the drill.
    }
    ""
  end
  
  def account( user_id = nil )
    requires_login
    
    @user = session[ :user ]
    @u = User[ user_id ] || @user
  end
  
  def account_update
    @user = session[ :user ]
    
    catch( :error ) do
      if @user.nil?
        flash[ :error ] = "You are not logged in."
        throw :error
      end
      if request.post?
        data = {
          :realname => request[ 'realname' ],
          :email => request[ 'email' ],
        }
        if not request[ 'old-password' ].empty?
          if encrypt( request[ 'old-password' ] ) != @user.encrypted_password
            flash[ :error ] = "Current password not verified."
            throw :error
          end
          if request[ 'new-password1' ] != request[ 'new-password2' ]
            flash[ :error ] = "New password mismatch."
            throw :error
          end
          data[ :encrypted_password ] = encrypt( request[ 'new-password1' ] )
        end
        
        @user.set( data )
        
        flash[ :success ] = "Updated user account."
      end
    end
    
    redirect Rs( :account )
  end
  
  def markdown_preview
    request[ 'data' ].marked_up
  end
end
