class Bpromotion < ActiveRecord::Base
  belongs_to :brecord,  :foreign_key => 'bobjid'

  def promdate
    self[:bpromdate].to_s(:db)
  end
end
