class AdminController < Ramaze::Controller
  map '/admin'
  layout '/page'
  
  include AuthAC
  
  def index
    requires_flag 'admin'
    
    @user = session[ :user ]
    
    if request.post?
      Configuration.each do |c|
        Configuration[ :key => c.key ].value = request[ c.key ]
      end
      @success = 'Settings updated.'
    end
    
    @conf = {}
    Configuration.each do |c|
      @conf[ c.key ] = c.value
    end
    @resolutions = Resolution.all
    @statuses = Status.all
    
  end
  
  def ticket
    requires_flag 'admin'
    @user = session[ :user ]
    
    @unmoderated_tickets = Ticket.s %{
      SELECT t.*
      FROM tickets t
      WHERE
        t.is_spam
        AND t.time_moderated IS NULL
      ORDER BY t.id
    }
    @page = request[ 'page' ].to_i
    if @page < 0
      @page = 0
    end
    @page_size = request[ 'page-size' ].to_i
    if @page_size < 1
      @page_size = 10
    end
    @tickets = Ticket.s(
      %{
        SELECT t.*
        FROM tickets t
        ORDER BY t.id DESC
        OFFSET ?
        LIMIT ?
      },
      @page * @page_size,
      @page_size
    )
  end
  
  def ticket_approve( ticket_id )
    requires_flag 'admin'
    t = Ticket[ ticket_id ]
    if t
      t.set(
        :is_spam => false,
        :time_moderated => Time.now
      )
      flash[ :success ] = "Approved ticket ##{ticket_id}."
    else
      flash[ :error ] = "Failed to approve ticket ##{ticket_id}."
    end
    redirect Rs( :ticket )
  end
  
  def ticket_reject( ticket_id )
    requires_flag 'admin'
    t = Ticket[ ticket_id ]
    if t
      t.set(
        :is_spam => true,
        :time_moderated => Time.now
      )
      akismet_result = Akismet.spam_ticket(
        {
          :description => t.description,
          :author_name => t.creator_name,
          :title => t.title,
          :tags => t.tags,
        },
        request
      )
      flash[ :success ] = "Marked ticket ##{ticket_id} as spam."
    else
      flash[ :error ] = "Failed to mark ticket ##{ticket_id} as spam."
    end
    redirect Rs( :ticket )
  end
  
  def ticket_delete( ticket_id )
    requires_flag 'admin'
    
    t = Ticket[ ticket_id ]
    if t and t.delete
      flash[ :success ] = "Deleted ticket ##{ticket_id}."
    else
      flash[ :error ] = "Failed to delete ticket ##{ticket_id}."
    end
    redirect Rs( :ticket )
  end
  
  def comment
    requires_flag 'admin'
    @user = session[ :user ]
    @unmoderated_comments = Comment.s %{
      SELECT c.*
      FROM comments c
      WHERE
        c.is_spam
        AND c.time_moderated IS NULL
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
      c.set(
        :is_spam => false,
        :time_moderated => Time.now
      )
      flash[ :success ] = "Approved comment ##{comment_id}."
    else
      flash[ :error ] = "Failed to approve comment ##{comment_id}."
    end
    redirect Rs( :comment )
  end
  
  def comment_reject( comment_id )
    requires_flag 'admin'
    c = Comment[ comment_id ]
    if c
      c.set(
        :is_spam => true,
        :time_moderated => Time.now
      )
      akismet_result = Akismet.spam_comment(
        {
          :text => c.text,
          :author_name => c.author_name,
        },
        request
      )
      flash[ :success ] = "Marked comment ##{comment_id} as spam."
    else
      flash[ :error ] = "Failed to mark comment ##{comment_id} as spam."
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
  
  def comment_view( comment_id )
    requires_flag 'admin'
    @comment = Comment[ comment_id.to_i ]
  end
  
  # -----------------
  
  def blacklist
    requires_flag 'admin'
    @user = session[ :user ]
    
    @words = BlacklistedWord.all
  end
  
  def blacklist_add
    requires_flag 'admin'
    if request.post?
      begin
        BlacklistedWord.create(
          :word => request[ 'word' ]
        )
      rescue DBI::Error => e
        if e =~ /value too long for type/
          flash[ :error ] = "That word is too long."
        else
          raise e
        end
      end
      
      redirect Rs( :blacklist )
    end
  end
  
  def blacklist_delete( word_id )
    requires_flag 'admin'
    $dbh.d( "DELETE FROM blacklisted_words WHERE id = ?", word_id.to_i )
    redirect Rs( :blacklist )
  end
end