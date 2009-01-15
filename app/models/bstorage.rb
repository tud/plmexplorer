class Bstorage < ActiveRecord::Base
  has_many :blocations, :foreign_key => 'bobjid'
  has_many :bfiles,     :foreign_key => 'bstorage', :primary_key => 'bname'

  def open?
    baccess == 'OPEN'
  end

end
