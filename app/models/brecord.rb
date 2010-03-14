class Brecord < ActiveRecord::Base
  has_many   :budas,         :foreign_key => 'bobjid'
  has_many   :bfiles,        :foreign_key => 'bobjid'
  has_many   :bpromotions,   :foreign_key => 'bobjid'
  has_many   :bchkhistories, :foreign_key => 'bobjid'
  has_many   :brefs,         :foreign_key => 'bobjid'

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

  def migrated?
    project.migrated?
  end

  def obsolete?
    project.obsolete?
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

  def files
    (bfiles + parents('IMAGE_FOR').map { |image| image.bfiles }.flatten).sort { |f1,f2| f1.name <=> f2.name }
  end

  def file(balias)
    for file in files
      return file if file.balias == balias
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
    recspec = self[:brectype] + '\\' + self[:brecname] + '\\' + self[:brecalt].to_s
    recalt = self[:brecalt]
    recalt = ' ' if !recalt || recalt.empty?
    record_exists = Brecord.exists?(:brectype => self[:brectype], :brecname => self[:brecname], :brecalt => recalt)

    logfile = Tempfile.new(self[:brecname])
    if ENV['RAILS_ENV'] == 'development'
      # In sviluppo creo lo script DMS di lancio del report
      # in un file temporaneo
      script = logfile
    else
      # In produzione uso il file temporaneo come file di log
      # e creo una pipe verso una sessione DMS remota, cui sottometto
      # lo script di lancio del report
      logfile.close
      script = IO.popen("rsh #{PREF['SHERPA_SERVER']} dms > #{logfile.path}", "w")
    end
    script.puts("set db #{PREF['SHERPA_DB']}")
    script.puts("set user #{self[:bcreateuser]}")

    # Incremento campo Autonumber, su usato
    if self[:autonumber]
      script.puts("modify record PIM_AUTONUM\\WORKAUTH")
      script.puts "  change attribute DESC \"#{self[:brecname].to_i + 1}\""
      script.puts("end modify")
    end

    if record_exists
      script.puts "modify record #{recspec}"
    else
      script.puts "create record #{recspec}"
    end

    CHANGE_ATTRIBUTES.each do |attr|
      if self[attr]
        script.puts "  change attribute #{attr.to_s.upcase[1..-1]} \"#{self[attr]}\""
      end
    end
    budas.each do |uda|
      if uda.bvalue
        script.puts "  change attribute #{uda.bname.upcase} \"#{uda.bvalue}\""
      end
    end

    if record_exists
      script.puts "end modify"
    else
      script.puts "end create"
    end
    script.puts("exit")
    script.close
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

  def uda_t_size(rectype, name)
    Batt.find(:all, :conditions => [ "BRECTYPE = ? and BNAME like ?", rectype.upcase, name.upcase+'_%' ]).count
  end

end
