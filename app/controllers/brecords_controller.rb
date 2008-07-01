class BrecordsController < ApplicationController
  protect_from_forgery :secret => '2kdjnaLI8', :only => [:update, :delete, :create]
  
  def parts
  end
  
  def grid_parts
      page = (params[:page] || 1).to_i
      rp = (params[:rp] || 30).to_i
      query = params[:query] || ""
      qtype = params[:qtype] || ""
      sortname = params[:sortname] || "brectype,brecname,brecalt,brecver"
      sortorder = params[:sortorder] || "desc"

      start = ((page-1) * rp).to_i
      query = "%"+query+"%"

      # No search terms provided
      if(query == "%%")
        @brecords = Brecord.find :all,
          :offset => start,
          :limit => rp,
          :order => sortname+' '+sortorder,
          :select =>"id,brectype, brecname, brecalt, brecver, bdesc",
          :conditions => ["brectype = 'PART'"]
        count = Brecord.count :all,
          :conditions=>["brectype = 'PART'"]
      else
        @brecords = Brecord.paginate :all,
          :select =>"id,brectype, brecname, brecalt, brecver, bdesc",
          :order => sortname+' '+sortorder,
          :offset => start,
          :limit => rp,
          :conditions=>["brectype = 'PART' AND "+qtype+" like ?", query]
        count = Brecord.count :all,
          :conditions=>["brectype = 'PART' AND "+qtype+" like ?", query]
      end

      # Construct a hash from the ActiveRecord result
      return_data = Hash.new()
      return_data[:page] = page
      return_data[:total] = count

      return_data[:rows] = @brecords.collect{|u| {
        :cell=>[
          u.brectype,
          u.recname,
          u.cage_code,
          u.brecalt,
          u.brecver,
          u.bdesc]}}

      # Convert the hash to a json object
      render :text=>return_data.to_json, :layout=>false
    end
  
end
