class Status < DBI::Model( :statuses )
  def to_s
    name
  end
end