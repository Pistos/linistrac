class String
  def marked_up
    s = self.gsub( /ticket(?: #?|:)(\d+)/i, "[\\0](/ticket/view/\\1)" )
    BlueCloth.new( s ).to_html
  end
end