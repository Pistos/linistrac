class User < DBI::Model( :users )
  def admin?
    has_flag? 'admin'
  end
  
  def to_s
    username
  end
  
  def subscribe_to( ticket )
    num_inserted = $dbh.i(
      "INSERT INTO ticket_subscriptions( ticket_id, user_id ) VALUES ( ?, ? )",
      ticket.id,
      id
    )
    num_inserted > 0
  end
  
  def unsubscribe_from( ticket )
    num_deleted = $dbh.d(
      "DELETE FROM ticket_subscriptions WHERE ticket_id = ? AND user_id = ?",
      ticket.id,
      id
    )
    num_deleted > 0
  end
  
  def subscribed_to?( ticket )
    subscribed_tickets.include? ticket
  end
  
  def notify( subject, message )
    Ramaze::Log.debug "E-mailing #{username}: '#{subject}'"
    if email and not email.empty?
      Ramaze::EmailHelper.send(
        email,
        '[LinisTrac] ' + subject,
        message
      )
    end
  end
end