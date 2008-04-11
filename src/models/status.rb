class Status < DBI::Model( :statuses )
  def self.initial
    self[ :name => 'New' ]
  end
end