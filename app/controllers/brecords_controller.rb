class BrecordsController < ApplicationController
  
  ESCAPE = '\\'
  
  def index
    @rectype = ''
    @clause = "brectype = ' '"
    render :action => "show"
  end

  def show
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
    sord = params[:sord]
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
      :select =>"id, brecname, brecalt, breclevel, bdesc",
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

    return_data[:rows] = @brecords.collect{|u| {
      :id => u.id,
      :cell => [
        u.id,
        u.name,
        u.cage_code,
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
    sord = params[:sord]
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
      
    count = Bref.count :all,
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
end
