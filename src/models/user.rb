class User < DBI::Model( :users )
  def admin?
    has_flag? 'admin'
  end
  
  def to_s
    username
  end
  
  def subscribe_to( ticket )
    begin
      num_inserted = $dbh.i(
        "INSERT INTO ticket_subscriptions( ticket_id, user_id ) VALUES ( ?, ? )",
        ticket.id,
        id
      )
      num_inserted > 0
    rescue DBI::ProgrammingError => e
      if e.message =~ /duplicate key violates unique constraint "ticket_subscriptions_ticket_id_key"/
        # already subscribed; ignore
      else
        raise e
      end
    end
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
    if email and not email.empty?
      Thread.new( email,subject, message ) do |email_, subject_, message_|
        begin
          delivered = false
          40.times do |i|
            begin
              Ramaze::EmailHelper.send(
                email_,
                '[LinisTrac] ' + subject_,
                message_
              )
              delivered = true
              break
            rescue Object => e
              Ramaze::Log.error "Try ##{i}: #{e.message_}"
              Ramaze::Log.error e.backtrace.join( "\n" )
            end
            sleep 10
          end
          if not delivered
            Ramaze::Log.warn "Failed to deliver e-mail to #{email_}."
          end
        rescue Object => e
          Ramaze::Log.error e
        end
      end
    end
  end
end