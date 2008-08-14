class DynList

  Option = Struct.new(:value, :key)

  class OptGroup
    attr_reader :name, :options
    def initialize(name)
      @name = name
      @options = []
    end
    def <<(option)
      @options << option
    end
  end

  def self.build_from(rectype)
    dynList = []
    groupRecs = Brecord.find :all,
                  :conditions => ["brectype = ? and brecalt like ?" , rectype, '%GROUP%'],
                  :order => :brecname
    groupRecs.inject do |currRec, nextRec|
      optGroup = OptGroup.new(currRec.bname1)
      optionRecs = Brecord.find :all,
                      :conditions => ["brectype = ? and brecname >= ? and brecname < ? and brecalt not like ?", rectype, currRec.brecname, nextRec.brecname, '%GROUP%'],
                      :order => :bname1
      optionRecs.each do | rec |
        optGroup << Option.new(rec.bname1, rec.bname1)
      end
      dynList << optGroup
      nextRec
    end
    unless groupRecs.empty?
      lastRec = groupRecs.last
      optGroup = OptGroup.new(lastRec.bname1)
      optionRecs = Brecord.find :all,
                      :conditions => ["brectype = ? and brecname >= ? and brecalt not like ?", rectype, lastRec.brecname, '%GROUP%'],
                      :order => :bname1
      optionRecs.each do | rec |
        optGroup << Option.new(rec.bname1, rec.bname1)
      end
      dynList << optGroup
    end
    dynList
  end
end
