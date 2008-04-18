class TicketDelta
  attr_reader :time, :changer, :changes
  
  def initialize( ss1, ss2 )
    @time = ss2.time_snapshot
    @changer = ss2.changer
    @changes = ss1.diff( ss2 ).map { |key|
      case key
        when 'group_id'
          {
            :key => 'Group',
            :old => Group[ ss1[ key ].to_i ],
            :new => Group[ ss2[ key ].to_i ],
          }
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
        when 'title', 'tags'
          {
            :key => key[ 0..0 ].upcase + key[ 1..-1 ],
            :old => '"' + ss1[ key ] + '"',
            :new => '"' + ss2[ key ] + '"',
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