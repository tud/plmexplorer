class Brecord < ActiveRecord::Base
  has_many :budas,         :foreign_key => 'bobjid'
  has_many :bfiles,        :foreign_key => 'bobjid'
  has_many :bpromotions,   :foreign_key => 'bobjid'
  has_many :bchkhistories, :foreign_key => 'bobjid'
  has_many :brefs,         :foreign_key => 'bobjid'

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
    self[:bpromdate].to_s(:db)
  end

  def project
    @project ||= Bproject.find_by_bname(bproject)
  end

  def migrated?
    project.migrated?
  end

  def self.tree_label u
    u[:breftype] ||= ""
    u.breftype+" "+u.brecname.gsub(/&/,'~')+" Rev. "+u.brecalt+" at Status "+u.breclevel+" - "+u.bdesc
  end

  def workspace_label
    name+"-"+brecalt
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
