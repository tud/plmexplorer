require 'net/ftp'

class Bdbuser < ActiveRecord::Base
  
  AUTH_KO = 'Invalid username/password combination'
  AUTH_OK = 'User successfully logged in'
  CONN_KO = 'Connection to server failed'

  belongs_to :bdb, :foreign_key => 'bobjid'

  def self.authenticate(username, password)
    # Vengono autenticati solo gli utenti registrati nel DB
    user = self.find_by_buser(username.upcase)
    if user
      # In sviluppo si accetta l'omissione della password.
      # Tuttavia, se fornita, viene comunque verificata.
      if ENV['RAILS_ENV'] != 'development' || !password.empty?
        begin
          connection = Net::FTP.open(SHERPA_SERVER, username, password)
          user[:logged_in] = true
          user[:log_message] = AUTH_OK
        rescue Net::FTPPermError
          user[:logged_in] = false
          user[:log_message] = AUTH_KO
        rescue
          user[:logged_in] = false
          user[:log_message] = CONN_KO
        ensure
          connection.close unless connection.nil?
        end
      else
        user[:logged_in] = true
        user[:log_message] = AUTH_OK
      end
    else
      # Viene comunque creato uno user per ritonare lo stato
      user = Bdbuser.new
      user[:logged_in] = false
      user[:log_message] = AUTH_KO
    end
    user
  end

  def admin?
    buser[0..5] == 'SHERPA' || bdb.bdbas.find_by_buser(buser) != nil
  end

end
