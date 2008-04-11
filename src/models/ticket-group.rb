class TicketGroup < DBI::Model( :ticket_groups )
  def self.default
    self[ :name => 'Uncategorized' ]
  end
end