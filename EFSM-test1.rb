
$m1 = EFSM.new

$m1.states = ["s1", "s2"]
$m1.s0 = "s1"
$m1.cur_state = "s1"
$m1.regs = [0, 0]
$m1.trans = [
  {from: "s1", to: "s2", input: "a", output: "x", update: ["r0", "r1 + 1"], outpars: ["i0 + r0", "r1"], guard: "i0 >= r1"},
  {from: "s1", to: "s2", input: "a", output: "y", update: ["r0 + 1", "r1 + 1"], outpars: ["i0 + r0", "r1"], guard: "i0 < r1"},
  {from: "s2", to: "s1", input: "a", output: "y", update: ["r0", "0"], outpars: ["i0 + r0", "r1"], guard: "true"},
]

$m2 = EFSM.new
$m2.states = [1, 2, 3, 4]
$m2.s0 = 1
$m2.regs = []
$m2.cur_state = 1
$m2.trans = [
  {from: 1, to: 2, input: "x", output: "1", update: [], outpars: [], guard: "true"},
  {from: 1, to: 4, input: "y", output: "1", update: [], outpars: [], guard: "true"},
  {from: 2, to: 2, input: "x", output: "0", update: [], outpars: [], guard: "true"},
  {from: 2, to: 3, input: "y", output: "0", update: [], outpars: [], guard: "true"},
  {from: 3, to: 2, input: "x", output: "1", update: [], outpars: [], guard: "true"},
  {from: 3, to: 3, input: "y", output: "1", update: [], outpars: [], guard: "true"},
  {from: 4, to: 2, input: "x", output: "0", update: [], outpars: [], guard: "true"},
  {from: 4, to: 3, input: "y", output: "1", update: [], outpars: [], guard: "true"},
]
