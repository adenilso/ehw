
class EHW
  attr_accessor :h
  attr_accessor :W

  attr_accessor :M

  #attr_accessor :inputs
  attr_accessor :inputsigs

  attr_accessor :bb

  attr_reader :omega

  def initialize
    @h = []
    @W = []
    self.inputs = []
    @M = EFSM.new
    @M.states = []
    @H = {}
    @domDelta = {}
  end

  def inputs=(inputs)
    @inputs = inputs
    @M.inputs = inputs if @M
  end

  def inputs
    return @inputs
  end

  def projecth(outs)
    return outs.map{|e| e.first}
  end

  def projectw(outs)
    return outs.map{|e| e.first}
  end

  def shorstestToUndef(q)
    toProcess = [[[q], []]]
    while toProcess != []
      puts "toProcess: #{toProcess}" if $DEBUG > 1
      (sts, seq) = toProcess.shift
      x = @inputs.find{|x| not @M.trans.any?{|t| t[:from] == sts.first and t[:input] == x}}
      if x
        return [seq, [x, []], sts.first]
      else
        @inputs.each do |x|
          trans = @M.trans.select{|t| t[:from] == sts.first and t[:input] == x}
          t = trans.first
          qline = t[:to]
          puts "qline: #{qline}" if $DEBUG > 1
          if not sts.include?(qline)
            toProcess << [[qline] + sts, seq + [[x, []]]]
          end
        end
      end
    end
    return nil
  end

  def ehw
    while not @M.complete?
      eta = self.projecth(self.apply!(@h))
      puts "eta: #{eta}" if $DEBUG > 0
      if not @H[eta]
        @H[eta] = {} 
      end
      w = @W.find{|w| not @H[eta][w]}
      if w
        y = self.projectw(self.apply!(w))
        puts "w: #{w} / #{y}" if $DEBUG > 0
        @H[eta][w] = y
      else
        q = @W.map{|w| @H[eta][w]}
        puts "q: #{q}"
        @M.states |= [q]
        (alpha, x, qline) = self.shorstestToUndef(q)
        puts "(alpha, x, qline) = (#{alpha}, #{x}, #{qline})" if $DEBUG > 0
        self.apply!(alpha)
        y = self.apply!([x]).first
        if y.first == OMEGA
          puts "OMEGA!" if $DEBUG > 0
          @M.trans << {
            from: qline,
            to: qline,
            input: x.first,
            output: y.first,
            guard: true,
            update: [],
            outpars: [],
          }
        else
          @domDelta[qline] = {} unless @domDelta[qline]
          @domDelta[qline][x] = {} unless @domDelta[qline][x]
          w = @W.find{|w| not @domDelta[qline][x][w]}
          if w
            xi = self.projectw(self.apply!(w))
            puts "[x] w: #{w} / #{xi}" if $DEBUG > 0
            @domDelta[qline][x][w] = xi
            if not @W.find{|w| not @domDelta[qline][x][w]}
              nq = @W.map{|w| @domDelta[qline][x][w]}
              @M.states |= [nq]
              @M.trans << {
                from: qline,
                to: nq,
                input: x.first,
                output: y.first,
                guard: true,
                update: [],
                outpars: [],
              }
            end
          end
        end
      end
    end
  end

  def steps!(s)
    return @bb.steps!(s)
  end

  def apply!(s)
    return self.steps!(s)
  end

  def simplifyState(s)
    return s.map{|a| a.join(".")}.join(";")
  end

  def conjecture_to_dot
    res = EFSM.new
    res.inputs = @M.inputs
    res.states = @M.states.map{|s| simplifyState(s)}
    res.trans = @M.trans.map{|t| t2 = t.clone; t2[:from] = simplifyState(t[:from]); t2[:to] = simplifyState(t[:to]); t2}
    return res.to_dot
  end
end
