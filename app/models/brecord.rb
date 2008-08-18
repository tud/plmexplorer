class Brecord < ActiveRecord::Base
  has_many :budas,         :foreign_key => 'bobjid', :order => 'bname'
  has_many :bfiles,        :foreign_key => 'bobjid', :order => 'balias'
  has_many :brefs,         :foreign_key => 'bobjid', :order => 'breftype,brectype,brecname,brecalt'
  has_many :bpromotions,   :foreign_key => 'bobjid', :order => 'bpromdate'
  has_many :bchkhistories, :foreign_key => 'bobjid', :order => 'bdate'

  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1] || ''
  end

  def title
    brectype+" "+brecname.gsub(/&/,'~')+" Rev. "+brecalt+" at Status "+breclevel+" - "+bdesc
  end
  
  def promdate
    self[:bpromdate].to_s(:db)
  end

  def self.latest(brectype, brecname, brecalt = '#')
    latest_rev = nil
    conditions = "brectype = '#{brectype}' AND brecname = '#{brecname}' AND id = blatest"
    if brecalt
      if brecalt[-1,1] == '#'
        brecalt[-1,1] = '%'
      end
      if !brecalt.empty?
        conditions += " AND brecalt LIKE '#{brecalt}'"
      end
    end
    rec = self.find(:first,
      :select =>"MAX(brecalt) AS brecalt",
      :conditions => conditions,
      :group => 'brectype,brecname')
    if rec
      conditions = "brectype = '#{brectype}' AND brecname = '#{brecname}' AND brecalt = '#{rec.brecalt}' AND id = blatest"
      latest_rev = self.find(:first, :conditions => conditions)
    end
    latest_rev
  end

end
