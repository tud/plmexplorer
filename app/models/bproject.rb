class Bproject < ActiveRecord::Base
  has_many :brecords, :foreign_key => 'bproject', :primary_key => 'bname'

  def migrated?
    bdesc.downcase.include? '*** migrato'
  end
end
