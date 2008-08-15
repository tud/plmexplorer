class DynList

  DEFAULT_NAME = 'Choose from:'

  LOGISTIC_ITEMS = [
    [ '',                      ''   ],
    [ 'Ricambio',              'R'  ],
    [ 'Dotazione',             'D'  ],
    [ 'Dotazione-Ricambio',    'DR' ],
    [ 'Attrezzatura',          'A'  ],
    [ 'Attrezzatura-Ricambio', 'AR' ]
  ]

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
    if groupRecs.empty?
      # Lista semplice, senza gruppi
      optGroup = OptGroup.new(DEFAULT_NAME)
      optionRecs = Brecord.find_all_by_brectype(rectype, :order => :bname1)
      optionRecs.each do | rec |
        optGroup << Option.new(rec.bname1, rec.bname1)
      end
    else
      # Lista con gruppi
      groupRecs.inject do |currRec, nextRec|
        optGroup = OptGroup.new(currRec.bname1)
        optionRecs = Brecord.find :all,
                        :conditions => ["brectype = ? and brecname >= ? and brecname < ? and brecalt not like ? and brecalt not like ?", rectype, currRec.brecname, nextRec.brecname, '%GROUP%', '%END%'],
                        :order => :bname1
        optionRecs.each do | rec |
          optGroup << Option.new(rec.bname1, rec.bname1)
        end
        dynList << optGroup
        nextRec
      end
      lastRec = groupRecs.last
      optGroup = OptGroup.new(lastRec.bname1)
      optionRecs = Brecord.find :all,
                      :conditions => ["brectype = ? and brecname >= ? and brecalt not like ? and brecalt not like ?", rectype, lastRec.brecname, '%GROUP%', '%END%'],
                      :order => :bname1
      optionRecs.each do | rec |
        optGroup << Option.new(rec.bname1, rec.bname1)
      end
    end
    dynList << optGroup
    dynList
  end

  def self.sw_types
    optGroup = OptGroup.new(DEFAULT_NAME)
    optGroup << Option.new('SOURCE', 'SOURCE')
    optGroup << Option.new('OBJECT', 'OBJECT')
    optGroup << Option.new('EXECUTABLE', 'EXECUTABLE')
    [ optGroup ]
  end
end
