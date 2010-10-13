class Bproject < ActiveRecord::Base
  has_many :brecords,  :foreign_key => 'bproject', :primary_key => 'bname'
  has_many :bprjusers, :foreign_key => 'bobjid'

  def migrated?
    bdesc.downcase.include? '*** migrato'
  end

  def obsolete?
    bdesc.downcase.include? '*** config. obsoleta'
  end
end

# == Schema Information
#
# Table name: bprojects
#
#  id            :integer(10)     primary key
#  bname         :string(16)
#  bdesc         :string(80)
#  barcdate      :datetime
#  barclabel     :string(6)
#  barcset       :string(32)
#  breloaddate   :datetime
#  bowner        :string(16)
#  bdictversion  :integer(5)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

