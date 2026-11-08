// Shell for Computer "Radio 86RK" / "Apogee BK01"
// (c) 12-05-2014 vinxru (aleksey.f.morozov@gmail.com)

#include "fs/fs.h"
#include "fs/fs_open0.h"

#include "n.h"
#include "Radio86rk/video.h"

const char* fs_cmdLine = "";
const char* fs_selfName = "SHELL.RK";
uint        fs_low;
uint        fs_high;



void fs_reboot() {
  fs_exec("","");
  //asm {
  //  jmp 0F800h
  //}
	__asm__("jp 0F800h" :  :  : );
}

uchar fs_swap() {
	return fs_open0("", O_SWAP);
}

uchar fs_open(const char* name) {
	return fs_open0(name, O_OPEN);
}

uchar fs_create(const char* name) {
	return fs_open0(name, O_CREATE);
}

uchar fs_mkdir(const char* name) {
	return fs_open0(name, O_MKDIR);
}

uchar fs_gettotal() { // fs_high:fs_low - размер в ћб
	return fs_seek(0, 0, 101);
}

uchar fs_getsize() { // fs_high:fs_low - размер
	return fs_seek(0, 0, 100);
}

uchar fs_getfree() { // fs_high:fs_low - размер в ћб
	return fs_seek(0, 0, 102);
}

uchar fs_findnext(FileInfo* dest, uint size) {
	return fs_findfirst(":", dest, size);
}

uchar fs_delete(const char* name) {
	return fs_open0(name, O_DELETE);
}
