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
    bchks.detect { |chk| chk.bname == name && chk.blevel == level && chk.bstatus == 'ON' }
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

  def approve(user, chk_name, level_name, comment = '')
    dms_script = DmsScript.new(user, self)
    dms_script.approve_record(chk_name, level_name, comment)
    if autopromote?(chk_name)
      dms_script.promote_record(level_name, MSG['AUTOPROMOTE'])
    end
    dms_script.run
  end

  def promote(user, level_name, comment = '')
    dms_script = DmsScript.new(user, self)
    dms_script.promote_record(level_name, comment)
    dms_script.run
  end

  def autopromote?(curr_check)
    # Si assume che il check corrente vada a buon fine!
    fully_checked = true
    next_level = blevel.next
    next_level.check_list.each do |chk_name|
      if chk_name != curr_check && chk_name != 'OVERRIDE' && !signoff(chk_name, next_level.bname)
        fully_checked = false
      end
    end
    fully_checked || curr_check == 'OVERRIDE'
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

# == Schema Information
#
# Table name: brecords
#
#  btype1         :string(16)
#  btype2         :string(16)
#  btype3         :string(16)
#  btype4         :string(16)
#  bname1         :string(32)
#  bname2         :string(32)
#  bname3         :string(32)
#  bname4         :string(32)
#  blong1         :integer(10)
#  blong2         :integer(10)
#  blong3         :integer(10)
#  blong4         :integer(10)
#  bdate1         :datetime
#  bdate2         :datetime
#  bdate3         :datetime
#  bdate4         :datetime
#  bdouble1       :decimal(, )
#  bdouble2       :decimal(, )
#  bdouble3       :decimal(, )
#  bdouble4       :decimal(, )
#  bdouble5       :decimal(, )
#  bdouble6       :decimal(, )
#  bdouble7       :decimal(, )
#  bdouble8       :decimal(, )
#  bfilecount     :integer(10)
#  brefcount      :integer(10)
#  bdictversion   :integer(5)
#  bsuffix1       :string(12)
#  btimestamp     :datetime
#  bmdtid         :integer(10)
#  bsubclusterid  :integer(5)
#  brevisionid    :integer(10)
#  bpromuser      :string(16)
#  bcanceldesc    :string(80)
#  bcancelrelproc :string(16)
#  baffcount      :integer(10)
#  brecusercount  :integer(10)
#  brectype       :string(16)
#  brecname       :string(32)
#  brecalt        :string(32)
#  brecver        :integer(5)
#  breclevel      :string(16)
#  id             :integer(10)     primary key
#  bid            :integer(10)
#  blatest        :integer(10)
#  blevelid       :integer(5)
#  bowner         :string(16)
#  bcost          :decimal(, )
#  bmeasure       :string(16)
#  bcreateuser    :string(16)
#  created_at     :datetime
#  bcanceluser    :string(16)
#  bcanceldate    :datetime
#  bmodifyuser    :string(16)
#  bmodifydate    :datetime
#  bupdateuser    :string(16)
#  updated_at     :datetime
#  bbegindate     :datetime
#  benddate       :datetime
#  bfamily        :string(16)
#  bdesc          :string(80)
#  bpromdate      :datetime
#  bgroupflag     :string(3)
#  bproject       :string(16)
#  bprjobjid      :integer(10)
#  brelproc       :string(16)
#  brelobjid      :integer(10)
#  barcdate       :datetime
#  barclabel      :string(6)
#  barcset        :string(32)
#  breloaddate    :datetime
#

