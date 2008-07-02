class Brecord < ActiveRecord::Base
  has_many :budas, :foreign_key => 'bobjid', :order => 'bname'
  has_many :bfiles, :foreign_key => 'bobjid', :order => 'balias'
  has_many :brefs, :foreign_key => 'bobjid', :order => 'brectype,brecname,brecalt'
  
  def number
    brecname.split('&')[0]
  end
  
  def cage_code
    brecname.split('&')[1].to_s
  end
  
end
