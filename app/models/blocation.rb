class Blocation < ActiveRecord::Base
  belongs_to :bstorage, :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: blocations
#
#  bobjid        :integer(10)
#  bname         :string(16)
#  bnode         :string(33)
#  bdevice       :string(16)
#  bdirectory    :string(255)
#  bactive       :string(3)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

