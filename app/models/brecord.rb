class Brecord < ActiveRecord::Base
  has_many   :budas,         :foreign_key => 'bobjid'
  has_many   :bchks,         :foreign_key => 'bobjid'
  has_many   :bchkhistories, :foreign_key => 'bobjid'
  has_many   :brefs,         :foreign_key => 'bobjid'
  has_many   :bfiles,        :foreign_key => 'bobjid'
  has_many   :bpromotions,   :foreign_key => 'bobjid'

  attr_accessor :dms_errorlog

  def recspec
    brectype + '\\' + brecname + '\\' + brecalt.to_s
  end

  def name
    brecname.split('&')[0]
  end

  def cage_code
    brecname.split('&')[1] || ''
  end

  def title
    brecname.gsub(/&/,'~')+" Rev. "+brecalt+" at Status "+breclevel+" - "+bdesc
  end

  def promdate
    bpromdate.to_s(:db) if bpromdate
  end

  def project
    @project ||= Bproject.find_by_bname(bproject)
  end

  def relproc
    @relproc ||= Brelproc.find_by_bname(brelproc)
  end

  def blevel(level = breclevel)
    relproc.blevel(level)
  end

  def signoff(name, level)
    bchks.detect { |chk| chk.bname == name && chk.blevel == level && chk.bstatus == 'ON'}
  end

  def migrated?
    project.migrated? if project
  end

  def obsolete?
    project.obsolete? if project
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
    @udas.map { |uda| uda.bvalue if uda.bname == name.upcase }.compact.at(0).to_s
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
    Batt.find(:all, :conditions => [ "BRECTYPE = ? and BNAME like ?", brectype.upcase, name.upcase+'_%' ]).size
  end

  def files
    (bfiles + parents('IMAGE_FOR').map { |image| image.bfiles }.flatten).sort { |f1,f2| f1.name <=> f2.name }
  end

  def file(name)
    for file in files
      return file if file.balias == name.upcase[0..31]
    end
    nil
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

  def set_uda(name, value)
    buda = Buda.new
    buda[:bname] = name
    buda[:bvalue] = value
    budas << buda
  end

  def create(user, autonumber)
    dms_script = DmsScript.new(user, self)
    dms_script.create_record(autonumber) do
      dms_script.change_attributes
      dms_script.add_files
    end
    dms_script.run
    # Se non ci sono errori, carico l'id del record appena creato 
    if (!dms_errorlog)
      self[:id] = Brecord.find_by_brectype_and_brecname_and_brecalt(brectype, brecname, brecalt).id
      Rails.logger.info("\n========== Created: #{recspec} => id: #{id}")
    end
  end

  def modify(user)
    dms_script = DmsScript.new(user, self)
    dms_script.modify_record do
      dms_script.change_attributes
      dms_script.add_files
    end
    dms_script.run
  end

  def approve(user, level_name, chk_name, chk_comment)
    dms_script = DmsScript.new(user, self)
    dms_script.approve_record(level_name, chk_name, chk_comment)
    dms_script.run
  end

  def autopromote?
    fully_checked = true
    override = false
    next_level = blevel.next
    next_level.check_list.each do |chk_name|
      checked = signoff(chk_name, next_level.bname)
      if checked
        if checked.bname == 'OVERRIDE'
          override = true
        end
      else
        fully_checked = false
      end
    end
    fully_checked || override
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
      if files.size > 0
        files[0].name
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

end
