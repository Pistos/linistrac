class Status < DBI::Model( :statuses )
  def self.initial
    self[ :name => 'New' ]
  end
  def to_s
    name
  end
end