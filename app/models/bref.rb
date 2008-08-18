class Bref < ActiveRecord::Base
  belongs_to :brecord, :foreign_key => 'bobjid'

  attr_reader :child_id
  
  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1] || ''
  end

  def self.resolve(order, limit, offset, conditions)
    refs = Bref.find(:all,
      :order => order,
      :limit => limit,
      :offset => offset,
      :select =>"breftype, brectype, brecname, brecalt, breclevel, bdesc, bquantity, btype1",
      :conditions => conditions)
    refs.each do |ref|
      if ref.btype1 == 'LATEST' || ref.brecalt[-1,1] == '#'
        child = Brecord.latest(ref.brectype, ref.brecname, ref.brecalt)
      else
        child = Brecord.find(:all,
          :conditions => "brectype = '#{ref.brectype}' AND brecname = '#{ref.brecname}' AND brecalt = '#{ref.brecalt}' AND id = blatest")[0]
      end
      if child
        child_id = child.id
        ref.brecalt = child.brecalt
        ref.breclevel = child.breclevel
        ref.bdesc = child.bdesc
      else
        child_id = 0
        ref.bdesc = '*** UNRESOLVED ***'
      end
    end
    refs
  end
  
end
