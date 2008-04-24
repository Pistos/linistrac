class MainController < Ramaze::Controller
  layout '/page' => [ :index, :account ]
  
  include AuthAC
  
  
  def index
    @user = session[ :user ]
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
    RedCloth.new( request[ 'data' ] ).to_html
  end
end
