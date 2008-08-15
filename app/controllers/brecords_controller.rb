class BrecordsController < ApplicationController
  
  ESCAPE = '\\'

  def index
    redirect_to :action => :show, :rectype => '*'
  end

  def show
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
            @conditions = add_condition(@conditions, field, value)
          end
        when /find_uda_(.+)/
          if !matches_any(value)
            field = $1.upcase
            join_count += 1
            uda_ref = 'u' + join_count.to_s
            @joins += ', budas ' + uda_ref
            @conditions = add_condition(@conditions, uda_ref+'.bname', field)
            @conditions = add_condition(@conditions, uda_ref+'.bvalue', value)
            @conditions += ' AND ' + uda_ref + '.bobjid = brecords.id'
          end
        else
          print "Illegal field name: #{key}"
        end
      end
      if name.nil?
        # Il recname non contiene il Cage Code (es. WORKAUTH)
        unless matches_any(cage_code)
          @conditions = add_condition(@conditions, "bname1", cage_code)
        end
      else
        # Il recname contiene il Cage Code (es. PART)
        unless matches_any(name) && matches_any(cage_code)
          value = name
          value += ('&' + cage_code) unless cage_code.nil?
          @conditions = add_condition(@conditions, 'brecname', value)
        end
      end
    else
      @rectype = params[:rectype].upcase
      #@conditions = "brectype = '" + @rectype + "'"
      @conditions = "brectype = '!'"
    end

    unless @cageCodes
      @cageCodes = DynList.build_from('IPD_BUSINESSID')
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
  end

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

  def add_condition(conditions, field, value)
    if !matches_any(value)
      conditions ||= ''
      conditions += ' AND ' unless conditions.empty?
      if value.index(/[*?]/).nil?
        # there are no wildcards in value
        conditions += "#{field} = '#{value}'"
      else
        # translate wildcards into SQL
        value.gsub!(/%/,ESCAPE+'%')
        value.gsub!(/_/,ESCAPE+'_')
        value.gsub!(/\*/,'%')
        value.gsub!(/\?/,'_')
        conditions += "#{field} LIKE '#{value}' ESCAPE '#{ESCAPE}'"
      end
    end
    return conditions
  end

  def grid_records
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || "desc"
    conditions = params[:conditions]
    joins = params[:joins]

    start = ((page-1) * limit).to_i
    #start = (limit*(page-limit)).to_i
    if (start < 0)
      start = 0
    end

    isSearch     = params[:_search]
    searchField  = params[:searchField]
    searchOper   = params[:searchOper]
    searchString = params[:searchString]

    if (isSearch == 'true')
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
      :select => "id, brecname, brecalt, brecver, bdesc",
      :conditions => conditions,
      :joins => joins
      
    count = Brecord.count :all,
      :conditions => conditions,
      :joins => joins

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
        u.cage_code,
        u.brecalt,
        u.brecver,
        u.bdesc]}}

      # Convert the hash to a json object
      render :text => return_data.to_json, :layout=>false
    end
  
  def load_record_base
    @record = Brecord.find(params[:id])
  end
  
  def load_record_udas
    @udas = Brecord.find(params[:id]).budas
  end
  
  def load_record_refs
    @refs = Brecord.find(params[:id]).brefs
  end
end
