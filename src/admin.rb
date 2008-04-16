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
    @unmoderated_comments = Comment.s %{
      SELECT c.*
      FROM comments c
      WHERE c.in_moderation
      ORDER BY c.id
    }
    @page = request[ 'page' ].to_i
    if @page < 0
      @page = 0
    end
    @page_size = request[ 'page-size' ].to_i
    if @page_size < 1
      @page_size = 10
    end
    @comments = Comment.s(
      %{
        SELECT c.*
        FROM comments c
        ORDER BY c.id DESC
        OFFSET ?
        LIMIT ?
      },
      @page * @page_size,
      @page_size
    )
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