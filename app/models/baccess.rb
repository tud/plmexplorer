class Baccess < ActiveRecord::Base
  belongs_to :brelproc, :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: baccesses
#
#  bobjid        :integer(10)
#  blevelid      :integer(5)
#  blevel        :string(16)
#  buclass       :string(16)
#  bpriv         :string(10)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

