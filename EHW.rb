
class EHW
  attr_accessor :h
  attr_accessor :W

  attr_accessor :M

  attr_accessor :inputs
  attr_accessor :inputsigs

  attr_accessor :applications

  attr_accessor :bb

  def initialize
    @h = []
    @W = []
    @lastcstate = nil
    @seqsincelastcstate = nil
    @verifiedseqs = []
    @verifiedtrans = []
    @inputs = []
    @M = EFSM.new
    @M.states = []
    @M.s0 = @M.cur_state = @M.states.first
    @applications = {}
    @lastH = nil
  end

  #def ehw
  #  known = false
  #  while true
  #    if not known
  #      hres = @bb.steps!(@h)
  #      puts "--h: #{hres}"
  #      w = unknownW(hres, [])
  #      if w
  #        wres = @bb.steps!(w)
  #        puts "--w: #{wres}"
  #        known = addW(hres, [], wres)
  #      end
  #    else
  #      break
  #    end
  #  end
  #end

  def steps!(s)
    @seqsincelastcstate += s if @seqsincelastcstate
    return @bb.steps!(s)
  end

  def apply_h
    while true
      if @seqsincelastcstate and @seqsincelastcstate == [] and 
        res = unknownX(@M.cur_state, @inputs)
        if res
          (seq, x) = res
          hres = self.steps!(seq + [x])
          puts "tr x: #{seq} - #{x}"
          w = unknownW(hres, seq + [x])
          if w
            wres = self.steps!(w)
            puts "--w: #{wres}"
            addW(hres, [], wres)
          end
        end
        break
      else
        hres = self.steps!(@h)
        puts "--h: #{@h} / #{hres}"
        w = unknownW(hres, [])
        if w
          wres = self.steps!(w)
          puts "--w: #{w} / #{wres}"
          addW(hres, [], wres)
        end
      end
      self.advanceCState!
    end
  end

  def advanceCState!
    return
  end

  def unknownX(state, inputs)
    return unknownXAux([state], [], inputs)
  end

  def unknownXAux(seq, iseq, inputs)
    state = seq.first
    inputs.each do |x|
      p = @M.trans.select{|t| t[:from] == state and t[:input] == input and eval_expr(t[:guard], [], [])}
      if p.length == 0
        return [iseq, [x, []]]
      end
    end
    inputs.each do |x|
      p = @M.trans.select{|t| t[:from] == state and t[:input] == input and eval_expr(t[:guard], [], [])}.first
      res = self.unknownXAux([p[:to]] + seq, [x] + iseq, inputs)
      if res
        return res
      end
    end
    return nil
  end

  def unknownW(res, seq)
    @applications[res] = {} unless @applications[res]
    @applications[res][seq] = [] unless @applications[res][seq]
    p = @applications[res][seq].length
    if p < @W.length
      return @W[p]
    else
      return nil
    end
  end

  def addW(res, seq, wres)
    @applications[res] = {} unless @applications[res]
    @applications[res][seq] = [] unless @applications[res][seq]
    @applications[res][seq] << wres
    if @applications[res][seq].length == @W.length
      @M.states = @M.states | [@applications[res][seq]]
      @M.cur_state = @applications[res][seq]
      if @lastcstate
        @verifiedseqs << [@lastcstate, @seqsincelastcstate, @applications[res][seq]]
        if @seqsincelastcstate.length == 1
          @verifiedtrans << [@lastcstate, @seqsincelastcstate.first]
        end
      end
      @lastcstate = @applications[res][seq]
      @seqsincelastcstate = []
      return @applications[res][seq]
    else
      return nil
    end
  end
end
