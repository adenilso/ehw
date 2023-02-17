
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

  def shortestToUndef(q)
    toProcess = [[[q], []]]
    while toProcess != []
      puts "toProcess: #{toProcess}" if $DEBUG > 1
      (sts, seq) = toProcess.shift
      x = @inputs.find{|x| not @M.trans.any?{|t| t[:from] == sts.first and t[:input] == x[0]}}
      if x
        i = x[0]
        pars = x[1].map{|p| p.shuffle.first}
        return [seq, [i, pars], sts.first]
      else
        @inputs.each do |x|
          trans = @M.trans.select{|t| t[:from] == sts.first and t[:input] == x[0]}
          t = trans.first
          qprime = t[:to]
          puts "qprime: #{qprime}" if $DEBUG > 1
          if not sts.include?(qprime)
            i = x[0]
            pars = x[1].map{|p| p.shuffle.first}
            toProcess << [[qprime] + sts, seq + [[i, pars]]]
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
    return unless qprime.all?{|o| o}
    alphaprimebetaprime = @omega.slice(pos, @omega.length)
    (0..alphaprimebetaprime.length-1).map{|i| [alphaprimebetaprime.slice(0, i), alphaprimebetaprime.slice(i, alphaprimebetaprime.length)]}.reverse.each do |alphaprime, betaprime|
      rprime = @M.delta(qprime, @M.regs, alphaprime.map{|e| e[0]})  ## Delta(H(pi_h(a')), alpha)
      next unless rprime and rprime.all?{|o| o}
      betaPrimeIn = betaprime.map{|e| e[0]}
      betaPrimeOut = betaprime.map{|e| e[1]}
      alphaPrimeIn = alphaprime.map{|e| e[0]}
      (0..@omegaIn.length-1).to_a.reverse
        .select{|p| @omegaIn.slice(p, betaPrimeIn.length) == betaPrimeIn}
        .select{|p| @omegaOut.slice(p, betaPrimeOut.length) != betaPrimeOut}
        .select{|p| @C[p] and @C[p] == rprime}
        .each do |p|
          (0..p).to_a.reverse.each do |p1|
            alphaIn = @omegaIn.slice(p1, p - p1)
            e = @LLoc.keys.find{|e| @LLoc[e].include?(p1)}
            found = alphaPrimeIn != alphaIn or eta != e
            self.printTrace if $DEBUG > 3
            puts self.conjecture_to_dot if $DEBUG > 3
            raise WNDException.new(betaPrimeIn) if found and not @W.include?(betaPrimeIn)
          end
      end
    end
  end
  
  def printTrace
    (0..@omega.length-1).each do |i|
      eta = @LLoc.keys.find{|eta| @LLoc[eta].include?(i)}
      h = if eta then "(h/#{eta.join}) " else "" end
      w = if @C[i] then "(#{@C[i].map{|e| if e then e.join else "-" end}.join(",")}) " else "" end

      print "#{i}: #{h}#{w}#{@omegaIn[i][0]}/#{@omegaOut[i][0]} "
    end
    puts "" 
  end

  def ehw
    while true
      while not @M.complete?
        begin
          eta = self.projecth(self.apply!(@h))
          @LLoc[eta] = [] unless @LLoc[eta]
          @lastHApplication = [eta, @omega.length]
          @LLoc[eta] << @omega.length
          puts "eta: #{eta}" if $DEBUG > 1
          if not @H[eta]
            @H[eta] = {} 
          end
          @C[@omega.length] = @W.map{|w| @H[eta][w]}
          w = @W.find{|w| not @H[eta][w]}
          if w or @W.length == 0
            pos = @omega.length
            y = self.projectw(self.apply!(w))
            puts "w: #{w} / #{y}" if $DEBUG > 1
            @H[eta][w] = y
            @C[pos] = @W.map{|w| @H[eta][w]}
          else
            q = @W.map{|w| @H[eta][w]}
            puts "q: #{q}" if $DEBUG > 1
            @M.states |= [q]
            (alpha, x, qprime) = self.shortestToUndef(q)
            puts "(alpha, x, qprime) = (#{alpha}, #{x}, #{qprime})" if $DEBUG > 1
            self.apply!(alpha)
            @C[@omega.length] = qprime
            y = self.apply!([x]).first
            if y.first == OMEGA
              puts "OMEGA!" if $DEBUG > 1
              @M.trans << {
                from: qprime,
                to: qprime,
                input: x.first,
                output: y.first,
                guard: true,
                update: [],
                outpars: [],
              }
            else
              @domDelta[qprime] = {} unless @domDelta[qprime]
              @domDelta[qprime][x] = {} unless @domDelta[qprime][x]
              w = @W.find{|w| not @domDelta[qprime][x][w]}
              if w or @W.length == 0
                pos = @omega.length
                xi = self.projectw(self.apply!(w))
                puts "[x] w: #{w} / #{xi}" if $DEBUG > 1
                @domDelta[qprime][x][w] = xi
                if not @W.find{|w| not @domDelta[qprime][x][w]}
                  nq = @W.map{|w| @domDelta[qprime][x][w]}
                  @C[pos] = nq
                  @M.states |= [nq]
                  @M.trans << {
                    from: qprime,
                    to: nq,
                    input: x.first,
                    output: y.first,
                    guard: true,
                    update: [],
                    outpars: [],
                    concrete_parameters: [[x[1], y[1]]],
                  }
                end
              end
            end
          end
        rescue HNDException => e
          puts "**********************************************" if $DEBUG > 0
          puts "newH #{e.h}" if $DEBUG > 0
          puts $ehw.conjecture_to_dot.map{|str| "+++#{str}"} if $DEBUG > 0
          @h += e.h
          self.initM
          #exit
        rescue WNDException => e
          puts "**********************************************" if $DEBUG > 0
          puts "newW #{e.w}" if $DEBUG > 0
          puts $ehw.conjecture_to_dot.map{|str| "+++#{str}"} if $DEBUG > 0
          @W << e.w
          @W = prefixFree(@W)
          self.initM
        end
        self.printTrace if $DEBUG > 3
        sleep 1 if $DEBUG > 4
      end
      puts $ehw.conjecture_to_dot.map{|str| "+++#{str}"} if $DEBUG > 3
      @M.positionCurrentState(@omega)
      GP.computeEFSM!(@M)
      eqOrCE = @bb.randomWalkUntilDiff(@M, 1000)
      puts "#{eqOrCE}"
      if eqOrCE[:status] == "EQ"
        puts "equiv? = #{@bb.equiv?(@M)}" if $DEBUG > 3
        break
      elsif eqOrCE[:status] == "CE"
        seq = eqOrCE[:ce]
        (1..seq.length-1).each do |i|
          suffix = seq.slice(seq.length - i, seq.length)
          if not @W.include?(suffix)
            puts "@W = #{@W} suffix = #{suffix}" if $DEBUG > 1
            @W << suffix
            @W = prefixFree(@W)
            self.initM
            break
          end
        end
      end
    end
    puts "equiv? #{@bb.equiv?(@M)}" if $DEBUG > 3
  end

  def prefixFree(seqs)
    return seqs.select{|s| not seqs.any?{|s1| s.length < s1.length and s == s1.slice(0, s.length)}}
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
