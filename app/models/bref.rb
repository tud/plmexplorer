class Bref < ActiveRecord::Base
  belongs_to :brecord, :foreign_key => 'bobjid'
  named_scope :of_type, lambda { |reftypes|
    # reftypes e' un elenco di tipi di legame separati da virgole e/o spazi
    if reftypes && !reftypes.empty?
      # clausola di tipo BREFTYPE IN (...)
      { :conditions => { :breftype => reftypes.upcase.split(/[, ]+/) } }
    else
      # anche senza filtri, escludo comunque i legami "di sistema"
      { :conditions => "brefs.breftype != 'EFFECTIVE_ON' AND brefs.breftype != 'IMAGE_FOR' AND brefs.breftype != 'MARKUP_FOR'" }
    end
  }
  named_scope :parent_of, lambda { |record|
    { :conditions => [ "brefs.brectype = ? AND brefs.brecname = ? AND (((brefs.btype1 = 'LATEST' OR SUBSTR(brefs.brecalt,-1,1) = '#') AND SUBSTR(brefs.breftype,-4,4) != '_FRZ' AND SUBSTR(brefs.brecalt,1,4) <= ?) OR (((brefs.btype1 != 'LATEST' AND SUBSTR(brefs.brecalt,-1,1) != '#') OR SUBSTR(brefs.breftype,-4,4) = '_FRZ') AND SUBSTR(brefs.brecalt,1,4) = ?))", record.brectype, record.brecname, record.brecalt, record.brecalt ] }
  }

  attr_reader :child_id

  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1] || ''
  end

  def resolve
    # Forzo REF.RECALT a 4 caratteri max (standard Oto)
    #self.brecalt.slice!(4..-1)

    # Personalizzazione Oto per legami di tipo FROZEN:
    # REF.TYPE1 vale LATEST nel DB, ma dovrebbe essere SPECIFIC!
    if self.breftype[-4,4] == '_FRZ'
      self.btype1 = 'SPECIFIC'
      self.brecalt.chop! if self.brecalt[-1,1] == '#'
    end
    self.brecalt = ' ' if self.brecalt.empty?   # per far felice Oracle!  :-(

    if self.btype1 == 'LATEST' || (self.brecalt[-1,1] == '#' && self.btype1 != 'SPECIFIC')
      relop = '>='
      self.brecalt[-1,1] = ' ' if self.brecalt[-1,1] == '#'
    else
      relop = '='
    end
    child = Brecord.find :first,
      :conditions => "brectype = '#{self.brectype}' AND brecname = '#{self.brecname}' AND brecalt #{relop} '#{self.brecalt}' AND id = blatest",
      :order => 'brecalt DESC'
    if child
      @child_id = child.id
      self.brecalt = child.brecalt
      self.breclevel = child.breclevel
      self.bdesc = child.bdesc
    else
      @child_id = 0
      self.bdesc = '*** UNRESOLVED ***'
    end
    self
  end

end
