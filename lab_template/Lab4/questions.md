part1时钟周期有：

Cycles = 46874
Insts  = 21628

Cycles = 14681
Insts  = 6873

Cycles = 6339
Insts  = 3020

Cycles = 19310
Insts  = 9909

Cycles = 775
Insts  = 369

Cycles = 48117
Insts  = 21100

Cycles = 1980474
Insts  = 867331

Cycle Per Instruction(CPI) = (46874/21628 + 14681/6873 + 6339/3020 + 19310/9909 + 775/369 + 48117/21100 + 1980474/867331)/7 = 2.145



part2实现了Execute到Fetch的数据转发，时钟周期有：

Cycles = 41073
Insts  = 21628

Cycles = 12812
Insts  = 6873

Cycles = 5741
Insts  = 3020

Cycles = 17724
Insts  = 9909

Cycles = 706
Insts  = 369

Cycles = 42683
Insts  = 21100

Cycles = 1724365
Insts  = 867331

Cycle Per Instruction(CPI) = (41073/21628 + 12812/6873 + 5741/3020 + 17724/9909 + 706/369 + 42683/21100 + 1724365/867331)/7 = 1.911



Do all of your rules fire every cycle?

```
Rules in Bluespec SystemVerilog only fire when their fire conditions are satisfied, ensuring that the system behaves correctly and efficiently by executing rules when necessary rather than in every clock cycle.
The rule will still block when there are unresolved data dependencies.
```

