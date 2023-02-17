
class GP
  def self.computeEFSM!(m)
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
            lineout = ["i0", "2*i0", "3*i0"].shuffle.first
          else
            lineout = ["10*i0+i1", "i0+2*i1", "42*i0*i1", "i0*2*i1;", "42+i0*i1", "2*i0+2*i1", "42*i0*i1"].shuffle.first
          end
        end
        #lineout = readline
        outpars = lineout
        t[:update] = []
        t[:update]
        t[:outpars] = outpars.split(",")
        puts "#{t}"
      end
    end
    return m
  end
end
