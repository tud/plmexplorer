class Bdba < ActiveRecord::Base
  belongs_to :bdb, :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: bdbas
#
#  bobjid     :integer(10)
#  buser      :string(16)
#  btimestamp :datetime
#  bmdtid     :integer(10)
#

