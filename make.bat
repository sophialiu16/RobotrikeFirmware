asm86chk rmain.asm
asm86chk eventq.asm
asm86chk queue.asm 

asm86chk keypad.asm
asm86chk display.asm
asm86chk converts.asm
asm86chk segtab14.asm

asm86chk timer.asm
asm86chk initcs.asm
asm86chk EHdlr.asm
asm86chk DKTmrEH.asm

asm86chk serial.asm
asm86chk seriali.asm

asm86 rmain.asm m1 db ep
asm86 eventq.asm m1 db ep
asm86 queue.asm m1 db ep

asm86 keypad.asm m1 db ep
asm86 display.asm m1 db ep
asm86 converts.asm m1 db ep
asm86 segtab14.asm m1 db ep

asm86 timer.asm m1 db ep
asm86 initcs.asm m1 db ep
asm86 EHdlr.asm m1 db ep
asm86 DKTmrEH.asm m1 db ep

asm86 serial.asm m1 db ep
asm86 seriali.asm m1 db ep

link86 rmain.obj, eventq.obj, queue.obj, keypad.obj, display.obj, converts.obj, segtab14.obj to temp1.lnk
link86 timer.obj, initcs.obj, EHdlr.obj, DKTmrEH.obj, serial.obj, seriali.obj to temp2.lnk
link86 temp1.lnk, temp2.lnk to rmain.lnk
loc86 rmain.lnk to rmain NOIC AD(SM(CODE(4000H), DATA(400H), STACK(7000H)))
