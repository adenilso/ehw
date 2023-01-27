
class HNDException < Exception
  attr_reader :h
  def initialize(h)
    @h = h
  end
end

class WNDException < Exception
  attr_reader :w
  def initialize(w)
    @w = w
  end
end

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
    self.initM
  end

  def initM
    @H = {}
    @domDelta = {}
    @omega = []
    @omegaIn = []
    @omegaOut = []
    @statesVisited = []
    @C = {}
    @LLoc = {}
    @lastHApplication = nil
    @M = EFSM.new
    @M.states = []
    @M.trans = []
    @M.inputs = @inputs
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
        puts "@inputs: #{@inputs}"
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

  def checkhND
    return unless @lastHApplication
    (eta, pos) = @lastHApplication
    betav = @omega.slice(pos, @omega.length)
    beta = betav.map{|i| i[0]}
    v = self.projecth(betav.map{|i| i[1]})
    lloc = @LLoc[eta].find{|l| vprime = @omega.slice(l, betav.length) ; vprime.map{|i| i[0]} == beta and self.projecth(vprime.map{|i| i[1]}) != v}
    raise HNDException.new(beta) if lloc
    return lloc
  end

  def checkWND
    return unless @lastHApplication
    (eta, pos) = @lastHApplication
    qprime = @W.map{|w| @H[eta][w]} ## H(pi_h(a'))
    puts "qprime = #{qprime}" if $DEBUG > 2
    return unless qprime.all?{|o| o}
    alphaprimebetaprime = @omega.slice(pos, @omega.length)
    puts "alphaprimebetaprime = #{alphaprimebetaprime}" if $DEBUG > 2
    (0..alphaprimebetaprime.length-2).map{|i| [alphaprimebetaprime.slice(0, i), alphaprimebetaprime.slice(i+1, alphaprimebetaprime.length)]}.reverse.each do |alphaprime, betaprime|
      puts "(alpha, beta) = #{[alphaprime.map{|e| e[0].join}, betaprime.map{|e| e[0].join}]}" if $DEBUG > 2
      pprime = @M.delta(qprime, @M.regs, alphaprime.map{|e| e[0]})  ## Delta(H(pi_h(a')), alpha)
      next unless pprime
      puts "pprime = #{pprime}" if $DEBUG > 2
      betaPrimeIn = betaprime.map{|e| e[0]}
      betaPrimeOut = betaprime.map{|e| e[1]}
      alphaPrimeIn = alphaprime.map{|e| e[0]}
      (0..@omegaIn.length-1).to_a.reverse
        .select{|p| @omegaIn.slice(p, betaPrimeIn.length) == betaPrimeIn}
        .select{|p| @omegaOut.slice(p, betaPrimeOut.length) != betaPrimeOut}
        .select{|p| @C[p] and @C[p] == pprime}
        .each do |p|
          (0..p).to_a.reverse.each do |p1|
            alphaIn = @omegaIn.slice(p1, p - p1)
            found = alphaPrimeIn != alphaIn or eta != @LLoc.keys.find{|p2| p2 != p1}
            self.printTrace
            puts "betaPrimeIn = #{betaPrimeIn}" if found
            raise WNDException.new(betaPrimeIn) if found
          end
      end
    end
  end
  
  def printTrace
    (0..@omega.length-1).each do |i|
      eta = @LLoc.keys.find{|eta| @LLoc[eta].include?(i)}
      h = if eta then "(h/#{eta.join}) " else "" end

      print "#{h}#{@omegaIn[i][0]}/#{@omegaOut[i][0]} "
    end
    puts "" 
  end

  def ehw
    while not @M.complete?
      begin
        eta = self.projecth(self.apply!(@h))
        @LLoc[eta] = [] unless @LLoc[eta]
        @lastHApplication = [eta, @omega.length]
        @LLoc[eta] << @omega.length
        puts "eta: #{eta}" if $DEBUG > 0
        if not @H[eta]
          @H[eta] = {} 
        end
        w = @W.find{|w| not @H[eta][w]}
        if w
          pos = @omega.length
          y = self.projectw(self.apply!(w))
          puts "w: #{w} / #{y}" if $DEBUG > 0
          @H[eta][w] = y
          @C[pos] = @W.map{|w| @H[eta][w]}
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
              pos = @omega.length
              xi = self.projectw(self.apply!(w))
              puts "[x] w: #{w} / #{xi}" if $DEBUG > 0
              @domDelta[qline][x][w] = xi
              if not @W.find{|w| not @domDelta[qline][x][w]}
                nq = @W.map{|w| @domDelta[qline][x][w]}
                @C[pos] = nq
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
      rescue HNDException => e
        puts "**********************************************" if $DEBUG > 3
        puts "newH #{e.h}" if $DEBUG > 3
        puts @omega.zip(@statesVisited).map{|e| "#{e[0][0].first}/#{e[0][1].first} [#{e[1]}]"}.join(" ") if $DEBUG > 3
        puts $ehw.conjecture_to_dot.map{|str| "+++#{str}"} if $DEBUG > 3
        @h += e.h
        self.initM
        #exit
      end
    end
  end

  def steps!(ss)
    res = []
    ss.each do |s|
      r = @bb.steps!([s]).first
      res << r
      @omega << [s, r]
      @omegaIn << s
      @omegaOut << r
      @statesVisited << @bb.cur_state
      self.checkhND
      self.checkWND
    end
    return res
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
