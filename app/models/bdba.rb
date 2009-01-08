class Bdba < ActiveRecord::Base
  belongs_to :bdb, :foreign_key => 'bobjid'
end
