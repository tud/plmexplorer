module BrecordsHelper

  def tab_names rectype
    tabs = TABS["#{rectype}"]
    tabnames = Array.new
    tabs.each do |htab|
      tab = Hash.new
      tab['label'] = "<span>"+htab['label']+"</span>"
      tab['action'] = htab['label'].gsub(/ /,'_').to_s
      tab['fields'] = htab['fields']
      tabnames << tab
    end
    tabnames
  end

  def tab_commons
    tabs = TABS['COMMONS']
    tabnames = Array.new
    tabs.each do |htab|
      tab = Hash.new
      tab['label'] = "<span>"+htab['label']+"</span>"
      tab['action'] = htab['action']
      tab['fields'] = htab['fields']
      tabnames << tab
    end
    tabnames
  end

end
