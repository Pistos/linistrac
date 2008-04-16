class Akismet
  # Generic Akismet POST, used by all Akismet operations.
  def self.post( action, hash, request )
    akismet_key = Configuration.get( 'akismet_key' )
    http = SimpleHttp.new "#{akismet_key}.rest.akismet.com/1.1/#{action}"
    http.request_headers[ 'User-Agent' ] = "LinisTrac/#{LinisTrac::VERSION} | LinisTrac/#{LinisTrac::VERSION}"
    post_params = {
      'blog' => 'http://linis.purepistos.net',
      'user_ip' => request.env[ 'REMOTE_ADDR' ],
      'user_agent' => request.env[ 'HTTP_USER_AGENT' ],
      'referrer' => request.env[ 'HTTP_REFERER' ],
      # and all request.env
      #'permalink' => '',
      #'comment_author_email' => '',
      #'comment_author_url' => '',
    }.merge( hash )
    
    post_params.each_key do |key|
      if post_params[ key ].nil?
        raise "Akismet error: post_params[ #{key.inspect} ] is nil"
      end
    end
    
    begin
      http.post( post_params )
    rescue Exception => e
      Ramaze::Log.error "Error when posting to Akismet.  post_params:\n#{post_params.inspect}"
      raise e
    end
  end
  
  def self.check( hash, request )
    post 'comment-check', hash, request
  end
  
  def self.spam( hash, request )
    post 'submit-spam', hash, request
  end
  
  def self.ham( hash, request )
    post 'submit-ham', hash, request
  end
  
  def self.check_ticket( hash, request )
    check(
      {
        'comment_type' => 'ticket',
        'comment_author' => hash[ :author_name ],
        'comment_content' => hash[ :description ],
        'ticket_title' => hash[ :title ],
        'ticket_tags' => hash[ :tags ],
      },
      request
    )
  end
  
  def self.check_comment( hash, request )
    check(
      {
        'comment_type' => 'comment',
        'comment_content' => hash[ :text ],
        'comment_author' => hash[ :author_name ],
      },
      request
    )
  end
  
  def self.spam_ticket( hash, request )
    spam(
      {
        'comment_type' => 'ticket',
        'comment_author' => hash[ :author_name ],
        'comment_content' => hash[ :description ],
        'ticket_title' => hash[ :title ],
        'ticket_tags' => hash[ :tags ],
      },
      request
    )
  end
  
  def self.spam_comment( hash, request )
    check(
      {
        'comment_type' => 'comment',
        'comment_content' => hash[ :text ],
        'comment_author' => hash[ :author_name ],
      },
      request
    )
  end
end