xml.instruct! :xml, :version=>"1.0" 
xml.rss(:version=>"2.0"){
  xml.channel  {
    xml.title("#{@item.name} - #{[@setting[:title]].join(" - ")}")
    xml.link(url_for(:action => "view", :controller => "items", :id => @item, :only_path => false ))
    @setting[:meta_description] = @setting[:meta_description].reverse
    @setting[:meta_description].shift
    xml.description(@setting[:meta_description].join(" - "))
    xml.language("#{I18n.locale}")
    
    for log in @item.logs
      xml.item do        
        xml.title(log.log)
        xml.description(log.to_s.downcase)
        xml.pubDate(log.created_at.rfc2822)    
        xml.link(url_for(:controller => "items", :action => "view", :id => @item, :only_path => false))
        xml.guid(url_for(:controller => "items", :action => "view", :id => @item, :only_path => false))
      end
    end    
  }
}