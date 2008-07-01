class CitiesController < 
  def list
    end

    def grid_data
      page = (params[:page]).to_i
      rp = (params[:rp]).to_i
      query = params[:query]
      qtype = params[:qtype]
      sortname = params[:sortname]
      sortorder = params[:sortorder]

      if (!sortname)
        sortname = "iso"
      end

      if (!sortorder)
        sortorder = "desc"
      end

      if (!page)
        page = 1
      end

      if (!rp)
        rp = 10
      end

      start = ((page-1) * rp).to_i
      query = "%"+query+"%"

      # No search terms provided
      if(query == "%%")
        @countries = Country.find(:all,
    	:order => sortname+' '+sortorder,
    	:limit =>rp,
    	:offset =>start
    	)
        count = Country.count(:all)
      end

      # User provided search terms
      if(query != "%%")
          @countries = Country.find(:all,
  	  :order => sortname+' '+sortorder,
  	  :limit =>rp,
    	  :offset =>start,
    	  :conditions=>[qtype +" like ?", query])
  	count = Country.count(:all,
  	  :conditions=>[qtype +" like ?", query])
      end

      # Construct a hash from the ActiveRecord result
      return_data = Hash.new()
      return_data[:page] = page
      return_data[:total] = count

      return_data[:rows] = @countries.collect{|u| {
    			   :cell=>[u.iso,
    			   u.name,
    			   u.printable_name,
    			   u.iso3,
      			   u.numcode]}}

      # Convert the hash to a json object
      render :text=>return_data.to_json, :layout=>false
    end
  
end
