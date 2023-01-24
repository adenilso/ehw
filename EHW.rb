
class HNDException < Exception
  attr_reader :h
  def initialize(h)
    @h = h
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
    puts "checking h-ND..." if $DEBUG > 3
    puts "checking h-ND lastHApplication = #{@lastHApplication}" if $DEBUG > 3
    return unless @lastHApplication
    (eta, pos) = @lastHApplication
    betav = @omega.slice(pos, @omega.length)
    puts "checking h-ND betav = #{betav}" if $DEBUG > 3
    beta = betav.map{|i| i[0]}
    v = self.projecth(betav.map{|i| i[1]})
    lloc = @LLoc[eta].find{|l| vline = @omega.slice(l, betav.length) ; vline.map{|i| i[0]} == beta and self.projecth(vline.map{|i| i[1]}) != v}
    puts "checking h-ND lloc = #{lloc}" if $DEBUG > 3
    raise HNDException.new(beta) if lloc
    return lloc
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
      @statesVisited << @bb.cur_state
      self.checkhND
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
