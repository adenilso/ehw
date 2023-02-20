
OMEGA = "#!OMEGA!#"
ND = "#!ND!#"
ERRORVAL = "#!ERROR!#"

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
   self.regs = [] unless self.regs
   @trans = []
   @cur_state = []
  end 

  def to_s
    return "#{@states} #{@s0} #{self.regs} #{@trans}"
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

  def step(state, regs, input, pars, store_concrete = true)
    applicable = @trans.select{|t| t[:from] == state and t[:input] == input and eval_expr(t[:guard], pars, regs)}
    if applicable.length == 0
      return [state, regs, OMEGA, []]
    elsif applicable.length > 1
      return [state, regs, ND, []]
    else
      t = applicable.first
      puts "t: #{t}" if $DEBUG > 2
      opars = t[:outpars].map{|e| begin eval_expr(e, pars, regs) rescue ERRORVAL end}
      oregs = t[:update].map{|e| begin eval_expr(e, pars, regs) rescue ERRORVAL end}
      #regs = t[:update].map{|e| eval_expr(e, pars, regs)}
      t[:concrete_parameters] = [] unless t[:concrete_parameters]
      if store_concrete
        #t[:concrete_parameters] |= [[pars, opars]]     
      end
      return [
        t[:to], 
        oregs, 
        t[:output], 
        opars
      ]
    end
  end

  def complete?
    return (@states != [] and @states.all?{|s| @inputs.all?{|x| @trans.find{|t| t[:from] == s and t[:input] == x[0]}}})
  end

  def step!(input, pars)
    res = step(@cur_state, self.regs, input, pars) 
    self.regs = res[1]
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
      str << "\"#{s}\";"
    end
    @trans.each do |t|
      input = "#{t[:input]}"
      output = "#{t[:output]}"
      if t[:outpars].length > 0
        input += "(#{t[:outpars].join(" ").scan(/i\d+/).join(",")})"
        output += "(#{t[:outpars].join(",")})"
      end
      if t[:update].length > 0
        output += "[#{t[:update].join(",")}]"
      end
      inout = "#{input}/#{output}"
      str << "\"#{t[:from]}\" -> \"#{t[:to]}\" [label=\"#{inout}\"]; "
    end
    str << "}"
    return str
  end

  def positionCurrentState(omega)
    possibleStates = self.states.map{|s| [s, []]}
    omega.each do |x, y|
      puts ">>#{__LINE__}>>#{possibleStates}" if $DEBUG > 3
      nPossibleStates = possibleStates.map{|s, regs| self.step(s, regs, x[0], x[1], false)}.select{|r| r.slice(2, 2) == y}.map{|r| [r[0], r[1]]}
      puts "<<#{__LINE__}<<#{nPossibleStates}" if $DEBUG > 3
      if nPossibleStates.length == 0
        possibleStates = self.states.map{|s| [s, []]}
      else
        possibleStates = nPossibleStates
      end
    end
    if possibleStates.length > 0
      stateregs = possibleStates.first
      self.cur_state = stateregs[0]
      self.regs = stateregs[1]
    end
  end

  def randomWalkUntilDiff(m1, steps)
    res = []
    puts ">>>> #{self.regs} #{m1.regs}"
    steps.times do
      x = self.inputs.shuffle.first
      i = x[0]
      pars = x[1].map{|p| p.shuffle.first}
      res << [i, pars]
      y = self.step!(i, pars)
      yprime = m1.step!(i, pars)
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
          i = x[0]
          pars = x[1].map{|p| p.shuffle.first}
          r1 = self.step(s1, self.regs, i, pars)
          r2 = self.step(s2, self.regs, i, pars)
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
