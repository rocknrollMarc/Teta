
module ActionContainer

  def initialize  
    @actions = {}
    super
  end

  def add_action(*symbols, &block)
    symbols.each do |symbol|  
      @actions[symbol] = block
    end
  end

  def has_action?(symbol)
    @actions.has_key? symbol
  end

  def eval_action(symbol, *args)
    action = @actions[symbol]

    if action.arity == 0 then
      self.instance_eval(&action)
    else
      self.instance_exec(*args, &action)
    end
  end

  def eval_action_safe(symbol, *args)
     if has_action? symbol then
       [eval_action(symbol, *args)]
     else
       nil
     end
  end

end
