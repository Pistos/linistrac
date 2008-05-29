require 'redcloth'
require 'rss/maker'

class TicketController < Ramaze::Controller
  map '/ticket'
  layout '/page' => [ :create, :view, :list, :error ]
  
  include AuthAC
  helper :partial
  
  MIN_PRIORITY = 1
  MAX_PRIORITY = 3
  
  def index
    redirect Rs( :create )
  end
  
  def error
    @error = %{
      Gosh golly gee willakers!  Something went wrong.  If you're feeling particularly noble
      at the moment, you can
      <a href="http://linis.purepistos.net/ticket/create">file a new ticket</a> about it, describing what you think happened,
      steps to reproduce the issue, blah blah... you know the drill.
    }
    ""
  end
  
  def list( group = nil )
    @user = session[ :user ]
    
    @resolutions = Resolution.all
    @statuses = Status.all
    @groups = TicketGroup.all
    
    if request.post?
      @selected = {
        :statuses => [],
        :resolutions => [],
        :groups => [],
      }
      @statuses.each do |s|
        if request[ "status-#{s.id}" ]
          @selected[ :statuses ] << s
        end
      end
      @resolutions.each do |s|
        if request[ "resolution-#{s.id}" ]
          @selected[ :resolutions ] << s
        end
      end
      @groups.each do |s|
        if request[ "group-#{s.id}" ]
          @selected[ :groups ] << s
        end
      end
    else
      if group
        g = TicketGroup[ group.to_i ] || TicketGroup[ :name => group ]
        if g
          groups = [ g, *g.descendants ]
        end
      end
      groups ||= @groups
      @selected = {
        :statuses => @statuses - Status.where( :name => 'Closed' ),
        :resolutions => @resolutions,
        :groups => groups,
      }
    end
    
    if(
      @selected[ :statuses ].empty? or
      @selected[ :resolutions ].empty? or
      @selected[ :groups ].empty?
    )
      @tickets = []
    else
      @tickets = Ticket.s(
        %{
          SELECT *
          FROM tickets
          WHERE is_spam = FALSE
            AND status_id IN ( #{@selected[ :statuses ].to_placeholders } )
            AND resolution_id IN ( #{@selected[ :resolutions ].to_placeholders } )
            AND group_id IN ( #{@selected[ :groups ].to_placeholders } )
          ORDER BY id
        },
        *(
          @selected[ :statuses ].map { |s| s.id } + 
          @selected[ :resolutions ].map { |s| s.id } + 
          @selected[ :groups ].map { |s| s.id }
        )
      )
    end
  end
  
  def view( ticket_id = nil )
    ticket_id = ticket_id.to_i
    @t = Ticket[ ticket_id ]
    
    if @t.nil?
      if ticket_id != 0
        flash[ :error ] = "No such ticket (##{ticket_id})."
      end
      redirect Rs( :list )
    end
    
    @user = session[ :user ]
    @resolutions = Resolution.all
    @statuses = Status.all
    @priorities = (MIN_PRIORITY..MAX_PRIORITY).to_a
    @severities = Severity.all_sorted
    @groups = TicketGroup.root_groups
    @selected_groups = ( @t.group.ancestors << @t.group )
    
    ss = TicketSnapshot.where( :ticket_id => @t.id ).sort_by { |s| s.time_snapshot }
    @deltas = @t.comments.elements
    ss.each_with_index do |s,i|
      next if i == 0
      @deltas << TicketDelta.new( ss[ i - 1 ], s )
    end
    @deltas = @deltas.sort_by { |d| d.time }
    
    @attachments = Dir[ @t.dir / '*' ].map { |f|
      basename = File.basename( f )
      {
        :uri_path => @t.dir_uri / basename,
        :basename => basename
      }
    }
  end
  
  def comment_add( ticket_id )
    ticket_id = ticket_id.to_i
    @t = Ticket[ ticket_id ]
    @user = session[ :user ]
    
    if @t.nil?
      flash[ :error ] = "No such ticket (##{ticket_id})."
      redirect Rs( :list )
    elsif request.post?
      comment_data = {
        :ticket_id => ticket_id,
        :text => request[ 'text' ].strip
      }
      if @user
        comment_data[ :author_id ] = @user.id
        author_name = @user.username
      else
        author_name = request[ 'author-name' ]
        if author_name.nil? or author_name.strip.empty?
          author_name = 'Anonymous'
        end
        comment_data[ :author_name ] = author_name
      end
      
      if BlacklistedWord.matches?( comment_data[ :text ] + author_name )
        comment_data[ :is_spam ] = true
      else
        akismet_result = Akismet.check_comment(
          comment_data.merge( { :author_name => author_name } ),
          request
        )
        comment_data[ :is_spam ] = ( akismet_result == 'true' )
      end
      
      begin
        new_comment = Comment.create( comment_data )
      rescue DBI::Error => e
        case e.message
          when /text_length/
            @error = 'Comment text too short.'
          when /value too long for type/
            @error = 'Text too long.'
          else
            raise e
        end
      end
    
      redirect_to = :view
      if new_comment.is_spam
        flash[ :error ] = "Your comment seems to be spam; it must be approved before becoming visible."
      else
        flash[ :new ] = new_comment.id
        @t.notify_subscribers(
          "Comment on Ticket ##{@t.id}",
          %{
#{new_comment.author_name} has posted a new comment on ticket ##{@t.id} \"#{ticket.title}\" ( #{@t.uri} ):

#{new_comment.text}
          }
        )
        if request[ 'subscribe' ] and @user
          redirect_to = :subscribe
        end
      end
        
      redirect Rs( redirect_to, ticket_id )
    end
  end
  
  def attach_file( ticket_id )
    ticket_id = ticket_id.to_i
    ticket = Ticket[ ticket_id ]
    user = session[ :user ]
    if request.post? and ticket and user
      tempfile, filename = request[ 'attachment' ].values_at( :tempfile, :filename )
      if tempfile.size < Configuration.get( 'max_upload_size' ).to_i * 1024
        FileUtils.mkdir_p ticket.dir
        original_basename = basename = File.basename( filename )
        filepath = ticket.dir / basename
        while File.exists? filepath
          basename = "_" + basename
          filepath = ticket.dir / basename
        end
        if basename != original_basename
          flash[ :notice ] = "Your file was renamed from '#{original_basename}' to '#{basename}' to avoid collision with an existing file."
        end
        FileUtils.move( tempfile.path, filepath )
        
        new_comment = Comment.create(
          :ticket_id => ticket.id,
          :author_id => user.id,
          :text => "Attached '#{basename}' to ticket."
        )
      
        ticket.notify_subscribers(
          "Attachment to Ticket ##{ticket.id}",
          "#{user} has attached a file (#{basename}) to ticket ##{ticket.id} \"#{ticket.title}\" ( #{ticket.uri} )."
        )
        
        flash[ :success ] = "'#{basename}' attached."
      else
        flash[ :error ] = "Uploaded file was discarded because it was too large."
      end
    end
    
    redirect Rs( :view, ticket_id )
  end
  
  def create
    @severities = Severity.sort_by { |s| s.ordinal }
    @priorities = (MIN_PRIORITY..MAX_PRIORITY)
    @status = Status[ Configuration.get( 'initial_status_id' ) ]
    @resolution = Resolution[ Configuration.get( 'initial_resolution_id' ) ]
    @groups = TicketGroup.root_groups
    
    @description = c request[ 'description' ]
    @title = c request[ 'title' ]
    @tags = c request[ 'tags' ]
    @group = request[ 'group_id' ] ? TicketGroup[ request[ 'group_id' ].to_i ] : TicketGroup.default
    @severity = request[ 'severity_id' ] ? Severity[ request[ 'severity_id' ].to_i ] : Severity.default
    @priority = normalized_priority( request[ 'priority' ] ? request[ 'priority' ].to_i : 2 )
    
    @user = session[ :user ]
    if @user
      @creator_name = @user.username
    else
      @creator_name = 'Anonymous'
    end
    
    if request.post?
      new_ticket = nil
      
      ticket_data = {
        :severity_id => @severity.id,
        :priority => @priority,
        :creator_id => @user ? @user.id : nil,
        :group_id => @group.id,
        :status_id => @status.id,
        :resolution_id => @resolution.id,
        :title => @title,
        :description => @description,
        :tags => @tags,
      }
      
      if BlacklistedWord.matches?( @title + @description + @tags + @creator_name )
          ticket_data[ :is_spam ] = true
      else
        # Check against Akismet
        akismet_result = Akismet.check_ticket(
          ticket_data.merge( :author_name => @creator_name ),
          request
        )
        ticket_data[ :is_spam ] = ( akismet_result == 'true' )
      end
      
      if ticket_data[ :is_spam ]
        @error = "Your ticket seems to be spam; it must be approved before becoming visible."
      end
      
      begin
        new_ticket = Ticket.create( ticket_data )
      rescue DBI::Error => e
        case e.message
          when /title_length/
            @error = 'Title too short.'
          when /description_length/
            @error = 'Description too short.'
          when /value too long for type/
            @error = 'Text too long.'
          else
            raise e
        end
      end
      if new_ticket
        if @error.nil?
          TicketSnapshot.snapshoot( new_ticket, @user || User.one )
          flash[ :success ] = "Created ticket."
          if request[ 'subscribe' ]
            redirect Rs( :subscribe, new_ticket.id )
          else
            redirect Rs( :view, new_ticket.id )
          end
        end
      elsif @error.nil?
        @error = "Failed to create new ticket."
      end
    end
  end
  
  def delete
  end
  
  def update( ticket_id )
    require_login
    
    if request.post?
      ticket_id = ticket_id.to_i
      t = Ticket[ ticket_id ]
      if t
        old_ticket = t.to_h
        resolution = Resolution[ request[ 'resolution_id' ].to_i ]
        status = Status[ request[ 'status_id' ].to_i ]
        priority = normalized_priority( request[ 'priority' ].to_i )
        severity = Severity[ request[ 'severity_id' ].to_i ]
        group = TicketGroup[ request[ 'group_id' ].to_i ]
        
        update_hash = {
          :resolution_id => ( resolution.id if resolution ),
          :status_id => ( status.id if status ),
          :priority => priority,
          :severity_id => ( severity.id if severity ),
          :group_id => ( group.id if group ),
          :title => ( c( request[ 'title' ] ) if not request[ 'title' ].empty? ),
          :tags => ( c( request[ 'tags' ] ) if not request[ 'tags' ].empty? ),
        }.delete_if { |k,v| v.nil? }
        
        t.set update_hash
        new_ticket = t.to_h
        # TODO: Spam check again?  NULL time_moderated?
        if not old_ticket.diff( new_ticket ).empty?
          user = session[ :user ]
          snapshot = TicketSnapshot.snapshoot( t, user )
          flash[ :new ] = snapshot.id
          t.notify_subscribers(
            "Ticket ##{t.id} updated",
            %{
#{user} has updated ticket ##{t.id} \"#{ticket.title}\" ( #{t.uri} ):

#{snapshot.delta}
            }
          )
        else
          flash[ :notice ] = "Ticket ##{t.id} not modified."
        end
      end
    end
    
    redirect Rs( :view, ticket_id )
  end
  
  def subscribe( ticket_id )
    requires_login
    
    ticket_id = ticket_id.to_i
    t = Ticket[ ticket_id ]
    
    if t.nil?
      flash[ :error ] = "No such ticket (##{ticket_id})."
      redirect Rs( :list )
    end
    
    user = session[ :user ]
    if user.subscribe_to( t )
      flash[ :success ] = "You have subscribed to ticket ##{t.id}."
    else
      flash[ :error ] = "Failed to subscribe to ticket ##{t.id}."
    end
    
    redirect Rs( :view, ticket_id )
  end
  
  def unsubscribe( ticket_id )
    ticket_id = ticket_id.to_i
    t = Ticket[ ticket_id ]
    
    if t.nil?
      flash[ :error ] = "No such ticket (##{ticket_id})."
      redirect Rs( :list )
    end
    
    user = session[ :user ]
    if user.unsubscribe_from( t )
      flash[ :success ] = "You are no longer subscribed to ticket ##{t.id}."
    else
      flash[ :error ] = "Failed to unsubscribe from ticket ##{t.id}."
    end
    
    redirect Rs( :view, ticket_id )
  end
  
  def rss( ticket_id )
    ticket_id = ticket_id.to_i
    t = Ticket[ ticket_id ]
    
    if t.nil?
      flash[ :error ] = "No such ticket (##{ticket_id})."
      redirect Rs( :list )
    end
    
    ss = TicketSnapshot.where( :ticket_id => t.id ).sort_by { |s| s.time_snapshot }
    @deltas = t.comments.elements
    ss.each_with_index do |s,i|
      next if i == 0
      @deltas << TicketDelta.new( ss[ i - 1 ], s )
    end
    @deltas = @deltas.sort_by { |d| d.time }
    
    response.header[ 'Content-Type' ] = 'application/rss+xml'
    RSS::Maker.make( '1.0' ) do |rss|
      rss.channel.title = "LinisTrac Ticket ##{t.id}"
      rss.channel.link = t.uri
      rss.channel.description = "Changelog for LinisTrac Ticket ##{t.id}"
      rss.channel.about = Configuration.get( 'site_root' ) + Rs( :rss, t.id )
      rss.items.do_sort = true
      
      @deltas.each do |delta|
        i = rss.items.new_item
        case delta
          when TicketDelta
            i.title = "#{delta.changer} changed ticket ##{t.id}"
            i.link = t.uri + "#delta-#{delta.id}"
            i.date = delta.time.to_time
            i.description = delta.changes.map { |c|
              "#{c[:key]} changed from #{c[:old]} to #{c[:new]}"
            }.join( "\n" )
            
          when Comment
            i.title = "#{delta.author_name} commented on ticket ##{t.id}"
            i.link = t.uri + "#comment-#{delta.id}"
            i.date = delta.time_created.to_time
            i.description = delta.text
        end
        #i[ :guid ] = RSS::Maker::RSS20::Items::Item::Guid.new( i.link )
      end
    end
  end
  
  private
  
  def normalized_priority( priority )
    if priority < MIN_PRIORITY
      MIN_PRIORITY
    elsif priority > MAX_PRIORITY
      MAX_PRIORITY
    else
      priority
    end
  end
end