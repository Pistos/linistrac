class User < DBI::Model( :users )
  def to_s
    username
  end
end