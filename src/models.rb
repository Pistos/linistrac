require 'm4dbi'

$dbh = DBI.connect( "DBI:Pg:dbname=#{LinisTrac::DB_NAME};host=#{LinisTrac::DB_HOST}", LinisTrac::DB_USER , LinisTrac::DB_PASSWORD )

acquire 'src/models/*.rb'

DBI::Model.one_to_many( Ticket, Comment, :comments, :ticket, :ticket_id )
DBI::Model.many_to_many(
  Ticket, User, :subscribed_tickets, :subscribed_users, :ticket_subscriptions, :ticket_id, :user_id
)
