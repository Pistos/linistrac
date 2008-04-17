class TicketSnapshot < DBI::Model( :ticket_snapshots )
  def self.snapshoot( ticket, changer )
    h = ticket.to_h
    h[ :ticket_id ] = ticket.id
    h[ :changer_id ] = changer.id
    h.delete( 'id' )
    create( h )
  end
  
  def diff( ticket )
    d = to_h.diff( ticket.to_h )
    d -= [ 'id', 'ticket_id', 'time_snapshot', 'changer_id' ]
  end
  
  def changer
    User[ changer_id ]
  end
  
  def time_snapshot_s
    time_snapshot.strftime "%Y-%m-%d %H:%M"
  end
end