class Configuration < DBI::Model( :configuration, 'key' )
  def self.get( key )
    p = self[ key ]
    if p
      p.value
    end
  end
end