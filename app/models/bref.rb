class Bref < ActiveRecord::Base
  
  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1]
  end
  
end
