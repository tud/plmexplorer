class BrecordsController < ApplicationController
  protect_from_forgery :secret => '2kdjnaLI8', :only => [:update, :delete, :create]
  
  def showrecbyrectype
    @rectype = params[:rectype].upcase
  end
  
  def grid_records
    page = (params[:page] || 1).to_i
    limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || "desc"
    rectype = params[:rectype] || "PART"
    
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
      conditions = "brectype = '" + rectype+"' AND " + query
    else
      conditions = "brectype = '" + rectype+"'"  
    end
#
#    page = (params[:page] || 1).to_i
#    rp = (params[:rp] || 30).to_i
#    query = params[:query] || ""
#    qtype = params[:qtype] || ""
#    sortname = params[:sortname] || "brectype,brecname,brecalt,brecver"
#    sortorder = params[:sortorder] || "desc"
#    rectype = params[:rectype] || "PART"
#    puts params
#
#    start = ((page-1) * rp).to_i
#    query = "%"+query+"%"
#
#    # No search terms provided
#    if(query == "%%")
#     conditions = "brectype = '" + rectype+"'"
#    else
#      conditions = ["brectype = '"+rectype+"' AND "+qtype+" like ?", query]
#    end
#    puts conditions
#
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
        u.number,
        u.cage_code,
        u.brecalt,
        u.brecver,
        u.bdesc]}}

      # Convert the hash to a json object
      render :text=>return_data.to_json, :layout=>false
    end
  
end
