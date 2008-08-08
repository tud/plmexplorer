class BrecordsController < ApplicationController
  
  ESCAPE = '\\'
  
  def index
    @rectype = ''
  end

  def show
    if request.post?
      brecord = params[:brecord]
      @rectype = brecord[:rec_brectype].upcase
      @clause = ''
      name = '*'
      cage_code = nil
      brecord.each do |key, value|
        downkey = key.downcase
        case downkey
        when /rec_(.+)/
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
      @rectype = params[:rectype].upcase
      @clause = "brectype = '" + @rectype + "'"
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

  def grid_records
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || "desc"
    clause = params[:clause]
    puts clause

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
      conditions = clause + " AND " + query
    else
      conditions = clause
    end

    @brecords = Brecord.find :all,
      :order => sidx+' '+sord,
      :limit => limit,
      :offset => start,
      :select =>"id, brecname, brecalt, brecver, bdesc",
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
        u.brecver,
        u.bdesc]}}

      # Convert the hash to a json object
      render :text=>return_data.to_json, :layout=>false
    end
  
end
