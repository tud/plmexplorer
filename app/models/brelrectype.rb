class Brelrectype < ActiveRecord::Base
  belongs_to :brelproc, :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: brelrectypes
#
#  bobjid        :integer(10)
#  bname         :string(16)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

