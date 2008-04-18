class Severity < DBI::Model( :severities )
  def self.default
    self[ :name => 'Normal' ]
  end
  
  def self.all_sorted
    all.sort_by { |s| s.ordinal }.reverse
  end
  
  def to_s
    name
  end
end