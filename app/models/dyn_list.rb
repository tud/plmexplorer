class DynList

  DEFAULT_LABEL = 'Choose from:'

  Option = Struct.new(:value, :key)

  class OptGroup
    attr_reader :label, :options
    def initialize(label)
      @label = label
      @options = []
    end
    def <<(option)
      @options << option
    end
  end

  def self.build_from(rectype, keyField = :bname1)
    @dynList = []
    groupRecs = Brecord.find(:all,
                             :conditions => ["brectype = ? and brecalt like ?" , rectype, '%GROUP%'],
                             :order => :brecname)
    if groupRecs.empty?
      # Lista semplice, senza gruppi
      add_group(DEFAULT_LABEL, ["brectype = ?", rectype], keyField)
    else
      # Lista con gruppi
      groupRecs.inject do |currRec, nextRec|
        add_group(currRec[:bname1],
                  ["brectype = ? and brecname >= ? and brecname < ? and brecalt not like ? and brecalt not like ?", rectype, currRec[:brecname], nextRec[:brecname], '%GROUP%', '%END%'],
                  keyField)
        nextRec
      end
      lastRec = groupRecs.last
      add_group(lastRec[:bname1],
                ["brectype = ? and brecname >= ? and brecalt not like ? and brecalt not like ?", rectype, lastRec[:brecname], '%GROUP%', '%END%'],
                keyField)
    end
    @dynList
  end

  def self.add_group(label, conditions, keyField)
    @dynList ||= []
    optGroup = OptGroup.new(label)
    optionRecs = Brecord.find(:all, :conditions => conditions, :order => :bname1)
    optionRecs.each do | rec |
      if keyField == :bname1
        optGroup << Option.new(rec[:bname1], rec[keyField])
      else
        optGroup << Option.new(rec[:bname1], rec[:bname1]+' - '+rec[keyField])
      end
    end
    @dynList << optGroup
  end

  def self.sw_types
    optGroup = OptGroup.new(DEFAULT_LABEL)
    optGroup << Option.new('SOURCE', 'SOURCE')
    optGroup << Option.new('OBJECT', 'OBJECT')
    optGroup << Option.new('EXECUTABLE', 'EXECUTABLE')
    [ optGroup ]
  end

end
