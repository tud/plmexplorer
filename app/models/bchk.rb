class Bchk < ActiveRecord::Base
  belongs_to :brecord,  :foreign_key => 'bobjid'
end

# == Schema Information
#
# Table name: bchks
#
#  bobjid        :integer(10)
#  bactive       :string(3)
#  bname         :string(16)
#  blevelid      :integer(5)
#  blevel        :string(16)
#  bstatus       :string(3)
#  buser         :string(16)
#  bdesc         :string(80)
#  bchkdate      :datetime
#  bsignuser     :string(16)
#  bsignuclass   :string(16)
#  bdynamic      :string(3)
#  bchkdesc      :string(80)
#  bautopromote  :string(3)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

