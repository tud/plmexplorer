class Brelproc < ActiveRecord::Base
  has_many :baccesses,    :foreign_key => 'bobjid'
  has_many :brelrectypes, :foreign_key => 'bobjid'
  has_many :blevels,      :foreign_key => 'bobjid', :order => 'bid'
  has_many :bpromchks,    :foreign_key => 'bobjid', :order => 'blevelid'

  def level_list
    @level_list ||= blevels.map { |lvl| lvl.bname }
  end

  def blevel(level)
    if level.class == String
      blevels.detect { |lvl| lvl.bname == level }
    elsif level.class == Fixnum
      blevels.detect { |lvl| lvl.bid == level }
    end
  end

end

# == Schema Information
#
# Table name: brelprocs
#
#  id            :integer(10)     primary key
#  bname         :string(16)
#  bdesc         :string(80)
#  bstatus       :string(7)
#  bfreeze       :string(6)
#  barcdate      :datetime
#  barclabel     :string(6)
#  barcset       :string(32)
#  breloaddate   :datetime
#  bbaselevelid  :integer(5)
#  bdictversion  :integer(5)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

