class Batt < ActiveRecord::Base
  belongs_to :bdb, :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: batts
#
#  bobjid     :integer(10)
#  brectype   :string(16)
#  bname      :string(16)
#  bdesc      :string(80)
#  btimestamp :datetime
#  bmdtid     :integer(10)
#

