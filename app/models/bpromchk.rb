class Bpromchk < ActiveRecord::Base
  belongs_to :brelproc, :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: bpromchks
#
#  bobjid        :integer(10)
#  blevelid      :integer(5)
#  blevel        :string(16)
#  bname         :string(16)
#  buclass       :string(16)
#  bdesc         :string(80)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

