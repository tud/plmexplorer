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
