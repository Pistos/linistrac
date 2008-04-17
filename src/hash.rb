class Hash
  # Returns an array of top-level keys which differ between
  # this Hash and the other Hash.
  def diff( other )
    d = []
    keys.each do |key|
      if self[ key ] != other[ key ]
        d << key
      end
    end
    other.keys.each do |key|
      if other[ key ] != self[ key ]
        d << key
      end
    end
    d.uniq
  end
  
  def slice( subhash_keys )
    subhash = Hash.new
    subhash_keys.each do |key|
      if not self[ key ].nil?
        subhash[ key ] = self[ key ]
      end
    end
    subhash
  end
  
end