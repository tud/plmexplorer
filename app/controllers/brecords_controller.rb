class BrecordsController < ApplicationController
  
  ESCAPE = '|'

  def index
    redirect_to :action => :show, :rectype => '*', :hiddengrid => 'true'
  end

  def show
    @hiddengrid = params[:hiddengrid] || "false"
    @joins = ''
    join_count = 0
    if request.post?
      brecord = params[:brecord]
      @rectype = brecord[:find_rec_brectype].upcase
      @conditions = nil
      name = nil
      cage_code = nil
      brecord.each do |key, value|
        downkey = key.downcase
        case downkey
        when /find_rec_(.+)/
          field = $1.downcase
          if field != 'bdesc'
            normalize(value)
          end
          if field == 'name'
            name = value
          elsif field == 'bname1'
            cage_code = value
          else
            add_condition(field, value)
          end
        when /find_uda_(.+)/
          if !matches_any(value)
            field = $1.upcase
            join_count += 1
            uda_ref = 'u' + join_count.to_s
            @joins += ', budas ' + uda_ref
            add_condition(uda_ref+'.bname', field)
            add_condition(uda_ref+'.bvalue', value)
            @conditions += ' AND ' + uda_ref + '.bobjid = brecords.id'
          end
        else
          print "Illegal field name: #{key}"
        end
      end
      if name.nil?
        # Il recname non contiene il Cage Code (es. WORKAUTH)
        unless matches_any(cage_code)
          add_condition("bname1", cage_code)
        end
      else
        # Il recname contiene il Cage Code (es. PART)
        unless matches_any(name) && matches_any(cage_code)
          value = name
          value += ('&' + cage_code) unless cage_code.nil?
          add_condition('brecname', value)
        end
      end
    else
      @rectype = params[:rectype].upcase
      @conditions = "brectype is null"
    end

    unless @cageCodes
      @cageCodes = DynList.build_from('IPD_BUSINESSID', :bdesc)
    end

    unless @statusList
      if @rectype == '*'
        @statusList = Blevel.find(:all).map { |level| level.bname }.sort.uniq
      else
        @statusList = Blevel.find(:all,
                                  :conditions => "blevels.bobjid = brelprocs.id and brelprocs.id = brelrectypes.bobjid and brelrectypes.bname = '" + @rectype + "'",
                                  :joins => ',brelprocs,brelrectypes').map { |level| level.bname }.sort.uniq
      end
      @statusList.unshift('')
    end

    unless @prjList
      @prjList = Bproject.find(:all).map { |prj| prj.bname }.sort
      @prjList.unshift('')
    end

    unless @userList
      @userList = Bdbuser.find(:all).map { |user| user.buser }.sort.uniq
      @userList.unshift('')
    end

    unless @typeList
      if @rectype == 'PART'
        @typeList = DynList.build_from('IPD_PARTSUBTYPE')
      elsif @rectype == 'DOCUMENT'
        @typeList = DynList.build_from('IPD_DOCSUBTYPE')
      elsif @rectype == 'WORKAUTH'
        @typeList = DynList.build_from('IPD_WORKASUBTYP')
      elsif @rectype == 'SOFTWARE'
        @typeList = DynList.sw_types
      else
        @typeList = []
      end
    end

    unless @docSizes || @rectype != 'DOCUMENT'
      @docSizes = DynList.build_from('IPD_DOCSIZE', :bdesc)
    end

    unless @changeClasses || @rectype != 'WORKAUTH'
      @changeClasses = DynList.build_from('IPD_CHNGCLASS', :bdesc)
    end

    unless @changeSubClasses || @rectype != 'WORKAUTH'
      @changeSubClasses = DynList.build_from('IPD_CHNGSUBCLASS', :bdesc)
    end
  end

  def grid_records
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || 'desc'
    conditions = params[:conditions]
    joins = params[:joins]

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
      conditions += " AND " + query
    end

    @brecords = Brecord.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"id, brecname, brecalt, breclevel, bdesc, bname1",
      :conditions => conditions,
      :joins => joins
      
    count =  Brecord.count :all,
            :conditions => conditions,
            :joins => joins

    total_pages = (count/limit).ceil
      
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
    conditions = params[:conditions]

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
      conditions = conditions + " AND " + query
    else
      conditions = conditions
    end

    @brefs = Bref.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"breftype, brectype, brecname, brecalt, bdesc, bquantity",
      :conditions => conditions
      
    count = Bref.count :all,
            :conditions => conditions
    
    total_pages = (count/limit).ceil

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
    conditions = params[:conditions]

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
      conditions = conditions + " AND " + query
    else
      conditions = conditions
    end

    @promotions = Bpromotion.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"bpromdate, blevel, brelproc, buser, bdesc",
      :conditions => conditions
      
    count = Bpromotion.count :all,
            :conditions => conditions
    
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
    conditions = params[:conditions]

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
      conditions = conditions + " AND " + query
    else
      conditions = conditions
    end

    @signoffs = Bchkhistory.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"bdate, bcommand, bstatus, bname, buser, bdesc",
      :conditions => conditions
      
    count = Bchkhistory.count :all,
            :conditions => conditions
    
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
  
  def grid_revisions
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || 'desc'
    conditions = params[:conditions]

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
      conditions = conditions + " AND " + query
    else
      conditions = conditions
    end

    @revisions = Brecord.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"brectype, brecname, brecalt, breclevel, bproject, bowner, bpromdate",
      :conditions => conditions
      
    count = Brecord.count :all,
            :conditions => conditions
    
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
    return_data[:rows] = @revisions.collect{|u| {
      :id => id+1,
      :cell => [
        id,
        u.brecalt,
        u.breclevel,
        u.bproject,
        u.bowner,
        u.promdate]}}

    # Convert the hash to a json object
    render :text => return_data.to_json, :layout=>false
  end

  def load_record_base
    @record = Brecord.find(params[:id])
  end

  def load_record_refs
    #@refs = Brecord.find(params[:id]).brefs
  end

  def load_record_history
    @record = Brecord.find(params[:id])
    #@promotions = rec.bpromotions
    #@chkhistories = rec.bchkhistories
    #@revisions = Brecord.find_all_by_brectype_and_brecname(rec.brectype,rec.brecalt)
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

def add_condition(field, value)
  if !matches_any(value)
    @conditions ||= ''
    @conditions += ' AND ' unless @conditions.empty?
    if value.index(/[*?]/).nil?
      # there are no wildcards in value
      @conditions += "#{field} = '#{value}'"
    else
      # translate wildcards into SQL
      value.gsub!(/%/,ESCAPE+'%')
      value.gsub!(/_/,ESCAPE+'_')
      value.gsub!(/\*/,'%')
      value.gsub!(/\?/,'_')
      @conditions += "#{field} LIKE '#{value}' ESCAPE '#{ESCAPE}'"
    end
  end
end
end
