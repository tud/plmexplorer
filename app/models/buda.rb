class Buda < ActiveRecord::Base
  belongs_to :brecord, :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: budas
#
#  bobjid        :integer(10)
#  bname         :string(16)
#  bvalue        :string(80)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

