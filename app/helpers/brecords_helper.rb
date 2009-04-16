module BrecordsHelper

  def filter_names rectype
    filters = FORMS["#{rectype.upcase}"]
    filternames = Array.new
    if (filters)
      filters.each do |filter|
        filternames << filter['label']
      end
    end
    filternames
  end

  def get_uda_value udas, uda_name
    uda_value = ""
    udas.each do |u|
      if (u.bname == uda_name)
        uda_value = u.bvalue
        break
      end
    end
    uda_value
  end

  def find_result_table_title rectype
    if (rectype != "*")
      "Find result table -- " + (fam_img_tag_rectype(rectype)) + " " + rectype.capitalize.pluralize
    else
      ""
    end
  end

  def navigation_find_items
    items = Array.new
    NAVIGATION['FIND'].each do |entry|
      items << "<a class='wNavigation_find tooltip' href='"+entry['type']+"' title='"+entry['title']+"'>"+fam_img_tag(entry['iconclass'])+entry['label']+"</a>"
    end
    items
  end

  def navigation_report_items
    items = Array.new
    NAVIGATION['REPORT'].each do |entry|
      if entry['rule']
        rc = send entry['rule']
      else
        rc = true
      end
      if rc == true
        items << "<a class='wNavigation_report tooltip' href='"+entry['type']+"' title='"+entry['title']+"'>"+fam_img_tag(entry['iconclass'])+entry['label']+"</a>"
      end
    end
    items
  end

  def fam_img_tag famimg
    "<img src='/images/fam/"+famimg+".gif'/>&nbsp;"
  end

  def fam_img_tag_rectype rectype
    fam_img_tag NAVIGATION['FIND'].find {|hash| hash['type'] == rectype}['iconclass']
  end

  def default_reftypes relations, rectype
    reftypes = [ ]
    relations[rectype.upcase] && relations[rectype.upcase].each do |relation|
      reftypes << relation['reftype'] if relation['default']
    end
    reftypes.join(',')
  end

  def get_report_title action
    NAVIGATION['REPORT'].find {|hash| hash['type'] == action}['title']
  end

  def image_exporter
    false
  end
end
