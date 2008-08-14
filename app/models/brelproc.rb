class Brelproc < ActiveRecord::Base
  has_many :brelrectypes, :foreign_key => 'bobjid'
  has_many :blevels,      :foreign_key => 'bobjid'
end
