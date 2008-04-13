class Resolution < DBI::Model( :resolutions )
  def to_s
    name
  end
end