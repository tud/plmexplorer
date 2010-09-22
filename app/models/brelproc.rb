class Brelproc < ActiveRecord::Base
  has_many :baccesses,    :foreign_key => 'bobjid'
  has_many :brelrectypes, :foreign_key => 'bobjid'
  has_many :blevels,      :foreign_key => 'bobjid', :order => 'bid'
  has_many :bpromchks,    :foreign_key => 'bobjid', :order => 'blevelid'
end
