
class GP
  def self.computeEFSM!(m)
    m.trans.each do |t|
      if t[:concrete_parameters] and t[:concrete_parameters].length > 0# and t[:concrete_parameters].any?{|ip, op| op.length > 0}
        print "output function for: "
        puts "#{t}"
        t[:concrete_parameters].each do |ip, op|
          puts "#{ip} => #{op}"
        end
        line = readline
        t[:outpars] = line.chomp.split(",")
        t[:outpars].shift
        puts "#{t}"
      end
    end
    return m
  end
end
