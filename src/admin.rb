class AdminController < Ramaze::Controller
  map '/admin'
  layout '/page'
  
  include AuthAC
  
  def index
    requires_flag 'admin'
    
    @user = session[ :user ]
  end
  
  def ticket
    requires_flag 'admin'
    @user = session[ :user ]
  end
  
  def comment
    requires_flag 'admin'
    @user = session[ :user ]
    @comments = Comment.where( :in_moderation => true )
  end
  
  def comment_approve( comment_id )
    requires_flag 'admin'
    c = Comment[ comment_id ]
    if c
      c.in_moderation = false
      flash[ :success ] = "Approved comment ##{comment_id}."
    else
      flash[ :error ] = "Failed to approve comment ##{comment_id}."
    end
    redirect Rs( :comment )
  end
  def comment_delete( comment_id )
    requires_flag 'admin'
    
    c = Comment[ comment_id ]
    if c and c.delete
      flash[ :success ] = "Deleted comment ##{comment_id}."
    else
      flash[ :error ] = "Failed to delete comment ##{comment_id}."
    end
    redirect Rs( :comment )
  end
end