class Brecord < ActiveRecord::Base
  has_many :budas, :foreign_key => 'bobjid', :order => 'bname'
  has_many :bfiles, :foreign_key => 'bobjid', :order => 'balias'
  has_many :brefs, :foreign_key => 'bobjid', :order => 'brectype,brecname,brecalt'
  
  def cage_code
    idx = brecname.index('&')
    if (idx)
      brecname.from(idx+1)
    else
      ""
    end
  end
  
  def recname
    idx = brecname.index('&')
    if (idx)
      brecname.to(idx-1)
    else
      brecname
    end
  end
  
end