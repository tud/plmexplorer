class Bproject < ActiveRecord::Base
  has_many :brecords,  :foreign_key => 'bproject', :primary_key => 'bname'
  has_many :bprjusers, :foreign_key => 'bobjid'

  def migrated?
    bdesc.downcase.include? '*** migrato'
  end

  def obsolete?
    bdesc.downcase.include? '*** config. obsoleta'
  end
end
