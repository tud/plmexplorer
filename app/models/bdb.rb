class Bdb < ActiveRecord::Base
  has_many :bdbusers,      :foreign_key => 'bobjid'
  has_many :bdbas,         :foreign_key => 'bobjid'
  has_many :batts,         :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: bdbs
#
#  id           :integer(10)     primary key
#  bname        :string(16)
#  bdesc        :string(80)
#  bstatus      :string(7)
#  bschemaid    :integer(5)
#  barcdate     :datetime
#  barclabel    :string(6)
#  barcset      :string(32)
#  breloaddate  :datetime
#  bdictversion :integer(5)
#  btimestamp   :datetime
#  bmdtid       :integer(10)
#

