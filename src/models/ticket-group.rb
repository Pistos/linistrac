class TicketGroup < DBI::Model( :ticket_groups )
  def self.default
    self[ :name => 'Uncategorized' ]
  end
  
  def self.root_groups
    TicketGroup.where( :parent_id => nil )
  end
  
  def to_s
    name
  end
  
  def parent
    TicketGroup[ parent_id ]
  end
  
  # Provides ancestry in order from parent to furthest ancestor.
  def ancestors
    if parent_id.nil?
      []
    else
      [ parent ] + parent.ancestors
    end
  end

  def children
    TicketGroup.where( :parent_id => id )
  end
end