$runex = EFSM.new
$runex.states = ["s0", "s1", "s2"]
$runex.s0 = "s0"
$runex.regs = [nil, nil]
$runex.cur_state = $runex.s0
$runex.trans = [
  {from: "s0", to: "s1", input: "select", output: "", update: ["i0", "0"], outpars: [], guard: "true"},
  {from: "s1", to: "s1", input: "coin", output: "Rej", update: ["r0", "r1"], outpars: ["i0"], guard: "i0 < 100"},
  {from: "s1", to: "s2", input: "coin", output: "Display", update: ["r0", "r1 + i0"], outpars: ["r1 + i0"], guard: "i0 >= 100"},
  {from: "s2", to: "s2", input: "coin", output: "Display", update: ["r0", "r1 + i0"], outpars: ["r1 + i0"], guard: "true"},
  {from: "s2", to: "s0", input: "vend", output: "Serv", update: ["r0", "r1"], outpars: ["r0"], guard: "true"},
]

$m2 = EFSM.new
$m2.states = [0, 1, 2, 3]
$m2.s0 = 0
$m2.regs = []
$m2.cur_state = 0
$m2.trans = [
  {from: 0, to: 1, input: "x", output: "0", update: [], outpars: [], guard: "true"},
  {from: 0, to: 3, input: "y", output: "0", update: [], outpars: [], guard: "true"},
  {from: 1, to: 1, input: "x", output: "0", update: [], outpars: [], guard: "true"},
  {from: 1, to: 2, input: "y", output: "1", update: [], outpars: [], guard: "true"},
  {from: 2, to: 1, input: "x", output: "1", update: [], outpars: [], guard: "true"},
  {from: 2, to: 3, input: "y", output: "0", update: [], outpars: [], guard: "true"},
  {from: 3, to: 3, input: "x", output: "1", update: [], outpars: [], guard: "true"},
  {from: 3, to: 0, input: "y", output: "1", update: [], outpars: [], guard: "true"},
]
$m2.inputs = [["x", []], ["y", []]]

# ICGI2018_Groz_final.pdf, Fig1(a)
$ICGI2018 = EFSM.new
$ICGI2018.states = [1, 2, 3, 4]
$ICGI2018.s0 = 1
$ICGI2018.regs = []
$ICGI2018.cur_state = 1
$ICGI2018.trans = [
  {from: 1, to: 2, input: "a", output: "0", update: [], outpars: [], guard: "true"},
  {from: 1, to: 1, input: "b", output: "0", update: [], outpars: [], guard: "true"},
  {from: 2, to: 3, input: "a", output: "0", update: [], outpars: [], guard: "true"},
  {from: 2, to: 1, input: "b", output: "0", update: [], outpars: [], guard: "true"},
  {from: 3, to: 4, input: "a", output: "1", update: [], outpars: [], guard: "true"},
  {from: 3, to: 2, input: "b", output: "0", update: [], outpars: [], guard: "true"},
  {from: 4, to: 2, input: "a", output: "0", update: [], outpars: [], guard: "true"},
  {from: 4, to: 3, input: "b", output: "1", update: [], outpars: [], guard: "true"},
]
$ICGI2018.inputs = [ ["a", []], ["b", []] ]

$ICGI2018Pars = EFSM.new
$ICGI2018Pars.states = [1, 2, 3, 4]
$ICGI2018Pars.s0 = 1
$ICGI2018Pars.regs = []
$ICGI2018Pars.cur_state = 1
$ICGI2018Pars.trans = [
  {from: 1, to: 2, input: "a", output: "0", update: [], outpars: [], guard: "true"},
  {from: 1, to: 1, input: "b", output: "0", update: [], outpars: [], guard: "true"},
  {from: 2, to: 3, input: "a", output: "0", update: [], outpars: [], guard: "true"},
  {from: 2, to: 1, input: "b", output: "0", update: [], outpars: [], guard: "true"},
  {from: 3, to: 4, input: "a", output: "1", update: [], outpars: ["2*i0"], guard: "true"},
  {from: 3, to: 2, input: "b", output: "0", update: [], outpars: [], guard: "true"},
  {from: 4, to: 2, input: "a", output: "0", update: [], outpars: [], guard: "true"},
  {from: 4, to: 3, input: "b", output: "1", update: [], outpars: ["10*i0 + i1"], guard: "true"},
]
$ICGI2018Pars.inputs = [ ["a", [[101, 102]]], ["b", [[201,202,203], [10, 11]]] ]

$m = $ICGI2018

$ehw = EHW.new
$ehw.bb = $m
$ehw.h = []
#$ehw.W = [[["b", []]]]
$ehw.W = [[]]
$ehw.inputs = $m.inputs 

$DEBUG = 5

$ehw.ehw

puts $ehw.conjecture_to_dot.map{|str| "+++#{str}"}

puts $m.to_dot.map{|str| "@@@#{str}"}
