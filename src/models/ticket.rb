class Ticket < DBI::Model( :tickets )
  def severity
    Severity[ severity_id ]
  end
  def creator
    User[ creator_id ]
  end
  def creator_name
    u = creator
    if u
      u.username
    else
      'Anonymous'
    end
  end
  def time_created_s
    time_created.strftime "%Y-%m-%d %H:%M"
  end
  def time_updated_s
    t = $dbh.sc(
      %{
        SELECT MAX(t) FROM (
          (
            SELECT time_snapshot AS t
            FROM ticket_snapshots ss 
            WHERE ss.ticket_id = ?
          ) UNION (
            SELECT time_created AS t
            FROM comments c
            WHERE c.ticket_id = ?
          )
        ) AS x
      },
      id,
      id
    ).strftime "%Y-%m-%d %H:%M"
  end
  def group
    TicketGroup[ group_id ]
  end
  def status
    Status[ status_id ]
  end
  def resolution
    Resolution[ resolution_id ]
  end
end