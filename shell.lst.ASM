  .include "stdlib8080.inc"
  .org 100h
start:
  jmp main




getPalmiraMode:
  xra a
  sta mode
  ; 29 asm {
    MVI A, 2
    CALL 0F003h
    STA mode
  
  ret
  ; --- setPalmiraMode -----------------------------------------------------------------
setPalmiraMode:
  sta setPalmiraMode_1
  ; 38 asm {
    LDA setPalmiraMode_1 
    MOV C, A
    MVI A, 1
    CALL 0F003h
  
  ret
  ; --- getPalmiraModeStr -----------------------------------------------------------------
getPalmiraModeStr:
  lda mode
  ora a
  jz l1
  cpi 1
  jz l2
  cpi 2
  jz l3
  jmp l4
l1:
  ; 50 return "48K:";
  lxi h, string0
  ret
l2:
  ; 52 return "32K:";
  lxi h, string1
  ret
l3:
  ; 54 return "16K:";
  lxi h, string2
  ret
l4:
  ; 56 return "???:";
  lxi h, string3
  ret
l0:
  ret
  ; --- drawFiles -----------------------------------------------------------------
drawFiles:
  call hideFileCursor
  ; 70 drawColumn(0);
  xra a
  call drawColumn
  ; 71 drawColumn(1);
  mvi a, 1
  jmp drawColumn
swapPanels:
  lxi h, panelA
  shld memswap_1
  lxi h, panelB
  shld memswap_2
  lxi h, 266
  call memswap
  ; 79 drawSwapPanels();
  jmp drawSwapPanels
getSel:
  lhld (panelA)+(260)
  xchg
  lhld (panelA)+(259)
  mvi h, 0
  dad d
  push h
  mvi d, 22
  lda (panelA)+(258)
  call op_mul
  ; Сложение
  pop d
  dad d
  shld getSel_n
  ; 86 if(n < panelA.cnt) return panelA.files1 + n;
  xchg
  lhld (panelA)+(262)
  call op_cmp16
  jc l5
  jz l5
  ; 86 return panelA.files1 + n;
  lhld getSel_n
  ; Умножение HL на 20
  mov d, h
  mov e, l
  dad h
  dad h
  dad d
  dad h
  dad h
  ; Сложение
  xchg
  lhld panelA
  dad d
  ret
l5:
  ; 87 panelA.offset = 0;
  lxi h, 0
  shld (panelA)+(260)
  ; 88 panelA.cursorY = 0;
  xra a
  sta (panelA)+(259)
  ; 89 panelA.cursorX = 0;
  sta (panelA)+(258)
  ; 90 if(panelA.cnt != 0) return panelA.files1;Сложение с константой 0
  lhld (panelA)+(262)
  mov a, l
  ora h
  jz l6
  ; 90 return panelA.files1;
  lhld panelA
  ret
l6:
  ; 91 return (FileInfo*)parentDir;
  lxi h, parentDir
  ret
  ; --- getSelNoBack -----------------------------------------------------------------
getSelNoBack:
  call getSel
  shld getSelNoBack_f
  ; 98 if(f->fname[0] == '.') f = 0;Сложение с константой 0
  mov a, m
  cpi 46
  jnz l7
  ; 98 f = 0;
  lxi h, 0
  shld getSelNoBack_f
l7:
  ; 99 return f;  
  ret
  ; --- drawFileInfo -----------------------------------------------------------------
drawFileInfo:
  call getSel
  shld drawFileInfo_f
  ; 111 if(f->fattrib & 0x10) {Сложение
  lxi d, 11
  dad d
  mov a, m
  ani 16
  ; convertToConfition
  jz l8
  ; 112 drawFileInfoDir();
  call drawFileInfoDir
  jmp l9
l8:
  ; 114 i2s32(buf, &f->fsize, 10, ' ');           
  lxi h, drawFileInfo_buf
  shld i2s32_1
  ; Сложение
  lhld drawFileInfo_f
  lxi d, 12
  dad d
  shld i2s32_2
  lxi h, 10
  shld i2s32_3
  mvi a, 32
  call i2s32
  ; 115 drawFileInfo1(buf);
  lxi h, drawFileInfo_buf
  call drawFileInfo1
l9:
  ; 118 if(f->fdate==0 && f->ftime==0) {Сложение
  lhld drawFileInfo_f
  lxi d, 18
  dad d
  ; Сложение с константой 0
  mov e, m
  inx h
  mov d, m
  xchg
  mov a, l
  ora h
  jnz l10
  ; Сложение
  lhld drawFileInfo_f
  lxi d, 16
  dad d
  ; Сложение с константой 0
  mov e, m
  inx h
  mov d, m
  xchg
  mov a, l
  ora h
  jnz l10
  ; 119 buf[0] = 0;
  xra a
  sta (drawFileInfo_buf)+(0)
  jmp l11
l10:
  ; 121 i2s(buf, f->fdate & 31, 2, ' ');  
  lxi h, drawFileInfo_buf
  shld i2s_1
  ; Сложение
  lhld drawFileInfo_f
  lxi d, 18
  dad d
  ; 16 битная арифметическая операция с константой
  mov e, m
  inx h
  mov d, m
  xchg
  mov a, l
  ani 31
  mov l, a
  mvi h, 0
  shld i2s_2
  mvi l, 2
  shld i2s_3
  mvi a, 32
  call i2s
  ; 122 buf[2] = '-';
  mvi a, 45
  sta (drawFileInfo_buf)+(2)
  ; 123 i2s(buf+3, (f->fdate>>5) & 15, 2, '0');
  lxi h, (drawFileInfo_buf)+(3)
  shld i2s_1
  ; Сложение
  lhld drawFileInfo_f
  lxi d, 18
  dad d
  ; Сдвиг вправо
  mov e, m
  inx h
  mov d, m
  xchg
  lxi d, 5
  call op_shr16
  ; 16 битная арифметическая операция с константой
  mov a, l
  ani 15
  mov l, a
  mvi h, 0
  shld i2s_2
  mvi l, 2
  shld i2s_3
  mvi a, 48
  call i2s
  ; 124 buf[5] = '-';
  mvi a, 45
  sta (drawFileInfo_buf)+(5)
  ; 125 i2s(buf+6, (f->fdate>>9)+1980, 4, '0');
  lxi h, (drawFileInfo_buf)+(6)
  shld i2s_1
  ; Сложение
  lhld drawFileInfo_f
  lxi d, 18
  dad d
  ; Сдвиг вправо
  mov e, m
  inx h
  mov d, m
  xchg
  lxi d, 9
  call op_shr16
  ; Сложение
  lxi d, 1980
  dad d
  shld i2s_2
  lxi h, 4
  shld i2s_3
  mvi a, 48
  call i2s
  ; 126 buf[10] = ' ';
  mvi a, 32
  sta (drawFileInfo_buf)+(10)
  ; 127 i2s(buf+11, f->ftime>>11, 2, '0');
  lxi h, (drawFileInfo_buf)+(11)
  shld i2s_1
  ; Сложение
  lhld drawFileInfo_f
  lxi d, 16
  dad d
  ; Сдвиг вправо
  mov e, m
  inx h
  mov d, m
  xchg
  lxi d, 11
  call op_shr16
  shld i2s_2
  lxi h, 2
  shld i2s_3
  mvi a, 48
  call i2s
  ; 128 buf[13] = ':';
  mvi a, 58
  sta (drawFileInfo_buf)+(13)
  ; 129 i2s(buf+14, (f->ftime>>5)&63, 2, '0');
  lxi h, (drawFileInfo_buf)+(14)
  shld i2s_1
  ; Сложение
  lhld drawFileInfo_f
  lxi d, 16
  dad d
  ; Сдвиг вправо
  mov e, m
  inx h
  mov d, m
  xchg
  lxi d, 5
  call op_shr16
  ; 16 битная арифметическая операция с константой
  mov a, l
  ani 63
  mov l, a
  mvi h, 0
  shld i2s_2
  mvi l, 2
  shld i2s_3
  mvi a, 48
  call i2s
l11:
  ; 131 drawFileInfo2(buf);
  lxi h, drawFileInfo_buf
  jmp drawFileInfo2
showFileCursorAndDrawFileInfo:
  call showFileCursor
  ; 139 drawFileInfo();  
  jmp drawFileInfo
drawFilesCount:
  lxi h, 0
  shld (drawFilesCount_total)+(0)
  ; 1 ((ushort*)a)[1] = (b>>16); }
  shld (drawFilesCount_total)+(2)
  ; 150 filesCnt = 0;
  shld drawFilesCount_filesCnt
  ; 151 for(p = panelA.files1, i = panelA.cnt; i; ++p, --i) {
  lhld panelA
  shld drawFilesCount_p
  lhld (panelA)+(262)
  shld drawFilesCount_i
l12:
  ; convertToConfition
  mov a, l
  ora h
  jz l13
  ; 152 if((p->fattrib & 0x10) == 0) ++filesCnt;Сложение
  lhld drawFilesCount_p
  lxi d, 11
  dad d
  mov a, m
  ani 16
  jnz l15
  ; 152 ++filesCnt;
  lhld drawFilesCount_filesCnt
  inx h
  shld drawFilesCount_filesCnt
l15:
  ; 153 add32_32(&total, &p->fsize);
  lxi h, drawFilesCount_total
  shld add32_32_1
  ; Сложение
  lhld drawFilesCount_p
  lxi d, 12
  dad d
  call add32_32
l14:
  lhld drawFilesCount_p
  lxi d, 20
  dad d
  shld drawFilesCount_p
  lhld drawFilesCount_i
  dcx h
  shld drawFilesCount_i
  jmp l12
l13:
  ; 156 drawFilesCountInt(&total, filesCnt);
  lxi h, drawFilesCount_total
  shld drawFilesCountInt_1
  lhld drawFilesCount_filesCnt
  jmp drawFilesCountInt
drawFiles2:
  call drawFiles
  ; 164 drawFilesCount();
  call drawFilesCount
  ; 165 swapPanels();
  call swapPanels
  ; 166 drawFiles();
  call drawFiles
  ; 167 drawFilesCount();
  call drawFilesCount
  ; 168 drawFileInfo();
  call drawFileInfo
  ; 169 swapPanels();
  call swapPanels
  ; 170 showFileCursorAndDrawFileInfo();
  jmp showFileCursorAndDrawFileInfo
drawScreen:
  xra a
  sta (cmdline)+(0)
  ; 178 drawScreenInt();
  call drawScreenInt
  ; 179 drawCmdLineWithPath();
  call drawCmdLineWithPath
  ; 180 drawFiles2();
  jmp drawFiles2
processInput:
  push b
  sta processInput_1
  ; 187 strlen(cmdline);<cmdline_pos>
  lxi h, cmdline
  call strlen
  mov b, h
  mov c, l
  ; 188 if(c==KEY_BKSPC) {
  lda processInput_1
  cpi 127
  jnz l16
  ; 189 if(cmdline_pos==0) return;Сложение с константой 0
  mov a, l
  ora h
  jnz l17
  ; 189 return;
  pop b
  ret
l17:
  ; 190 --cmdline_pos;    
  dcx b
  ; 191 cmdline[cmdline_pos] = 0;Сложение с BC
  lxi h, cmdline
  dad b
  mvi m, 0
  ; 192 return;
  pop b
  ret
l16:
  ; 194 if(c>=32) {
  lda processInput_1
  cpi 32
  jc l18
  ; 195 if(cmdline_pos==255) return; Сложение с BC
  lxi h, 65281
  dad b
  mov a, l
  ora h
  jnz l19
  ; 195 return; 
  pop b
  ret
l19:
  ; 196 cmdline[cmdline_pos] = c;Сложение с BC
  lxi h, cmdline
  dad b
  lda processInput_1
  mov m, a
  ; 197 ++cmdline_pos;
  inx b
  ; 198 cmdline[cmdline_pos] = 0;Сложение с BC
  lxi h, cmdline
  dad b
  mvi m, 0
l18:
  pop b
  ret
  ; --- drawError -----------------------------------------------------------------
drawError:
  sta drawError_2
  ; 209 if(e == 0) return;
  ora a
  jnz l20
  ; 209 return;
  ret
l20:
  ; 212 drawWindow(" o{ibka ");
  lxi h, string4
  call drawWindow
  ; 213 drawAnyKeyButton();
  call drawAnyKeyButton
  ; 214 drawWindowText(0, 0, text);
  xra a
  sta drawWindowText_1
  sta drawWindowText_2
  lhld drawError_1
  call drawWindowText
  ; 217 switch(e) {
  lda drawError_2
  cpi 1
  jz l22
  cpi 2
  jz l23
  cpi 7
  jz l24
  cpi 3
  jz l25
  cpi 4
  jz l26
  cpi 5
  jz l27
  cpi 6
  jz l28
  cpi 8
  jz l29
  cpi 128
  jz l30
  cpi 11
  jz l31
  jmp l32
l22:
  ; 218 text = "net fajlowoj sistemy"; break;
  lxi h, string5
  shld drawError_1
  ; 218 break;
  jmp l21
l23:
  ; 219 text = "o{ibka nakopitelq"; break;
  lxi h, string6
  shld drawError_1
  ; 219 break;
  jmp l21
l24:
  ; 220 text = "papka ne pusta"; break;
  lxi h, string7
  shld drawError_1
  ; 220 break;
  jmp l21
l25:
  ; 221 text = "fajl ne otkryt"; break;
  lxi h, string8
  shld drawError_1
  ; 221 break;
  jmp l21
l26:
  ; 222 text = "putx ne najden"; break;
  lxi h, string9
  shld drawError_1
  ; 222 break;
  jmp l21
l27:
  ; 223 text = "maksimum fajlow w papke"; break;
  lxi h, string10
  shld drawError_1
  ; 223 break;
  jmp l21
l28:
  ; 224 text = "disk zapolnen"; break;
  lxi h, string11
  shld drawError_1
  ; 224 break;
  jmp l21
l29:
  ; 225 text = "fail su}estwuet"; break;
  lxi h, string12
  shld drawError_1
  ; 225 break;
  jmp l21
l30:
  ; 226 text = "prerwano polxzowatelem"; break;
  lxi h, string13
  shld drawError_1
  ; 226 break;
  jmp l21
l31:
  ; 227 text = "putx bolx{e 255 simwolow"; break;
  lxi h, string14
  shld drawError_1
  ; 227 break;
  jmp l21
l32:
  ; 228 i2s(buf, e, 3, '0'); text = buf; break;
  lxi h, drawError_buf
  shld i2s_1
  lhld drawError_2
  mvi h, 0
  shld i2s_2
  mvi l, 3
  shld i2s_3
  mvi a, 48
  call i2s
  ; 228 text = buf; break;
  lxi h, drawError_buf
  shld drawError_1
  ; 228 break;
l21:
  ; 232 drawWindowText(0, 2, text);
  xra a
  sta drawWindowText_1
  mvi a, 2
  sta drawWindowText_2
  lhld drawError_1
  call drawWindowText
  ; 235 getch1();
  jmp getch1
inputBox:
  push b
  shld inputBox_1
  ; 243 clearFlag = 1;
  mvi c, 1
  ; 246 drawWindow(title);
  call drawWindow
  ; 247 drawWindowText(3, 1, "imq:");
  mvi a, 3
  sta drawWindowText_1
  mvi a, 1
  sta drawWindowText_2
  lxi h, string15
  call drawWindowText
  ; 248 drawWindowText(6, 4, "[ wk - ok ]  [ ar2 - otmena ]");
  mvi a, 6
  sta drawWindowText_1
  mvi a, 4
  sta drawWindowText_2
  lxi h, string16
  call drawWindowText
  ; 251 while(1) {
l33:
  ; 252 drawWindowInput(3, 2, 32);
  mvi a, 3
  sta drawWindowInput_1
  dcr a
  sta drawWindowInput_2
  mvi a, 32
  call drawWindowInput
  ; 253 c = getch1();
  call getch1
  mov b, a
  ; 254 if(c==KEY_RIGHT) clearFlag = 0;
  mvi a, 24
  cmp b
  jnz l35
  ; 254 clearFlag = 0;
  mvi c, 0
l35:
  ; 255 if(c==KEY_LEFT) clearFlag = 0;
  mvi a, 8
  cmp b
  jnz l36
  ; 255 clearFlag = 0;
  mvi c, 0
l36:
  ; 256 if(c==KEY_ENTER) { hideTextCursor(); return 1; }
  mvi a, 13
  cmp b
  jnz l37
  ; 256 hideTextCursor(); return 1; }
  call hideTextCursor
  ; 256 return 1; }
  mvi a, 1
  pop b
  ret
l37:
  ; 257 if(c==KEY_ESC) { hideTextCursor(); return 0; }
  mvi a, 27
  cmp b
  jnz l38
  ; 257 hideTextCursor(); return 0; }
  call hideTextCursor
  ; 257 return 0; }
  xra a
  pop b
  ret
l38:
  ; 258 if(clearFlag) clearFlag = 0, cmdline[0] = 0;convertToConfition
  mov a, c
  ora a
  jz l39
  ; 258 clearFlag = 0, cmdline[0] = 0;
  mvi c, 0
  xra a
  sta (cmdline)+(0)
l39:
  ; 259 processInput(c);
  mov a, b
  call processInput
  jmp l33
l34:
  pop b
  ret
  ; --- confirm -----------------------------------------------------------------
confirm:
  shld confirm_2
  ; 268 drawWindow(title);
  lhld confirm_1
  call drawWindow
  ; 269 drawWindowText(3, 1, text);
  mvi a, 3
  sta drawWindowText_1
  mvi a, 1
  sta drawWindowText_2
  lhld confirm_2
  call drawWindowText
  ; 270 drawWindowText(6, 4, "[ wk - ok ]  [ ar2 - otmena ]");
  mvi a, 6
  sta drawWindowText_1
  mvi a, 4
  sta drawWindowText_2
  lxi h, string16
  call drawWindowText
  ; 273 while(1) {
l40:
  ; 274 switch(getch1()) {
  call getch1
  cpi 13
  jz l43
  cpi 27
  jz l44
  jmp l42
l43:
  ; 275 return 1;
  mvi a, 1
  ret
l44:
  ; 276 return 0;
  xra a
  ret
l42:
  jmp l40
l41:
  ret
  ; --- unpackName -----------------------------------------------------------------
unpackName:
  push b
  shld unpackName_2
  ; 286 for(i=0; i!=11; ++i, ++s) {
  mvi b, 0
l45:
  mvi a, 11
  cmp b
  jz l46
  ; 287 if(i==8) *d = '.', ++d;
  mvi a, 8
  cmp b
  jnz l48
  ; 287 *d = '.', ++d;
  lhld unpackName_1
  mvi m, 46
  inx h
  shld unpackName_1
l48:
  ; 288 if(*s!=' ') *d = *s, ++d;
  lhld unpackName_2
  mov a, m
  cpi 32
  jz l49
  ; 288 *d = *s, ++d;
  mov a, m
  lhld unpackName_1
  mov m, a
  lhld unpackName_1
  inx h
  shld unpackName_1
l49:
l47:
  inr b
  lhld unpackName_2
  inx h
  shld unpackName_2
  jmp l45
l46:
  ; 290 if(d[-1]=='.') --d;Сложение с константой -1
  lhld unpackName_1
  dcx h
  mov a, m
  cpi 46
  jnz l50
  ; 290 --d;
  lhld unpackName_1
  dcx h
  shld unpackName_1
l50:
  ; 291 *d = 0;
  lhld unpackName_1
  mvi m, 0
  pop b
  ret
  ; --- catPathAndUnpack -----------------------------------------------------------------
catPathAndUnpack:
  shld catPathAndUnpack_2
  ; 297 strlen(str);<len>
  lhld catPathAndUnpack_1
  call strlen
  shld catPathAndUnpack_len
  ; 298 if(len) {convertToConfition
  mov a, l
  ora h
  jz l51
  ; 299 if(len >= 255-13) return 1; // Не влезает разделитель плюс имя файла  Сложение
  lxi d, 65294
  dad d
  jnc l52
  ; 299 return 1; // Не влезает разделитель плюс имя файла  
  mvi a, 1
  ret
l52:
  ; 300 str[len] = '/';  Сложение
  lhld catPathAndUnpack_1
  xchg
  lhld catPathAndUnpack_len
  dad d
  mvi m, 47
  ; 301 str += len+1;Сложение с константой 1
  lhld catPathAndUnpack_len
  inx h
  ; Сложение
  xchg
  lhld catPathAndUnpack_1
  dad d
  shld catPathAndUnpack_1
l51:
  ; 303 unpackName(str, fileName);
  lhld catPathAndUnpack_1
  shld unpackName_1
  lhld catPathAndUnpack_2
  call unpackName
  ; 304 return 0;
  xra a
  ret
  ; --- getFirstSelected -----------------------------------------------------------------
getFirstSelected:
  shld getFirstSelected_1
  ; 315 nextSelectedCnt = panelA.cnt;
  lhld (panelA)+(262)
  shld nextSelectedCnt
  ; 316 nextSelectedFile = panelA.files1;
  lhld panelA
  shld nextSelectedFile
  ; 317 if(type = getNextSelected(name)) return type; 
  lhld getFirstSelected_1
  call getNextSelected
  sta getFirstSelected_type
  ; convertToConfition
  ora a
  jz l53
  ; 317 return type; 
  lda getFirstSelected_type
  ret
l53:
  ; 319 nextSelectedFile = getSelNoBack();
  call getSelNoBack
  shld nextSelectedFile
  ; 320 if(!nextSelectedFile) return 0;convertToConfition
  mov a, l
  ora h
  jnz l54
  ; 320 return 0;
  xra a
  ret
l54:
  ; 321 unpackName(name, nextSelectedFile->fname);
  lhld getFirstSelected_1
  shld unpackName_1
  lhld nextSelectedFile
  call unpackName
  ; 322 if(nextSelectedFile->fattrib & 0x10) return 2;Сложение
  lhld nextSelectedFile
  lxi d, 11
  dad d
  mov a, m
  ani 16
  ; convertToConfition
  jz l55
  ; 322 return 2;
  mvi a, 2
  ret
l55:
  ; 323 return 1;
  mvi a, 1
  ret
  ; --- getNextSelected -----------------------------------------------------------------
getNextSelected:
  shld getNextSelected_1
  ; 329 for(;;) {
l56:
  ; 330 if(nextSelectedCnt == 0) return 0;Сложение с константой 0
  lhld nextSelectedCnt
  mov a, l
  ora h
  jnz l59
  ; 330 return 0;
  xra a
  ret
l59:
  ; 331 if(nextSelectedFile->fattrib & 0x80) break;Сложение
  lhld nextSelectedFile
  lxi d, 11
  dad d
  mov a, m
  ani 128
  ; convertToConfition
  jnz l57
  lhld nextSelectedFile
  lxi d, 20
  dad d
  shld nextSelectedFile
  lhld nextSelectedCnt
  dcx h
  shld nextSelectedCnt
l58:
  jmp l56
l57:
  ; 335 nextSelectedFile->fattrib &= 0x7F;Сложение
  lhld nextSelectedFile
  lxi d, 11
  dad d
  mov a, m
  ani 127
  mov m, a
  ; 336 unpackName(name, nextSelectedFile->fname);
  lhld getNextSelected_1
  shld unpackName_1
  lhld nextSelectedFile
  call unpackName
  ; 337 ++nextSelectedFile, --nextSelectedCnt;
  lhld nextSelectedFile
  lxi d, 20
  dad d
  shld nextSelectedFile
  lhld nextSelectedCnt
  dcx h
  shld nextSelectedCnt
  ; 338 if(nextSelectedFile[-1].fattrib & 0x10) return 2;Сложение
  lhld nextSelectedFile
  lxi d, 65516
  dad d
  ; Сложение
  lxi d, 11
  dad d
  mov a, m
  ani 16
  ; convertToConfition
  jz l61
  ; 338 return 2;
  mvi a, 2
  ret
l61:
  ; 339 return 1;
  mvi a, 1
  ret
  ; --- cmpFileInfo -----------------------------------------------------------------
cmpFileInfo:
  push b
  shld cmpFileInfo_2
  ; 348 i = (a->fattrib&0x10);Сложение
  lhld cmpFileInfo_1
  lxi d, 11
  dad d
  mov a, m
  ani 16
  mov b, a
  ; 349 j = (b->fattrib&0x10);Сложение
  lhld cmpFileInfo_2
  lxi d, 11
  dad d
  mov a, m
  ani 16
  mov c, a
  ; 350 if(i<j) return 1;
  mov a, c
  cmp b
  jc l62
  jz l62
  ; 350 return 1;
  mvi a, 1
  pop b
  ret
l62:
  ; 351 if(j<i) return 0;
  mov a, c
  cmp b
  jnc l63
  ; 351 return 0;
  xra a
  pop b
  ret
l63:
  ; 352 if(1==memcmp(a->fname, b->fname, sizeof(a->fname))) return 1;
  lhld cmpFileInfo_1
  shld memcmp_1
  lhld cmpFileInfo_2
  shld memcmp_2
  lxi h, 11
  call memcmp
  cpi 1
  jnz l64
  ; 352 return 1;
  mvi a, 1
  pop b
  ret
l64:
  ; 353 return 0;
  xra a
  pop b
  ret
  ; --- sort -----------------------------------------------------------------
sort:
  shld sort_2
  ; 360 st_;<st>
  lxi h, sort_st_
  shld sort_st
  ; 361 0;<stc>
  xra a
  sta sort_stc
  ; 362 while(1) {
l65:
  ; 363 i = low;
  lhld sort_1
  shld sort_i
  ; 364 j = high;
  lhld sort_2
  shld sort_j
  ; 365 x = low + (high-low)/2;16 битная арифметическая операция с константой
  lhld sort_1
  xchg
  lhld sort_2
  mov a, l
  sub e
  mov l, a
  mov a, h
  sbb d
  mov h, a
  lxi d, 20
  call op_div16
  lxi d, 2
  call op_div16
  ; Умножение HL на 20
  mov d, h
  mov e, l
  dad h
  dad h
  dad d
  dad h
  dad h
  ; Сложение
  xchg
  lhld sort_1
  dad d
  shld sort_x
  ; 366 while(1) {
l67:
  ; 367 while(0!=cmpFileInfo(x, i)) i++;
l69:
  lhld sort_x
  shld cmpFileInfo_1
  lhld sort_i
  call cmpFileInfo
  ora a
  jz l70
  ; 367 i++;
  lhld sort_i
  push h
  lxi d, 20
  dad d
  shld sort_i
  pop h
  jmp l69
l70:
  ; 368 while(0!=cmpFileInfo(j, x)) j--;
l71:
  lhld sort_j
  shld cmpFileInfo_1
  lhld sort_x
  call cmpFileInfo
  ora a
  jz l72
  ; 368 j--;
  lhld sort_j
  push h
  lxi d, 65516
  dad d
  shld sort_j
  pop h
  jmp l71
l72:
  ; 369 if(i <= j) {
  lhld sort_i
  xchg
  lhld sort_j
  call op_cmp16
  jc l73
  ; 370 memswap(i, j, sizeof(FileInfo));
  lhld sort_i
  shld memswap_1
  lhld sort_j
  shld memswap_2
  lxi h, 20
  call memswap
  ; 371 if(x==i) x=j; else if(x==j) x=i;
  lhld sort_x
  xchg
  lhld sort_i
  call op_cmp16
  jnz l74
  ; 371 x=j; else if(x==j) x=i;
  lhld sort_j
  shld sort_x
  jmp l75
l74:
  ; 371 if(x==j) x=i;
  lhld sort_x
  xchg
  lhld sort_j
  call op_cmp16
  jnz l76
  ; 371 x=i;
  lhld sort_i
  shld sort_x
l76:
l75:
  ; 372 i++; j--;   
  lhld sort_i
  push h
  lxi d, 20
  dad d
  shld sort_i
  pop h
  ; 372 j--;   
  lhld sort_j
  push h
  lxi d, 65516
  dad d
  shld sort_j
  pop h
l73:
  ; 374 if(j<=i) break;
  lhld sort_j
  xchg
  lhld sort_i
  call op_cmp16
  jnc l68
  jmp l67
l68:
  ; 376 if(i < high) {
  lhld sort_i
  xchg
  lhld sort_2
  call op_cmp16
  jc l78
  jz l78
  ; 377 if(low < j) if(stc != SORT_STACK_MAX) *st = low, ++st, *st = j, ++st, ++stc;
  lhld sort_1
  xchg
  lhld sort_j
  call op_cmp16
  jc l79
  jz l79
  ; 377 if(stc != SORT_STACK_MAX) *st = low, ++st, *st = j, ++st, ++stc;
  lda sort_stc
  cpi 128
  jz l80
  ; 377 *st = low, ++st, *st = j, ++st, ++stc;
  lhld sort_1
  xchg
  lhld sort_st
  mov m, e
  inx h
  mov m, d
  lhld sort_st
  inx h
  inx h
  shld sort_st
  lhld sort_j
  xchg
  lhld sort_st
  mov m, e
  inx h
  mov m, d
  lhld sort_st
  inx h
  inx h
  shld sort_st
  lxi h, sort_stc
  inr m
l80:
l79:
  ; 378 low = i; 
  lhld sort_i
  shld sort_1
  ; 379 continue;
  jmp l65
l78:
  ; 381 if(low < j) { 
  lhld sort_1
  xchg
  lhld sort_j
  call op_cmp16
  jc l81
  jz l81
  ; 382 high = j;
  lhld sort_j
  shld sort_2
  ; 383 continue; 
  jmp l65
l81:
  ; 385 if(stc==0) break;
  lda sort_stc
  ora a
  jz l66
  lxi h, sort_stc
  dcr m
  lhld sort_st
  dcx h
  dcx h
  shld sort_st
  mov e, m
  inx h
  mov d, m
  xchg
  shld sort_2
  lhld sort_st
  dcx h
  dcx h
  shld sort_st
  mov e, m
  inx h
  mov d, m
  xchg
  shld sort_1
  jmp l65
l66:
  ret
  ; --- packName -----------------------------------------------------------------
packName:
  push b
  shld packName_2
  ; 395 memset(buf, ' ', 11);    
  lhld packName_1
  shld memset_1
  mvi a, 32
  sta memset_2
  lxi h, 11
  call memset
  ; 397 i = 8;
  mvi a, 8
  sta packName_i
  ; 398 f = '.';
  mvi c, 46
  ; 399 for(;;) {
l83:
  ; 400 c = *path;
  lhld packName_2
  mov b, m
  ; 401 if(c == 0) return;
  xra a
  cmp b
  jnz l86
  ; 401 return;
  pop b
  ret
l86:
  ; 402 ++path;
  inx h
  shld packName_2
  ; 403 if(c == f) { buf += i; i = 3; f = 0; continue; }
  mov a, c
  cmp b
  jnz l87
  ; 403 buf += i; i = 3; f = 0; continue; }Сложение
  lhld packName_i
  mvi h, 0
  xchg
  lhld packName_1
  dad d
  shld packName_1
  ; 403 i = 3; f = 0; continue; }
  mvi a, 3
  sta packName_i
  ; 403 f = 0; continue; }
  mov c, d
  ; 403 continue; }
  jmp l85
l87:
  ; 404 if(i) { *buf = c; ++buf; --i; }convertToConfition
  lda packName_i
  ora a
  jz l88
  ; 404 *buf = c; ++buf; --i; }
  lhld packName_1
  mov m, b
  ; 404 ++buf; --i; }
  lhld packName_1
  inx h
  shld packName_1
  ; 404 --i; }
  lxi h, packName_i
  dcr m
l88:
l85:
  jmp l83
l84:
  pop b
  ret
  ; --- getFiles -----------------------------------------------------------------
getFiles:
  call hideTextCursor
  ; 421 panelA.cnt = 0;
  lxi h, 0
  shld (panelA)+(262)
  ; 422 panelA.offset = 0;
  shld (panelA)+(260)
  ; 423 panelA.cursorX = 0;
  xra a
  sta (panelA)+(258)
  ; 424 panelA.cursorY = 0;
  sta (panelA)+(259)
  ; 426 f = panelA.files1;
  lhld panelA
  shld getFiles_f
  ; 429 if(panelA.path1[0]) {convertToConfition
  lda ((panelA)+(2))+(0)
  ora a
  jz l89
  ; 430 memcpy(f, parentDir, sizeof(FileInfo));
  shld memcpy_1
  lxi h, parentDir
  shld memcpy_2
  lxi h, 20
  call memcpy
  ; 431 ++f;
  lhld getFiles_f
  lxi d, 20
  dad d
  shld getFiles_f
  ; 432 ++panelA.cnt;    
  lhld (panelA)+(262)
  inx h
  shld (panelA)+(262)
l89:
  ; 435 st = f;
  lhld getFiles_f
  shld getFiles_st
  ; 436 for(;;) {
l90:
  ; 437 i = fs_findfirst(panelA.path1, f, maxFiles-panelA.cnt);  
  lxi h, (panelA)+(2)
  shld fs_findfirst_1
  lhld getFiles_f
  shld fs_findfirst_2
  ; 16 битная арифметическая операция с константой
  lhld (panelA)+(262)
  xchg
  lhld maxFiles
  mov a, l
  sub e
  mov l, a
  mov a, h
  sbb d
  mov h, a
  call fs_findfirst
  sta getFiles_i
  ; 438 if(i==ERR_MAX_FILES) i=0; //! Вывести бы ошибки
  cpi 10
  jnz l93
  ; 438 i=0; //! Вывести бы ошибки
  xra a
  sta getFiles_i
l93:
  ; 439 if(i==0) break;    
  ora a
  jz l91
  lda ((panelA)+(2))+(0)
  ora a
  jnz l95
  ; 440 return; //! Вывести бы ошибки
  ret
l95:
  ; 441 panelA.path1[0] = 0;
  xra a
  sta ((panelA)+(2))+(0)
l92:
  jmp l90
l91:
  ; 444 f += fs_low;
  lhld fs_low
  ; Умножение HL на 20
  mov d, h
  mov e, l
  dad h
  dad h
  dad d
  dad h
  dad h
  ; Сложение
  xchg
  lhld getFiles_f
  dad d
  shld getFiles_f
  ; 445 panelA.cnt += fs_low;Сложение
  lhld fs_low
  xchg
  lhld (panelA)+(262)
  dad d
  shld (panelA)+(262)
  ; 447 for(j=panelA.cnt, f=panelA.files1; j; --j, ++f) { 
  shld getFiles_j
  lhld panelA
  shld getFiles_f
l96:
  ; convertToConfition
  lhld getFiles_j
  mov a, l
  ora h
  jz l97
  ; 448 f->fattrib &= 0x7F;Сложение
  lhld getFiles_f
  lxi d, 11
  dad d
  mov a, m
  ani 127
  mov m, a
  ; 449 n=f->fname;
  lhld getFiles_f
  shld getFiles_n
  ; 450 for(i=12; i; --i, ++n)
  mvi a, 12
  sta getFiles_i
l99:
  ; convertToConfition
  lda getFiles_i
  ora a
  jz l100
  ; 451 if((uchar)*n>='a' && (uchar)*n<='z')
  mov a, m
  cpi 97
  jc l102
  mov a, m
  cpi 122
  jz l103
  jnc l102
l103:
  ; 452 *n = *n-('a'-'A');Арифметика 9/3
  lhld getFiles_n
  mov a, m
  sui 32
  mov m, a
l102:
l101:
  lxi h, getFiles_i
  dcr m
  lhld getFiles_n
  inx h
  shld getFiles_n
  jmp l99
l100:
l98:
  lhld getFiles_j
  dcx h
  shld getFiles_j
  lhld getFiles_f
  lxi d, 20
  dad d
  shld getFiles_f
  jmp l96
l97:
  ; 455 if(panelA.cnt > 1)Сложение с константой -2
  lhld (panelA)+(262)
  dcx h
  dcx h
  jz l105
  jnc l104
l105:
  ; 456 sort(st, ((FileInfo*)panelA.files1) + (panelA.cnt-1));
  lhld getFiles_st
  shld sort_1
  ; Сложение с константой -1
  lhld (panelA)+(262)
  dcx h
  ; Умножение HL на 20
  mov d, h
  mov e, l
  dad h
  dad h
  dad d
  dad h
  dad h
  ; Сложение
  xchg
  lhld panelA
  dad d
  call sort
l104:
  ret
  ; --- selectFile -----------------------------------------------------------------
selectFile:
  push b
  shld selectFile_1
  ; 464 for(l=0, f=panelA.files1; l<panelA.cnt; ++l, ++f) {
  lxi b, 0
  lhld panelA
  shld selectFile_f
l106:
  lhld (panelA)+(262)
  mov d, b
  mov e, c
  call op_cmp16
  jc l107
  jz l107
  ; 465 if(0==memcmp(f->fname, sfile, 11)) {
  lhld selectFile_f
  shld memcmp_1
  lhld selectFile_1
  shld memcmp_2
  lxi h, 11
  call memcmp
  ora a
  jnz l109
  ; 467 if(l>=2*ROWS_CNT) {Сложение с BC
  lxi h, 65492
  dad b
  jnc l110
  ; 468 panelA.offset = l-ROWS_CNT-(l%ROWS_CNT);Сложение с BC
  lxi h, 65514
  dad b
  lxi d, 22
  push h
  mov h, b
  mov l, c
  call op_mod16
  ; 16 битная арифметическая операция с константой
  xchg
  pop h
  mov a, l
  sub e
  mov l, a
  mov a, h
  sbb d
  mov h, a
  shld (panelA)+(260)
  ; 469 l-=panelA.offset;Арифметическая операция с BC&
  mov a, c
  sub l
  mov c, a
  mov a, h
  sbb h
  mov b, a
l110:
  ; 472 panelA.cursorX = l/ROWS_CNT;
  lxi d, 22
  mov h, b
  mov l, c
  call op_div16
  mov a, l
  sta (panelA)+(258)
  ; 473 panelA.cursorY = op_div16_mod;
  lda op_div16_mod
  sta (panelA)+(259)
  ; 474 break;
  jmp l107
l109:
l108:
  inx b
  lhld selectFile_f
  lxi d, 20
  dad d
  shld selectFile_f
  jmp l106
l107:
  pop b
  ret
  ; --- reloadFiles -----------------------------------------------------------------
reloadFiles:
  shld reloadFiles_1
  ; 484 drawPanelTitle(1);   
  mvi a, 1
  call drawPanelTitle
  ; 485 drawCmdLineWithPath();
  call drawCmdLineWithPath
  ; 488 getFiles();
  call getFiles
  ; 491 drawPanelTitle(1);   
  mvi a, 1
  call drawPanelTitle
  ; 492 drawCmdLineWithPath();
  call drawCmdLineWithPath
  ; 495 if(sfile) {convertToConfition
  lhld reloadFiles_1
  mov a, l
  ora h
  jz l111
  ; 496 selectFile(sfile);
  call selectFile
l111:
  ; 500 drawFilesCount();
  call drawFilesCount
  ; 501 drawFiles();
  call drawFiles
  ; 502 showFileCursorAndDrawFileInfo();
  call showFileCursorAndDrawFileInfo
  ; 505 drawCmdLine(); 
  jmp drawCmdLine
absolutePath:
  shld absolutePath_1
  ; 515 if(str[0] == '/') {Сложение с константой 0
  mov a, m
  cpi 47
  jnz l112
  ; 516 strcpy(str, str+1);
  shld strcpy_1
  ; Сложение с константой 1
  lhld absolutePath_1
  inx h
  call strcpy
  ; 517 return 1;
  mvi a, 1
  ret
l112:
  ; 521 l = strlen(panelA.path1);
  lxi h, (panelA)+(2)
  call strlen
  shld absolutePath_l
  ; 524 if(l != 0) l++;Сложение с константой 0
  mov a, l
  ora h
  jz l113
  ; 524 l++;
  mov d, h
  mov e, l
  inx h
  shld absolutePath_l
  xchg
l113:
  ; 527 if(strlen(str) + l >= 255) return 0;
  lhld absolutePath_1
  call strlen
  ; Сложение
  xchg
  lhld absolutePath_l
  dad d
  ; Сложение
  lxi d, 65281
  dad d
  jnc l114
  ; 527 return 0;
  xra a
  ret
l114:
  ; 530 memcpy_back(str+l, str, strlen(str)+1);Сложение
  lhld absolutePath_1
  xchg
  lhld absolutePath_l
  dad d
  shld memcpy_back_1
  lhld absolutePath_1
  shld memcpy_back_2
  lhld absolutePath_1
  call strlen
  ; Сложение с константой 1
  inx h
  call memcpy_back
  ; 531 memcpy(str, panelA.path1, l);
  lhld absolutePath_1
  shld memcpy_1
  lxi h, (panelA)+(2)
  shld memcpy_2
  lhld absolutePath_l
  call memcpy
  ; 534 if(l != 0) str[l-1] = '/';Сложение с константой 0
  lhld absolutePath_l
  mov a, l
  ora h
  jz l115
  ; 534 str[l-1] = '/';Сложение с константой -1
  dcx h
  ; Сложение
  xchg
  lhld absolutePath_1
  dad d
  mvi m, 47
l115:
  ; 536 return 1;
  mvi a, 1
  ret
  ; --- getName -----------------------------------------------------------------
getName:
  shld getName_1
  ; 543 for(p = name; *p; p++)
  shld getName_p
l116:
  ; convertToConfition
  lhld getName_p
  xra a
  ora m
  jz l117
  ; 544 if(*p == '/')
  mov a, m
  cpi 47
  jnz l119
  ; 545 name = p+1;Сложение с константой 1
  inx h
  shld getName_1
l119:
l118:
  lhld getName_p
  mov d, h
  mov e, l
  inx h
  shld getName_p
  xchg
  jmp l116
l117:
  ; 546 return name;
  lhld getName_1
  ret
  ; --- dropPathInt -----------------------------------------------------------------
dropPathInt:
  shld dropPathInt_2
  ; 556 p = getname(src);
  lhld dropPathInt_1
  call getName
  shld dropPathInt_p
  ; 559 if(preparedName) packName(preparedName, p);convertToConfition
  lhld dropPathInt_2
  mov a, l
  ora h
  jz l120
  ; 559 packName(preparedName, p);
  shld packName_1
  lhld dropPathInt_p
  call packName
l120:
  ; 562 if(p != src) --p;
  lhld dropPathInt_p
  xchg
  lhld dropPathInt_1
  call op_cmp16
  jz l121
  ; 562 --p;
  lhld dropPathInt_p
  dcx h
  shld dropPathInt_p
l121:
  ; 563 *p = 0;
  lhld dropPathInt_p
  mvi m, 0
  ret
  ; --- dropPath -----------------------------------------------------------------
dropPath:
  lxi h, (panelA)+(2)
  shld dropPathInt_1
  lxi h, dropPath_buf
  call dropPathInt
  ; 572 reloadFiles(buf);
  lxi h, dropPath_buf
  jmp reloadFiles
cursor_left:
  lda (panelA)+(258)
  ora a
  jz l122
  ; 580 --panelA.cursorX; 
  lxi h, (panelA)+(258)
  dcr m
  jmp l123
l122:
  ; 582 if(panelA.offset) { convertToConfition
  lhld (panelA)+(260)
  mov a, l
  ora h
  jz l124
  ; 583 if(ROWS_CNT > panelA.offset) { Сложение
  lxi d, 65514
  dad d
  jc l125
  jz l125
  ; 584 panelA.offset = 0; 
  lxi h, 0
  shld (panelA)+(260)
  ; 585 drawFiles();
  call drawFiles
  jmp l126
l125:
  ; 587 panelA.offset -= ROWS_CNT; 16 битная арифметическая операция с константой
  lhld (panelA)+(260)
  mov a, l
  sui 22
  mov l, a
  mov a, h
  sbi 0
  mov h, a
  shld (panelA)+(260)
  ; 588 drawFiles();
  call drawFiles
l126:
  jmp l127
l124:
  ; 591 if(panelA.cursorY) {convertToConfition
  lda (panelA)+(259)
  ora a
  jz l128
  ; 592 panelA.cursorY = 0; 
  xra a
  sta (panelA)+(259)
l128:
l127:
l123:
  ; 595 showFileCursorAndDrawFileInfo();
  jmp showFileCursorAndDrawFileInfo
cursor_right:
  lhld (panelA)+(260)
  xchg
  lhld (panelA)+(259)
  mvi h, 0
  dad d
  push h
  mvi d, 22
  lda (panelA)+(258)
  call op_mul
  ; Сложение
  pop d
  dad d
  shld cursor_right_w
  ; 606 if(w + ROWS_CNT >= panelA.cnt) { //! перепутаны > и >=Сложение
  lxi d, 22
  dad d
  xchg
  lhld (panelA)+(262)
  call op_cmp16
  jz l130
  jnc l129
l130:
  ; 608 if(w + 1 >= panelA.cnt) { Сложение с константой 1
  lhld cursor_right_w
  inx h
  xchg
  lhld (panelA)+(262)
  call op_cmp16
  jz l132
  jnc l131
l132:
  ; 609 return;
  ret
l131:
  ; 612 panelA.cursorY = panelA.cnt - (panelA.offset + panelA.cursorX*ROWS_CNT + 1);
  mvi d, 22
  lda (panelA)+(258)
  call op_mul
  ; Сложение
  xchg
  lhld (panelA)+(260)
  dad d
  ; Сложение с константой 1
  inx h
  ; 16 битная арифметическая операция с константой
  xchg
  lhld (panelA)+(262)
  mov a, l
  sub e
  mov l, a
  mov a, h
  sbb d
  mov h, a
  mov a, l
  sta (panelA)+(259)
  ; 614 if(panelA.cursorY>ROWS_CNT-1) {
  cpi 21
  jc l133
  jz l133
  ; 615 panelA.cursorY -= ROWS_CNT;Арифметика 4/3
  sui 22
  sta (panelA)+(259)
  ; 616 if(panelA.cursorX == 1) { 
  lda (panelA)+(258)
  cpi 1
  jnz l134
  ; 617 panelA.offset += ROWS_CNT;Сложение
  lxi d, 22
  lhld (panelA)+(260)
  dad d
  shld (panelA)+(260)
  ; 618 drawFiles();
  call drawFiles
  jmp l135
l134:
  ; 620 panelA.cursorX++; 
  lxi h, (panelA)+(258)
  inr m
l135:
l133:
  jmp l136
l129:
  ; 624 if(panelA.cursorX == 1) { 
  lda (panelA)+(258)
  cpi 1
  jnz l137
  ; 625 panelA.offset += ROWS_CNT;Сложение
  lxi d, 22
  lhld (panelA)+(260)
  dad d
  shld (panelA)+(260)
  ; 626 drawFiles();
  call drawFiles
  jmp l138
l137:
  ; 628 panelA.cursorX++;
  lxi h, (panelA)+(258)
  inr m
l138:
l136:
  ; 631 showFileCursorAndDrawFileInfo();
  jmp showFileCursorAndDrawFileInfo
cursor_up:
  lda (panelA)+(259)
  ora a
  jz l139
  ; 639 --panelA.cursorY;
  lxi h, (panelA)+(259)
  dcr m
  jmp l140
l139:
  ; 641 if(panelA.cursorX) { convertToConfition
  lda (panelA)+(258)
  ora a
  jz l141
  ; 642 --panelA.cursorX;
  lxi h, (panelA)+(258)
  dcr m
  ; 643 panelA.cursorY = ROWS_CNT-1; 
  mvi a, 21
  sta (panelA)+(259)
  jmp l142
l141:
  ; 645 if(panelA.offset) {convertToConfition
  lhld (panelA)+(260)
  mov a, l
  ora h
  jz l143
  ; 646 --panelA.offset; 
  dcx h
  shld (panelA)+(260)
  ; 647 drawFiles();
  call drawFiles
l143:
l142:
l140:
  ; 650 showFileCursorAndDrawFileInfo();
  jmp showFileCursorAndDrawFileInfo
cursor_down:
  mvi d, 22
  lda (panelA)+(258)
  call op_mul
  ; Сложение
  xchg
  lhld (panelA)+(260)
  dad d
  ; Сложение
  xchg
  lhld (panelA)+(259)
  mvi h, 0
  dad d
  ; Сложение с константой 1
  inx h
  xchg
  lhld (panelA)+(262)
  call op_cmp16
  jz l145
  jnc l144
l145:
  ; 657 return;
  ret
l144:
  ; 659 if(panelA.cursorY < ROWS_CNT-1) {
  lda (panelA)+(259)
  cpi 21
  jnc l146
  ; 660 ++panelA.cursorY;
  lxi h, (panelA)+(259)
  inr m
  jmp l147
l146:
  ; 662 if(panelA.cursorX == 0) {
  lda (panelA)+(258)
  ora a
  jnz l148
  ; 663 panelA.cursorY = 0;
  xra a
  sta (panelA)+(259)
  ; 664 ++panelA.cursorX; 
  lxi h, (panelA)+(258)
  inr m
  jmp l149
l148:
  ; 666 ++panelA.offset; 
  lhld (panelA)+(260)
  inx h
  shld (panelA)+(260)
  ; 667 drawFiles();
  call drawFiles
l149:
l147:
  ; 670 showFileCursorAndDrawFileInfo();
  jmp showFileCursorAndDrawFileInfo
cmd_tab:
  call hideFileCursor
  ; 678 drawPanelTitle(0);
  xra a
  call drawPanelTitle
  ; 679 swapPanels();
  call swapPanels
  ; 680 showFileCursor();
  call showFileCursor
  ; 681 drawPanelTitle(1);
  mvi a, 1
  call drawPanelTitle
  ; 682 drawCmdLineWithPath();
  jmp drawCmdLineWithPath
runCmdLine:
  push b
  ; 692 if(!absolutePath(cmdline)) return;
  lxi h, cmdline
  call absolutePath
  ; convertToConfition
  ora a
  jnz l150
  ; 692 return;
  pop b
  ret
l150:
  ; 695 cmdLine2 = strchr(cmdLine, ' ');
  lxi h, cmdline
  shld strchr_1
  mvi a, 32
  call strchr
  mov b, h
  mov c, l
  ; 696 if(cmdLine2) {convertToConfition
  mov a, l
  ora h
  jz l151
  ; 697 *cmdLine2 = 0;
  xra a
  stax b
  ; 698 ++cmdLine2;
  inx b
  jmp l152
l151:
  ; 700 cmdLine2 = "";
  lxi b, string17
l152:
  ; 704 run(cmdLine, cmdLine2);
  lxi h, cmdline
  shld run_1
  mov h, b
  mov l, c
  call run
  pop b
  ret
  ; --- dupFiles -----------------------------------------------------------------
dupFiles:
  sta dupFiles_1
  ; 710 swapPanels();
  call swapPanels
  ; 712 if(0==strcmp(panelA.path1, panelB.path1)) {
  lxi h, (panelA)+(2)
  shld strcmp_1
  lxi h, (panelB)+(2)
  call strcmp
  ora a
  jnz l153
  ; 713 memcpy(panelA.files1, panelB.files1, maxFiles*sizeof(FileInfo));
  lhld panelA
  shld memcpy_1
  lhld panelB
  shld memcpy_2
  lhld maxFiles
  lxi d, 20
  call op_mul16
  call memcpy
  ; 714 panelA.cnt = panelB.cnt;    
  lhld (panelB)+(262)
  shld (panelA)+(262)
  jmp l154
l153:
  ; 717 if(reload) getFiles();convertToConfition
  lda dupFiles_1
  ora a
  cnz getFiles
l154:
  ; 720 getSel();
  call getSel
  ; 721 swapPanels();
  jmp swapPanels
loadState:
  lhld fs_selfName
  call strlen
  shld loadState_i
  ; 729 if(i < 4) return;Сложение
  lxi d, 65531
  dad d
  jc l156
  ; 729 return;
  ret
l156:
  ; 730 i -= 3;16 битная арифметическая операция с константой
  lhld loadState_i
  mov a, l
  sui 3
  mov l, a
  mov a, h
  sbi 0
  mov h, a
  shld loadState_i
  ; 731 if(0 != strcmp(fs_selfName + i, ".RK")) return;Сложение
  lhld fs_selfName
  xchg
  lhld loadState_i
  dad d
  shld strcmp_1
  lxi h, string18
  call strcmp
  ora a
  jz l157
  ; 731 return;
  ret
l157:
  ; 732 strcpy(fs_selfName + i, ".IN");Сложение
  lhld fs_selfName
  xchg
  lhld loadState_i
  dad d
  shld strcpy_1
  lxi h, string19
  call strcpy
  ; 734 if(fs_open(fs_selfName)) return;
  lhld fs_selfName
  call fs_open
  ; convertToConfition
  ora a
  jz l158
  ; 734 return;
  ret
l158:
  ; 735 fs_read(cmdline, 12);
  lxi h, cmdline
  shld fs_read_1
  lxi h, 12
  call fs_read
  ; 736 if(cmdline[11]) swapPanels();convertToConfition
  lda (cmdline)+(11)
  ora a
  cnz swapPanels
  lxi h, (panelA)+(2)
  shld fs_read_1
  lxi h, 256
  call fs_read
  ; 737 panelA.path1[255] = 0;
  xra a
  sta ((panelA)+(2))+(255)
  ; 738 fs_read(panelB.path1, 256); panelB.path1[255] = 0;
  lxi h, (panelB)+(2)
  shld fs_read_1
  lxi h, 256
  call fs_read
  ; 738 panelB.path1[255] = 0;
  xra a
  sta ((panelB)+(2))+(255)
  ret
  ; --- saveState -----------------------------------------------------------------
saveState:
  lhld fs_selfName
  call fs_create
  ; convertToConfition
  ora a
  jz l160
  lhld fs_selfName
  call fs_open
  ; convertToConfition
  ora a
  jz l160
  ; 744 return;
  ret
l160:
  ; 745 fs_write(getSel()->fname, 11);
  call getSel
  shld fs_write_1
  lxi h, 11
  call fs_write
  ; 746 fs_write(&activePanel, 1);
  lxi h, activePanel
  shld fs_write_1
  lxi h, 1
  call fs_write
  ; 747 fs_write(panelA.path1, 256);
  lxi h, (panelA)+(2)
  shld fs_write_1
  lxi h, 256
  call fs_write
  ; 748 fs_write(panelB.path1, 256);
  lxi h, (panelB)+(2)
  shld fs_write_1
  lxi h, 256
  jmp fs_write
run:
  shld run_2
  ; 758 saveState();
  call saveState
  ; 760 if (mode != 0) {
  lda mode
  ora a
  jz l161
  ; 761 asm {
        mvi c,1fh
        call 0f809h
    
  ; 765 setPalmiraMode(mode);
  lda mode
  call setPalmiraMode
l161:
  ; 767 e = fs_exec(prog, cmdLine);
  lhld run_1
  shld fs_exec_1
  lhld run_2
  call fs_exec
  sta run_e
  ; 768 if (mode != 0) {
  lda mode
  ora a
  jz l162
  ; 769 setPalmiraMode(0);
  xra a
  call setPalmiraMode
  ; 770 drawInit();  
  call drawInit
l162:
  ; 775 drawError(prog, e); 
  lhld run_1
  shld drawError_1
  lda run_e
  call drawError
  ; 776 drawScreen(); // Там происходит очистка ком строки
  jmp drawScreen
cmd_editview:
  shld cmd_editview_1
  ; 782 getSel();<f>
  call getSel
  shld cmd_editview_f
  ; 783 if(f->fattrib & 0x10) return;Сложение
  lxi d, 11
  dad d
  mov a, m
  ani 16
  ; convertToConfition
  jz l163
  ; 783 return;
  ret
l163:
  ; 784 unpackName(cmdLine, f->fname);
  lxi h, cmdline
  shld unpackName_1
  lhld cmd_editview_f
  call unpackName
  ; 785 if(!absolutePath(cmdLine)) {
  lxi h, cmdline
  call absolutePath
  ; convertToConfition
  ora a
  jnz l164
  ; 786 drawScreen();
  jmp drawScreen
  ; 787 return;
l164:
  ; 789 run(app, cmdLine);
  lhld cmd_editview_1
  shld run_1
  lxi h, cmdline
  jmp run
cmd_enter:
  lda (cmdline)+(0)
  ora a
  jz l165
  ; 801 runCmdLine(); // Функция восстановит экран
  jmp runCmdLine
  ; 802 return;
l165:
  ; 806 f = getSelNoBack();
  call getSelNoBack
  shld cmd_enter_f
  ; 809 if(f == 0) { Сложение с константой 0
  mov a, l
  ora h
  jnz l166
  ; 810 dropPath(); 
  jmp dropPath
  ; 811 return; 
l166:
  ; 815 unpackName(cmdLine, f->fname);
  lxi h, cmdline
  shld unpackName_1
  lhld cmd_enter_f
  call unpackName
  ; 816 if(!absolutePath(cmdLine)) { drawScreen(); return; }
  lxi h, cmdline
  call absolutePath
  ; convertToConfition
  ora a
  jnz l167
  ; 816 drawScreen(); return; }
  jmp drawScreen
  ; 816 return; }
l167:
  ; 819 if((f->fattrib & 0x10) != 0) { Сложение
  lhld cmd_enter_f
  lxi d, 11
  dad d
  mov a, m
  ani 16
  jz l168
  ; 820 strcpy(panelA.path1, cmdline);
  lxi h, (panelA)+(2)
  shld strcpy_1
  lxi h, cmdline
  call strcpy
  ; 821 cmdline[0] = 0;
  xra a
  sta (cmdline)+(0)
  ; 822 reloadFiles(0);
  lxi h, 0
  jmp reloadFiles
  ; 823 return;
l168:
  ; 827 run(cmdline, "");
  lxi h, cmdline
  shld run_1
  lxi h, string17
  jmp run
cmd_esc:
  lda (cmdline)+(0)
  ora a
  jz l169
  ; 834 cmdline[0] = 0;
  xra a
  sta (cmdline)+(0)
  ; 835 drawCmdLine();
  jmp drawCmdLine
  ; 836 return;
l169:
  ; 838 dropPath();
  jmp dropPath
cmd_inverseOne:
  call getSelNoBack
  shld cmd_inverseOne_f
  ; 845 if(!f) return;convertToConfition
  mov a, l
  ora h
  jnz l170
  ; 845 return;
  ret
l170:
  ; 846 f->fattrib ^= 0x80;Сложение
  lxi d, 11
  dad d
  mov a, m
  xri 128
  mov m, a
  ; 847 drawFile(panelA.cursorX, panelA.cursorY, f);
  lda (panelA)+(258)
  sta drawFile_1
  lda (panelA)+(259)
  sta drawFile_2
  lhld cmd_inverseOne_f
  call drawFile
  ; 848 cursor_down();
  jmp cursor_down
cmd_inverseAll:
  lhld panelA
  shld cmd_inverseAll_f
  lhld (panelA)+(262)
  shld cmd_inverseAll_i
l171:
  ; convertToConfition
  lhld cmd_inverseAll_i
  mov a, l
  ora h
  jz l172
  ; 857 if(f->fattrib & 0x10) {Сложение
  lhld cmd_inverseAll_f
  lxi d, 11
  dad d
  mov a, m
  ani 16
  ; convertToConfition
  jz l174
  ; 858 f->fattrib &= 0x7F;Сложение
  lhld cmd_inverseAll_f
  lxi d, 11
  dad d
  mov a, m
  ani 127
  mov m, a
  jmp l175
l174:
  ; 860 f->fattrib ^= 0x80;Сложение
  lhld cmd_inverseAll_f
  lxi d, 11
  dad d
  mov a, m
  xri 128
  mov m, a
l175:
l173:
  lhld cmd_inverseAll_i
  dcx h
  shld cmd_inverseAll_i
  lhld cmd_inverseAll_f
  lxi d, 20
  dad d
  shld cmd_inverseAll_f
  jmp l171
l172:
  ; 863 drawFiles();
  call drawFiles
  ; 864 showFileCursor();
  jmp showFileCursor
main:
  push b
  ; 874 fs_init();
  call fs_init
  ; 876 getPalmiraMode();
  call getPalmiraMode
  ; 877 setPalmiraMode(0);
  xra a
  call setPalmiraMode
  ; 880 drawInit();  
  call drawInit
  ; 883 panelA.files1 = ((FileInfo*)START_FILE_BUFFER);
  lxi h, 13568
  shld panelA
  ; 884 panelB.files1 = ((FileInfo*)START_FILE_BUFFER)+maxFiles;
  lhld maxFiles
  ; Умножение HL на 20
  mov d, h
  mov e, l
  dad h
  dad h
  dad d
  dad h
  dad h
  ; Сложение
  lxi d, 13568
  dad d
  shld panelB
  ; 887 panelA.path1[0] = 0;
  xra a
  sta ((panelA)+(2))+(0)
  ; 888 panelB.path1[0] = 0;
  sta ((panelB)+(2))+(0)
  ; 891 cmdline[0] = 0;
  sta (cmdline)+(0)
  ; 894 drawScreenInt();
  call drawScreenInt
  ; 895 drawCmdLineWithPath();
  call drawCmdLineWithPath
  ; 898 loadState();
  call loadState
  ; 901 getFiles();
  call getFiles
  ; 904 dupFiles(1);
  mvi a, 1
  call dupFiles
  ; 907 selectFile(cmdline);
  lxi h, cmdline
  call selectFile
  ; 908 cmdline[0] = 0;
  xra a
  sta (cmdline)+(0)
  ; 911 drawPanelTitle(1);
  inr a
  call drawPanelTitle
  ; 912 swapPanels();
  call swapPanels
  ; 913 drawPanelTitle(0);
  xra a
  call drawPanelTitle
  ; 914 swapPanels();
  call swapPanels
  ; 915 drawFiles2();
  call drawFiles2
  ; 916 drawCmdLineWithPath();
  call drawCmdLineWithPath
  ; 919 while(1) {
l176:
  ; 920 c = getch1();
  call getch1
  mov b, a
  ; 922 switch(c) {
  mov a, b
  ora a
  jz l179
  cpi 1
  jz l180
  cpi 2
  jz l181
  cpi 3
  jz l182
  cpi 13
  jz l183
  cpi 27
  jz l184
  cpi 8
  jz l185
  cpi 24
  jz l186
  cpi 26
  jz l187
  cpi 25
  jz l188
  cpi 9
  jz l189
  jmp l178
l179:
  ; 923 cmd_freespace();         continue;
  call cmd_freespace
  ; 923 continue;
  jmp l176
l180:
  ; 924 cmd_new(0);              continue;
  xra a
  call cmd_new
  ; 924 continue;
  jmp l176
l181:
  ; 925 cmd_editview(viewerApp); continue;
  lxi h, viewerApp
  call cmd_editview
  ; 925 continue;
  jmp l176
l182:
  ; 926 cmd_editview(editorApp); continue;
  lxi h, editorApp
  call cmd_editview
  ; 926 continue;
  jmp l176
l183:
  ; 927 cmd_enter();             continue;
  call cmd_enter
  ; 927 continue;
  jmp l176
l184:
  ; 928 cmd_esc();               continue;
  call cmd_esc
  ; 928 continue;
  jmp l176
l185:
  ; 929 cursor_left();           continue;
  call cursor_left
  ; 929 continue;
  jmp l176
l186:
  ; 930 cursor_right();          continue; 
  call cursor_right
  ; 930 continue; 
  jmp l176
l187:
  ; 931 cursor_down();           continue;
  call cursor_down
  ; 931 continue;
  jmp l176
l188:
  ; 932 cursor_up();             continue; 
  call cursor_up
  ; 932 continue; 
  jmp l176
l189:
  ; 933 cmd_tab();               continue; 
  call cmd_tab
  ; 933 continue; 
  jmp l176
l178:
  ; 937 if(!cmdLine[0]) {convertToConfition
  lda (cmdline)+(0)
  ora a
  jnz l190
  ; 938 switch(c) {
  mov a, b
  cpi 49
  jz l192
  cpi 50
  jz l193
  cpi 51
  jz l194
  cpi 52
  jz l195
  cpi 37
  jz l196
  cpi 53
  jz l197
  cpi 38
  jz l198
  cpi 54
  jz l199
  cpi 55
  jz l200
  cpi 56
  jz l201
  cpi 31
  jz l202
  cpi 58
  jz l203
  cpi 59
  jz l204
  cpi 45
  jz l205
  jmp l191
l192:
  ; 939 cmd_freespace();         continue;
  call cmd_freespace
  ; 939 continue;
  jmp l176
l193:
  ; 940 cmd_new(0);              continue;
  xra a
  call cmd_new
  ; 940 continue;
  jmp l176
l194:
  ; 941 cmd_editview(viewerApp); continue;
  lxi h, viewerApp
  call cmd_editview
  ; 941 continue;
  jmp l176
l195:
  ; 942 cmd_editview(editorApp); continue;
  lxi h, editorApp
  call cmd_editview
  ; 942 continue;
  jmp l176
l196:
  ; 943 cmd_copymove(1, 1);      continue;
  mvi a, 1
  sta cmd_copymove_1
  call cmd_copymove
  ; 943 continue;
  jmp l176
l197:
  ; 944 cmd_copymove(1, 0);      continue;
  mvi a, 1
  sta cmd_copymove_1
  xra a
  call cmd_copymove
  ; 944 continue;
  jmp l176
l198:
  ; 945 cmd_copymove(0, 1);      continue;
  xra a
  sta cmd_copymove_1
  inr a
  call cmd_copymove
  ; 945 continue;
  jmp l176
l199:
  ; 946 cmd_copymove(0, 0);      continue;
  xra a
  sta cmd_copymove_1
  call cmd_copymove
  ; 946 continue;
  jmp l176
l200:
  ; 947 cmd_new(1);              continue;
  mvi a, 1
  call cmd_new
  ; 947 continue;
  jmp l176
l201:
  ; 948 cmd_delete();            continue;
  call cmd_delete
  ; 948 continue;
  jmp l176
l202:
  ; 949 cmd_inverseOne();        continue;
  call cmd_inverseOne
  ; 949 continue;
  jmp l176
l203:
  ; 950 cmd_inverseAll();        continue; // *
  call cmd_inverseAll
  ; 950 continue; // *
  jmp l176
l204:
  ; 951 cmd_sel(1);              continue; // +
  mvi a, 1
  call cmd_sel
  ; 951 continue; // +
  jmp l176
l205:
  ; 952 cmd_sel(0);              continue;
  xra a
  call cmd_sel
  ; 952 continue;
  jmp l176
l191:
l190:
  ; 957 processInput(c);
  mov a, b
  call processInput
  ; 958 drawCmdLine();
  call drawCmdLine
  jmp l176
l177:
  pop b
  ret
  ; --- cmd_copyFile -----------------------------------------------------------------
cmd_copyFile:
  shld cmd_copyFile_2
  ; 10 0;<progress_i>
  xra a
  sta cmd_copyFile_progress_i
  ; 15 if(e = fs_open(from)) return e;
  lhld cmd_copyFile_1
  call fs_open
  sta cmd_copyFile_e
  ; convertToConfition
  ora a
  jz l206
  ; 15 return e;
  lda cmd_copyFile_e
  ret
l206:
  ; 16 if(e = fs_getsize()) return e;
  call fs_getsize
  sta cmd_copyFile_e
  ; convertToConfition
  ora a
  jz l207
  ; 16 return e;
  lda cmd_copyFile_e
  ret
l207:
  ; 19 set32(&progress_step, &fs_result);
  lxi h, cmd_copyFile_progress_step
  shld set32_1
  lxi h, fs_low
  call set32
  ; 20 div32_16(&progress_step, 40);
  lxi h, cmd_copyFile_progress_step
  shld div32_16_1
  lxi h, 40
  call div32_16
  ; 23 drawWindow(" kopirowanie ");
  lxi h, string20
  call drawWindow
  ; 24 drawWindowText(0, 0, "iz:");
  xra a
  sta drawWindowText_1
  sta drawWindowText_2
  lxi h, string21
  call drawWindowText
  ; 25 drawWindowText(4, 0, from);
  mvi a, 4
  sta drawWindowText_1
  xra a
  sta drawWindowText_2
  lhld cmd_copyFile_1
  call drawWindowText
  ; 26 drawWindowText(0, 1, "w:");
  xra a
  sta drawWindowText_1
  inr a
  sta drawWindowText_2
  lxi h, string22
  call drawWindowText
  ; 27 drawWindowText(4, 1, to);
  mvi a, 4
  sta drawWindowText_1
  mvi a, 1
  sta drawWindowText_2
  lhld cmd_copyFile_2
  call drawWindowText
  ; 28 drawWindowText(0, 2, "skopirowano           /           bajt");
  xra a
  sta drawWindowText_1
  mvi a, 2
  sta drawWindowText_2
  lxi h, string23
  call drawWindowText
  ; 29 drawWindowProgress(0, 3, 40, '#');
  xra a
  sta drawWindowProgress_1
  mvi a, 3
  sta drawWindowProgress_2
  mvi a, 40
  sta drawWindowProgress_3
  mvi a, 35
  call drawWindowProgress
  ; 30 i2s32(buf, &fs_result, 10, ' ');
  lxi h, cmd_copyFile_buf
  shld i2s32_1
  lxi h, fs_low
  shld i2s32_2
  lxi h, 10
  shld i2s32_3
  mvi a, 32
  call i2s32
  ; 31 drawWindowText(23, 2, buf);
  mvi a, 23
  sta drawWindowText_1
  mvi a, 2
  sta drawWindowText_2
  lxi h, cmd_copyFile_buf
  call drawWindowText
  ; 32 drawEscButton();
  call drawEscButton
  ; 35 if(e = fs_swap()) return e;
  call fs_swap
  sta cmd_copyFile_e
  ; convertToConfition
  ora a
  jz l208
  ; 35 return e;
  lda cmd_copyFile_e
  ret
l208:
  ; 36 if(e = fs_create(to)) return e;
  lhld cmd_copyFile_2
  call fs_create
  sta cmd_copyFile_e
  ; convertToConfition
  ora a
  jz l209
  ; 36 return e;
  lda cmd_copyFile_e
  ret
l209:
  ; 1 ((ushort*)a)[0] = (b&0xFFFF); ((ushort*)a)[1] = (b>>16); }
  lxi h, 0
  shld (cmd_copyFile_progress)+(0)
  ; 1 ((ushort*)a)[1] = (b>>16); }
  shld (cmd_copyFile_progress)+(2)
  ; 1 ((ushort*)a)[0] = (b&0xFFFF); ((ushort*)a)[1] = (b>>16); }
  shld (cmd_copyFile_progress_x)+(0)
  ; 1 ((ushort*)a)[1] = (b>>16); }
  shld (cmd_copyFile_progress_x)+(2)
  ; 41 for(;;) {
l210:
  ; 43 i2s32(buf, &progress, 10, ' ');
  lxi h, cmd_copyFile_buf
  shld i2s32_1
  lxi h, cmd_copyFile_progress
  shld i2s32_2
  lxi h, 10
  shld i2s32_3
  mvi a, 32
  call i2s32
  ; 44 drawWindowText(12, 2, buf); 
  mvi a, 12
  sta drawWindowText_1
  mvi a, 2
  sta drawWindowText_2
  lxi h, cmd_copyFile_buf
  call drawWindowText
  ; 47 if(e = fs_swap()) return e;
  call fs_swap
  sta cmd_copyFile_e
  ; convertToConfition
  ora a
  jz l213
  ; 47 return e;
  lda cmd_copyFile_e
  ret
l213:
  ; 48 if(e = fs_read(panelB.files1, 1024) ) return e;
  lhld panelB
  shld fs_read_1
  lxi h, 1024
  call fs_read
  sta cmd_copyFile_e
  ; convertToConfition
  ora a
  jz l214
  ; 48 return e;
  lda cmd_copyFile_e
  ret
l214:
  ; 49 if(fs_low == 0) return 0; // ‘ ЇҐаҐ§ Јаг§Є®© д ©«®ўСложение с константой 0
  lhld fs_low
  mov a, l
  ora h
  jnz l215
  ; 49 return 0; // ‘ ЇҐаҐ§ Јаг§Є®© д ©«®ў
  xra a
  ret
l215:
  ; 50 if(e = fs_swap()) return e;
  call fs_swap
  sta cmd_copyFile_e
  ; convertToConfition
  ora a
  jz l216
  ; 50 return e;
  lda cmd_copyFile_e
  ret
l216:
  ; 51 if(e = fs_write(panelB.files1, fs_low)) return e;
  lhld panelB
  shld fs_write_1
  lhld fs_low
  call fs_write
  sta cmd_copyFile_e
  ; convertToConfition
  ora a
  jz l217
  ; 51 return e;
  lda cmd_copyFile_e
  ret
l217:
  ; 54 add32_16(&progress, fs_low);
  lxi h, cmd_copyFile_progress
  shld add32_16_1
  lhld fs_low
  call add32_16
  ; 57 add32_16(&progress_x, fs_low);
  lxi h, cmd_copyFile_progress_x
  shld add32_16_1
  lhld fs_low
  call add32_16
  ; 58 while(progress_i < 40 && cmp32_32(&progress_x, &progress_step) != 1) {
l218:
  lda cmd_copyFile_progress_i
  cpi 40
  jnc l219
  lxi h, cmd_copyFile_progress_x
  shld cmp32_32_1
  lxi h, cmd_copyFile_progress_step
  call cmp32_32
  cpi 1
  jz l219
  ; 59 sub32_32(&progress_x, &progress_step);
  lxi h, cmd_copyFile_progress_x
  shld sub32_32_1
  lxi h, cmd_copyFile_progress_step
  call sub32_32
  ; 60 drawWindowText(progress_i, 3, "\x17");
  lda cmd_copyFile_progress_i
  sta drawWindowText_1
  mvi a, 3
  sta drawWindowText_2
  lxi h, string24
  call drawWindowText
  ; 61 ++progress_i;
  lxi h, cmd_copyFile_progress_i
  inr m
  jmp l218
l219:
  ; 65 if(bioskey1() == KEY_ESC) { e = ERR_USER; break; }
  call bioskey1
  cpi 27
  jnz l220
  ; 65 e = ERR_USER; break; }
  mvi a, 128
  sta cmd_copyFile_e
  ; 65 break; }
  jmp l211
l220:
l212:
  jmp l210
l211:
  ; 69 fs_delete(to);
  lhld cmd_copyFile_2
  call fs_delete
  ; 70 return e;
  lda cmd_copyFile_e
  ret
  ; --- applyMask1 -----------------------------------------------------------------
applyMask1:
  push b
  sta applyMask1_3
  ; 77 for(;;) {
l221:
  ; 78 m = *mask;
  lhld applyMask1_2
  mov b, m
  ; 79 if(m == '*') return;
  mvi a, 42
  cmp b
  jnz l224
  ; 79 return;
  pop b
  ret
l224:
  ; 80 if(m != '?') *dest = m;
  mvi a, 63
  cmp b
  jz l225
  ; 80 *dest = m;
  lhld applyMask1_1
  mov m, b
l225:
  ; 81 --i;
  lxi h, applyMask1_3
  dcr m
  ; 82 if(i==0) return;
  lda applyMask1_3
  ora a
  jnz l226
  ; 82 return;
  pop b
  ret
l226:
  ; 83 ++mask, ++dest;
  lhld applyMask1_2
  inx h
  shld applyMask1_2
  lhld applyMask1_1
  inx h
  shld applyMask1_1
l223:
  jmp l221
l222:
  pop b
  ret
  ; --- cmd_copyFolder -----------------------------------------------------------------
cmd_copyFolder:
  shld cmd_copyFolder_2
  ; 94 0;<level>
  xra a
  sta cmd_copyFolder_level
  ; 99 e = fs_mkdir(to); 
  call fs_mkdir
  sta cmd_copyFolder_e
  ; 100 if(e) return e;convertToConfition
  ora a
  jz l227
  ; 100 return e;
  lda cmd_copyFolder_e
  ret
l227:
  ; 102 for(i=0;;++i) {
  lxi h, 0
  shld cmd_copyFolder_i
l228:
  ; 104 if(i == maxFiles) return ERR_MAX_FILES;
  xchg
  lhld maxFiles
  call op_cmp16
  jnz l231
  ; 104 return ERR_MAX_FILES;
  mvi a, 10
  ret
l231:
  ; 108 e = fs_findfirst(from, panelB.files1, i+1);
  lhld cmd_copyFolder_1
  shld fs_findfirst_1
  lhld panelB
  shld fs_findfirst_2
  ; Сложение с константой 1
  lhld cmd_copyFolder_i
  inx h
  call fs_findfirst
  sta cmd_copyFolder_e
  ; 109 if(e != 0 && e != ERR_MAX_FILES) return e; // Њл ўбҐЈ¤  Ўг¤Ґ¬ Ї®«гзЁвм ERR_MAX_FILES
  ora a
  jz l232
  lda cmd_copyFolder_e
  cpi 10
  jz l232
  ; 109 return e; // Њл ўбҐЈ¤  Ўг¤Ґ¬ Ї®«гзЁвм ERR_MAX_FILES
  ret
l232:
  ; 112 if(i >= fs_low) {
  lhld cmd_copyFolder_i
  xchg
  lhld fs_low
  call op_cmp16
  jz l234
  jnc l233
l234:
  ; 114 if(level==0) return 0;
  lda cmd_copyFolder_level
  ora a
  jnz l235
  ; 114 return 0;
  xra a
  ret
l235:
  ; 116 dropPathInt(from, 0);
  lhld cmd_copyFolder_1
  shld dropPathInt_1
  lxi h, 0
  call dropPathInt
  ; 117 dropPathInt(to, 0);
  lhld cmd_copyFolder_2
  shld dropPathInt_1
  lxi h, 0
  call dropPathInt
  ; 118 --level;
  lxi h, cmd_copyFolder_level
  dcr m
  ; 119 i = stack[level];
  lhld cmd_copyFolder_level
  mvi h, 0
  ; Умножение HL на 2
  dad h
  ; Сложение
  lxi d, cmd_copyFolder_stack
  dad d
  mov e, m
  inx h
  mov d, m
  xchg
  shld cmd_copyFolder_i
  ; 120 continue;
  jmp l230
l233:
  ; 122 f = panelB.files1 + i;
  lhld cmd_copyFolder_i
  ; Умножение HL на 20
  mov d, h
  mov e, l
  dad h
  dad h
  dad d
  dad h
  dad h
  ; Сложение
  xchg
  lhld panelB
  dad d
  shld cmd_copyFolder_f
  ; 125 if(catPathAndUnpack(from, f->fname)) return ERR_RECV_STRING;
  lhld cmd_copyFolder_1
  shld catPathAndUnpack_1
  lhld cmd_copyFolder_f
  call catPathAndUnpack
  ; convertToConfition
  ora a
  jz l236
  ; 125 return ERR_RECV_STRING;
  mvi a, 11
  ret
l236:
  ; 126 if(catPathAndUnpack(to,   f->fname)) return ERR_RECV_STRING;
  lhld cmd_copyFolder_2
  shld catPathAndUnpack_1
  lhld cmd_copyFolder_f
  call catPathAndUnpack
  ; convertToConfition
  ora a
  jz l237
  ; 126 return ERR_RECV_STRING;
  mvi a, 11
  ret
l237:
  ; 129 if(f->fattrib & 0x10) {Сложение
  lhld cmd_copyFolder_f
  lxi d, 11
  dad d
  mov a, m
  ani 16
  ; convertToConfition
  jz l238
  ; 131 if(level == COPY_STACK-1) return ERR_RECV_STRING;
  lda cmd_copyFolder_level
  cpi 7
  jnz l239
  ; 131 return ERR_RECV_STRING;
  mov a, e
  ret
l239:
  ; 132 stack[level] = i;
  lhld cmd_copyFolder_level
  mov h, d
  ; Умножение HL на 2
  dad h
  ; Сложение
  lxi d, cmd_copyFolder_stack
  dad d
  push h
  lhld cmd_copyFolder_i
  pop d
  xchg
  mov m, e
  inx h
  mov m, d
  dcx h
  ; 133 level++;
  lxi h, cmd_copyFolder_level
  inr m
  ; 135 e = fs_mkdir(to); 
  lhld cmd_copyFolder_2
  call fs_mkdir
  sta cmd_copyFolder_e
  ; 136 if(e) return e;convertToConfition
  ora a
  jz l240
  ; 136 return e;
  lda cmd_copyFolder_e
  ret
l240:
  ; 138 i = -1;
  lxi h, 65535
  shld cmd_copyFolder_i
  ; 139 continue;
  jmp l230
l238:
  ; 143 e = cmd_copyFile(from, to);
  lhld cmd_copyFolder_1
  shld cmd_copyFile_1
  lhld cmd_copyFolder_2
  call cmd_copyFile
  sta cmd_copyFolder_e
  ; 146 dropPathInt(from, 0);
  lhld cmd_copyFolder_1
  shld dropPathInt_1
  lxi h, 0
  call dropPathInt
  ; 147 dropPathInt(to, 0);
  lhld cmd_copyFolder_2
  shld dropPathInt_1
  lxi h, 0
  call dropPathInt
  ; 150 if(e) return e;convertToConfition
  lda cmd_copyFolder_e
  ora a
  jz l241
  ; 150 return e;
  lda cmd_copyFolder_e
  ret
l241:
l230:
  lhld cmd_copyFolder_i
  inx h
  shld cmd_copyFolder_i
  jmp l228
l229:
  ret
  ; --- applyMask -----------------------------------------------------------------
applyMask:
  shld applyMask_2
  ; 157 applyMask1(dest, mask, 8);
  lhld applyMask_1
  shld applyMask1_1
  lhld applyMask_2
  shld applyMask1_2
  mvi a, 8
  call applyMask1
  ; 158 applyMask1(dest+8, mask+8, 3);Сложение
  lhld applyMask_1
  lxi d, 8
  dad d
  shld applyMask1_1
  ; Сложение
  lhld applyMask_2
  lxi d, 8
  dad d
  shld applyMask1_2
  mvi a, 3
  jmp applyMask1
cmd_copymove1:
  sta cmd_copymove1_2
  ; 173 if(shiftPressed) {convertToConfition
  ora a
  jz l242
  ; 175 f = getSelNoBack();
  call getSelNoBack
  shld cmd_copymove1_f
  ; 176 if(!f) return 0; // ” ©« ­Ґ ўлЎа ­, ўле®¤Ё¬ ЎҐ§ ®иЁЎЄЁconvertToConfition
  mov a, l
  ora h
  jnz l243
  ; 176 return 0; // ” ©« ­Ґ ўлЎа ­, ўле®¤Ё¬ ЎҐ§ ®иЁЎЄЁ
  xra a
  ret
l243:
  ; 177 unpackName(cmdLine, f->fname);
  lxi h, cmdline
  shld unpackName_1
  lhld cmd_copymove1_f
  call unpackName
  jmp l244
l242:
  ; 180 i = strlen(panelB.path1);
  lxi h, (panelB)+(2)
  call strlen
  shld cmd_copymove1_i
  ; 181 if(i >= 254) return ERR_RECV_STRING; // ’ Є Є Є ЇаЁЎ ўЁ¬ 2 бЁ¬ў®« Сложение
  lxi d, 65282
  dad d
  jnc l245
  ; 181 return ERR_RECV_STRING; // ’ Є Є Є ЇаЁЎ ўЁ¬ 2 бЁ¬ў®« 
  mvi a, 11
  ret
l245:
  ; 182 cmdLine[0] = '/';
  mvi a, 47
  sta (cmdline)+(0)
  ; 183 strcpy(cmdline+1, panelB.path1);
  lxi h, (cmdline)+(1)
  shld strcpy_1
  lxi h, (panelB)+(2)
  call strcpy
  ; 184 if(i != 0) strcpy(cmdline+i+1, "/");Сложение с константой 0
  lhld cmd_copymove1_i
  mov a, l
  ora h
  jz l246
  ; 184 strcpy(cmdline+i+1, "/");Сложение
  lxi d, cmdline
  dad d
  ; Сложение с константой 1
  inx h
  shld strcpy_1
  lxi h, string25
  call strcpy
l246:
l244:
  ; 188 if(!inputBox(copymode ? " kopirowatx " : " pereimenowatx/peremestitx ") && cmdline[0]!=0) return 0;
  lda cmd_copymove1_1
  ora a
  jz l248
  lxi h, string26
  jmp l249
l248:
  lxi h, string27
l249:
  call inputBox
  ; convertToConfition
  ora a
  jnz l247
  lda (cmdline)+(0)
  ora a
  jz l247
  ; 188 return 0;
  xra a
  ret
l247:
  ; 191 if(!absolutePath(cmdline)) return ERR_RECV_STRING;
  lxi h, cmdline
  call absolutePath
  ; convertToConfition
  ora a
  jnz l250
  ; 191 return ERR_RECV_STRING;
  mvi a, 11
  ret
l250:
  ; 194 mask[0] = 0;  
  xra a
  sta (cmd_copymove1_mask)+(0)
  ; 195 name = getname(cmdline);
  lxi h, cmdline
  call getName
  shld cmd_copymove1_name
  ; 196 if(name[0] != 0) {Сложение с константой 0
  mov a, m
  ora a
  jz l251
  ; 198 packName(mask, name);
  lxi h, cmd_copymove1_mask
  shld packName_1
  lhld cmd_copymove1_name
  call packName
  ; 200 dropPathInt(cmdLine, 0);
  lxi h, cmdline
  shld dropPathInt_1
  lxi h, 0
  call dropPathInt
  jmp l252
l251:
  ; 204 if(cmdline[0] != 0 && name[0] == 0) name[-1] = 0;
  lda (cmdline)+(0)
  ora a
  jz l253
  ; Сложение с константой 0
  lhld cmd_copymove1_name
  mov a, m
  ora a
  jnz l253
  ; 204 name[-1] = 0;Сложение с константой -1
  dcx h
  mvi m, 0
l253:
l252:
  ; 208 type = getFirstSelected(sourceFile);
  lxi h, cmd_copymove1_sourceFile
  call getFirstSelected
  sta cmd_copymove1_type
  ; 209 if(type == 0) return 0; // ЌҐв ўлЎа ­­ле д ©«®ў
  ora a
  jnz l254
  ; 209 return 0; // ЌҐв ўлЎа ­­ле д ©«®ў
  xra a
  ret
l254:
  ; 211 for(;;) {
l255:
  ; 213 if(!absolutePath(sourceFile)) { e = ERR_RECV_STRING; break; }
  lxi h, cmd_copymove1_sourceFile
  call absolutePath
  ; convertToConfition
  ora a
  jnz l258
  ; 213 e = ERR_RECV_STRING; break; }
  mvi a, 11
  sta cmd_copymove1_e
  ; 213 break; }
  jmp l256
l258:
  ; 216 packName(forMask, getname(sourceFile));
  lxi h, cmd_copymove1_forMask
  shld packName_1
  lxi h, cmd_copymove1_sourceFile
  call getName
  call packName
  ; 217 if(mask[0]) applyMask(forMask, mask);convertToConfition
  lda (cmd_copymove1_mask)+(0)
  ora a
  jz l259
  ; 217 applyMask(forMask, mask);
  lxi h, cmd_copymove1_forMask
  shld applyMask_1
  lxi h, cmd_copymove1_mask
  call applyMask
l259:
  ; 218 if(catPathAndUnpack(cmdline, forMask)) return ERR_RECV_STRING;
  lxi h, cmdline
  shld catPathAndUnpack_1
  lxi h, cmd_copymove1_forMask
  call catPathAndUnpack
  ; convertToConfition
  ora a
  jz l260
  ; 218 return ERR_RECV_STRING;
  mvi a, 11
  ret
l260:
  ; 221 if(0!=strcmp(sourceFile, cmdline)) {
  lxi h, cmd_copymove1_sourceFile
  shld strcmp_1
  lxi h, cmdline
  call strcmp
  ora a
  jz l261
  ; 223 if(copymode) {convertToConfition
  lda cmd_copymove1_1
  ora a
  jz l262
  ; 224 if(type==2) {
  lda cmd_copymove1_type
  cpi 2
  jnz l263
  ; 225 e = cmd_copyFolder(sourceFile, cmdline);
  lxi h, cmd_copymove1_sourceFile
  shld cmd_copyFolder_1
  lxi h, cmdline
  call cmd_copyFolder
  sta cmd_copymove1_e
  jmp l264
l263:
  ; 227 e = cmd_copyFile(sourceFile, cmdline);
  lxi h, cmd_copymove1_sourceFile
  shld cmd_copyFile_1
  lxi h, cmdline
  call cmd_copyFile
  sta cmd_copymove1_e
l264:
  jmp l265
l262:
  ; 231 drawWindow(" pereimenowanie/pereme}enie ");
  lxi h, string28
  call drawWindow
  ; 232 drawWindowText(0, 1, "iz:");
  xra a
  sta drawWindowText_1
  inr a
  sta drawWindowText_2
  lxi h, string21
  call drawWindowText
  ; 233 drawWindowText(4, 1, sourceFile);
  mvi a, 4
  sta drawWindowText_1
  mvi a, 1
  sta drawWindowText_2
  lxi h, cmd_copymove1_sourceFile
  call drawWindowText
  ; 234 drawWindowText(0, 2, "w:");
  xra a
  sta drawWindowText_1
  mvi a, 2
  sta drawWindowText_2
  lxi h, string22
  call drawWindowText
  ; 235 drawWindowText(4, 2, cmdline);
  mvi a, 4
  sta drawWindowText_1
  mvi a, 2
  sta drawWindowText_2
  lxi h, cmdline
  call drawWindowText
  ; 236 drawAnyKeyButton();
  call drawAnyKeyButton
  ; 239 if(bioskey1() == KEY_ESC) { e = ERR_USER; break; }
  call bioskey1
  cpi 27
  jnz l266
  ; 239 e = ERR_USER; break; }
  mvi a, 128
  sta cmd_copymove1_e
  ; 239 break; }
  jmp l256
l266:
  ; 241 e = fs_move(sourceFile, cmdline);    
  lxi h, cmd_copymove1_sourceFile
  shld fs_move_1
  lxi h, cmdline
  call fs_move
  sta cmd_copymove1_e
l265:
  ; 244 if(e) break;convertToConfition
  lda cmd_copymove1_e
  ora a
  jnz l256
l261:
  ; 248 dropPathInt(cmdLine, 0);
  lxi h, cmdline
  shld dropPathInt_1
  lxi h, 0
  call dropPathInt
  ; 251 type = getNextSelected(sourceFile);
  lxi h, cmd_copymove1_sourceFile
  call getNextSelected
  sta cmd_copymove1_type
  ; 252 if(type == 0) { e=0; break; }
  ora a
  jnz l268
  ; 252 e=0; break; }
  xra a
  sta cmd_copymove1_e
  ; 252 break; }
  jmp l256
l268:
l257:
  jmp l255
l256:
  ; 257 getFiles();
  call getFiles
  ; 258 dupFiles(1);
  mvi a, 1
  call dupFiles
  ; 260 return e;
  lda cmd_copymove1_e
  ret
  ; --- cmd_copymove -----------------------------------------------------------------
cmd_copymove:
  sta cmd_copymove_2
  ; 266 drawError(copymode ? "o{ibka kopirowaniq" : "o{ibka pereme}eniq", cmd_copymove1(copymode, shiftPressed));
  lda cmd_copymove_1
  ora a
  jz l269
  lxi h, string29
  jmp l270
l269:
  lxi h, string30
l270:
  shld drawError_1
  lda cmd_copymove_1
  sta cmd_copymove1_1
  lda cmd_copymove_2
  call cmd_copymove1
  call drawError
  ; 267 drawScreen();
  jmp drawScreen
cmd_new1:
  sta cmd_new1_1
  ; 8 cmdLine[0] = 0;
  xra a
  sta (cmdline)+(0)
  ; 11 if(!inputBox(dir ? " sozdatx papku " : " sozdatx fajl ") && cmdline[0]!=0) return 0;
  lda cmd_new1_1
  ora a
  jz l272
  lxi h, string31
  jmp l273
l272:
  lxi h, string32
l273:
  call inputBox
  ; convertToConfition
  ora a
  jnz l271
  lda (cmdline)+(0)
  ora a
  jz l271
  ; 11 return 0;
  xra a
  ret
l271:
  ; 13 if(!absolutePath(cmdline)) return ERR_RECV_STRING;
  lxi h, cmdline
  call absolutePath
  ; convertToConfition
  ora a
  jnz l274
  ; 13 return ERR_RECV_STRING;
  mvi a, 11
  ret
l274:
  ; 16 if(!dir) {convertToConfition
  lda cmd_new1_1
  ora a
  jnz l275
  ; 17 if(strlen(cmdline) >= 255) return ERR_RECV_STRING;
  lxi h, cmdline
  call strlen
  ; Сложение
  lxi d, 65281
  dad d
  jnc l276
  ; 17 return ERR_RECV_STRING;
  mvi a, 11
  ret
l276:
  ; 20 memcpy_back(cmdline+1, cmdline, 255);
  lxi h, (cmdline)+(1)
  shld memcpy_back_1
  lxi h, cmdline
  shld memcpy_back_2
  lxi h, 255
  call memcpy_back
  ; 21 cmdline[0] = '*';
  mvi a, 42
  sta (cmdline)+(0)
  ; 24 run(editorApp, cmdLine);
  lxi h, editorApp
  shld run_1
  lxi h, cmdline
  call run
  ; 25 return 0;
  xra a
  ret
l275:
  ; 29 dir = fs_mkdir(cmdline);
  lxi h, cmdline
  call fs_mkdir
  sta cmd_new1_1
  ; 32 if(!dir) {convertToConfition
  ora a
  jnz l277
  ; 33 getFiles();
  call getFiles
  ; 34 dupFiles(0);
  xra a
  call dupFiles
l277:
  ; 37 return dir;
  lda cmd_new1_1
  ret
  ; --- cmd_new -----------------------------------------------------------------
cmd_new:
  sta cmd_new_1
  ; 41 drawError("o{ibka sozdaniq papki", cmd_new1(dir));
  lxi h, string33
  shld drawError_1
  call cmd_new1
  call drawError
  ; 43 drawScreen();
  jmp drawScreen
cmd_freespace_1:
  shld cmd_freespace_1_2
  ; 10 i2s32(buf, (ulong*)&fs_low, 10, ' ');
  lxi h, cmd_freespace_1_buf
  shld i2s32_1
  lxi h, fs_low
  shld i2s32_2
  lxi h, 10
  shld i2s32_3
  mvi a, 32
  call i2s32
  ; 13 memcpy_back(buf+10, buf+7, 3); buf[9]  = ' ';
  lxi h, (cmd_freespace_1_buf)+(10)
  shld memcpy_back_1
  lxi h, (cmd_freespace_1_buf)+(7)
  shld memcpy_back_2
  lxi h, 3
  call memcpy_back
  ; 13 buf[9]  = ' ';
  mvi a, 32
  sta (cmd_freespace_1_buf)+(9)
  ; 14 memcpy_back(buf+6,  buf+4, 3); buf[5]  = ' ';
  lxi h, (cmd_freespace_1_buf)+(6)
  shld memcpy_back_1
  lxi h, (cmd_freespace_1_buf)+(4)
  shld memcpy_back_2
  lxi h, 3
  call memcpy_back
  ; 14 buf[5]  = ' ';
  mvi a, 32
  sta (cmd_freespace_1_buf)+(5)
  ; 15 memcpy_back(buf+2,  buf+1, 3); buf[1]  = ' ';
  lxi h, (cmd_freespace_1_buf)+(2)
  shld memcpy_back_1
  lxi h, (cmd_freespace_1_buf)+(1)
  shld memcpy_back_2
  lxi h, 3
  call memcpy_back
  ; 15 buf[1]  = ' ';
  mvi a, 32
  sta (cmd_freespace_1_buf)+(1)
  ; 16 strcpy(buf+13, " mb");
  lxi h, (cmd_freespace_1_buf)+(13)
  shld strcpy_1
  lxi h, string34
  call strcpy
  ; 19 drawWindowText(6, y, text);
  mvi a, 6
  sta drawWindowText_1
  lda cmd_freespace_1_1
  sta drawWindowText_2
  lhld cmd_freespace_1_2
  call drawWindowText
  ; 20 drawWindowText(16, y, buf);
  mvi a, 16
  sta drawWindowText_1
  lda cmd_freespace_1_1
  sta drawWindowText_2
  lxi h, cmd_freespace_1_buf
  jmp drawWindowText
cmd_freespace:
  lxi h, string35
  call drawWindow
  ; 30 drawWindowText(6, 2, "prowerka...");  
  mvi a, 6
  sta drawWindowText_1
  mvi a, 2
  sta drawWindowText_2
  lxi h, string36
  call drawWindowText
  ; 33 if(e = fs_getfree()) { 
  call fs_getfree
  sta cmd_freespace_e
  ; convertToConfition
  ora a
  jz l278
  ; 34 drawError("o{ibka ~teniq", e);
  lxi h, string37
  shld drawError_1
  lda cmd_freespace_e
  call drawError
  jmp l279
l278:
  ; 37 cmd_freespace_1(2, "swobodno: ");
  mvi a, 2
  sta cmd_freespace_1_1
  lxi h, string38
  call cmd_freespace_1
  ; 40 if(!fs_gettotal()) cmd_freespace_1(1, "wsego:");
  call fs_gettotal
  ; convertToConfition
  ora a
  jnz l280
  ; 40 cmd_freespace_1(1, "wsego:");
  mvi a, 1
  sta cmd_freespace_1_1
  lxi h, string39
  call cmd_freespace_1
l280:
  ; 43 drawAnyKeyButton();
  call drawAnyKeyButton
  ; 44 getch1();
  call getch1
l279:
  ; 47 drawScreen();
  jmp drawScreen
cmd_deleteFile:
  lxi h, string40
  call drawWindow
  ; 9 drawWindowText(0, 1, cmdline);
  xra a
  sta drawWindowText_1
  inr a
  sta drawWindowText_2
  lxi h, cmdline
  call drawWindowText
  ; 10 drawEscButton();
  call drawEscButton
  ; 13 if(bioskey1() == KEY_ESC) return ERR_USER;
  call bioskey1
  cpi 27
  jnz l281
  ; 13 return ERR_USER;
  mvi a, 128
  ret
l281:
  ; 16 return fs_delete(cmdline);
  lxi h, cmdline
  jmp fs_delete
  ret
  ; --- cmd_deleteFolder -----------------------------------------------------------------
cmd_deleteFolder:
  xra a
  sta cmd_deleteFolder_level
  ; 29 while(1) {
l282:
  ; 31 e = fs_findfirst(cmdline, panelB.files1, maxFiles);  
  lxi h, cmdline
  shld fs_findfirst_1
  lhld panelB
  shld fs_findfirst_2
  lhld maxFiles
  call fs_findfirst
  sta cmd_deleteFolder_e
  ; 32 if(e != 0 && e != ERR_MAX_FILES) return e;
  ora a
  jz l284
  lda cmd_deleteFolder_e
  cpi 10
  jz l284
  ; 32 return e;
  ret
l284:
  ; 33 panelB.cnt = fs_low;
  lhld fs_low
  shld (panelB)+(262)
  ; 36 e = 0;
  xra a
  sta cmd_deleteFolder_e
  ; 37 for(p=panelB.files1, i=panelB.cnt; i; --i, ++p) {
  lhld panelB
  shld cmd_deleteFolder_p
  lhld (panelB)+(262)
  shld cmd_deleteFolder_i
l285:
  ; convertToConfition
  lhld cmd_deleteFolder_i
  mov a, l
  ora h
  jz l286
  ; 38 if(catPathAndUnpack(cmdLine, p->fname)) return ERR_RECV_STRING;
  lxi h, cmdline
  shld catPathAndUnpack_1
  lhld cmd_deleteFolder_p
  call catPathAndUnpack
  ; convertToConfition
  ora a
  jz l288
  ; 38 return ERR_RECV_STRING;
  mvi a, 11
  ret
l288:
  ; 39 e = cmd_deleteFile();
  call cmd_deleteFile
  sta cmd_deleteFolder_e
  ; 40 if(e == ERR_DIR_NOT_EMPTY) break;
  cpi 7
  jz l286
  lxi h, cmdline
  shld dropPathInt_1
  lxi h, 0
  call dropPathInt
  ; 43 if(e) return e;convertToConfition
  lda cmd_deleteFolder_e
  ora a
  jz l290
  ; 43 return e;
  lda cmd_deleteFolder_e
  ret
l290:
l287:
  lhld cmd_deleteFolder_i
  dcx h
  shld cmd_deleteFolder_i
  lhld cmd_deleteFolder_p
  lxi d, 20
  dad d
  shld cmd_deleteFolder_p
  jmp l285
l286:
  ; 47 if(e == ERR_DIR_NOT_EMPTY) { 
  lda cmd_deleteFolder_e
  cpi 7
  jnz l291
  ; 48 ++level;
  lxi h, cmd_deleteFolder_level
  inr m
  ; 49 continue;
  jmp l282
l291:
  ; 53 if(panelB.cnt == maxFiles) continue;
  lhld (panelB)+(262)
  xchg
  lhld maxFiles
  call op_cmp16
  jz l282
  call cmd_deleteFile
  sta cmd_deleteFolder_e
  ; 57 if(e) return e;convertToConfition
  ora a
  jz l293
  ; 57 return e;
  lda cmd_deleteFolder_e
  ret
l293:
  ; 60 if(level == 0) return 0;
  lda cmd_deleteFolder_level
  ora a
  jnz l294
  ; 60 return 0;
  xra a
  ret
l294:
  ; 61 --level;
  lxi h, cmd_deleteFolder_level
  dcr m
  ; 62 dropPathInt(cmdLine, 0);
  lxi h, cmdline
  shld dropPathInt_1
  lxi h, 0
  call dropPathInt
  jmp l282
l283:
  ret
  ; --- cmd_delete -----------------------------------------------------------------
cmd_delete:
  lxi h, string41
  shld confirm_1
  lxi h, string42
  call confirm
  ; convertToConfition
  ora a
  jz l295
  ; 73 needRefresh2 = 0;
  xra a
  sta cmd_delete_needRefresh2
  ; 76 if(getFirstSelected(cmdLine)) {
  lxi h, cmdline
  call getFirstSelected
  ; convertToConfition
  ora a
  jz l296
  ; 77 for(;;) {
l297:
  ; 78 if(!absolutePath(cmdline)) { e = ERR_RECV_STRING; break; }
  lxi h, cmdline
  call absolutePath
  ; convertToConfition
  ora a
  jnz l300
  ; 78 e = ERR_RECV_STRING; break; }
  mvi a, 11
  sta cmd_delete_e
  ; 78 break; }
  jmp l298
l300:
  ; 81 e = cmd_deleteFile();
  call cmd_deleteFile
  sta cmd_delete_e
  ; 84 if(e == ERR_DIR_NOT_EMPTY) {
  cpi 7
  jnz l301
  ; 85 needRefresh2 = 1; // Џа ў п Ї ­Ґ«м Ўг¤Ґв ЁбЇ®азҐ­ 
  mvi a, 1
  sta cmd_delete_needRefresh2
  ; 86 e = cmd_deleteFolder();
  call cmd_deleteFolder
  sta cmd_delete_e
l301:
  ; 88 if(e) break;convertToConfition
  ora a
  jnz l298
  lxi h, cmdline
  call getNextSelected
  ; convertToConfition
  ora a
  jz l298
l299:
  jmp l297
l298:
  ; 95 drawError("o{ibka udaleniq", e);
  lxi h, string43
  shld drawError_1
  lda cmd_delete_e
  call drawError
  ; 98 getFiles();
  call getFiles
  ; 99 dupFiles(needRefresh2);
  lda cmd_delete_needRefresh2
  call dupFiles
l296:
l295:
  ; 103 drawScreen();
  jmp drawScreen
compareMask1:
  push b
  sta compareMask1_3
  ; 8 for(;;) {
l304:
  ; 9 m = *mask;
  lhld compareMask1_2
  mov b, m
  ; 10 if(m == '*') return 1;
  mvi a, 42
  cmp b
  jnz l307
  ; 10 return 1;
  mvi a, 1
  pop b
  ret
l307:
  ; 11 if(m != '?' && m != *fileName) return 0;  
  mvi a, 63
  cmp b
  jz l308
  lhld compareMask1_1
  mov a, m
  cmp b
  jz l308
  ; 11 return 0;  
  xra a
  pop b
  ret
l308:
  ; 12 --i;
  lxi h, compareMask1_3
  dcr m
  ; 13 if(i==0) return 1;
  lda compareMask1_3
  ora a
  jnz l309
  ; 13 return 1;
  mvi a, 1
  pop b
  ret
l309:
  ; 14 ++mask, ++fileName;
  lhld compareMask1_2
  inx h
  shld compareMask1_2
  lhld compareMask1_1
  inx h
  shld compareMask1_1
l306:
  jmp l304
l305:
  pop b
  ret
  ; --- compareMask -----------------------------------------------------------------
compareMask:
  shld compareMask_2
  ; 21 if(!compareMask1(fileName, mask, 8)) return 0;
  lhld compareMask_1
  shld compareMask1_1
  lhld compareMask_2
  shld compareMask1_2
  mvi a, 8
  call compareMask1
  ; convertToConfition
  ora a
  jnz l310
  ; 21 return 0;
  xra a
  ret
l310:
  ; 22 return compareMask1(fileName+8, mask+8, 3);Сложение
  lhld compareMask_1
  lxi d, 8
  dad d
  shld compareMask1_1
  ; Сложение
  lhld compareMask_2
  lxi d, 8
  dad d
  shld compareMask1_2
  mvi a, 3
  jmp compareMask1
  ret
  ; --- cmd_sel -----------------------------------------------------------------
cmd_sel:
  sta cmd_sel_1
  ; 33 strcpy(cmdLine, "*.*");
  lxi h, cmdline
  shld strcpy_1
  lxi h, string44
  call strcpy
  ; 34 if(inputBox(" pometitx fajly ")) {
  lxi h, string45
  call inputBox
  ; convertToConfition
  ora a
  jz l311
  ; 35 packName(buf, cmdLine);
  lxi h, cmd_sel_buf
  shld packName_1
  lxi h, cmdline
  call packName
  ; 37 for(i=panelA.cnt, f=panelA.files1; i; --i, ++f) {
  lhld (panelA)+(262)
  shld cmd_sel_i
  lhld panelA
  shld cmd_sel_f
l312:
  ; convertToConfition
  lhld cmd_sel_i
  mov a, l
  ora h
  jz l313
  ; 38 if(f->fattrib & 0x10) {Сложение
  lhld cmd_sel_f
  lxi d, 11
  dad d
  mov a, m
  ani 16
  ; convertToConfition
  jz l315
  ; 39 f->fattrib &= 0x7F;Сложение
  lhld cmd_sel_f
  lxi d, 11
  dad d
  mov a, m
  ani 127
  mov m, a
  jmp l316
l315:
  ; 41 if(compareMask(f->fname, buf)) {
  lhld cmd_sel_f
  shld compareMask_1
  lxi h, cmd_sel_buf
  call compareMask
  ; convertToConfition
  ora a
  jz l317
  ; 42 if(add) {convertToConfition
  lda cmd_sel_1
  ora a
  jz l318
  ; 43 f->fattrib |= 0x80;Сложение
  lhld cmd_sel_f
  lxi d, 11
  dad d
  mov a, m
  ori 128
  mov m, a
  jmp l319
l318:
  ; 45 f->fattrib &= 0x7F;Сложение
  lhld cmd_sel_f
  lxi d, 11
  dad d
  mov a, m
  ani 127
  mov m, a
l319:
l317:
l316:
l314:
  lhld cmd_sel_i
  dcx h
  shld cmd_sel_i
  lhld cmd_sel_f
  lxi d, 20
  dad d
  shld cmd_sel_f
  jmp l312
l313:
l311:
  ; 52 drawScreen();
  jmp drawScreen
initPalmiraScreen:
;    LXI H, 0C001h; VG_75+1
;    MVI M, 0
;    DCR	L
;    MVI M, 04DH
;    MVI M, 064H
;;    MVI M, 0CCH
;;    MVI M, 058H
;    MVI M, 00CH
;    MVI M, 048H
;    INR L
;    MVI M, 27H
;    MOV A, M
;WAIT_VRTC:
;    MOV A, M
;    ANI 20H
;    JZ WAIT_VRTC
;    LXI H, 0C608h; VT_57+8
;    MVI M, 80H
;    MVI L, 4
;    MVI M, 0D0H
;    MVI M, 0B6H
;    INR L
;    MVI	M, 1FH
;    MVI	M, 49H
;    MVI L, 8
;    MVI	M, 0A4H
;
;    VG75[1] = 0; 
;    VG75[0] = 0x4d
;    VG75[0] = 0x64
;    VG75[0] = 0x77
;    VG75[0] = 0x50
;    VG75[1] = 0x23
    mvi  a,50h
    DI
    OUT  98h+1
    mvi  A,80h+1
    OUT  98h+1
    ;EI
    ret
  
  ret
  ; --- showTextCursor -----------------------------------------------------------------
showTextCursor:
  sta showTextCursor_2
  ; 105 gotoxy(x,y);
  lda showTextCursor_1
  sta gotoxy_1
  lda showTextCursor_2
  jmp gotoxy
drawInit:
  call clrscr
  ; 116 initPalmiraScreen();
  call initPalmiraScreen
  ; 118 maxFiles = /*getMemTop()*/0xC000 - START_FILE_BUFFER;
  lxi h, 35584
  shld maxFiles
  ; 119 maxFiles /= sizeof(FileInfo)*2;
  lxi d, 40
  call op_div16
  shld maxFiles
  ; 120 activePanel = 0;
  xra a
  sta activePanel
  ; 121 fileCursorAddr = 0;  
  lxi h, 0
  shld fileCursorAddr
  ret
  ; --- hideTextCursor -----------------------------------------------------------------
hideTextCursor:
  mvi a, 255
  sta showTextCursor_1
  jmp showTextCursor
drawSwapPanels:
  lxi h, activePanel
  mvi a, 32
  sub m
  sta activePanel
  ret
  ; --- setaddr -----------------------------------------------------------------
setaddr:
  shld setaddr_1
  ; 155 asm
    di
    mov  a,l
    out  98h + 1
    mov  a,h
    ori  40h
    out  98h + 1
    ei
  
  ret
  ; --- setch -----------------------------------------------------------------
setch:
  sta setch_1
  ; 169 asm
    OUT  98h
  
  ret
  ; --- hLine -----------------------------------------------------------------
hLine:
  sta hLine_3
  ; 179 asm{
    mov e, a
    lda hLine_2
    mov d, a
    lhld hLine_1
    di
    mov  a,l
    out  98h + 1
    mov  a,h
    ori  40h
    out  98h + 1
    ei
    mov  a, d
hLine_l0 :
    OUT  98h
    ; mov m, d
    dcr e
    jnz hLine_l0
  
  ret
  ; --- vLine -----------------------------------------------------------------
vLine:
  sta vLine_3
  ; 201 asm{
    push b
    mov d, a
    lda radio86rkVideoBpl
    mov c, a
    mvi b, 0
    lda vLine_2
    mov e, a
    lhld vLine_1
vLine_l0 :
    di
    mov  a,l
    out  98h + 1
    mov  a,h
    ori  40h
    out  98h + 1
    ei
    mov  a, d
    OUT  98h
    ; mov m, d
    dad b
    dcr e
    jnz vLine_l0
    pop b
  
  ret
  ; --- hideFileCursor -----------------------------------------------------------------
hideFileCursor:
  lhld fileCursorAddr
  mov a, l
  ora h
  jnz l320
  ; 232 return;
  ret
l320:
  ; 234 setaddr(fileCursorAddr);
  call setaddr
  ; 235 setch(' ');
  mvi a, 32
  call setch
  ; 237 setaddr(fileCursorAddr+13);Сложение
  lhld fileCursorAddr
  lxi d, 13
  dad d
  call setaddr
  ; 238 setch(' ');
  mvi a, 32
  call setch
  ; 239 hLine(fileCursorAddr + (int)radio86rkVideoAttrMem,attrHidden, 14);Сложение
  lhld fileCursorAddr
  xchg
  lhld radio86rkVideoAttrMem
  dad d
  shld hLine_1
  lda attrHidden
  sta hLine_2
  mvi a, 14
  call hLine
  ; 240 fileCursorAddr = 0;
  lxi h, 0
  shld fileCursorAddr
  ret
  ; --- showFileCursor -----------------------------------------------------------------
showFileCursor:
  call hideFileCursor
  ; 250 fileCursorAddr = charAddr(panelA.cursorX*15 + 2 + activePanel, 2 + panelA.cursorY);
  mvi d, 15
  lda (panelA)+(258)
  call op_mul
  ; Сложение с константой 2
  inx h
  inx h
  ; Сложение
  xchg
  lhld activePanel
  mvi h, 0
  dad d
  mov a, l
  sta charAddr_1
  lda (panelA)+(259)
  adi 2
  call charAddr
  shld fileCursorAddr
  ; 252 setaddr(fileCursorAddr);
  call setaddr
  ; 253 setch('[');
  mvi a, 91
  call setch
  ; 255 setaddr(fileCursorAddr + 13);Сложение
  lhld fileCursorAddr
  lxi d, 13
  dad d
  call setaddr
  ; 256 setch(']');
  mvi a, 93
  call setch
  ; 257 hLine(fileCursorAddr + (int)radio86rkVideoAttrMem, attrShow, 14);Сложение
  lhld fileCursorAddr
  xchg
  lhld radio86rkVideoAttrMem
  dad d
  shld hLine_1
  lda attrShow
  sta hLine_2
  mvi a, 14
  jmp hLine
drawRect:
  sta drawRect_3
  ; 266 setaddr(a);
  lhld drawRect_1
  call setaddr
  ; 267 setch(0x4);
  mvi a, 4
  call setch
  ; 268 for (i = w-1; i; --i)
  lda drawRect_2
  dcr a
  sta drawRect_i
l321:
  ; convertToConfition
  lda drawRect_i
  ora a
  jz l322
  ; 269 setch(0x1C);
  mvi a, 28
  call setch
l323:
  lxi h, drawRect_i
  dcr m
  jmp l321
l322:
  ; 270 setch(0x10);
  mvi a, 16
  call setch
  ; 271 a += VIDEO_BPL;Сложение
  lxi d, 80
  lhld drawRect_1
  dad d
  shld drawRect_1
  ; 272 for(i=h; i; --i) {
  lda drawRect_3
  sta drawRect_i
l324:
  ; convertToConfition
  lda drawRect_i
  ora a
  jz l325
  ; 273 setaddr(a);
  lhld drawRect_1
  call setaddr
  ; 274 setch(0x06);
  mvi a, 6
  call setch
  ; 275 setaddr(a+w);Сложение
  lhld drawRect_1
  xchg
  lhld drawRect_2
  mvi h, 0
  dad d
  call setaddr
  ; 276 setch(0x11);
  mvi a, 17
  call setch
  ; 277 a += VIDEO_BPL;Сложение
  lxi d, 80
  lhld drawRect_1
  dad d
  shld drawRect_1
l326:
  lxi h, drawRect_i
  dcr m
  jmp l324
l325:
  ; 280 setaddr(a);
  lhld drawRect_1
  call setaddr
  ; 281 setch(0x02);
  mvi a, 2
  call setch
  ; 282 for (i = w-1; i; --i)
  lda drawRect_2
  dcr a
  sta drawRect_i
l327:
  ; convertToConfition
  lda drawRect_i
  ora a
  jz l328
  ; 283 setch(0x1C);
  mvi a, 28
  call setch
l329:
  lxi h, drawRect_i
  dcr m
  jmp l327
l328:
  ; 284 setch(0x01);
  mvi a, 1
  jmp setch
fillRect:
  sta fillRect_4
  ; 291 asm {
    push b
    lda radio86rkVideoBpl
    mov c, a
    mvi b, 0
    lhld fillRect_1
    lda fillRect_3
    mov d, a
    lda fillRect_2
    mov e, a
fillRect_l1:  
    ;lda fillRect_2
    push h
    mov  a,l
    out  98h+1
    mov  a,h
    ori  40h
    out  98h+1
    lda  fillRect_4

fillRect_l0:
    ;mov m, e
    ;inx h
    out 98h
    dcr e
    jnz fillRect_l0
    pop h
    dad b    
    dcr d
    jnz fillRect_l1
    pop b
  
  ret
  ; --- drawFilesCountInt -----------------------------------------------------------------
drawFilesCountInt:
  shld drawFilesCountInt_2
  ; 331 a = charAddr(2+activePanel, 4+ROWS_CNT);
  lda activePanel
  adi 2
  sta charAddr_1
  mvi a, 26
  call charAddr
  shld drawFilesCountInt_a
  ; 333 i2s32(buf, total, 10, ' ');
  lxi h, buf
  shld i2s32_1
  lhld drawFilesCountInt_1
  shld i2s32_2
  lxi h, 10
  shld i2s32_3
  mvi a, 32
  call i2s32
  ; 334 print2(a, buf);
  lhld drawFilesCountInt_a
  shld print2_1
  lxi h, buf
  call print2
  ; 335 print2(a+11, "bajt w    ");Сложение
  lhld drawFilesCountInt_a
  lxi d, 11
  dad d
  shld print2_1
  lxi h, string46
  call print2
  ; 336 if(filesCnt < 1000)Сложение
  lhld drawFilesCountInt_2
  lxi d, 64535
  dad d
  jc l330
  ; 339 i2s(buf, filesCnt, 3, ' ');
  lxi h, buf
  shld i2s_1
  lhld drawFilesCountInt_2
  shld i2s_2
  lxi h, 3
  shld i2s_3
  mvi a, 32
  call i2s
  ; 340 print2(a + 18, buf);Сложение
  lhld drawFilesCountInt_a
  lxi d, 18
  dad d
  shld print2_1
  lxi h, buf
  call print2
l330:
  ; 342 i2s((char*)a+18, filesCnt, 3, ' ');Сложение
  lhld drawFilesCountInt_a
  lxi d, 18
  dad d
  shld i2s_1
  lhld drawFilesCountInt_2
  shld i2s_2
  lxi h, 3
  shld i2s_3
  mvi a, 32
  call i2s
  ; 343 v = filesCnt % 100;
  lxi d, 100
  lhld drawFilesCountInt_2
  call op_mod16
  mov a, l
  sta drawFilesCountInt_v
  ; 344 print2(a+22, (!(v >= 10 && v < 20) && v % 10 == 1) ? "fajle " : "fajlah ");Сложение
  lhld drawFilesCountInt_a
  lxi d, 22
  dad d
  shld print2_1
  cpi 10
  jc l331
  cpi 20
  jnc l331
  mvi a, 1
  jmp l332
l331:
  xra a
l332:
  ; convertToConfition
  ora a
  jnz l333
  mvi d, 10
  lda drawFilesCountInt_v
  call op_mod
  cpi 1
  jnz l333
  mvi a, 1
  jmp l334
l333:
  xra a
l334:
  ora a
  jz l335
  lxi h, string47
  jmp l336
l335:
  lxi h, string48
l336:
  jmp print2
drawPanel:
  shld drawPanel_1
  ; 350 drawRect(a, 30, ROWS_CNT + 4);
  shld drawRect_1
  mvi a, 30
  sta drawRect_2
  mvi a, 26
  call drawRect
  ; 352 hLine(a + (VIDEO_BPL * (2 + ROWS_CNT) + 1), 0x1C, 29); // hLineСложение
  lhld drawPanel_1
  lxi d, 1921
  dad d
  shld hLine_1
  mvi a, 28
  sta hLine_2
  inr a
  call hLine
  ; 353 vLine(a + (VIDEO_BPL + 15), ROWS_CNT+1, 0x1B);Сложение
  lhld drawPanel_1
  lxi d, 95
  dad d
  shld vLine_1
  mvi a, 23
  sta vLine_2
  mvi a, 27
  call vLine
  ; 354 print2(a + (VIDEO_BPL + 6 ), "imq");Сложение
  lhld drawPanel_1
  lxi d, 86
  dad d
  shld print2_1
  lxi h, string49
  call print2
  ; 355 print2(a + (VIDEO_BPL + 21), "imq");  Сложение
  lhld drawPanel_1
  lxi d, 101
  dad d
  shld print2_1
  lxi h, string49
  jmp print2
drawScreenInt:
  lhld radio86rkVideoMem
  shld fillRect_1
  mvi a, 64
  sta fillRect_2
  mvi a, 30
  sta fillRect_3
  mvi a, 32
  call fillRect
  ; 366 print(1, ROWS_CNT+7, "F1 FREE F2 NEW  F3 VIEW  F4 EDIT F5 COPY F6 REN  F7 DIR  F8 DEL"); 
  mvi a, 1
  sta print_1
  mvi a, 29
  sta print_2
  lxi h, string50
  call print
  ; 369 drawPanel(radio86rkVideoMem + 1);Сложение с константой 1
  lhld radio86rkVideoMem
  inx h
  call drawPanel
  ; 370 drawPanel(radio86rkVideoMem + 33);Сложение
  lhld radio86rkVideoMem
  lxi d, 33
  dad d
  call drawPanel
  ; 373 drawPanelTitle(1);
  mvi a, 1
  call drawPanelTitle
  ; 374 swapPanels();
  call swapPanels
  ; 375 drawPanelTitle(0);
  xra a
  call drawPanelTitle
  ; 376 swapPanels();
  call swapPanels
  ; 379 fileCursorAddr = 0;
  lxi h, 0
  shld fileCursorAddr
  ret
  ; --- drawPanelTitle -----------------------------------------------------------------
drawPanelTitle:
  sta drawPanelTitle_1
  ; 392 hLine((uchar*)charAddr(activePanel + 2, 0), 0x1C, 29);
  lda activePanel
  adi 2
  sta charAddr_1
  xra a
  call charAddr
  shld hLine_1
  mvi a, 28
  sta hLine_2
  inr a
  call hLine
  ; 395 p = panelA.path1;
  lxi h, (panelA)+(2)
  shld drawPanelTitle_p
  ; 396 if(p[0]==0) p = "/";Сложение с константой 0
  mov a, m
  ora a
  jnz l337
  ; 396 p = "/";
  lxi h, string25
  shld drawPanelTitle_p
l337:
  ; 397 l = strlen(p);
  call strlen
  shld drawPanelTitle_l
  ; 398 if(l>=27) p=p+(l-27), l=27;Сложение
  lxi d, 65509
  dad d
  jnc l338
  ; 398 p=p+(l-27), l=27;Сложение
  lhld drawPanelTitle_l
  lxi d, 65509
  dad d
  ; Сложение
  xchg
  lhld drawPanelTitle_p
  dad d
  shld drawPanelTitle_p
  lxi h, 27
  shld drawPanelTitle_l
l338:
  ; 399 x = 2 + (30 - l) / 2 + activePanel;16 битная арифметическая операция с константой
  lhld drawPanelTitle_l
  mvi a, 30
  sub l
  mov l, a
  mvi a, 0
  sbb h
  mov h, a
  lxi d, 2
  call op_div16
  ; Сложение с константой 2
  inx h
  inx h
  ; Сложение
  xchg
  lhld activePanel
  mvi h, 0
  dad d
  mov a, l
  sta drawPanelTitle_x
  ; 400 printn(x, 0, l, p);
  sta printn_1
  xra a
  sta printn_2
  lda drawPanelTitle_l
  sta printn_3
  lhld drawPanelTitle_p
  call printn
  ; 401 if(!active) return;convertToConfition
  lda drawPanelTitle_1
  ora a
  jnz l339
  ; 401 return;
  ret
l339:
  ; 402 print(x-1, 0, "[");
  lda drawPanelTitle_x
  dcr a
  sta print_1
  xra a
  sta print_2
  lxi h, string51
  call print
  ; 403 print(x+l, 0, "]");Сложение
  lhld drawPanelTitle_x
  mvi h, 0
  xchg
  lhld drawPanelTitle_l
  dad d
  mov a, l
  sta print_1
  xra a
  sta print_2
  lxi h, string52
  jmp print
drawFile2:
  shld drawFile2_2
  ; 409 print2n(a, 8, f->fname); 
  lhld drawFile2_1
  shld print2n_1
  mvi a, 8
  sta print2n_2
  lhld drawFile2_2
  call print2n
  ; 410 setaddr(a+8);Сложение
  lhld drawFile2_1
  lxi d, 8
  dad d
  call setaddr
  ; 411 setch((f->fattrib & 0x80) ? '*' : ((f->fattrib & 0x06) ? 0x7F : ' '));Сложение
  lhld drawFile2_2
  lxi d, 11
  dad d
  mov a, m
  ani 128
  jz l340
  mvi a, 42
  jmp l341
l340:
  ; Сложение
  lhld drawFile2_2
  lxi d, 11
  dad d
  mov a, m
  ani 6
  jz l342
  mvi a, 127
  jmp l343
l342:
  mvi a, 32
l343:
l341:
  call setch
  ; 413 print2n(a + 9, 3, f->fname + 8); Сложение
  lhld drawFile2_1
  lxi d, 9
  dad d
  shld print2n_1
  mvi a, 3
  sta print2n_2
  ; Сложение
  lhld drawFile2_2
  lxi d, 8
  dad d
  jmp print2n
drawColumn:
  push b
  sta drawColumn_1
  ; 421 panelA.offset+i*ROWS_CNT;<n>
  mvi d, 22
  call op_mul
  ; Сложение
  xchg
  lhld (panelA)+(260)
  dad d
  mov b, h
  mov c, l
  ; 422 panelA.files1 + n;  <f>
  mov d, h
  mov e, l
  dad h
  dad h
  dad d
  dad h
  dad h
  ; Сложение
  xchg
  lhld panelA
  dad d
  shld drawColumn_f
  ; 424 a = charAddr(i*15+3+activePanel,2);
  mvi d, 15
  lda drawColumn_1
  call op_mul
  ; Сложение с константой 3
  inx h
  inx h
  inx h
  ; Сложение
  xchg
  lhld activePanel
  mvi h, 0
  dad d
  mov a, l
  sta charAddr_1
  mvi a, 2
  call charAddr
  shld drawColumn_a
  ; 425 for(y=ROWS_CNT; y; --y, a+=VIDEO_BPL) {
  mvi a, 22
  sta drawColumn_y
l344:
  ; convertToConfition
  lda drawColumn_y
  ora a
  jz l345
  ; 426 if(n>=panelA.cnt) {
  lhld (panelA)+(262)
  mov d, b
  mov e, c
  call op_cmp16
  jz l348
  jnc l347
l348:
  ; 427 print2cn(a, 12, ' ');
  lhld drawColumn_a
  shld print2cn_1
  mvi a, 12
  sta print2cn_2
  mvi a, 32
  call print2cn
  ; 428 continue;
  jmp l346
l347:
  ; 430 drawFile2(a, f);
  lhld drawColumn_a
  shld drawFile2_1
  lhld drawColumn_f
  call drawFile2
  ; 431 ++f; ++n; 
  lhld drawColumn_f
  lxi d, 20
  dad d
  shld drawColumn_f
  ; 431 ++n; 
  inx b
l346:
  lxi h, drawColumn_y
  dcr m
  ; Сложение
  lxi d, 80
  lhld drawColumn_a
  dad d
  shld drawColumn_a
  jmp l344
l345:
  pop b
  ret
  ; --- drawFile -----------------------------------------------------------------
drawFile:
  shld drawFile_3
  ; 438 drawFile2(charAddr(x*15+3+activePanel, 2+y), f);
  mvi d, 15
  lda drawFile_1
  call op_mul
  ; Сложение с константой 3
  inx h
  inx h
  inx h
  ; Сложение
  xchg
  lhld activePanel
  mvi h, 0
  dad d
  mov a, l
  sta charAddr_1
  lda drawFile_2
  adi 2
  call charAddr
  shld drawFile2_1
  lhld drawFile_3
  jmp drawFile2
drawFileInfo1:
  shld drawFileInfo1_1
  ; 445 printm(3+activePanel, ROWS_CNT+3, 10, buf);
  lda activePanel
  adi 3
  sta printm_1
  mvi a, 25
  sta printm_2
  mvi a, 10
  sta printm_3
  jmp printm
drawFileInfoDir:
  lxi h, string53
  jmp drawFileInfo1
drawFileInfo2:
  shld drawFileInfo2_1
  ; 458 printm(14+activePanel, ROWS_CNT+3, 16, buf);
  lda activePanel
  adi 14
  sta printm_1
  mvi a, 25
  sta printm_2
  mvi a, 16
  sta printm_3
  jmp printm
drawCmdLineWithPath:
  push b
  ; 467 print(1, ROWS_CNT+6, getPalmiraModeStr());
  mvi a, 1
  sta print_1
  mvi a, 28
  sta print_2
  call getPalmiraModeStr
  call print
  ; 470 print(6, ROWS_CNT+6, "/");
  mvi a, 6
  sta print_1
  mvi a, 28
  sta print_2
  lxi h, string25
  call print
  ; 471 l = strlen(panelA.path1);
  lxi h, (panelA)+(2)
  call strlen
  shld drawCmdLineWithPath_l
  ; 472 if(l>=25) o=l-25, l=25; else o=0;Сложение
  lxi d, 65511
  dad d
  jnc l349
  ; 472 o=l-25, l=25; else o=0;Сложение
  lhld drawCmdLineWithPath_l
  lxi d, 65511
  dad d
  mov b, h
  mov c, l
  lxi h, 25
  shld drawCmdLineWithPath_l
  jmp l350
l349:
  ; 472 o=0;
  lxi b, 0
l350:
  ; 473 printn(7, ROWS_CNT+6, l, panelA.path1+o);
  mvi a, 7
  sta printn_1
  mvi a, 28
  sta printn_2
  lda drawCmdLineWithPath_l
  sta printn_3
  ; Сложение с BC
  lxi h, (panelA)+(2)
  dad b
  call printn
  ; 474 print(l+7, ROWS_CNT+6, ">");Сложение
  lhld drawCmdLineWithPath_l
  lxi d, 7
  dad d
  mov a, l
  sta print_1
  mvi a, 28
  sta print_2
  lxi h, string54
  call print
  ; 477 panelA.cmdLineOff = l+8;Сложение
  lhld drawCmdLineWithPath_l
  lxi d, 8
  dad d
  shld (panelA)+(264)
  ; 480 drawCmdLine();
  call drawCmdLine
  pop b
  ret
  ; --- drawWindow -----------------------------------------------------------------
drawWindow:
  push b
  shld drawWindow_1
  ; 489 hideTextCursor();
  call hideTextCursor
  ; 491 fillRect(charAddr(WINDOW_X-5,WINDOW_Y-3), 49, 11, ' ');
  mvi a, 8
  sta charAddr_1
  call charAddr
  shld fillRect_1
  mvi a, 49
  sta fillRect_2
  mvi a, 11
  sta fillRect_3
  mvi a, 32
  call fillRect
  ; 492 drawRect(charAddr(WINDOW_X-4,WINDOW_Y-2), 46, 7);
  mvi a, 9
  sta charAddr_1
  call charAddr
  shld drawRect_1
  mvi a, 46
  sta drawRect_2
  mvi a, 7
  call drawRect
  ; 494 print((64-strlen(title)) >> 1, WINDOW_Y-2, title);
  lhld drawWindow_1
  call strlen
  ; 16 битная арифметическая операция с константой
  mvi a, 64
  sub l
  mov l, a
  mvi a, 0
  sbb h
  mov h, a
  ; Сдвиг на 1 вправо
  mov a, h
  cmp a
  rar
  mov h, a
  mov a, l
  rar
  mov l, a
  mov a, l
  sta print_1
  mvi a, 9
  sta print_2
  lhld drawWindow_1
  call print
  pop b
  ret
  ; --- drawAnyKeyButton -----------------------------------------------------------------
drawAnyKeyButton:
  mvi a, 27
  sta print_1
  mvi a, 15
  sta print_2
  lxi h, string55
  jmp print
drawEscButton:
  mvi a, 25
  sta print_1
  mvi a, 15
  sta print_2
  lxi h, string56
  jmp print
drawWindowText:
  shld drawWindowText_3
  ; 514 printn(WINDOW_X+ox, WINDOW_Y+oy, 40-ox, text);
  lda drawWindowText_1
  adi 13
  sta printn_1
  lda drawWindowText_2
  adi 11
  sta printn_2
  ; Арифметика 3/4
  lxi h, drawWindowText_1
  mvi a, 40
  sub m
  sta printn_3
  lhld drawWindowText_3
  jmp printn
drawWindowProgress:
  sta drawWindowProgress_4
  ; 521 if(n==0) return;
  lda drawWindowProgress_3
  ora a
  jnz l351
  ; 521 return;
  ret
l351:
  ; 522 printcn(WINDOW_X+ox, WINDOW_Y+oy, n, chr);
  lda drawWindowProgress_1
  adi 13
  sta printcn_1
  lda drawWindowProgress_2
  adi 11
  sta printcn_2
  lda drawWindowProgress_3
  sta printcn_3
  lda drawWindowProgress_4
  jmp printcn
drawCmdLine:
  lda (panelA)+(264)
  sta drawInput_1
  mvi a, 28
  sta drawInput_2
  ; 16 битная арифметическая операция с константой
  lhld (panelA)+(264)
  mvi a, 62
  sub l
  mov l, a
  mvi a, 0
  sbb h
  mov h, a
  mov a, l
  jmp drawInput
drawInput:
  push b
  sta drawInput_3
  ; 539 cmdline_pos = strlen(cmdline);
  lxi h, cmdline
  call strlen
  shld drawInput_cmdline_pos
  ; 540 --max;
  lxi h, drawInput_3
  dcr m
  ; 541 if(cmdline_pos < max) cmdline_offset = 0; else cmdline_offset = cmdline_pos-max;
  lhld drawInput_cmdline_pos
  xchg
  lhld drawInput_3
  mvi h, 0
  call op_cmp16
  jc l352
  jz l352
  ; 541 cmdline_offset = 0; else cmdline_offset = cmdline_pos-max;
  lxi h, 0
  shld drawInput_cmdline_offset
  jmp l353
l352:
  ; 541 cmdline_offset = cmdline_pos-max;16 битная арифметическая операция с константой
  lhld drawInput_3
  mvi h, 0
  xchg
  lhld drawInput_cmdline_pos
  mov a, l
  sub e
  mov l, a
  mov a, h
  sbb d
  mov h, a
  shld drawInput_cmdline_offset
l353:
  ; 542 c1 = cmdline_pos - cmdline_offset;16 битная арифметическая операция с константой
  lhld drawInput_cmdline_offset
  xchg
  lhld drawInput_cmdline_pos
  mov a, l
  sub e
  mov l, a
  mov a, h
  sbb d
  mov h, a
  shld drawInput_c1
  ; 543 cmdline[cmdline_pos] = 0;Сложение
  lhld drawInput_cmdline_pos
  lxi d, cmdline
  dad d
  mvi m, 0
  ; 544 ++c1;
  lhld drawInput_c1
  inx h
  shld drawInput_c1
  ; 545 if(c1 > max) c1 = max;
  xchg
  lhld drawInput_3
  mvi h, 0
  call op_cmp16
  jnc l354
  ; 545 c1 = max;
  lhld drawInput_3
  mvi h, 0
  shld drawInput_c1
l354:
  ; 546 ++c1;
  lhld drawInput_c1
  inx h
  shld drawInput_c1
  ; 547 ++max;
  lxi h, drawInput_3
  inr m
  ; 548 printm(x, y, max, cmdline + cmdline_offset);
  lda drawInput_1
  sta printm_1
  lda drawInput_2
  sta printm_2
  lda drawInput_3
  sta printm_3
  ; Сложение
  lhld drawInput_cmdline_offset
  lxi d, cmdline
  dad d
  call printm
  ; 551 showTextCursor(x+cmdline_pos-cmdline_offset, y);Сложение
  lhld drawInput_1
  mvi h, 0
  xchg
  lhld drawInput_cmdline_pos
  dad d
  ; 16 битная арифметическая операция с константой
  xchg
  lhld drawInput_cmdline_offset
  xchg
  mov a, l
  sub e
  mov l, a
  mov a, h
  sbb d
  mov h, a
  mov a, l
  sta showTextCursor_1
  lda drawInput_2
  call showTextCursor
  pop b
  ret
  ; --- drawWindowInput -----------------------------------------------------------------
drawWindowInput:
  sta drawWindowInput_3
  ; 557 drawInput(WINDOW_X+x, WINDOW_Y+y, max);
  lda drawWindowInput_1
  adi 13
  sta drawInput_1
  lda drawWindowInput_2
  adi 11
  sta drawInput_2
  lda drawWindowInput_3
  jmp drawInput
getch1:
  jmp 63491
  ret
  ; --- bioskey1 -----------------------------------------------------------------
bioskey1:
  jmp 63515
  ret
  ; --- memswap -----------------------------------------------------------------
memswap:
  shld memswap_3
  ; 2 asm {
    push b
    ; de = count
    xchg
    ; bc = from
    lhld memswap_2
    mov c, l
    mov b, h
    ; hl = to
    lhld memswap_1
memswap_l1:
    ; if(cnt==0) return
    mov a, d
    ora e
    jz memswap_l2
    ; *dest = *src
    ldax b
    sta memswap_v1
    mov a, m
    stax b
    .db 36h ; mvi m, 0
memswap_v1:
    .db 0    
    ; dest++, src++, cnt--
    inx h
    inx b
    dcx d
    ; loop
    jmp memswap_l1
memswap_l2:
    pop b
  
  ret
  ; --- op_mul -----------------------------------------------------------------
op_mul:
  push b
  lxi h, 0
  mov e, d  ; de=d
  mov d, l  
  mvi c, 8
op_mul1:
  dad h
  add a
  jnc op_mul2
    dad d
op_mul2:
  dcr c
  jnz op_mul1
pop_bc_ret:
  pop b

  ret
  ; --- op_cmp16 -----------------------------------------------------------------
op_cmp16:
    mov a, h
    cmp d
    rnz
    mov a, l
    cmp e
  
  ret
  ; --- i2s32 -----------------------------------------------------------------
i2s32:
  sta i2s32_4
  ; 7 set32(&v, src);
  lxi h, i2s32_v
  shld set32_1
  lhld i2s32_2
  call set32
  ; 9 buf += n;  Сложение
  lhld i2s32_3
  xchg
  lhld i2s32_1
  dad d
  shld i2s32_1
  ; 10 *buf = 0;
  mvi m, 0
  ; 12 while(1) {
l355:
  ; 13 div32_16(&v, 10);
  lxi h, i2s32_v
  shld div32_16_1
  lxi h, 10
  call div32_16
  ; 14 --buf;
  lhld i2s32_1
  dcx h
  shld i2s32_1
  ; 15 *buf = "0123456789ABCDEF"[op_div16_mod];Сложение
  lhld op_div16_mod
  lxi d, string57
  dad d
  mov a, m
  lhld i2s32_1
  mov m, a
  ; 16 if(--n == 0) return;
  lhld i2s32_3
  dcx h
  shld i2s32_3
  ; Сложение с константой 0
  mov a, l
  ora h
  jnz l357
  ; 16 return;
  ret
l357:
  ; 17 if(((ushort*)&v)[0] == 0 && ((ushort*)&v)[1] == 0) break;Сложение с константой 0
  lhld (i2s32_v)+(0)
  mov a, l
  ora h
  jnz l358
  ; Сложение с константой 0
  lhld (i2s32_v)+(2)
  mov a, l
  ora h
  jz l356
l358:
  jmp l355
l356:
  ; 20 while(1) {
l359:
  ; 21 --buf;
  lhld i2s32_1
  dcx h
  shld i2s32_1
  ; 22 *buf = spc;
  lda i2s32_4
  mov m, a
  ; 23 if(--n == 0) break;
  lhld i2s32_3
  dcx h
  shld i2s32_3
  ; Сложение с константой 0
  mov a, l
  ora h
  jz l360
  jmp l359
l360:
  ret
  ; --- i2s -----------------------------------------------------------------
i2s:
  sta i2s_4
  ; 4 buf += n;  Сложение
  lhld i2s_3
  xchg
  lhld i2s_1
  dad d
  shld i2s_1
  ; 5 *buf = 0;
  mvi m, 0
  ; 6 while(1) {
l362:
  ; 7 v /= 10;
  lxi d, 10
  lhld i2s_2
  call op_div16
  shld i2s_2
  ; 8 --buf;
  lhld i2s_1
  dcx h
  shld i2s_1
  ; 9 *buf = "0123456789ABCDEF"[op_div16_mod];Сложение
  lhld op_div16_mod
  lxi d, string57
  dad d
  mov a, m
  lhld i2s_1
  mov m, a
  ; 10 --n;
  lhld i2s_3
  dcx h
  shld i2s_3
  ; 11 if(n == 0) return;Сложение с константой 0
  mov a, l
  ora h
  jnz l364
  ; 11 return;
  ret
l364:
  ; 12 if(v == 0) break;Сложение с константой 0
  lhld i2s_2
  mov a, l
  ora h
  jz l363
  jmp l362
l363:
  ; 14 while(1) {
l366:
  ; 15 --buf;
  lhld i2s_1
  dcx h
  shld i2s_1
  ; 16 *buf = spc;
  lda i2s_4
  mov m, a
  ; 17 if(--n == 0) break;
  lhld i2s_3
  dcx h
  shld i2s_3
  ; Сложение с константой 0
  mov a, l
  ora h
  jz l367
  jmp l366
l367:
  ret
  ; --- op_shr16 -----------------------------------------------------------------
op_shr16:
  inr e
op_shr16_l:
  dcr e
  rz
  sub a
  ora h 
  rar
  mov h, a
  mov a, l
  rar
  mov l, a
  jmp op_shr16_l

  ret
  ; --- add32_32 -----------------------------------------------------------------
add32_32:
  shld add32_32_2
  ; 4 asm {   
   
    ; hl = add32_32_2   
    xchg
    lhld add32_32_1
    xchg

    ldax d
    add  m
    stax d
    inx  h
    inx  d
    ldax d
    adc  m
    stax d
    inx  h
    inx  d
    ldax d
    adc  m
    stax d
    inx  h
    inx  d
    ldax d
    adc  m
    stax d
  
  ret
  ; --- strlen -----------------------------------------------------------------
strlen:
  shld strlen_1
  ; 2 asm { 
 
    lxi d, -1
strlen_l1:
    xra a
    ora m
    inx d
    inx h
    jnz strlen_l1
    xchg
  
  ret
  ; --- memcmp -----------------------------------------------------------------
memcmp:
  shld memcmp_3
  ; 2 asm {
    ; if(len==0) return 0;
    mov a, l
    ora h
    rz
    push b
    ; de = len
    xchg
    ; bc = d
    lhld memcmp_1
    mov b, h
    mov c, l
    ; hl = s
    lhld memcmp_2
    ; loop
memcmp_l1:
      ldax b
      cmp m
      jnz memcmp_stop
      inx h
      inx b
      dcx d
      mov a, d
      ora e
    jnz memcmp_l1
    pop b
    ; a=0
    ret
memcmp_stop:
    pop b
    sbb a
    rc
    inr a
    ret
  
  ret
  ; --- op_div16 -----------------------------------------------------------------
op_div16:
        PUSH B
        XCHG
        CALL _DIV0
        XCHG
        SHLD op_div16_mod
        XCHG
        POP B
        RET

_DIV0:
_DIV:	MOV A,H
	ORA L
	RZ
	LXI B,0000
	PUSH B
_DIV1:	MOV A,E
	SUB L
	MOV A,D
	SBB H
	JC _DIV2
	PUSH H
	DAD H
	JNC _DIV1
_DIV2:	LXI H,0000
_DIV3:	POP B
	MOV A,B
	ORA C
	RZ
	DAD H
	PUSH D
	MOV A,E
	SUB C
	MOV E,A
	MOV A,D
	SBB B
	MOV D,A
	JC _DIV4
	INX H
	POP B
	JMP _DIV3
_DIV4:	POP D
	JMP _DIV3  
  
  ret
  ; --- memset -----------------------------------------------------------------
memset:
  shld memset_3
  ; 2 asm {
    push b
    lda memset_2
    xchg
    lhld memset_1
    xchg
    lxi b, -1    
memset_l1:
    dad b
    jnc memset_l2
    stax d
    inx d
    jmp memset_l1
memset_l2:
    pop b
  
  ret
  ; --- memcpy -----------------------------------------------------------------
memcpy:
  shld memcpy_3
  ; 2 asm {
    ; if(cnt==0) return
    mov a, h
    ora l
    rz
    ; start
    push b
    ; de = count
    xchg
    ; bc = from
    lhld memcpy_2
    mov c, l
    mov b, h
    ; hl = to
    lhld memcpy_1
    ; enter loop
    inr d
    xra a
    ora e
    jz memcpy_l2
memcpy_l1:
    ; *dest = *src
    ldax b
    mov m, a
    ; dest++, src++
    inx h
    inx b
    ; while(--cnt)
    dcr e
    jnz memcpy_l1
memcpy_l2:
    dcr d
    jnz memcpy_l1
    pop b
  
  ret
  ; --- fs_findfirst -----------------------------------------------------------------
fs_findfirst:
  shld fs_findfirst_3
  ; 4 if(path[0] == '/') path++;Сложение с константой 0
  lhld fs_findfirst_1
  mov a, m
  cpi 47
  jnz l369
  ; 4 path++;
  mov d, h
  mov e, l
  inx h
  shld fs_findfirst_1
  xchg
l369:
  ; 5 asm {
    PUSH B
    ; hl = fs_findfirst_3
    XCHG
    LHLD fs_findfirst_2
    MOV  B, H  
    MOV  C, L
    LHLD fs_findfirst_1 
    MVI  A, 1
    CALL fs_entry
    SHLD fs_low
    POP  B
  
  ret
  ; --- op_mod16 -----------------------------------------------------------------
op_mod16:
  call op_div16
  ; 5 asm {
    lhld op_div16_mod;
  
  ret
  ; --- strcpy -----------------------------------------------------------------
strcpy:
  shld strcpy_2
  ; 2 asm {
    ; de = src
    xchg
    ; hl = to
    lhld strcpy_1
strcpy_l1:
    ; *dest = *src
    ldax d
    mov m, a
    ora a
    inx h
    inx d
    jnz strcpy_l1
    dcx h
  
  ret
  ; --- memcpy_back -----------------------------------------------------------------
memcpy_back:
  shld memcpy_back_3
  ; 2 asm {
    ; if(cnt==0) return
    mov a, h
    ora l
    rz
    ; start
    push b
    ; de = count
    xchg
    ; bc = from
    lhld memcpy_back_2
    dad d
    mov c, l
    mov b, h
    ; hl = to
    lhld memcpy_back_1
    dad d
    ; enter loop
    inr d
    xra a
    ora e
    jz memcpy_back_l2
memcpy_back_l1:
    ; dest--, src--
    dcx h
    dcx b
    ; *dest = *src
    ldax b
    mov m, a
    ; while(cnt)
    dcr e
    jnz memcpy_back_l1
memcpy_back_l2:
    dcr d
    jnz memcpy_back_l1
    pop b
  
  ret
  ; --- strchr -----------------------------------------------------------------
strchr:
  sta strchr_2
  ; 2 asm {
    mov d, a
    lhld strchr_1
strchr_l1:
    ; *dest = *src    
    mov a, m
    cmp d
    rz
    inx h
    ora a
    jnz strchr_l1
    mov h, a
    mov l, a
  
  ret
  ; --- strcmp -----------------------------------------------------------------
strcmp:
  shld strcmp_2
  ; 3 while(1) {
l370:
  ; 4 a=*d, b=*s;
  lhld strcmp_1
  mov a, m
  sta strcmp_a
  lhld strcmp_2
  mov a, m
  sta strcmp_b
  ; 5 if(a < b) return 255;
  lxi h, strcmp_b
  lda strcmp_a
  cmp m
  jnc l372
  ; 5 return 255;
  mvi a, 255
  ret
l372:
  ; 6 if(b < a) return 1;
  lxi h, strcmp_a
  lda strcmp_b
  cmp m
  jnc l373
  ; 6 return 1;
  mvi a, 1
  ret
l373:
  ; 7 if(*d==0) return 0;
  lhld strcmp_1
  mov a, m
  ora a
  jnz l374
  ; 7 return 0;
  xra a
  ret
l374:
  ; 8 ++d, ++s;
  inx h
  shld strcmp_1
  lhld strcmp_2
  inx h
  shld strcmp_2
  jmp l370
l371:
  ret
  ; --- op_mul16 -----------------------------------------------------------------
op_mul16:
  push b
  mov b, h
  mov c, l
  lxi h, 0
  mvi a, 17
op_mul16_1:
  dcr a
  jz pop_bc_ret
  dad h
  xchg
  jnc op_mul16_2
  dad h
  inx h
  jmp op_mul16_3
op_mul16_2:
  dad h
op_mul16_3:
  xchg
  jnc op_mul16_1
  dad b
  jnc op_mul16_1
  inx d
  jmp op_mul16_1

  ret
  ; --- fs_open -----------------------------------------------------------------
fs_open:
  shld fs_open_1
  ; 5 return fs_open0(name, O_OPEN);
  shld fs_open0_1
  xra a
  jmp fs_open0
  ret
  ; --- fs_read -----------------------------------------------------------------
fs_read:
  shld fs_read_2
  ; 4 asm {
    PUSH B
    ; hl = fs_read_2
    XCHG
    LHLD fs_read_1
    XCHG
    MVI  A, 4
    CALL fs_entry ; HL-размер, DE-адрес / HL-сколько загрузили, A-код ошибки
    SHLD fs_low
    POP  B    
  
  ret
  ; --- fs_create -----------------------------------------------------------------
fs_create:
  shld fs_create_1
  ; 5 return fs_open0(name, O_CREATE);
  shld fs_open0_1
  mvi a, 1
  jmp fs_open0
  ret
  ; --- fs_write -----------------------------------------------------------------
fs_write:
  shld fs_write_2
  ; 4 asm {
    PUSH B
    ; hl = fs_write_2
    XCHG
    LHLD fs_write_1
    XCHG
    LDA  fs_addr
    MVI  A, 5
    CALL fs_entry ; HL-размер, DE-адрес / A-код ошибки
    POP  B    
  
  ret
  ; --- fs_exec -----------------------------------------------------------------
fs_exec:
  shld fs_exec_2
  ; 4 asm {    
    
    PUSH B
    XCHG
    LHLD fs_exec_1
    XRA  A
    CALL fs_entry
    POP  B
  
  ret
  ; --- fs_init -----------------------------------------------------------------
fs_init:
    SHLD fs_cmdLine
    XCHG
    SHLD fs_selfName
    MOV H, B
    MOV L, C
    SHLD fs_entry_n+1
  
  ret
  ; --- fs_entry -----------------------------------------------------------------
fs_entry:
fs_entry_n:
    JMP 0000h
  
  ret
  ; --- fs_getsize -----------------------------------------------------------------
fs_getsize:
  lxi h, 0
  shld fs_seek_1
  shld fs_seek_2
  mvi a, 100
  jmp fs_seek
  ret
  ; --- set32 -----------------------------------------------------------------
set32:
  shld set32_2
  ; 4 asm {
    xchg ; de = set32_2
    lhld set32_1
    ldax d
    mov m, a
    inx h
    inx d
    ldax d
    mov m, a
    inx h
    inx d
    ldax d
    mov m, a
    inx h
    inx d
    ldax d
    mov m, a
  
  ret
  ; --- div32_16 -----------------------------------------------------------------
div32_16:
  shld div32_16_2
  ; 9 ((ushort*)a)[1] = ((ushort*)a)[1] / b;Сложение с константой 2
  lhld div32_16_1
  inx h
  inx h
  ; Сложение с константой 2
  push h
  lhld div32_16_1
  inx h
  inx h
  xchg
  lhld div32_16_2
  xchg
  mov a, m
  inx h
  mov h, m
  mov l, a
  call op_div16
  pop d
  xchg
  mov m, e
  inx h
  mov m, d
  dcx h
  ; 11 ((uchar*)&tmp)[1] = op_div16_mod;
  lda op_div16_mod
  sta (div32_16_tmp)+(1)
  ; 12 ((uchar*)&tmp)[0] = ((uchar*)a)[1];Сложение с константой 1
  lhld div32_16_1
  inx h
  mov a, m
  sta (div32_16_tmp)+(0)
  ; 13 ((uchar*)a)[1] = tmp / b;Сложение с константой 1
  lhld div32_16_1
  inx h
  xchg
  lhld div32_16_2
  xchg
  push h
  lhld div32_16_tmp
  call op_div16
  mov a, l
  pop h
  mov m, a
  ; 15 ((uchar*)&tmp)[1] = op_div16_mod;
  lda op_div16_mod
  sta (div32_16_tmp)+(1)
  ; 16 ((uchar*)&tmp)[0] = ((uchar*)a)[0];Сложение с константой 0
  lhld div32_16_1
  mov a, m
  sta (div32_16_tmp)+(0)
  ; 17 ((uchar*)a)[0] = tmp / b;Сложение с константой 0
  xchg
  lhld div32_16_2
  xchg
  push h
  lhld div32_16_tmp
  call op_div16
  mov a, l
  pop h
  mov m, a
  ret
  ; --- fs_swap -----------------------------------------------------------------
fs_swap:
  lxi h, string17
  shld fs_open0_1
  mvi a, 101
  jmp fs_open0
  ret
  ; --- add32_16 -----------------------------------------------------------------
add32_16:
  shld add32_16_2
  ; 4 asm {
    ; de = *to
    lhld add32_16_1
    mov e, m
    inx h
    mov d, m

    ; hl = de + from
    lhld add32_16_2
    dad d

    ; *hl = de
    xchg
    lhld add32_16_1
    mov m, e
    inx h
    mov m, d     

    ; …б«Ё ЇҐаҐЇ®«­Ґ­ЁҐ, в® гўҐ«ЁзЁў Ґ¬ ўҐае­Ё© а §ап¤
    rnc
    inx h
    inr m    

    ; …б«Ё ЇҐаҐЇ®«­Ґ­ЁҐ, в® гўҐ«ЁзЁў Ґ¬ ўҐае­Ё© а §ап¤
    rnz
    inx h
    inr m
  
  ret
  ; --- cmp32_32 -----------------------------------------------------------------
cmp32_32:
  shld cmp32_32_2
  ; 4 asm {
    lhld cmp32_32_1
    inx h
    inx h
    inx h
    xchg

    lhld cmp32_32_2
    inx h
    inx h
    inx h
  
    ldax d
    cmp m
    jnz cmp32_32_l0
   
    dcx h
    dcx d
    ldax d
    cmp m
    jnz cmp32_32_l0
    
    dcx h
    dcx d
    ldax d
    cmp m
    jnz cmp32_32_l0

    dcx h
    dcx d
    ldax d
    cmp m
    rz

cmp32_32_l0:   
    cmc
    sbb a
    ori 1
    ret
  
  ret
  ; --- sub32_32 -----------------------------------------------------------------
sub32_32:
  shld sub32_32_2
  ; 4 asm {
    lhld sub32_32_1
    xchg
    lhld sub32_32_2
  
    ldax d
    sub m
    stax d
   
    inx h
    inx d
    ldax d
    sbb m
    stax d
    
    inx h
    inx d
    ldax d
    sbb m
    stax d

    inx h
    inx d
    ldax d
    sbb m
    stax d
  
  ret
  ; --- fs_delete -----------------------------------------------------------------
fs_delete:
  shld fs_delete_1
  ; 5 return fs_open0(name, O_DELETE);
  shld fs_open0_1
  mvi a, 100
  jmp fs_open0
  ret
  ; --- fs_mkdir -----------------------------------------------------------------
fs_mkdir:
  shld fs_mkdir_1
  ; 5 return fs_open0(name, O_MKDIR);
  shld fs_open0_1
  mvi a, 2
  jmp fs_open0
  ret
  ; --- fs_move -----------------------------------------------------------------
fs_move:
  shld fs_move_2
  ; 4 asm {
    PUSH B
    XCHG
    LHLD fs_move_1
    MVI  A, 6
    CALL fs_entry ; HL-из, DE-в / A-код ошибки
    POP  B
  
  ret
  ; --- fs_getfree -----------------------------------------------------------------
fs_getfree:
  lxi h, 0
  shld fs_seek_1
  shld fs_seek_2
  mvi a, 102
  jmp fs_seek
  ret
  ; --- fs_gettotal -----------------------------------------------------------------
fs_gettotal:
  lxi h, 0
  shld fs_seek_1
  shld fs_seek_2
  mvi a, 101
  jmp fs_seek
  ret
  ; --- gotoxy -----------------------------------------------------------------
gotoxy:
  sta gotoxy_2
  ; 4 putch(0x1B);
  mvi a, 27
  call putch
  ; 5 putch('Y');
  mvi a, 89
  call putch
  ; 6 putch(y+0x20);
  lda gotoxy_2
  adi 32
  call putch
  ; 7 putch(x+0x20);
  lda gotoxy_1
  adi 32
  jmp putch
clrscr:
    mvi c, 1Fh
    call 0F809h
  
  ret
  ; --- charAddr -----------------------------------------------------------------
charAddr:
  sta charAddr_2
  ; 4 return radio86rkVideoMem + y * radio86rkVideoBpl + x;
  lxi h, radio86rkVideoBpl
  mov d, m
  call op_mul
  ; Сложение
  xchg
  lhld radio86rkVideoMem
  dad d
  ; Сложение
  xchg
  lhld charAddr_1
  mvi h, 0
  dad d
  ret
  ; --- print2 -----------------------------------------------------------------
print2:
  shld print2_2
  ; 4 asm {
    xchg
    lhld print2_1
    di
    mov  a,l
    out  98h+1
    mov  a,h
    ori  40h
    out  98h+1
    ei
print2_loop:
    ldax d
    ora  a
    rz
    out   98h
    ;ani  07Fh
    ;mov  m, a
    ;inx  h
    inx  d
    jmp  print2_loop
  
  ret
  ; --- op_mod -----------------------------------------------------------------
op_mod:
    PUSH B
    MOV E, A
    LXI H, 8
    MVI C, 0
op_mod_1:
    MOV A,E
    RAL
    MOV E,A
    MOV A,C
    RAL
    SUB D
    JNC op_mod_2
    ADD D
op_mod_2:
    MOV C,A ; Остаток в С
    CMC
    MOV A,H
    RAL
    MOV H,A ; Частное в Н
    DCR L
    JNZ op_mod_1
    MOV A, C
    POP B
  
  ret
  ; --- print -----------------------------------------------------------------
print:
  shld print_3
  ; 4 print2(charAddr(x, y), text);
  lda print_1
  sta charAddr_1
  lda print_2
  call charAddr
  shld print2_1
  lhld print_3
  jmp print2
printn:
  shld printn_4
  ; 4 print2n(charAddr(x, y), len, text);
  lda printn_1
  sta charAddr_1
  lda printn_2
  call charAddr
  shld print2n_1
  lda printn_3
  sta print2n_2
  lhld printn_4
  jmp print2n
print2n:
  shld print2n_3
  ; 4 asm {
    push b
    xchg
    lhld print2n_1
    mov  a,l
    out  98h + 1
    mov  a,h
    ori  40h
    out  98h + 1
    lda print2n_2
    mov b, a
print2n_loop:
    ldax d
    ora  a
    jz   print2n_ret
    ;ani  07Fh
    ;mov  m, a
    ;inx  h
    out  98h
    inx  d
    dcr b
    jnz  print2n_loop 
print2n_ret:
    pop b
  
  ret
  ; --- print2cn -----------------------------------------------------------------
print2cn:
  sta print2cn_3
  ; 4 asm {
    ;ani  07Fh
    mov  e, a
    lda  print2cn_2
    mov  d, a
    lhld print2cn_1
    mov  a, l
    out  98h + 1
    mov  a, h
    ori  40h
    out  98h + 1
    mov  a,e
print2cn_loop:
    ;mov  m, d
    ;inx  h
    out  98h
    dcr  d
    jnz  print2cn_loop
  
  ret
  ; --- printm -----------------------------------------------------------------
printm:
  shld printm_4
  ; 4 print2m(charAddr(x, y), len, text);
  lda printm_1
  sta charAddr_1
  lda printm_2
  call charAddr
  shld print2m_1
  lda printm_3
  sta print2m_2
  lhld printm_4
  jmp print2m
printcn:
  sta printcn_4
  ; 4 print2cn(charAddr(x, y),len, c);
  lda printcn_1
  sta charAddr_1
  lda printcn_2
  call charAddr
  shld print2cn_1
  lda printcn_3
  sta print2cn_2
  lda printcn_4
  jmp print2cn
fs_open0:
  sta fs_open0_2
  ; 5 asm {      
      
    PUSH B
    ; a = fs_open0_2
    MOV  D, A 
    LHLD fs_open0_1
    MVI  A, 2
    CALL fs_entry
    POP  B
  
  ret
  ; --- fs_seek -----------------------------------------------------------------
fs_seek:
  sta fs_seek_3
  ; 4 asm {
    PUSH B
    ; a = fs_seek_3
    MOV  B, A
    LHLD fs_seek_2
    XCHG
    LHLD fs_seek_1
    MVI  A, 3
    CALL fs_entry ; B-режим, DE:HL-имя файла / A-код ошибки, DE:HL-позиция
    SHLD fs_low
    XCHG
    SHLD fs_high
    POP  B
  
  ret
  ; --- putch -----------------------------------------------------------------
putch:
    mov c, a
    call 0F809h
  
  ret
  ; --- print2m -----------------------------------------------------------------
print2m:
  shld print2m_3
  ; 4 asm {
    push b
    xchg
    lhld print2m_1
    mov  a,l
    out  98h + 1
    mov  a,h
    ori  40h
    out  98h + 1
    lda print2m_2
    mov b, a
print2m_loop:
    ldax d
    ora  a
    jz   print2m_ret
    inx  d
print2m_ret:
    ;ani  07Fh
    ;mov  m, a
    out  98h
    ;inx  h
    dcr b
    jnz  print2m_loop 
    pop b
  
  ret
editorApp:
  .db 66,79,79,84,47,69,68,73,84,46,82,75


  .db 0

viewerApp:
  .db 66,79,79,84,47,86,73,69,87,46,82,75


  .db 0

panelA:
 .ds 266
panelB:
 .ds 266
cmdline:
 .ds 256
maxFiles:
 .ds 2
mode:
 .ds 1
setPalmiraMode_1:
 .ds 1
parentDir:
 .db 46
 .db 46
 .db 32
 .db 32
 .db 32
 .db 32
 .db 32
 .db 32
 .db 32
 .db 32
 .db 32
 .db 16
 .db 0
 .db 0
 .db 0
 .db 0
 .db 0
 .db 0
 .db 0
 .db 0

getSel_n:
 .ds 2
getSelNoBack_f:
 .ds 2
drawFileInfo_f:
 .ds 2
drawFileInfo_buf:
 .ds 18
drawFilesCount_total:
 .ds 4
drawFilesCount_i:
 .ds 2
drawFilesCount_filesCnt:
 .ds 2
drawFilesCount_p:
 .ds 2
processInput_1:
 .ds 1
drawError_1:
 .ds 2
drawError_2:
 .ds 1
drawError_buf:
 .ds 4
inputBox_1:
 .ds 2
confirm_1:
 .ds 2
confirm_2:
 .ds 2
unpackName_1:
 .ds 2
unpackName_2:
 .ds 2
catPathAndUnpack_1:
 .ds 2
catPathAndUnpack_2:
 .ds 2
catPathAndUnpack_len:
 .ds 2
nextSelectedCnt:
 .ds 2
nextSelectedFile:
 .dw $+2
 .ds 20
getFirstSelected_1:
 .ds 2
getFirstSelected_type:
 .ds 1
getNextSelected_1:
 .ds 2
cmpFileInfo_1:
 .ds 2
cmpFileInfo_2:
 .ds 2
sort_1:
 .ds 2
sort_2:
 .ds 2
sort_i:
 .ds 2
sort_j:
 .ds 2
sort_x:
 .ds 2
sort_st_:
 .ds 512
sort_st:
 .ds 2
sort_stc:
 .ds 1
packName_1:
 .ds 2
packName_2:
 .ds 2
packName_i:
 .ds 1
getFiles_f:
 .ds 2
getFiles_st:
 .ds 2
getFiles_n:
 .ds 2
getFiles_i:
 .ds 1
getFiles_j:
 .ds 2
getFiles_dir:
 .ds 20
selectFile_1:
 .ds 2
selectFile_f:
 .ds 2
reloadFiles_1:
 .ds 2
absolutePath_1:
 .ds 2
absolutePath_l:
 .ds 2
getName_1:
 .ds 2
getName_p:
 .ds 2
dropPathInt_1:
 .ds 2
dropPathInt_2:
 .ds 2
dropPathInt_p:
 .ds 2
dropPath_buf:
 .ds 11
cursor_right_w:
 .ds 2
dupFiles_1:
 .ds 1
loadState_i:
 .ds 2
run_1:
 .ds 2
run_2:
 .ds 2
run_e:
 .ds 1
cmd_editview_1:
 .ds 2
cmd_editview_f:
 .ds 2
cmd_enter_d:
 .ds 2
cmd_enter_i:
 .ds 1
cmd_enter_f:
 .ds 2
cmd_enter_l:
 .ds 2
cmd_enter_o:
 .ds 2
cmd_inverseOne_f:
 .ds 2
cmd_inverseAll_f:
 .ds 2
cmd_inverseAll_i:
 .ds 2
cmd_copyFile_1:
 .ds 2
cmd_copyFile_2:
 .ds 2
cmd_copyFile_buf:
 .ds 16
cmd_copyFile_e:
 .ds 1
cmd_copyFile_progress_i:
 .ds 1
cmd_copyFile_progress:
 .ds 4
cmd_copyFile_progress_x:
 .ds 4
cmd_copyFile_progress_step:
 .ds 4
applyMask1_1:
 .ds 2
applyMask1_2:
 .ds 2
applyMask1_3:
 .ds 1
cmd_copyFolder_1:
 .ds 2
cmd_copyFolder_2:
 .ds 2
cmd_copyFolder_e:
 .ds 1
cmd_copyFolder_i:
 .ds 2
cmd_copyFolder_level:
 .ds 1
cmd_copyFolder_stack:
 .ds 16
cmd_copyFolder_f:
 .ds 2
applyMask_1:
 .ds 2
applyMask_2:
 .ds 2
cmd_copymove1_1:
 .ds 1
cmd_copymove1_2:
 .ds 1
cmd_copymove1_name:
 .ds 2
cmd_copymove1_e:
 .ds 1
cmd_copymove1_f:
 .ds 2
cmd_copymove1_sourceFile:
 .ds 256
cmd_copymove1_mask:
 .ds 11
cmd_copymove1_forMask:
 .ds 11
cmd_copymove1_type:
 .ds 1
cmd_copymove1_i:
 .ds 2
cmd_copymove_1:
 .ds 1
cmd_copymove_2:
 .ds 1
cmd_new1_1:
 .ds 1
cmd_new_1:
 .ds 1
cmd_freespace_1_1:
 .ds 1
cmd_freespace_1_2:
 .ds 2
cmd_freespace_1_buf:
 .ds 17
cmd_freespace_e:
 .ds 1
cmd_deleteFolder_level:
 .ds 1
cmd_deleteFolder_e:
 .ds 1
cmd_deleteFolder_p:
 .ds 2
cmd_deleteFolder_i:
 .ds 2
cmd_delete_e:
 .ds 1
cmd_delete_needRefresh2:
 .ds 1
compareMask1_1:
 .ds 2
compareMask1_2:
 .ds 2
compareMask1_3:
 .ds 1
compareMask_1:
 .ds 2
compareMask_2:
 .ds 2
cmd_sel_1:
 .ds 1
cmd_sel_f:
 .ds 2
cmd_sel_i:
 .ds 2
cmd_sel_buf:
 .ds 11
activePanel:
 .ds 1
fileCursorAddr:
 .dw $+2
 .ds 1
showTextCursor_1:
 .ds 1
showTextCursor_2:
 .ds 1
setaddr_1:
 .ds 2
setch_1:
 .ds 1
hLine_1:
 .ds 2
hLine_2:
 .ds 1
hLine_3:
 .ds 1
vLine_1:
 .ds 2
vLine_2:
 .ds 1
vLine_3:
 .ds 1
attrHidden:
 .db 244

attrShow:
 .db 79

drawRect_1:
 .ds 2
drawRect_2:
 .ds 1
drawRect_3:
 .ds 1
drawRect_i:
 .ds 1
fillRect_1:
 .ds 2
fillRect_2:
 .ds 1
fillRect_3:
 .ds 1
fillRect_4:
 .ds 1
buf:
 .ds 16
drawFilesCountInt_1:
 .ds 2
drawFilesCountInt_2:
 .ds 2
drawFilesCountInt_v:
 .ds 1
drawFilesCountInt_a:
 .ds 2
drawPanel_1:
 .ds 2
drawPanelTitle_1:
 .ds 1
drawPanelTitle_p:
 .ds 2
drawPanelTitle_l:
 .ds 2
drawPanelTitle_x:
 .ds 1
drawFile2_1:
 .ds 2
drawFile2_2:
 .ds 2
drawColumn_1:
 .ds 1
drawColumn_a:
 .ds 2
drawColumn_y:
 .ds 1
drawColumn_f:
 .ds 2
drawFile_1:
 .ds 1
drawFile_2:
 .ds 1
drawFile_3:
 .ds 2
drawFileInfo1_1:
 .ds 2
drawFileInfo2_1:
 .ds 2
drawCmdLineWithPath_l:
 .ds 2
drawCmdLineWithPath_old:
 .ds 2
drawWindow_1:
 .ds 2
drawWindowText_1:
 .ds 1
drawWindowText_2:
 .ds 1
drawWindowText_3:
 .ds 2
drawWindowProgress_1:
 .ds 1
drawWindowProgress_2:
 .ds 1
drawWindowProgress_3:
 .ds 1
drawWindowProgress_4:
 .ds 1
drawInput_1:
 .ds 1
drawInput_2:
 .ds 1
drawInput_3:
 .ds 1
drawInput_c1:
 .ds 2
drawInput_old:
 .ds 2
drawInput_cmdline_offset:
 .ds 2
drawInput_cmdline_pos:
 .ds 2
drawWindowInput_1:
 .ds 1
drawWindowInput_2:
 .ds 1
drawWindowInput_3:
 .ds 1
memswap_1:
 .ds 2
memswap_2:
 .ds 2
memswap_3:
 .ds 2
i2s32_1:
 .ds 2
i2s32_2:
 .ds 2
i2s32_3:
 .ds 2
i2s32_4:
 .ds 1
i2s32_v:
 .ds 4
i2s_1:
 .ds 2
i2s_2:
 .ds 2
i2s_3:
 .ds 2
i2s_4:
 .ds 1
add32_32_1:
 .ds 2
add32_32_2:
 .ds 2
strlen_1:
 .ds 2
memcmp_1:
 .ds 2
memcmp_2:
 .ds 2
memcmp_3:
 .ds 2
op_div16_mod:
 .ds 2
memset_1:
 .ds 2
memset_2:
 .ds 1
memset_3:
 .ds 2
memcpy_1:
 .ds 2
memcpy_2:
 .ds 2
memcpy_3:
 .ds 2
fs_findfirst_1:
 .ds 2
fs_findfirst_2:
 .ds 2
fs_findfirst_3:
 .ds 2
strcpy_1:
 .ds 2
strcpy_2:
 .ds 2
memcpy_back_1:
 .ds 2
memcpy_back_2:
 .ds 2
memcpy_back_3:
 .ds 2
strchr_1:
 .ds 2
strchr_2:
 .ds 1
strcmp_1:
 .ds 2
strcmp_2:
 .ds 2
strcmp_a:
 .ds 1
strcmp_b:
 .ds 1
fs_open_1:
 .ds 2
fs_read_1:
 .ds 2
fs_read_2:
 .ds 2
fs_create_1:
 .ds 2
fs_write_1:
 .ds 2
fs_write_2:
 .ds 2
fs_exec_1:
 .ds 2
fs_exec_2:
 .ds 2
fs_cmdLine:
 .dw $+2
 .ds 1
fs_selfName:
 .dw $+2
 .ds 1
fs_low:
 .ds 2
fs_high:
 .ds 2
fs_addr:
 .ds 1
set32_1:
 .ds 2
set32_2:
 .ds 2
div32_16_1:
 .ds 2
div32_16_2:
 .ds 2
div32_16_tmp:
 .ds 2
add32_16_1:
 .ds 2
add32_16_2:
 .ds 2
cmp32_32_1:
 .ds 2
cmp32_32_2:
 .ds 2
sub32_32_1:
 .ds 2
sub32_32_2:
 .ds 2
fs_delete_1:
 .ds 2
fs_mkdir_1:
 .ds 2
fs_move_1:
 .ds 2
fs_move_2:
 .ds 2
gotoxy_1:
 .ds 1
gotoxy_2:
 .ds 1
radio86rkVideoMem:
 .dw 0

radio86rkVideoAttrMem:
 .dw 12288

radio86rkVideoBpl:
 .db 80

charAddr_1:
 .ds 1
charAddr_2:
 .ds 1
print2_1:
 .ds 2
print2_2:
 .ds 2
print_1:
 .ds 1
print_2:
 .ds 1
print_3:
 .ds 2
printn_1:
 .ds 1
printn_2:
 .ds 1
printn_3:
 .ds 1
printn_4:
 .ds 2
print2n_1:
 .ds 2
print2n_2:
 .ds 1
print2n_3:
 .ds 2
print2cn_1:
 .ds 2
print2cn_2:
 .ds 1
print2cn_3:
 .ds 1
printm_1:
 .ds 1
printm_2:
 .ds 1
printm_3:
 .ds 1
printm_4:
 .ds 2
printcn_1:
 .ds 1
printcn_2:
 .ds 1
printcn_3:
 .ds 1
printcn_4:
 .ds 1
fs_open0_1:
 .ds 2
fs_open0_2:
 .ds 1
fs_seek_1:
 .ds 2
fs_seek_2:
 .ds 2
fs_seek_3:
 .ds 1
putch_1:
 .ds 1
print2m_1:
 .ds 2
print2m_2:
 .ds 1
print2m_3:
 .ds 2
string17:
 .db 0
string24:
 .db 23,0
string53:
 .db 32,32,32,32,32,60,68,73,82,62,0


string20:
 .db 32,107,111,112,105,114,111,119,97,110,105,101,32,0



string26:
 .db 32,107,111,112,105,114,111,119,97,116,120,32,0



string34:
 .db 32,109,98,0
string35:
 .db 32,110,97,107,111,112,105,116,101,108,120,32,0



string4:
 .db 32,111,123,105,98,107,97,32,0


string28:
 .db 32,112,101,114,101,105,109,101,110,111,119,97,110,105,101,47,112,101,114,101,109,101,125,101,110,105,101,32,0







string27:
 .db 32,112,101,114,101,105,109,101,110,111,119,97,116,120,47,112,101,114,101,109,101,115,116,105,116,120,32,0






string45:
 .db 32,112,111,109,101,116,105,116,120,32,102,97,106,108,121,32,0




string32:
 .db 32,115,111,122,100,97,116,120,32,102,97,106,108,32,0



string31:
 .db 32,115,111,122,100,97,116,120,32,112,97,112,107,117,32,0



string40:
 .db 32,117,100,97,108,101,110,105,101,32,0


string41:
 .db 32,117,100,97,108,105,116,120,32,0


string44:
 .db 42,46,42,0
string19:
 .db 46,73,78,0
string18:
 .db 46,82,75,0
string25:
 .db 47,0
string57:
 .db 48,49,50,51,52,53,54,55,56,57,65,66,67,68,69,70,0




string2:
 .db 49,54,75,58,0
 .db 49,54,75,58,0
string1:
 .db 51,50,75,58,0
 .db 51,50,75,58,0
string0:
 .db 52,56,75,58,0
 .db 52,56,75,58,0
string54:
 .db 62,0
string3:
 .db 63,63,63,58,0
 .db 63,63,63,58,0
string50:
 .db 70,49,32,70,82,69,69,32,70,50,32,78,69,87,32,32,70,51,32,86,73,69,87,32,32,70,52,32,69,68,73,84,32,70,53,32,67,79,80,89,32,70,54,32,82,69,78,32,32,70,55,32,68,73,82,32,32,70,56,32,68,69,76,0















string51:
 .db 91,0
string55:
 .db 91,32,65,78,89,32,75,69,89,32,93,0


string56:
 .db 91,32,97,114,50,32,45,32,115,116,111,112,32,93,0



string16:
 .db 91,32,119,107,32,45,32,111,107,32,93,32,32,91,32,97,114,50,32,45,32,111,116,109,101,110,97,32,93,0







string52:
 .db 93,0
string46:
 .db 98,97,106,116,32,119,32,32,32,32,0


string11:
 .db 100,105,115,107,32,122,97,112,111,108,110,101,110,0



string12:
 .db 102,97,105,108,32,115,117,125,101,115,116,119,117,101,116,0



string8:
 .db 102,97,106,108,32,110,101,32,111,116,107,114,121,116,0



string48:
 .db 102,97,106,108,97,104,32,0

string47:
 .db 102,97,106,108,101,32,0
 .db 102,97,106,108,101,32,0
string49:
 .db 105,109,113,0
string15:
 .db 105,109,113,58,0
 .db 105,109,113,58,0
string21:
 .db 105,122,58,0
string10:
 .db 109,97,107,115,105,109,117,109,32,102,97,106,108,111,119,32,119,32,112,97,112,107,101,0





string5:
 .db 110,101,116,32,102,97,106,108,111,119,111,106,32,115,105,115,116,101,109,121,0





string29:
 .db 111,123,105,98,107,97,32,107,111,112,105,114,111,119,97,110,105,113,0




string6:
 .db 111,123,105,98,107,97,32,110,97,107,111,112,105,116,101,108,113,0




string30:
 .db 111,123,105,98,107,97,32,112,101,114,101,109,101,125,101,110,105,113,0




string33:
 .db 111,123,105,98,107,97,32,115,111,122,100,97,110,105,113,32,112,97,112,107,105,0





string43:
 .db 111,123,105,98,107,97,32,117,100,97,108,101,110,105,113,0



string37:
 .db 111,123,105,98,107,97,32,126,116,101,110,105,113,0



string7:
 .db 112,97,112,107,97,32,110,101,32,112,117,115,116,97,0



string13:
 .db 112,114,101,114,119,97,110,111,32,112,111,108,120,122,111,119,97,116,101,108,101,109,0





string36:
 .db 112,114,111,119,101,114,107,97,46,46,46,0


string14:
 .db 112,117,116,120,32,98,111,108,120,123,101,32,50,53,53,32,115,105,109,119,111,108,111,119,0






string9:
 .db 112,117,116,120,32,110,101,32,110,97,106,100,101,110,0



string23:
 .db 115,107,111,112,105,114,111,119,97,110,111,32,32,32,32,32,32,32,32,32,32,32,47,32,32,32,32,32,32,32,32,32,32,32,98,97,106,116,0









string38:
 .db 115,119,111,98,111,100,110,111,58,32,0


string22:
 .db 119,58,0
string39:
 .db 119,115,101,103,111,58,0
 .db 119,115,101,103,111,58,0
string42:
 .db 119,121,32,104,111,116,105,116,101,32,117,100,97,108,105,116,120,32,102,97,105,108,40,121,41,63,0






  .end
 0
 0
