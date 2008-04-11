class Severity < DBI::Model( :severities )
  def self.default
    self[ :name => 'Normal' ]
  end
end