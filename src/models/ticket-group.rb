class TicketGroup < DBI::Model( :ticket_groups )
  def self.default
    self[ :name => 'Uncategorized' ]
  end
  def to_s
    name
  end
end