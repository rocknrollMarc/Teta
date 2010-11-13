
module ValueContainer
  
  def initialize
    @values = {}
    super
  end

  def has_value?(key)
    @values.include? key
  end

  def set(key, value = true)
    @values[key] = value
  end

  def unset(key)
    @values.delete key
  end

  alias :itis :has_value?
end