class Blocation < ActiveRecord::Base
  belongs_to :bstorage, :foreign_key => 'bobjid'
end
