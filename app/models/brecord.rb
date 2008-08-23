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
    conditions = "brectype = '#{brectype}' AND brecname = '#{brecname}' AND id = blatest"
    if brecalt && brecalt[-1,1] == '#'
      brecalt[-1,1] = '%'
      conditions += " AND brecalt like '#{brecalt}'"
    end
    latest_rev = self.find(:first, :conditions => conditions, :order => 'brecalt DESC')
  end

  def where_used(order, limit, offset, conditions = '')
    conditions ||= ''
    if !conditions.empty?
      conditions += ' AND '
    end
    select = 'brecords.brectype, brecords.brecname, MAX(brecords.brecalt) AS brecalt'
    conditions = "brecords.id = brefs.bobjid AND brefs.brectype = '#{self.brectype}' AND brefs.brecname = '#{self.brecname}' AND (((brefs.btype1 = 'LATEST' OR SUBSTR(brefs.brecalt,-1,1) = '#') AND SUBSTR(brefs.breftype,-4,4) != '_FRZ' AND SUBSTR(brefs.brecalt,1,4) <= '#{self.brecalt}') OR (((brefs.btype1 != 'LATEST' AND SUBSTR(brefs.brecalt,-1,1) != '#') OR SUBSTR(brefs.breftype,-4,4) = '_FRZ') AND SUBSTR(brefs.brecalt,1,4) = '#{self.brecalt}'))"
    joins = ', brefs'
    group = 'brecords.brectype, brecords.brecname'
    latest = Brecord.find(:all,
      :select => select,
      :conditions => conditions,
      :joins => joins,
      :group => group).uniq.map { |rec| [ "('#{rec.brectype}','#{rec.brecname}','#{rec.brecalt}')" ] }.join(',')
    if latest.empty?
      parents = []
    else
      conditions = "brecords.id = brefs.bobjid AND brecords.id = brecords.blatest AND (brecords.brectype,brecords.brecname,brecords.brecalt) IN (#{latest}) AND brefs.brectype = '#{self.brectype}' AND brefs.brecname = '#{self.brecname}'"
      parents = Brecord.find(:all,
        :select => "brefs.breftype, brecords.*",
        :conditions => conditions,
        :joins => joins)
    end
  end  

end
