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
    )
    if t
      t.strftime "%Y-%m-%d %H:%M"
    else
      "Never"
    end
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
  
  def self.selector( set, fk, selected_id )
    s = %{
      <select name="#{fk}">
    }
    set.each do |item|
      s << "<option value='#{item.id}' #{'selected' if selected_id == item.id}>#{item.name}</option>"
    end
    s << %{
      </select>
    }
  end
end