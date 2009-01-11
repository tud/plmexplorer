class Workspace
  
  def initialize
    @items = []
    @maxsize = 20
  end
  
  def add obj
    if @items.include? obj
      @items.delete obj
    end
    @items.unshift obj
    if @items.size > @maxsize.to_i
      @items.delete @items[-1]
    end
  end
  
  def remove obj
    @items.delete obj
  end
  
  def clear
    @items.clear
  end
  
  def items
    @items
  end
  
end
    