class Severity < DBI::Model( :severities )
  def self.default
    self[ :name => 'Normal' ]
  end
  
  def to_s
    name
  end
end