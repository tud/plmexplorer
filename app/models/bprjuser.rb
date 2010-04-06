class Bprjuser < ActiveRecord::Base
  belongs_to :bproject, :foreign_key => 'bobjid'
end
