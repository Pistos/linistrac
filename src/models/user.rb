class User < DBI::Model( :users )
  def admin?
    has_flag? 'admin'
  end
  
  def to_s
    username
  end
end