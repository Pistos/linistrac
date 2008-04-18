class TicketDelta
  attr_reader :time, :changer, :changes
  
  def initialize( ss1, ss2 )
    @time = ss2.time_snapshot
    @changer = ss2.changer
    @changes = ss1.diff( ss2 ).map { |key|
      case key
        when 'resolution_id'
          {
            :key => 'Resolution',
            :old => Resolution[ ss1[ key ].to_i ],
            :new => Resolution[ ss2[ key ].to_i ],
          }
        when 'status_id'
          {
            :key => 'Status',
            :old => Status[ ss1[ key ].to_i ],
            :new => Status[ ss2[ key ].to_i ],
          }
        when 'severity_id'
          {
            :key => 'Severity',
            :old => Severity[ ss1[ key ].to_i ],
            :new => Severity[ ss2[ key ].to_i ],
          }
        else
          {
            :key => key,
            :old => ss1[ key ],
            :new => ss2[ key ],
          }
      end
    }
  end
  
  def time_s( format = '%Y-%m-%d %H:%M' )
    @time.strftime format
  end
end