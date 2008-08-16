class Bpromotion < ActiveRecord::Base
  
  def promdate
    self[:bpromdate].to_s(:db)
  end
end
