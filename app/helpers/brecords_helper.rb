module BrecordsHelper

  def tab_names rectype
    tabs = TABS["#{rectype.upcase}"]
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

  def icon_span rectype
    classname = ""
    if (rectype != "*")
      MENU['FIND'].each do |entry|
        if (entry['type'] == rectype.upcase)
          classname = "<span class='ss_sprite "+entry['iconclass']+"'>&nbsp;</span>"
          break
        end
      end
    end
    classname
  end

  def find_result_table_title rectype
    if (rectype != "*")
      "Find result table -- " + (icon_span(rectype)) + " " + rectype.capitalize.pluralize
    else
      ""
    end
  end
  
  def find_menu_items
    items = Array.new
    MENU['FIND'].each do |entry|
      items << "<a href='#' class='find_rec' title='"+entry['type'].downcase+"'>"+icon_span(entry['type'])+entry['label']+"</a>"
    end
    items
  end
  

end
