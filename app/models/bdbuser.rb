class Bdbuser < ActiveRecord::Base
  
  belongs_to :bdb, :foreign_key => 'bobjid'

  def self.authenticate(username, password)
    user = self.find_by_buser(username.upcase)
    if user
      # controllo password
    end
    user
  end

  def admin?
    buser[0..5] == 'SHERPA' || bdb.bdbas.find_by_buser(buser) != nil
  end

end
