require 'rubygems'
gem 'ramaze', '2009.03'
require 'ramaze'
require 'auth-ac'
require 'ramaze/spec/helper/simple_http'
require 'ramaze/contrib/email'

require 'bluecloth'

require 'src/linis-trac'
require './database-config'

require 'src/hash'
require 'src/markup'
require 'src/auth'
require 'src/access'
require 'src/models.rb'
require 'src/akismet'
require 'src/main'
require 'src/ticket-delta'
require 'src/ticket'
require 'src/admin'

#require 'ruby-debug'
#Debugger.start

AuthAC.options(
  {
    :db => {
      :vendor => 'Pg',
      :user => 'linis',
      :password => 'linis',
      :host => nil,
      :database => 'linis-trac',
    },
  }
)

Ramaze::EmailHelper.trait( {
  :smtp_server      => Configuration.get( 'smtp_server' ),
  :smtp_helo_domain => Configuration.get( 'smtp_helo_domain' ),
  :smtp_username    => Configuration.get( 'smtp_username' ),
  :smtp_password    => Configuration.get( 'smtp_password' ),
  :sender_address   => Configuration.get( 'sender_address' ),
} )

Ramaze.start :adapter => :thin, :port => 8004, :sourcereload => false
