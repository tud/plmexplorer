class Bchkhistory < ActiveRecord::Base

  def date
    self[:bdate].to_s(:db)
  end
end

# == Schema Information
#
# Table name: bchkhistories
#
#  bobjid        :integer(10)
#  bname         :string(16)
#  blevelid      :integer(5)
#  blevel        :string(16)
#  bstatus       :string(3)
#  buser         :string(16)
#  bdesc         :string(80)
#  bdate         :datetime
#  bcommand      :string(8)
#  bsignuser     :string(16)
#  bsignuclass   :string(16)
#  bautopromote  :string(3)
#  brelproc      :string(16)
#  bproject      :string(16)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

