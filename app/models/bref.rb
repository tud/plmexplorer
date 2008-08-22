class Bref < ActiveRecord::Base
  belongs_to :brecord, :foreign_key => 'bobjid'

  attr_reader :child_id
  
  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1] || ''
  end

  def resolve
    # Forzo REF.RECALT a 4 caratteri max (standard Oto)
    self.brecalt.slice!(4..-1)

    # Personalizzazione Oto per legami di tipo FROZEN:
    # REF.TYPE1 vale LATEST nel DB, ma dovrebbe essere SPECIFIC!
    if self.breftype[-4,4] == '_FRZ'
      self.btype1 = 'SPECIFIC'
      self.brecalt.chop! if self.brecalt[-1,1] == '#'
    end
    self.brecalt = ' ' if self.brecalt.empty?   # per far felice Oracle!  :-(

    if self.btype1 == 'LATEST' || (self.brecalt[-1,1] == '#' && self.btype1 != 'SPECIFIC')
      relop = '>='
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

  def self.resolve_set(order, limit, offset, conditions)
    refs = Bref.find(:all,
      :order => order,
      :limit => limit,
      :offset => offset,
      :conditions => conditions)
    refs.each { |ref| ref.resolve }
    refs
  end
  
end
