class Bchkhistory < ActiveRecord::Base

  def date
    self[:bdate].to_s(:db)
  end
end
