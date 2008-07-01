class Brecord < ActiveRecord::Base
  has_many :budas, :foreign_key => 'bobjid', :order => 'bname'
  has_many :bfiles, :foreign_key => 'bobjid', :order => 'balias'
  has_many :brefs, :foreign_key => 'bobjid', :order => 'brectype,brecname,brecalt'
  
  def cage_code
    brecname.from(brecname.index('&')+1) || ""
  end
  
  def recname
    brecname.to(brecname.index('&')-1) || brecname
  end
  
end