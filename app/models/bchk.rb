class Bchk < ActiveRecord::Base
  belongs_to :brecord,  :foreign_key => 'bobjid'
end
