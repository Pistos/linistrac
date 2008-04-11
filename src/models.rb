require 'm4dbi'

$dbh = DBI.connect( "DBI:Pg:linis-trac", "linis", "linis" )

acquire 'src/models/*.rb'