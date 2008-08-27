class Condition

  ESCAPE = '|'
  attr :list

  def initialize(condition = nil)
    @list = []
    self << condition
  end

  def <<(condition)
    @list << condition if condition && !condition.empty?
  end

  def <=>(other)
    self.list <=> other.list
  end

  def empty?
    @list.empty?
  end

  def add(field, value)
    if !Condition.matches_any(value)
      if value.index(/[*?]/).nil?
        # there are no wildcards in value
        @list << "#{field} = '#{value}'"
      else
        # translate wildcards into SQL
        value.gsub!(/%/,ESCAPE+'%')
        value.gsub!(/_/,ESCAPE+'_')
        value.gsub!(/\*/,'%')
        value.gsub!(/\?/,'_')
        @list << "#{field} LIKE '#{value}' ESCAPE '#{ESCAPE}'"
      end
    end
  end

  def Condition.matches_any(string)
    string.nil? || /^\**$/.match(string)
  end

  def to_s
    @list.join(' AND ')
  end

end
