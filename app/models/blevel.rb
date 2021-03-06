class Blevel < ActiveRecord::Base
  include Comparable
  belongs_to :brelproc, :foreign_key => 'bobjid'

  # Confronto fra livelli
  def <=>(other)
    self.bid <=> other.bid
  end

  # Posizione del livello corrente nella relproc
  def index
    brelproc.blevels.find_index { |lvl| lvl.bid == self.bid }
  end

  # Livello successivo nella relproc
  def next
    brelproc.blevels[index+1]
  end

  # Livello precedente nella relproc
  def prev
    brelproc.blevels[index-1] if index > 0
  end

  # Livello massimo nella relproc
  def max
    brelproc.blevels.max
  end

  # Livello minimo nella relproc
  def min
    brelproc.blevels.min
  end

  # Firme per il livello corrente
  def bpromchks
    brelproc.bpromchks.find_all { |chk| chk.blevelid == self.bid }
  end

  # Elenco nomi firme per il livello corrente
  def check_list
    bpromchks.map { |chk| chk.bname }
  end

  # Firma relproc avente dato nome
  def bpromchk(name)
    brelproc.bpromchks.detect { |chk| chk.bname == name }
  end

end

# == Schema Information
#
# Table name: blevels
#
#  bobjid        :integer(10)
#  bid           :integer(5)
#  bname         :string(16)
#  bdesc         :string(80)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#

