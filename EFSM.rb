
OMEGA = "#!OMEGA!#"
ND = "#!ND!#"

def eval_expr(expr, inputs, regs)
  res_expr = "#{expr}"
  [[inputs, "i"], [regs, "r"]].each do |vals, type|
    vals.each_with_index do |e, i|
      v = nil
      if e.instance_of? String
        v = "\"#{e}\""
      else
        v = "#{e}"
      end
      res_expr = res_expr.gsub(/#{type}#{i}/, "#{v}")
    end
  end
  res = eval(res_expr)
  return res
end

class EFSM

  attr_accessor :trans
  attr_accessor :s0
  attr_accessor :regs
  attr_accessor :cur_state
  attr_accessor :states

 def initialize
   @states = []
   @s0 = nil
   @regs = []
   @trans = []
   @cur_state = []
  end 

  def to_s
    return "#{@states} #{@s0} #{@regs} #{@trans}"
  end

  def step(state, regs, input, pars)
    applicable = @trans.select{|t| t[:from] == state and t[:input] == input and eval_expr(t[:guard], pars, regs)}
    if applicable.length == 0
      return [state, regs, OMEGA, []]
    elsif applicable.length > 1
      return [state, regs, ND, []]
    else
      t = applicable.first
      
      return [
        t[:to], 
        t[:update].map{|e| eval_expr(e, pars, regs)}, 
        t[:output], 
        t[:outpars].map{|e| eval_expr(e, pars, regs)}
      ]
    end
  end

  def step!(input, pars)
    res = step(@cur_state, @regs, input, pars) 
    @regs = res[1]
    @cur_state = res[0]
    return [res[2], res[3]]
  end

  def steps!(seq)
    res = []
    seq.each do |i, p|
      res << self.step!(i, p)
    end
    return res
  end
end
