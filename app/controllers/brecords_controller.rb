class BrecordsController < ApplicationController
  
  ESCAPE = '\\'

  def index
    @rectype = ''
    @clause = "brectype is null"
    @hiddengrid = "true"
    redirect_to :action => "show", :rectype => ''
  end

  def show
    @hiddengrid = "false"
    @rectype = params[:rectype].upcase
    if request.post?
      # fake per gestire rectype
      params[:brecord][:find_rec_brectype] = @rectype
      brecord = params[:brecord]
      @clause = ''
      name = '*'
      cage_code = nil
      brecord.each do |key, value|
        downkey = key.downcase
        case downkey
        when /find_rec_(.+)/
          field = $1
          if field != 'bdesc'
            normalize(value)
          end
          if field == 'name'
            name = value
          elsif field == 'cage_code'
            cage_code = value
          else
            @clause = add_condition(@clause, field, value)
          end
        when /uda_(.+)/
          field = $1
        else
          print "Illegal field name: #{key}"
        end
      end
      unless matches_any(name) && matches_any(cage_code)
        value = name
        value += ('&' + cage_code) unless cage_code.nil?
        @clause = add_condition(@clause, 'brecname', value)
      end
    else
      @clause = "brectype = '" + @rectype + "'"
    end
  end

  def grid_records
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || 'desc'
    clause = params[:clause]

    start = ((page-1) * limit).to_i
    if (start < 0)
      start = 0
    end

    isSearch     = params[:_search]
    searchField  = params[:searchField]
    searchOper   = params[:searchOper]
    searchString = params[:searchString]

    if (isSearch == 'true')
      # TODO
      # check cage and name
      if (searchOper == 'eq')
        oper = "= '" + searchString +"'"
      elsif (searchOper == 'bw')
        oper = "LIKE '" + searchString + "%'"
      elsif (searchOper == 'ne')
        oper = "<> '" + searchString +"'"
      elsif (searchOper == 'lt')
        oper = "< '" + searchString +"'"
      elsif (searchOper == 'le')
        oper = "<= '" + searchString +"'"
      elsif (searchOper == 'gt')
        oper = "> '" + searchString +"'"
      elsif (searchOper == 'ge')
        oper = ">= '" + searchString +"'"
      elsif (searchOper == 'ew')
        oper = "LIKE '%" + searchString +"'"
      elsif (searchOper == 'cn')
        oper = "LIKE '%" + searchString +"%'"
      end

      query = searchField + " " + oper
      #puts '----> query=' + query
      conditions = clause + " AND " + query
    else
      conditions = clause
    end

    @brecords = Brecord.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"id, brecname, brecalt, breclevel, bdesc, bname1",
      :conditions => conditions
      
    count = @brecords.size
    
    if (count > 0)
      total_pages = (count/limit).ceil+1
    else
      total_pages = 0
    end

    # Construct a hash from the ActiveRecord result
    return_data = Hash.new()
    return_data[:page] = page
    return_data[:total] = total_pages
    return_data[:records] = count

    return_data[:rows] = @brecords.collect{|u| {
      :id => u.id,
      :cell => [
        u.id,
        u.name,
        u.bname1,
        u.brecalt,
        u.breclevel,
        u.bdesc]}}

    # Convert the hash to a json object
    render :text => return_data.to_json, :layout=>false
  end

  def grid_refs
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || 'desc'
    clause = params[:clause]

    start = ((page-1) * limit).to_i
    if (start < 0)
      start = 0
    end

    isSearch     = params[:_search]
    searchField  = params[:searchField]
    searchOper   = params[:searchOper]
    searchString = params[:searchString]

    if (isSearch == 'true')
      # TODO
      # check cage and name
      if (searchOper == 'eq')
        oper = "= '" + searchString +"'"
      elsif (searchOper == 'bw')
        oper = "LIKE '" + searchString + "%'"
      elsif (searchOper == 'ne')
        oper = "<> '" + searchString +"'"
      elsif (searchOper == 'lt')
        oper = "< '" + searchString +"'"
      elsif (searchOper == 'le')
        oper = "<= '" + searchString +"'"
      elsif (searchOper == 'gt')
        oper = "> '" + searchString +"'"
      elsif (searchOper == 'ge')
        oper = ">= '" + searchString +"'"
      elsif (searchOper == 'ew')
        oper = "LIKE '%" + searchString +"'"
      elsif (searchOper == 'cn')
        oper = "LIKE '%" + searchString +"%'"
      end

      query = searchField + " " + oper
      #puts '----> query=' + query
      conditions = clause + " AND " + query
    else
      conditions = clause
    end

    @brefs = Bref.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"breftype, brectype, brecname, brecalt, bdesc, bquantity",
      :conditions => conditions
      
    count = @brefs.size
    
    if (count > 0)
      total_pages = (count/limit).ceil+1
    else
      total_pages = 0
    end

    # Construct a hash from the ActiveRecord result
    return_data = Hash.new()
    return_data[:page] = page
    return_data[:total] = total_pages
    return_data[:records] = count

    id = 1
    return_data[:rows] = @brefs.collect{|u| {
      :id => id+1,
      :cell => [
        id,
        u.breftype,
        u.brectype,
        u.name,
        u.cage_code,
        u.brecalt,
        u.bdesc,
        u.bquantity]}}

    # Convert the hash to a json object
    render :text => return_data.to_json, :layout=>false
  end
  
  def grid_promotions
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || 'desc'
    clause = params[:clause]

    start = ((page-1) * limit).to_i
    if (start < 0)
      start = 0
    end

    isSearch     = params[:_search]
    searchField  = params[:searchField]
    searchOper   = params[:searchOper]
    searchString = params[:searchString]

    if (isSearch == 'true')
      # TODO
      # check cage and name
      if (searchOper == 'eq')
        oper = "= '" + searchString +"'"
      elsif (searchOper == 'bw')
        oper = "LIKE '" + searchString + "%'"
      elsif (searchOper == 'ne')
        oper = "<> '" + searchString +"'"
      elsif (searchOper == 'lt')
        oper = "< '" + searchString +"'"
      elsif (searchOper == 'le')
        oper = "<= '" + searchString +"'"
      elsif (searchOper == 'gt')
        oper = "> '" + searchString +"'"
      elsif (searchOper == 'ge')
        oper = ">= '" + searchString +"'"
      elsif (searchOper == 'ew')
        oper = "LIKE '%" + searchString +"'"
      elsif (searchOper == 'cn')
        oper = "LIKE '%" + searchString +"%'"
      end

      query = searchField + " " + oper
      #puts '----> query=' + query
      conditions = clause + " AND " + query
    else
      conditions = clause
    end

    @promotions = Bpromotion.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"bpromdate, blevel, brelproc, buser, bdesc",
      :conditions => conditions
      
    count = @promotions.size
    
    if (count > 0)
      total_pages = (count/limit).ceil+1
    else
      total_pages = 0
    end

    # Construct a hash from the ActiveRecord result
    return_data = Hash.new()
    return_data[:page] = page
    return_data[:total] = total_pages
    return_data[:records] = count

    id = 1
    return_data[:rows] = @promotions.collect{|u| {
      :id => id+1,
      :cell => [
        id,
        u.promdate,
        u.blevel,
        u.brelproc,
        u.buser,
        u.bdesc]}}

    # Convert the hash to a json object
    render :text => return_data.to_json, :layout=>false
  end
  
  def grid_signoffs
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || 'desc'
    clause = params[:clause]

    start = ((page-1) * limit).to_i
    if (start < 0)
      start = 0
    end

    isSearch     = params[:_search]
    searchField  = params[:searchField]
    searchOper   = params[:searchOper]
    searchString = params[:searchString]

    if (isSearch == 'true')
      # TODO
      # check cage and name
      if (searchOper == 'eq')
        oper = "= '" + searchString +"'"
      elsif (searchOper == 'bw')
        oper = "LIKE '" + searchString + "%'"
      elsif (searchOper == 'ne')
        oper = "<> '" + searchString +"'"
      elsif (searchOper == 'lt')
        oper = "< '" + searchString +"'"
      elsif (searchOper == 'le')
        oper = "<= '" + searchString +"'"
      elsif (searchOper == 'gt')
        oper = "> '" + searchString +"'"
      elsif (searchOper == 'ge')
        oper = ">= '" + searchString +"'"
      elsif (searchOper == 'ew')
        oper = "LIKE '%" + searchString +"'"
      elsif (searchOper == 'cn')
        oper = "LIKE '%" + searchString +"%'"
      end

      query = searchField + " " + oper
      #puts '----> query=' + query
      conditions = clause + " AND " + query
    else
      conditions = clause
    end

    @signoffs = Bchkhistory.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"bdate, bcommand, bstatus, bname, buser, bdesc",
      :conditions => conditions
      
    count = @signoffs.size
    
    if (count > 0)
      total_pages = (count/limit).ceil+1
    else
      total_pages = 0
    end

    # Construct a hash from the ActiveRecord result
    return_data = Hash.new()
    return_data[:page] = page
    return_data[:total] = total_pages
    return_data[:records] = count

    id = 1
    return_data[:rows] = @signoffs.collect{|u| {
      :id => id+1,
      :cell => [
        id,
        u.date,
        u.bcommand,
        u.bstatus,
        u.bname,
        u.buser,
        u.bdesc]}}

    # Convert the hash to a json object
    render :text => return_data.to_json, :layout=>false
  end

  def load_record_base
    @record = Brecord.find(params[:id])
  end

  def load_record_refs
    @refs = Brecord.find(params[:id]).brefs
  end

  def load_record_history
    rec = Brecord.find(params[:id])
    @promotions = rec.bpromotions
    @chkhistories = rec.bchkhistories
    @revisions = Brecord.find_all_by_brectype_and_brecname(rec.brectype,rec.brecalt)
  end

  private
  def normalize(string)
    string ||= ''
    string.sub!(/ +$/,'')
    string.sub!(/^$/,'*')
    string.upcase!
    return string
  end

  def matches_any(string)
    string.nil? || /^\**$/.match(string)
  end

  def add_condition(clause, field, value)
    if !matches_any(value)
      clause ||= ''
      clause += ' AND ' unless clause.empty?
      if value.index(/[*?]/).nil?
        # there are no wildcards in value
        clause += "#{field} = '#{value}'"
      else
        # translate wildcards into SQL
        value.gsub!(/%/,ESCAPE+'%')
        value.gsub!(/_/,ESCAPE+'_')
        value.gsub!(/\*/,'%')
        value.gsub!(/\?/,'_')
        clause += "#{field} LIKE '#{value}' ESCAPE '#{ESCAPE}'"
      end
    end
    return clause
  end
  
  def get_tabs rectype
    if (rectype == 'PART')
      tabs = TABS_PART
    elsif (rectype == 'WORKAUTH')
      tabs = TABS_WORKAUTH
    elsif (rectype == 'DOCUMENT')
      tabs = TABS_DOCUMENT
    elsif (rectype == 'SOFTWARE')
      tabs = TABS_SOFTWARE
    end
    tabs.each do |tab|
      p tab[:label]
      tab[:fields].each do |field|
        p field[:label]
      end
    end
    return tabs
  end


end
