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
    if self.btype1 == 'LATEST' || self.brecalt[-1,1] == '#'
      child = Brecord.latest(self.brectype, self.brecname, self.brecalt)
    else
      child = Brecord.find(:first,
        :conditions => "brectype = '#{self.brectype}' AND brecname = '#{self.brecname}' AND brecalt = '#{self.brecalt}' AND id = blatest")
    end
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
      :select =>"breftype, brectype, brecname, brecalt, breclevel, bdesc, bquantity, btype1",
      :conditions => conditions)
    refs.each { |ref| ref.resolve }
    refs
  end
  
end
