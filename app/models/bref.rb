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

  def name
    self[:brecname].split('&')[0]
  end

  def cage_code
    self[:brecname].split('&')[1] || ''
  end
  
  def tree_label
    breftype+" "+brecname.gsub(/&/,'~')+" Rev. "+brecalt+" at Status "+breclevel+" - "+bdesc
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
      self[:id] = child.id
      self.brecalt = child.brecalt
      self.breclevel = child.breclevel
      self.bdesc = child.bdesc
    else
      self[:id] = 0
      self.bdesc = '*** UNRESOLVED ***'
    end
    self
  end

end

# == Schema Information
#
# Table name: brefs
#
#  bdate1        :datetime
#  bdate2        :datetime
#  bdouble1      :decimal(, )
#  bdouble2      :decimal(, )
#  bdouble3      :decimal(, )
#  bdouble4      :decimal(, )
#  bdouble5      :decimal(, )
#  bdouble6      :decimal(, )
#  bdouble7      :decimal(, )
#  bdouble8      :decimal(, )
#  bdouble9      :decimal(, )
#  bdouble10     :decimal(, )
#  bdouble11     :decimal(, )
#  bdouble12     :decimal(, )
#  bdouble13     :decimal(, )
#  bdouble14     :decimal(, )
#  btext1        :string(1024)
#  bsuffix1      :string(12)
#  bsee_suffix1  :string(12)
#  btimestamp    :datetime
#  bmdtid        :integer(10)
#  bsubclusterid :integer(5)
#  brectype      :string(16)
#  brecname      :string(32)
#  brecalt       :string(32)
#  brecver       :integer(5)
#  breclevel     :string(16)
#  bobjid        :integer(10)
#  blevelid      :integer(5)
#  brellevel     :string(16)
#  bitem         :string(32)
#  bline         :string(32)
#  bquantity     :decimal(, )
#  bcreateuser   :string(16)
#  created_at    :datetime
#  bstartdate    :datetime
#  bstopdate     :datetime
#  bstartserial  :string(32)
#  bstopserial   :string(32)
#  bweight       :integer(5)
#  brefoption    :string(11)
#  breftype      :string(16)
#  brecobjid     :integer(10)
#  bsee_rectype  :string(16)
#  bsee_recname  :string(32)
#  bsee_recalt   :string(32)
#  bsee_recver   :integer(5)
#  bsee_reclevel :string(16)
#  bsee_rule     :string(16)
#  bsee_reftype  :string(16)
#  bsee_item     :string(32)
#  bsee_line     :string(32)
#  bdesc         :string(80)
#  btype1        :string(16)
#  btype2        :string(16)
#  bname1        :string(32)
#  bname2        :string(32)
#  blong1        :integer(10)
#  blong2        :integer(10)
#

