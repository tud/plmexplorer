class Baccess < ActiveRecord::Base
  belongs_to :brelproc, :foreign_key => 'bobjid'
end
