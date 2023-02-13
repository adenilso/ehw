
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
  attr_accessor :inputs

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

  def delta(state, regs, seq)
    s = state
    r = regs
    seq.each do |input, pars|
      (sprime, rprime, o, opars) = self.step(s, r, input, pars)
      puts "#{[sprime, rprime, o, opars]}" if $DEBUG > 3
      return nil if o == OMEGA
      s = sprime
      r = rprime
    end
    return s
  end

  def step(state, regs, input, pars)
    applicable = @trans.select{|t| t[:from] == state and t[:input] == input and eval_expr(t[:guard], pars, regs)}
    if applicable.length == 0
      return [state, regs, OMEGA, []]
    elsif applicable.length > 1
      return [state, regs, ND, []]
    else
      t = applicable.first
    puts "t: #{t}" if $DEBUG > 2
      
      return [
        t[:to], 
        t[:update].map{|e| eval_expr(e, pars, regs)}, 
        t[:output], 
        t[:outpars].map{|e| eval_expr(e, pars, regs)}
      ]
    end
  end

  def complete?
    return (@states != [] and @states.all?{|s| @inputs.all?{|x| @trans.find{|t| t[:from] == s and t[:input] == x}}})
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

  def to_dot
    str = []
    str << "digraph M {"
    @states.each do |s|
      str << "\"#{s}\"; // #{@cur_state}"
    end
    @trans.each do |t|
      str << "\"#{t[:from]}\" -> \"#{t[:to]}\" [label=\"#{t[:input]}/#{t[:output]}\"]; "
    end
    str << "}"
    return str
  end

  def positionCurrentState(omega)
    possibleStates = self.states
    regs = []
    omega.each do |x, y|
      nPossibleStates = possibleStates.map{|s| self.step(s, regs, x[0], x[1])}.select{|r| r.slice(2, 2) == y}.map{|r| r[0]}
      if nPossibleStates.length == 0
        possibleStates = self.states
      else
        possibleStates = nPossibleStates
      end
    end
    if possibleStates.length > 0
      self.cur_state = possibleStates.first
    end
  end

  def randomWalkUntilDiff(m1, steps)
    res = []
    regs = []
    steps.times do
      x = self.inputs.shuffle.first
      res << [x, []]
      y = self.step!(x, [])
      yprime = m1.step!(x, [])
      if y != yprime
        return {status: "CE", ce: res}
      end
    end
    return {status: "EQ"}
  end

  def equiv?(m1)
    m = m1.clone
    m1.states.each do |s0|
      toProcess = []
      toProcess << [@s0, s0]
      processed = []
      while toProcess.length > 0
        s = toProcess.shift
        processed << s
        (s1, s2) = s
        self.inputs.each do |x|
          r1 = self.step(s1, [], x, [])
          r2 = self.step(s2, [], x, [])
          if r1[3] != r2[3]
            return false
          end
          r = [r1[2], r2[2]]
          if not processed.include?(r)
            toProcess << r
          end
        end
      end
      return true
    end
    return false
  end
end
