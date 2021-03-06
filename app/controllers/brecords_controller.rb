include ActionView::Helpers::TextHelper

class BrecordsController < ApplicationController

  require 'tempfile'

  before_filter :authorize

  def index
    @joins = ''
    uda_ref = 'u0'
    if request.post?
      brecord = params[:brecord]
      @rectype = brecord[:find_rec_brectype].upcase
      condition = Condition.new('id = blatest')  # considero solo l'ultima versione
      latest_rev = false
      name = nil
      cage_code = nil
      brecord.each do |key, value|
        downkey = key.downcase
        case downkey
        when /find_rec_(.+)/
          field = $1
          if field != 'bdesc'
            normalize(value)
          end
          if field == 'brectype' and value == 'GENERIC'
            # Limito comunque la ricerca ai soli rectypes gestiti
            rectypes = APPL_RECTYPES.map { |rectype| "'#{rectype}'" }.join(',')
            condition << "brectype in (#{rectypes})"
          elsif field == 'name'
            name = value
          elsif field == 'bname1'
            cage_code = value
          else
            if field == 'brecalt' and value[-1,1] == '#'
              value[-1,1] = '*'
              latest_rev = true
            end
            condition.add(field, value)
          end
        when /find_uda_(.+)/
          if !Condition.matches_any(value)
            field = $1.upcase
            uda_ref.next!
            @joins += ',budas ' + uda_ref
            condition.add(uda_ref+'.bname', field)
            condition.add(uda_ref+'.bvalue', value)
            condition << uda_ref+'.bobjid = brecords.id'
          end
        else
          raise "Illegal field name: #{key}"
        end
      end
      if name.nil?
        # Il recname non contiene il Cage Code (es. WORKAUTH)
        condition.add("bname1", cage_code)
      else
        # Il recname contiene il Cage Code (es. PART)
        unless Condition.matches_any(name) && Condition.matches_any(cage_code)
          value = name
          value += ('&' + cage_code) unless cage_code.nil?
          condition.add('brecname', value)
        end
      end
      if latest_rev
        @conditions = "(brectype,brecname,brecalt) IN (SELECT brectype,brecname,MAX(brecalt) FROM brecords#{@joins} WHERE #{condition.to_s} GROUP BY brectype,brecname)"
        @joins = ''
      else
        @conditions = condition.to_s
      end
      render :layout => false
    else
      @rectype = "*"
      @conditions = "brectype = '!'"
    end
  end

  def find
    @rectype = params[:rectype].upcase

    if @rectype == 'GENERIC'
      rectypes = APPL_RECTYPES
    else
      rectypes = [ @rectype ]
    end
    @statusList = Blevel.find(:all,
                              :conditions => [ "blevels.bobjid = brelprocs.id and brelprocs.id = brelrectypes.bobjid and brelrectypes.bname in (?)", rectypes ],
                              :joins => ',brelprocs,brelrectypes').map { |level| level.bname }.sort.uniq

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
    render :layout => false
  end

  def fam_img_tag famimg
    "<img src='/images/fam/"+famimg+".gif'/>&nbsp;"
  end
  
  def fam_img_tag_rectype rectype
    fam_img_tag NAVIGATION['FIND'].find {|hash| hash['type'] == rectype}['iconclass']
  end

  def grid_records
    prep_query

    @brecords = Brecord.find :all,
      :order => @order,
      :limit => @limit,
      :offset => @offset,
      :select => 'id, brectype, brecname, brecalt, breclevel, bdesc, bname1, bproject',
      :conditions => @conditions,
      :joins => @joins
    count = Brecord.count :all, :conditions => @conditions, :joins => @joins

    prep_return_data(count)
    @return_data[:rows] = @brecords.collect{|u| {
      :id => u.id,
      :cell => [
        u.id,
        fam_img_tag_rectype(u.brectype),
        u.name,
        u.bname1,
        u.brecalt,
        u.ext_rev,
        u.breclevel,
        u.bdesc,
        u.effective_icon ]}}

    # Convert the hash to a json object
    render :text => @return_data.to_json, :layout => false
  end

  def grid_children
    prep_query

    record = session[:curr_record] || Brecord.find(params[:id])
    reftypes = params[:reftypes]
    count = record.brefs.of_type(reftypes).size
    children = record.children(reftypes, @order, @limit, @offset)
      
    prep_return_data(count)
    @return_data[:rows] = children.collect{|u| {
      :id => u.id,
      :cell => [
        u.id,
        u.breftype,
        fam_img_tag_rectype(u.brectype),
        u.name,
        u.cage_code,
        u.brecalt,
        u.breclevel,
        u.bdesc,
        u.bquantity] }}

    # Convert the hash to a json object
    render :text => @return_data.to_json, :layout => false
  end

  def fam_icon_rectype rectype
    "/images/fam/"+NAVIGATION['FIND'].find {|hash| hash['type'] == rectype}['iconclass']+".gif"
  end
  
  def tree_children
    if params[:id] == "0"
      record = session[:curr_record]
      root = true
    else
      record = Brecord.find(params[:id])
      root = false
    end

    reftypes = params[:reftypes]
    children = record.children(reftypes,"breftype,brectype,brecname")

    if root
      @return_data = Hash.new { |h,v| h[v]= Hash.new }
      @return_data[:state] = "open"
      @return_data[:data][:title]= Brecord.tree_label record
      @return_data[:data][:icon] = fam_icon_rectype record.brectype
      @return_data[:attr][:id] = record.id.to_s
      @return_data[:children] = children.collect{|u| {
        :state => "closed",
        :data => {
          :title => u.tree_label,
          :icon => fam_icon_rectype(u.brectype)
        },
        :attr => {
          :id => u.id.to_s
        }
      }}
    else
      @return_data = children.collect{|u| {
        :state => "closed",
        :data => {
          :title => u.tree_label,
          :icon => fam_icon_rectype(u.brectype)
        },
        :attr => {
          :id => u.id.to_s
        }
      }}
    end

    # Convert the hash to a json object
    render :text => @return_data.to_json, :layout=>false
  end
  
  def grid_parents
    prep_query

    record = session[:curr_record] || Brecord.find(params[:id])
    reftypes = params[:reftypes]
    count = record.parents_count(reftypes)
    parents = record.parents(reftypes, @order, @limit, @offset)

    prep_return_data(count)
    @return_data[:rows] = parents.collect{|u| {
      :id => u.id,
      :cell => [
        u.id,
        u.breftype,
        fam_img_tag_rectype(u.brectype),
        u.name,
        u.cage_code,
        u.brecalt,
        u.breclevel,
        u.bdesc] }}

    # Convert the hash to a json object
    render :text => @return_data.to_json, :layout => false
  end
  
  def tree_parents
    if params[:id] == "0"
      record = session[:curr_record]
      root = true
    else
      record = Brecord.find(params[:id])
      root = false
    end

    reftypes = params[:reftypes]
    parents = record.parents(reftypes,"breftype,brectype,brecname")

    if root
      @return_data = Hash.new { |h,v| h[v]= Hash.new }
      @return_data[:state] = "open"
      @return_data[:data][:title]= Brecord.tree_label record
      @return_data[:data][:icon] = fam_icon_rectype record.brectype
      @return_data[:attr][:id] = record.id.to_s
      @return_data[:children] = parents.collect{|u| {
        :state => "closed",
        :data => {
          :title => Brecord.tree_label(u),
          :icon => fam_icon_rectype(u.brectype)
        },
        :attr => {
          :id => u.id.to_s
        }
      }}
    else
      @return_data = parents.collect{|u| {
        :state => "closed",
        :data => {
          :title => Brecord.tree_label(u),
          :icon => fam_icon_rectype(u.brectype)
        },
        :attr => {
          :id => u.id.to_s
        }
      }}
    end

    # Convert the hash to a json object
    render :text => @return_data.to_json, :layout=>false
  end

  def grid_promotions
    prep_query

    record = session[:curr_record] || Brecord.find(params[:id])
    count = record.bpromotions.size
    promotions = record.bpromotions :order => @order, :limit => @limit, :offset => @offset

    prep_return_data(count)
    id = 1
    @return_data[:rows] = promotions.collect{|u| {
      :id => id+1,
      :cell => [
        id,
        u.promdate,
        u.blevel,
        u.brelproc,
        u.buser,
        u.bdesc]}}

    # Convert the hash to a json object
    render :text => @return_data.to_json, :layout => false
  end

  def grid_signoffs
    prep_query

    record = session[:curr_record] || Brecord.find(params[:id])
    count = record.bchkhistories.size
    signoffs = record.bchkhistories :order => @order, :limit => @limit, :offset => @offset

    prep_return_data(count)
    id = 1
    @return_data[:rows] = signoffs.collect{|u| {
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
    render :text => @return_data.to_json, :layout => false
  end

  def grid_revisions
    prep_query

    record = session[:curr_record] || Brecord.find(params[:id])
    conditions = [ 'brectype = ? AND brecname = ? AND id = blatest', record.brectype, record.brecname ]
    count = Brecord.count :all, :conditions => conditions
    revisions = Brecord.find :all,
      :order => @order,
      :limit => @limit,
      :offset => @offset,
      :select =>'id, brectype, brecname, brecalt, breclevel, bproject, bowner, bpromdate',
      :conditions => conditions

    prep_return_data(count)
    @return_data[:rows] = revisions.collect{|u| {
      :id => u.id,
      :cell => [
        u.id,
        u.brecalt,
        u.breclevel,
        u.bproject,
        u.bowner,
        u.promdate]}}

    # Convert the hash to a json object
    render :text => @return_data.to_json, :layout => false
  end
  
  def format_icon_files type
    if type == 'pdf'
      image = "page_white_acrobat"
    elsif type == 'zip'
      image = "page_white_compressed"
    elsif type == 'doc'
      image = "page_white_word"
    elsif type == 'dwg'
      image = "vector"
    elsif type == 'tif'
      image = "image"
    elsif type == '.c4'
      image = "image"
    elsif type == 'xls'
      image = "page_white_excel"
    else
      image = "page_white"
    end
    "<img src='/images/fam/"+image+".gif' />"
  end
  
  def grid_files
    prep_query
    
    record = session[:curr_record] || Brecord.find(params[:id])
    count = record.files.size
    files = record.files

    prep_return_data(count)
    @return_data[:rows] = files.collect{|u| {
      :id => u.balias,
      :cell => [
        u.balias,
        format_icon_files(u.format),
        u.name,
        u.size,
        u.balias] }}

    # Convert the hash to a json object
    render :text => @return_data.to_json, :layout => false
  end

  def load_record_base
    @record = Brecord.find(params[:id])
    session[:curr_record] = @record
    
    wrksp = session[:workspace] || Workspace.new
    obj = {:id => @record.id, :rectype => @record.brectype, :label => @record.workspace_label }
    wrksp.add obj
    session[:workspace] = wrksp
    
    render :layout => false
  end

  def load_record_children
    @record = Brecord.find(params[:id])
    @reftypes = params[:reftypes]
    @id = params[:id]
    cookiename = "children_" + @record.brectype
    session[cookiename] = {:reftypes => @reftypes, :view => ""}
    render :layout => false
  end
  
  def load_record_children_tree
    @record = Brecord.find(params[:id])
    @reftypes = params[:reftypes]
    @id = params[:id]
    cookiename = "children_" + @record.brectype
    session[cookiename] = {:reftypes => @reftypes, :view => "_tree"}
    render :layout => false
  end

  def load_record_history
    @id = params[:id]
    render :layout => false
  end
  
  def load_record_workflow
    @record = Brecord.find(params[:id])
    render :layout => false
  end
  
  def load_record_parents
    @record = Brecord.find(params[:id])
    @reftypes = params[:reftypes]
    @id = params[:id]
    cookiename = "parents_" + @record.brectype
    session[cookiename] = {:reftypes => @reftypes, :view => ""}
    render :layout => false
  end
  
  def load_record_parents_tree
    @record = Brecord.find(params[:id])
    @reftypes = params[:reftypes]
    @id = params[:id]
    cookiename = "parents_" + @record.brectype
    session[cookiename] = {:reftypes => @reftypes, :view => "_tree"}
    render :layout => false
  end
  
  def load_record_files
    @id = params[:id]
    @record = Brecord.find(@id)
    render :layout => false
  end

  def export
    logger.info(params[:id])
    logger.info(params[:balias])
    record = Brecord.find(params[:id])
    file = record.file(params[:balias])
    send_file(file.path, :filename => file.name, :x_sendfile => (ENV['RAILS_ENV'] == 'production'))
  end

  def show_workspace
    @workspace = session[:workspace] || Workspace.new
    render :layout => false
  end
  
  def clear_workspace
    session[:workspace].clear if session[:workspace]
    redirect_to(:action => 'show_workspace')
  end
  
  def new
    @brecord = Brecord.new
    @brecord[:brectype] = params[:rectype].upcase
    @action_type = 'create'
    render :layout => false
  end

  def show_modify
    @brecord = session[:curr_record]
    @action_type = 'modify'
    render :action => 'new', :layout => false
  end
  
  def create
    @brecord = Brecord.new
    fill @brecord
    @brecord.create(session[:user][:buser], autonumber?)
    render :save, :layout => false
  end

  def modify
    @brecord = Brecord.new
    fill @brecord
    @brecord.modify(session[:user][:buser])
    render :save, :layout => false
  end

  def approve
    @record = session[:curr_record]
    #level_name = @record.blevel.next.bname
    level_name = params[:chk_level]
    chk_name = params[:chk_name]
    chk_comment = params[:chk_comment]
    @record.approve(session[:user][:buser], chk_name, level_name, chk_comment)
    session[:curr_record] = @record
    render :layout => false
  end

private

  def normalize(string)
    string ||= ''
    string.sub!(/ +$/,'')
    string.sub!(/^$/,'*')
    string.upcase!
    return string
  end

  def prep_query
    page = (params[:page] || 1).to_i
    @limit = (params[:rows]).to_i
    sidx = params[:sidx]
    sord = params[:sord] || 'asc'
    @order = sidx + ' ' + sord
    @conditions = params[:conditions]
    @joins = params[:joins]

    prev_limit = session[:prev_limit].to_i

    if (prev_limit != @limit)
      page = 1
    end
    @offset = ((page-1) * @limit).to_i
    if (@offset < 0)
      @offset = 0
    end

################################################################################
# Non si gestisce piu' il filtro sulle grid, pertanto il seguente codice
# viene commentato
################################################################################
#    isSearch     = params[:_search]
#    searchField  = params[:searchField]
#    searchOper   = params[:searchOper]
#    searchString = params[:searchString]
#
#    if searchField != 'bdesc'
#      searchString.upcase! if searchString
#    end
#    if (isSearch == 'true')
#      if (searchOper == 'eq')
#        oper = "= '" + searchString +"'"
#      elsif (searchOper == 'bw')
#        oper = "LIKE '" + searchString + "%'"
#      elsif (searchOper == 'ne')
#        oper = "<> '" + searchString +"'"
#      elsif (searchOper == 'lt')
#        oper = "< '" + searchString +"'"
#      elsif (searchOper == 'le')
#        oper = "<= '" + searchString +"'"
#      elsif (searchOper == 'gt')
#        oper = "> '" + searchString +"'"
#      elsif (searchOper == 'ge')
#        oper = ">= '" + searchString +"'"
#      elsif (searchOper == 'ew')
#        oper = "LIKE '%" + searchString +"'"
#      elsif (searchOper == 'cn')
#        oper = "LIKE '%" + searchString +"%'"
#      end
#
#      @conditions += ' AND ' + searchField + ' ' + oper
#      #puts '----> conditions: ' + @conditions
#    end

    # Init a hash for the ActiveRecord result
    @return_data = Hash.new()
    @return_data[:page] = page
    @return_data[:total] = 0
    @return_data[:records] = 0
  end

  def prep_return_data(count)
    session[:prev_limit] = @limit.to_s

    total_pages = (count.to_f/@limit).ceil

    # Construct a hash from the ActiveRecord result
    @return_data[:total] = total_pages
    @return_data[:records] = count
  end

  def autonumber?
    params[:autonumber] == '1'
  end
  
  def fill(brecord)
    brecord[:brectype] = params[:rectype]
    params[:brecord].each do |key, value|
      downkey = key.downcase
      case downkey
      when /^rec_(.+)/
        brecord[$1] = value
      when /^uda_t_(.+)/
        uda_t = $1
        table_size = brecord.uda_t_size(uda_t)
        first_empty = 1
        # Split text area in righe da max 80 caratteri l'una
        word_wrap(value).split(/\n/).each_with_index do |line, index|
          if index <= table_size
            brecord.set_uda(uda_t + '_' + '%02d' % (index+1), line.rstrip)
            first_empty += 1
          end
        end
        # Le restanti righe sono vuote
        (first_empty..table_size).each do |index|
          brecord.set_uda(uda_t + '_' + '%02d' % index, '')
        end
      when /^uda_(.+)/
        brecord.set_uda($1, value)
      when /^file_(.+)/
        # Se non carico nessun file, value � una stringa vuota,
        # altrimenti � un'istanza di Tempfile.
        if value.class == Tempfile
          file = Bfile.new
          file[:upload] = value
          brecord.bfiles << file
        end
      else
        raise "Illegal field name: #{key}"
      end
    end
    brecord[:brectype].upcase!
    brecord[:brecname].upcase!
  end

end
