class Bpromchk < ActiveRecord::Base
  belongs_to :brelproc, :foreign_key => 'bobjid'

  def can_sign?(user, record)
    next_level = record.blevel.next
    # Posso firmare solo per il livello successivo a quello corrente
    next_level && next_level.bid == blevelid && (
      user.admin? ||
      buclass == 'DBUSER' ||
      buclass == 'OWNER' && user.buser == record.bowner ||
      record.project.bprjusers.detect { |prju| prju.buclass == buclass && prju.buser == user.buser } != nil
    )
  end

end
