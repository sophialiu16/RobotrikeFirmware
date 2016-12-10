asm86chk mumain.asm
asm86chk eventq.asm
asm86chk queue.asm 

asm86chk motors.inc
asm86chk motortmr.asm
asm86chk trigtbl.asm

asm86chk state.asm 

asm86chk initcs.asm
asm86chk EHdlr.asm

asm86chk serial.asm
asm86chk seriali.asm

asm86 mumain.asm m1 db ep
asm86 eventq.asm m1 db ep
asm86 queue.asm m1 db ep

asm86 motors.asm m1 db ep
asm86 motortmr.asm m1 db ep
asm86 trigtbl.asm m1 db ep

asm86 state.asm m1 db ep

asm86 initcs.asm m1 db ep
asm86 EHdlr.asm m1 db ep

asm86 serial.asm m1 db ep
asm86 seriali.asm m1 db ep

link86 mumain.obj, queue.obj, motors.obj, motortmr.obj, trigtbl.obj, state.obj to temp1.lnk
link86 initcs.obj, EHdlr.obj, serial.obj, seriali.obj, hw7test.obj to temp2.lnk
link86 temp1.lnk, temp2.lnk to mumain.lnk
loc86 mumain.lnk to mumain NOIC AD(SM(CODE(4000H), DATA(400H), STACK(7000H)))
