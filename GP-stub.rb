
class GP
  def self.computeEFSM!(m)
    maxregs = 0
    m.trans.each do |t|
      if t[:concrete_parameters] and t[:concrete_parameters].length > 0# and t[:concrete_parameters].any?{|ip, op| op.length > 0}
        print "output function for: "
        puts "#{t}"
        t[:concrete_parameters].each do |ip, op|
          puts "#{ip} => #{op}"
        end
        lineout = nil
        cp = t[:concrete_parameters].first
        if cp[1].length == 0
          lineout = ""
        else
          if cp[0].length == 1
            lineout = ["2*i0+r0"].shuffle.first
          else
            #lineout = ["10*i0+i1"].shuffle.first
            lineout = ["10*i0+i1", "i0+2*i1"].shuffle.first
          end
        end
        #lineout = readline
        outpars = lineout
        t[:outpars] = outpars.split(",")
      end
      print "update function for: "
      puts "#{t}"
      lineup = "r0,r1"
      if t[:input] == "a"
        lineup = "0,0"
      end
      if t[:input] == "b"# and t[:output] == "q"
        lineup = ["r0,r1", "r0+2,r1", "r0+1,r1"].shuffle.first
        #lineup = ["r0+1,r1"].shuffle.first
      end
      regsup = lineup.split(",")
      t[:update] = regsup
      maxregs = [maxregs, regsup.length].max
      puts "#{t}"
    end
    m.regs = maxregs.times.to_a.map{nil}
    return m
  end
end
