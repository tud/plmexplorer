class Brecord < ActiveRecord::Base
  has_many   :budas,         :foreign_key => 'bobjid'
  has_many   :bfiles,        :foreign_key => 'bobjid'
  has_many   :bpromotions,   :foreign_key => 'bobjid'
  has_many   :bchkhistories, :foreign_key => 'bobjid'
  has_many   :brefs,         :foreign_key => 'bobjid'

  require 'ftools'
  require 'tempfile'

  CHANGE_ATTRIBUTES = [ :bdesc, :bowner, :bproject, :brelproc, :btype1, :btype2, :btype3, :btype4, :bname1, :bname2, :bname3, :bname4, :bdate1, :bdate2, :bdate3, :bdate4, :blong1, :blong2, :blong3, :blong4, :bdouble1, :bdouble2, :bdouble3, :bdouble4, :bdouble5, :bdouble6, :bdouble7, :bdouble8, :bcost, :bfamily, :bbegindate, :benddate, :bmeasure ]

  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1] || ''
  end

  def title
    brecname.gsub(/&/,'~')+" Rev. "+brecalt+" at Status "+breclevel+" - "+bdesc
  end

  def promdate
    self[:bpromdate].to_s(:db) if self[:bpromdate]
  end

  def project
    @project ||= Bproject.find_by_bname(bproject)
  end

  def relproc
    @relproc ||= Brelproc.find_by_bname(brelproc)
  end

  def migrated?
    project.migrated?
  end

  def obsolete?
    project.obsolete?
  end

  def modifiable?(by_user)
    if by_user =~ /^SHERPA/
      true
    elsif migrated?
      false
    else
      # Trovo tutte le user classes cui appartiene l'utente nell'ambito del progetto.
      # Aggiungo sempre la classe DBUSER, cui appartengono tutti gli utenti.
      uclasses = project.bprjusers.find_all { |prjuser| prjuser.buser == by_user }.collect { |prjuser| prjuser.buclass } + [ 'DBUSER' ]
      # Calcolo l'unione di tutti i privilegi garantiti alle user classes dell'utente
      # all'attuale stato di rilascio del record nell'ambito della release procedure.
      privs = relproc.baccesses.find_all { |access| access.blevelid == blevelid and uclasses.include? access.buclass }.collect { |access| access.bpriv }
      # Controllo che ad almeno una user class siano garantiti Update e Modify.
      privs.detect { |priv| priv =~ /UM/ }
    end
  end

  def self.tree_label u
    u[:breftype] ||= ""
    u.breftype+" "+u.brecname.gsub(/&/,'~')+" Rev. "+u.brecalt+" at Status "+u.breclevel+" - "+u.bdesc
  end

  def workspace_label
    name+"-"+brecalt
  end

  def effective_icon
    html = ""
    if migrated?
      html = "<img src='/images/windchill.png' title='Migrated object'/>"
    elsif obsolete?
      html = "<img src='/images/obsolete.png' title='Obsolete object'/>"
    end
    html
  end

  def self.latest(brectype, brecname, brecalt = '#')
    conditions = "brectype = '#{brectype}' AND brecname = '#{brecname}' AND id = blatest"
    if brecalt && brecalt[-1,1] == '#'
      brecalt[-1,1] = '%'
      conditions += " AND brecalt like '#{brecalt}'"
    end
    latest_rev = self.find(:first, :conditions => conditions, :order => 'brecalt DESC')
  end

  def ext_rev
    if brectype == 'PART'
      uda('EXT_PART_RECALT')
    elsif brectype == 'DOCUMENT'
      uda('EXT_DOC_RECALT')
    else
      ''
    end
  end

  def uda(name)
    @udas ||= budas
    @udas.map { |uda| uda.bvalue if uda.bname == name.upcase }.compact.to_s
  end

  def uda_t(name)
    text = ""
    (1..uda_t_size(name)).each do |index|
      value = uda(name + '_' + '%02d' % index)
      text += value + "\n" if not value.empty?
    end
    text
  end

  def uda_t_size(name)
    Batt.find(:all, :conditions => [ "BRECTYPE = ? and BNAME like ?", self[:brectype].upcase, name.upcase+'_%' ]).size
  end

  def files
    (bfiles + parents('IMAGE_FOR').map { |image| image.bfiles }.flatten).sort { |f1,f2| f1.name <=> f2.name }
  end

  def file(name)
    for file in files
      return file if file.balias == name.upcase
    end
  end

  def children(reftypes = '', order = nil, limit = nil, offset = 0)
    brefs.of_type(reftypes).all(:order => order, :limit => limit, :offset => offset).each { |ref| ref.resolve }
  end

  def parents_count(reftypes = '')
    parent_entries(reftypes, nil, nil, 0).size
  end

  def parents(reftypes = '', order = nil, limit = nil, offset = 0)
    parent_entries(reftypes, order, limit, offset).map { |rec|
      parent = Brecord.find_by_brectype_and_brecname_and_brecalt(rec.brectype, rec.brecname, rec.brecalt,
                                                                 :conditions => "id = blatest")
      parent[:breftype] = rec.breftype
      parent
    }
  end

  def save
    self[:brectype].upcase!
    self[:brecname].upcase!
    recalt = self[:brecalt].to_s.upcase
    recalt = ' ' if recalt.empty?
    recspec = self[:brectype] + '\\' + self[:brecname] + '\\' + recalt

    logfile = Tempfile.new(self[:brecname])
    if ENV['RAILS_ENV'] == 'development'
      # In sviluppo creo lo script DMS di lancio del report
      # in un file temporaneo
      @script = logfile
    else
      # In produzione uso il file temporaneo come file di log
      # e creo una pipe verso una sessione DMS remota, cui sottometto
      # lo script di lancio del report
      logfile.close
      @script = IO.popen("rsh #{PREF['SHERPA_SERVER']} dms > #{logfile.path}", "w")
    end
    @script.puts("set db #{PREF['SHERPA_DB']}")
    @script.puts("set user #{self[:bcreateuser]}")

    # Incremento campo Autonumber, su usato
    if @autonumber
      @script.puts("modify record PIM_AUTONUM\\#{self[:brectype]}")
      @script.puts "  change attribute DESC \"#{self[:brecname].to_i + 1}\""
      @script.puts("end modify")
    end

    if self[:new]
      @script.puts "create record #{recspec}"
      @curr_rec = Brecord.new
    else
      @script.puts "modify record #{recspec}"
      @curr_rec = Brecord.find_by_brectype_and_brecname_and_brecalt(self[:brectype], self[:brecname], recalt,
                                                                    :conditions => "id = blatest")
    end

    CHANGE_ATTRIBUTES.each do |attr|
      if self[attr]
        @script.puts "  change attribute #{attr.to_s.upcase[1..-1]} \"#{self[attr]}\""
      end
    end
    budas.each do |uda|
      puts_uda(uda[:bname], uda[:bvalue])
    end
    bfiles.each do |file|
      if @curr_rec.bfiles.count > 0
        @script.puts "  remove file *"
      end
      orig_name = File.basename(file[:upload].original_filename)
      upload_name = File.basename(file[:upload].path)
      dest_path = PREF['SHERPA_TMP'][ENV['RAILS_ENV']] + '/' + upload_name
      File.copy(file[:upload].path, dest_path)
      @script.puts "  add file /secure \"#{dest_path}\" #{orig_name}"
    end

    if self[:new]
      @script.puts "end create"
    else
      @script.puts "end modify"
    end
    @script.puts("exit")
    @script.close
  end

  def set_uda(name, value)
    buda = Buda.new
    buda[:bname] = name
    buda[:bvalue] = value
    budas << buda
  end

  def autonumber
    @autonumber = true
    self[:brecname] = Brecord.find_by_brectype_and_brecname('PIM_AUTONUM', self[:brectype].upcase).bdesc
  end

  alias :original_method_missing :method_missing

  def method_missing(method_name, *args, &block)
    case method_name.to_s
    when /^rec_(.+)/
      send($1, *args, &block)
    when /^uda_t_(.+)/
      uda_t($1)
    when /^uda_(.+)/
      uda($1)
    when /^file_(.+)/
      if bfiles.count > 0
        bfiles[0].balias
      else
        ""
      end
    else
      original_method_missing(method_name, *args, &block)
    end
  end


  private

  def parent_entries(reftypes, order, limit, offset)
    select = 'DISTINCT brefs.breftype, brecords.brectype, brecords.brecname, MAX(brecords.brecalt) AS brecalt'
    joins = ', brecords'
    conditions = 'brefs.bobjid = brecords.id'
    group = 'brefs.breftype, brecords.brectype, brecords.brecname'
    Bref.of_type(reftypes).parent_of(self).all(:select => select,
                                               :joins => joins,
                                               :conditions => conditions,
                                               :group => group,
                                               :order => order,
                                               :limit => limit,
                                               :offset => offset)
  end

  def puts_uda(name, value)
    if @curr_rec.uda(name).strip != value
       @script.puts "  change attribute #{name.upcase} \"#{value}\""
    end
  end

end
