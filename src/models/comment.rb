class Comment < DBI::Model( :comments )
  def author
    User[ author_id ]
  end
  def author_name
    author ? author.username : self[ 'author_name' ]
  end
  def time_created_s
    time_created.strftime "%Y-%m-%d %H:%M"
  end
end