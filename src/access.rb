require 'digest/sha1'

class AccessController < Ramaze::Controller
    map "/access"
    layout '/page'
    
    include AuthAC
    
    #def index
        #redirect( R( AuthenticationController, :login ) )
    #end
    
    # This action is used to inform a visitor or user that she does not
    # have access to the given page/area.
    def denied
    end
end

