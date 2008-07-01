class Brecord < ActiveRecord::Base
  has_many :budas, :foreign_key => 'bobjid', :order => 'bname'
  has_many :bfiles, :foreign_key => 'bobjid', :order => 'balias'
  has_many :brefs, :foreign_key => 'bobjid', :order => 'brectype,brecname,brecalt'
  
  def cage_code
    idx = self[:BRECNAME].index('&')
    if (idx)
      self[:BRECNAME].from(idx+1)
    else
      self[:BRECNAME]
    end
  end
  
  def recname
    idx = self[:BRECNAME].index('&')
    if (idx)
      self[:BRECNAME].to(idx-1)
    else
      self[:BRECNAME]
    end
  end
  
end