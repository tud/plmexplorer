class Bdb < ActiveRecord::Base
  has_many :bdbusers,      :foreign_key => 'bobjid'
  has_many :bdbas,         :foreign_key => 'bobjid'
  has_many :batts,         :foreign_key => 'bobjid'
end
