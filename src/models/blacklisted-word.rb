class BlacklistedWord < DBI::Model( :blacklisted_words )
  def self.matches?( string )
    $dbh.sc (
      %{
        SELECT EXISTS(
          SELECT 1
          FROM blacklisted_words blw
          WHERE ? ILIKE '%' || blw.word || '%'
          LIMIT 1
        )
      },
      string
    )
  end
end