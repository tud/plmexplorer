class Bpromotion < ActiveRecord::Base
  belongs_to :brecord,  :foreign_key => 'bobjid'

  def promdate
    self[:bpromdate].to_s(:db)
  end
end

# == Schema Information
#
# Table name: bpromotions
#
#  bobjid        :integer(10)
#  bpromdate     :datetime
#  brelproc      :string(16)
#  blevelid      :integer(5)
#  blevel        :string(16)
#  brecver       :integer(5)
#  buser         :string(16)
#  bdesc         :string(80)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

