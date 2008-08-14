class Brecord < ActiveRecord::Base
  has_many :budas,  :foreign_key => 'bobjid', :order => 'bname'
  has_many :bfiles, :foreign_key => 'bobjid', :order => 'balias'
  has_many :brefs,  :foreign_key => 'bobjid', :order => 'brectype,brecname,brecalt'

  named_scope :parts,     :conditions => {:brectype => 'PART'}
  named_scope :pim_users, :conditions => {:brectype => 'PIM_USER'}
  named_scope :documents, :conditions => {:brectype => 'DOCUMENT'}
  named_scope :software,  :conditions => {:brectype => 'SOFTWARE'}

  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1].to_s
  end
  
  def title
    brectype+"\\"+brecname+"\\"+brecalt+";"+brecver.to_s+"@"+breclevel+" - "+bdesc
  end
end
