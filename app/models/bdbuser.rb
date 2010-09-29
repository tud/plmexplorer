require 'net/ftp'

class Bdbuser < ActiveRecord::Base
  belongs_to :bdb, :foreign_key => 'bobjid'

  def self.authenticate(username, password)
    # Vengono autenticati solo gli utenti registrati nel DB
    user = self.find_by_buser(username.upcase)
    if user
      # In sviluppo si accetta l'omissione della password.
      # Tuttavia, se fornita, viene comunque verificata.
      if ENV['RAILS_ENV'] != 'development' || !password.empty?
        begin
          connection = Net::FTP.open(PREF['SHERPA_SERVER'][ENV['RAILS_ENV']], username, password)
          user[:logged_in] = true
          user[:log_message] = MSG['AUTH_OK']
        rescue Net::FTPPermError
          user[:logged_in] = false
          user[:log_message] = MSG['AUTH_KO']
        rescue
          #logger.error(MSG['STARS'] + $!)
          user[:logged_in] = false
          user[:log_message] = MSG['CONN_KO']
        ensure
          connection.close unless connection.nil?
        end
      else
        user[:logged_in] = true
        user[:log_message] = MSG['AUTH_OK']
      end
    else
      # Viene comunque creato uno user per ritonare lo stato
      user = Bdbuser.new
      user[:logged_in] = false
      user[:log_message] = MSG['AUTH_KO']
    end
    user
  end

  def admin?
    buser[0..5] == 'SHERPA' || Bdba.find_by_buser(buser) != nil
  end

  def can_sign?(record, check)
    next_level = record.blevel.next
    # Posso firmare solo per il livello successivo a quello corrente
    next_level && next_level.bid == check.blevelid && (
      admin? ||
      check.buclass == 'DBUSER' ||
      check.buclass == 'OWNER' && buser == record.bowner ||
      record.project.bprjusers.detect { |prju| prju.buclass == check.buclass && prju.buser == buser } != nil
    )
  end

end
