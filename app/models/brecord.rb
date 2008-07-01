class Brecord < ActiveRecord::Base
  has_many :budas, :foreign_key => 'bobjid', :order => 'bname'
  has_many :bfiles, :foreign_key => 'bobjid', :order => 'balias'
  has_many :brefs, :foreign_key => 'bobjid', :order => 'brectype,brecname,brecalt'
  
  def cage_code
    idx = self[:brecname].index('&')
    if (idx)
      self[:brecname].from(idx+1)
    else
      self[:brecname]
    end
  end
  
  def recname
    idx = self[:brecname].index('&')
    if (idx)
      self[:brecname].to(idx-1)
    else
      self[:brecname]
    end
  end
  
end