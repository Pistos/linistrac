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
  
  def delta
    prev = TicketSnapshot.s1(
      %{
        SELECT *
        FROM ticket_snapshots
        WHERE
          ticket_id = ?
          AND id < ?
        ORDER BY
          id DESC
        LIMIT 1
      },
      ticket_id,
      id
    )
    TicketDelta.new( prev, self )
  end
end