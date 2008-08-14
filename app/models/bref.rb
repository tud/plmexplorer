class Bref < ActiveRecord::Base
  belongs_to :brecord, :foreign_key => 'bobjid'
  
  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1].to_s
  end
  
end
