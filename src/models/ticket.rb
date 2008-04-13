class Ticket < DBI::Model( :tickets )
  def severity
    Severity[ severity_id ]
  end
  def creator
    User[ creator_id ]
  end
  def time_created_s
    time_created.strftime "%Y-%m-%d %H:%M"
  end
  def time_updated_s
    time_updated.strftime "%Y-%m-%d %H:%M"
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