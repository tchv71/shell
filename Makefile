all: shell.rk

shell.rk: *.c *.h
	x80cc --target=rk86 shell.c cmd_copymove.c cmd_new.c cmd_freespace.c cmd_delete.c cmd_sel.c interface.c fs.c mem.asm

.PHONY: clean
clean:
	del shell.rk shell.s
