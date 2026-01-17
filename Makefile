all: shell.rk

shell.rk: *.c *.h
	../C8080/c8080.exe shell.c cmd_copymove.c cmd_new.c cmd_freespace.c cmd_delete.c cmd_sel.c interface.c
	../C8080/tasm -gb -b -85 -s shell.asm shell.bin
	cscript /E:jscript make-rka.js
	../../m80noi/x64/Release/m80noi.exe shell.lst

.PHONY: clean
clean:
	del shell.bin shell.rk shell.lst shell.asm
