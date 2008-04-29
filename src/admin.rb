class AdminController < Ramaze::Controller
  map '/admin'
  layout '/page'
  
  include AuthAC
  helper :sendfile
  
  def index
    requires_flag 'admin'
    
    @user = session[ :user ]
    
    if request.post?
      Configuration.each do |c|
        Configuration[ :key => c.key ].value = request[ c.key ]
      end
      Ramaze::EmailHelper.trait( {
        :smtp_server      => Configuration.get( 'smtp_server' ),
        :smtp_helo_domain => Configuration.get( 'smtp_helo_domain' ),
        :smtp_username    => Configuration.get( 'smtp_username' ),
        :smtp_password    => Configuration.get( 'smtp_password' ),
        :sender_address   => Configuration.get( 'sender_address' ),
      } )

      @success = 'Settings updated.'
    end
    
    @conf = {}
    Configuration.each do |c|
      @conf[ c.key ] = c.value
    end
    @resolutions = Resolution.all
    @statuses = Status.all
    
    @num_unmod_tickets = $dbh.sc %{
      SELECT COUNT(*)
      FROM tickets t
      WHERE
        t.is_spam
        AND t.time_moderated IS NULL
    }
    @num_unmod_comments = $dbh.sc %{
      SELECT COUNT(*)
      FROM comments c
      WHERE
        c.is_spam
        AND c.time_moderated IS NULL
    }
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
      akismet_result = Akismet.ham_ticket(
        {
          :description => t.description,
          :author_name => t.creator_name,
          :title => t.title,
          :tags => t.tags,
        },
        request
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
      akismet_result = Akismet.ham_comment(
        {
          :text => c.text,
          :author_name => c.author_name,
        },
        request
      )
      t = c.ticket
      t.notify_subscribers(
        "Comment on Ticket ##{t.id}",
        %{
#{c.author_name} has posted a new comment on ticket ##{t.id} ( #{t.uri} ):

#{c.text}
        }
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
        word = request[ 'word' ]
        BlacklistedWord.create(
          :word => word
        )
        flash[ :success ] = "'#{word}' added to blacklist."
      rescue DBI::Error => e
        if e =~ /value too long for type/
          flash[ :error ] = "That word is too long."
        else
          raise e
        end
      end
    end
    redirect Rs( :blacklist )
  end
  
  def blacklist_delete( word_id )
    requires_flag 'admin'
    $dbh.d( "DELETE FROM blacklisted_words WHERE id = ?", word_id.to_i )
    redirect Rs( :blacklist )
  end
  
  # -----------------
  
  def group
    requires_flag 'admin'
    
    @groups = TicketGroup.all
    @user = session[ :user ]
  end
  
  def group_add
    requires_flag 'admin'
    if request.post?
      begin
        name = request[ 'name' ]
        description = request[ 'description' ]
        TicketGroup.create(
          :name => name,
          :description => description
        )
        flash[ :success ] = "'#{name}' group added."
      rescue DBI::Error => e
        if e =~ /value too long for type/
          flash[ :error ] = "String is too long."
        else
          raise e
        end
      end
    end
    redirect Rs( :group )
  end
  
  # -----------------
  
  def backup
    requires_flag 'admin'
    @user = session[ :user ]
    
    @dumper_missing = ( `pg_dump --help`.size < 80 )
    
    backup_dir = Ramaze::Global.root + "/backups"
    
    if request.post? and not @dumper_missing
      begin
        FileUtils.mkdir_p backup_dir
        backup_file = backup_dir / Time.now.strftime( "linis-trac-backup-%Y-%m-%d.sql" )
        `pg_dump -O -U #{LinisTrac::DB_USER} #{LinisTrac::DB_NAME} > #{backup_file}`
        @success = "Created #{backup_file}."
      rescue Object => e
        Ramaze::Log.error e.message
        Ramaze::Log.error e.backtrace.join( "\n" )
        @error = "Failed to make backup: #{e.message}"
      end
    end
    
    @backups = Dir[ backup_dir / '*' ].map { |f| File.basename( f ) }
  end
  
  def restore( backup_filename )
    requires_flag 'admin'
    backup_dir = Ramaze::Global.root + "/backups"
    backups = Dir[ backup_dir / '*' ].map { |f| File.basename( f ) }
    if not backups.include?( backup_filename )
      flash[ :error ] = "No such backup file '#{backup_filename}'."
    else
      begin
        Ramaze::Log.debug "Drop schema:"
        output = `cat '#{Ramaze::Global.root}/sql/drop-schema.sql' | psql -U #{LinisTrac::DB_USER} #{LinisTrac::DB_NAME}`
        Ramaze::Log.debug output
        if output =~ /ERROR/m
          raise "Errors during schema drop.  See Ramaze log."
        end
        
        Ramaze::Log.debug "Restoration:"
        output = `cat '#{backup_dir/backup_filename}' | psql -U #{LinisTrac::DB_USER} #{LinisTrac::DB_NAME}`
        Ramaze::Log.debug output
        
        flash[ :success ] = "Restored database from #{backup_filename}."
      rescue Object => e
        Ramaze::Log.error e.message
        Ramaze::Log.error e.backtrace.join( "\n" )
        flash[ :error ] = "Failed to restore backup: #{e.message}"
      end
    end
    redirect Rs( :backup )
  end
  
  def download_backup( backup_filename )
    requires_flag 'admin'
    backup_dir = Ramaze::Global.root + "/backups"
    backups = Dir[ backup_dir / '*' ].map { |f| File.basename( f ) }
    if not backups.include?( backup_filename )
      flash[ :error ] = "No such backup file '#{backup_filename}'."
    else
      send_file( backup_dir / backup_filename )
    end
  end
end