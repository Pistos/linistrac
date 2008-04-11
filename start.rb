require 'ramaze'
require 'auth-ac'

require 'src/auth'
require 'src/access'
require 'src/models.rb'
require 'src/main'
require 'src/ticket'

require 'ruby-debug' 
Debugger.start

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

Ramaze.start :adapter => :mongrel, :port => 7005