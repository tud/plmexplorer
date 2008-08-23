module BrecordsHelper

  def tab_names rectype
    tabs = TABS["#{rectype}"]
    tabnames = Array.new
    if (tabs)
      tabs.each do |htab|
        tab = Hash.new
        tab['label'] = "<span>"+htab['label']+"</span>"
        tab['action'] = htab['label'].gsub(/ /,'_').to_s
        tab['fields'] = htab['fields']
        tabnames << tab
      end
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

  def get_uda_value udas, uda_name
    uda_value = nil
    udas.each do |u|
      if (u.bname == uda_name)
        uda_value = u.bvalue
        break
      end
    end
    uda_value
  end

end
