class Bstorage < ActiveRecord::Base
  has_many :blocations, :foreign_key => 'bobjid'
  has_many :bfiles,     :foreign_key => 'bstorage', :primary_key => 'bname'

  def open?
    baccess == 'OPEN'
  end

end

# == Schema Information
#
# Table name: bstorages
#
#  bsubclusterid :integer(5)
#  id            :integer(10)     primary key
#  bname         :string(16)
#  bdesc         :string(80)
#  barcdate      :datetime
#  barclabel     :string(6)
#  barcset       :string(32)
#  breloaddate   :datetime
#  bsyncflag     :string(3)
#  baccess       :string(6)
#  bactive       :string(3)
#  bcompressflag :string(3)
#  bcompressutil :string(255)
#  bdictversion  :integer(5)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#

