class Bchkhistory < ActiveRecord::Base
  belongs_to :brecord,  :foreign_key => 'bobjid'
end
