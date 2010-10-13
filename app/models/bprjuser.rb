class Bprjuser < ActiveRecord::Base
  belongs_to :bproject, :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: bprjusers
#
#  bobjid        :integer(10)
#  buser         :string(16)
#  buclass       :string(16)
#  bextprjname   :string(16)
#  bextuclass    :string(16)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

