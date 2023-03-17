.586
.model flat,stdcall
option casemap:none
    
include MyDbg.inc

.const
;************************************* 显示器功能相关 **************************************************

    g_szOutEAX  db "EAX=%08X  ",0
    g_szOutECX  db "ECX=%08X  ",0
    g_szOutEBX  db "EBX=%08X  ",0
    g_szOutEDX  db "EDX=%08X  ",0
    g_szOutESI  db "ESI=%08X  ",0
    g_szOutEDI  db "EDI=%08X",0ah,0
    g_szOutEIP  db "EIP=%08X  ",0
    g_szOutESP  db "ESP=%08X  ",0
    g_szOutEBP  db "EBP=%08X  ",0
    g_szOutIOPL db "IOPL=0    ",0

    g_szOutCS  db "CS=%04X    ",0
    g_szOutSS  db "SS=%04X    ",0
    g_szOutDS  db "DS=%04X    ",0
    g_szOutES  db "ES=%04X    ",0
    g_szOutFS  db "FS=%04X    ",0
    g_szOutGS  db "GS=%04X    ",0
    g_szOutEFL db "    EFL=%08X",0AH,0

    g_szOutCY db "CY  ",0
    g_szOutNC db "NC  ",0
    g_szOutPE db "PE  ",0
    g_szOutPO db "PO  ",0
    g_szOutAC db "AC  ",0
    g_szOutNA db "NA  ",0
    g_szOutZR db "ZR  ",0
    g_szOutNZ db "NZ  ",0
    g_szOutNG db "NG  ",0
    g_szOutPL db "PL  ",0
    g_szOutDI db "DI  ",0
    g_szOutEI db "EI  ",0
    g_szOutDN db "DN  ",0
    g_szOutUP db "UP  ",0
    g_szOutOV db "OV  ",0ah,0
    g_szOutNV db "NV  ",0ah,0
;===================================================================================================================
    g_szEnd                 db      "$"
    g_szCRLF                db      0dh, 0ah, 0
    g_sz                    db      "-", 0
    g_szInputErr            db      "Input Err", 0dh, 0ah, 0
    g_szPause               db      "pause", 0
    g_szBreaPointTitle      db      "| 序号 |   地址   |", 0dh, 0ah, 0  
    g_szBreakPoint          db      "| %04d | %08X |", 0dh, 0ah, 0
    g_szHWBreakPointTitle   db      "| 序号 |   地址   | 类型 | 长度 |", 0dh, 0ah, 0  
    g_szHWBreakPoint        db      "| %04d | %08X | %s | %04d |", 0dh, 0ah, 0
    g_szModuleListTitle     db      "|   地址   | 模块名                       | 模块路径", 0dh, 0ah, 0
    g_szModuleList          db      "| %08X | %-30s| %s",0dh, 0ah, 0
    g_szExecute             db      "执行", 0
    g_szWrite               db      "写入", 0
    g_szAccess              db      "访问", 0
    g_szCtx                 db      "EAX=%08X EBX=%08X ECX=%08X EDX=%08X ESI=%08X EDI=%08X", 0dh, 0ah,\
                                        "EIP=%08X ESP=%08X EBP=%08X                nv up ei pl zr na pe nc", 0dh, 0ah,\
                                        "CS=%04X  SS=%04X  DS=%04X  ES=%04X  FS=%04X  GS=%04X             EFL=%08X", 0dh, 0ah, 0
    g_szSysBP               db      "系统断点", 0dh, 0ah, 0
    g_szBP                  db      "软件断点", 0dh, 0ah, 0   
    g_szHWBPErr             db      "硬件断点设置失败", 0dh, 0ah ,0
    g_szMemBPErr            db      "内存断点设置失败", 0dh, 0ah ,0
    g_szDumpErr             db      "内存Dump失败",0dh, 0ah, 0
    
    g_szFuncName            db      "<%s.%s>", 0
    g_szOrdinal             db      "<%s.#%d>", 0
    g_szNoFunc              db      "<%s.%08X>", 0
    
    g_szHex                 db      "%08X  %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X  ", 0
    g_szShowMemErr          db      "第一次使用请指定要查看的地址",0dh, 0ah, 0
    
    g_szReg                 db      "%s:", 0
    g_szTmp                 db      "%s", 0dh, 0ah, 0
    
    g_szMemErr              db      "内存不可访问 --- 0x%08X",0dh, 0ah, 0
    g_szWriteMem            db      "0x%08X  %02X.", 0
    
    g_szScriptEnd           db      "脚本执行结束", 0
.data
    g_szFilter              db      "*.exe;", 0
    g_szBuf                 db      1024 dup(0)
    g_szRegBuf              db      512 dup(0)
    g_szMemBuf              db      512 dup(0)
    g_dwSysBP               dw      0       ;系统断点标志
    
    g_hProc                 HANDLE  0
    g_pList                 dd      0       ;软件断点链表
    g_dwIsStepTF            dd      0       ;单步标志
    g_dwIsHardwareTF        dd      0       ;硬件断点产生的单步标志
    g_dwCurAsmEip           dd      0       ;记录当前反汇编的EIP（U功能）
    g_pMemBPList            dd      0       ;内存断点链表
    g_pBPPageList           dd      0       ;断点与分页的关系链表
    g_pPageList             dd      0       ;分页属性链表
    g_dwIdCnt               dd      0
    g_szModBaseName         db      1000h dup(0)         ;模块名
    g_szModFullName         db      1000h dup(0)         ;模块全路径
    
    g_dwIsGoRet             dd      0       ;用于区分是否处于执行到返回状态
    
    g_dwIsTrace             dd      0       ;用于区分是否处于追踪状态
    g_dwTraceEndAddr        dd      0       ;追踪结束地址
    g_szTrace               db      512 dup(0)  ;追踪记录文件名
    g_hTraceFile            dd      0       ;追踪记录文件句柄
    
    g_dwIsScript            dd      0       ;判断是否处于脚本自动运行状态
    g_hScript               dd      0       ;脚本文件句柄
    
    g_dwIsWriteScript       dd      0       ;判断是否处于记录指令状态
    g_hWriteScript          dd      0       ;脚本文件句柄
    
    g_dwMemAddr             dd      0       ;记录当前查看内存的地址
.code
start:
    invoke CreateProc
    invoke EventLoop
    invoke ExitProcess,eax
; ---------------------------------------------------------------------------
FindNextWord proc pAddr: LPVOID
    mov eax, pAddr
    .while byte ptr[eax] != " "
        .if byte ptr[eax] == 0
            mov eax, 0
            ret
        .endif
        inc eax  
    .endw
    
    .while byte ptr[eax] == " "
        .if byte ptr[eax] == 0
            mov eax, 0
            ret
        .endif
        inc eax  
    .endw
    ret
FindNextWord endp

; ---------------------------------------------------------------------------
SetTF proc dwTid:DWORD
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT

    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, dwTid
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
     
    ;TF位 置1
    or @Ctx.regFlag, 100h       
    invoke SetThreadContext, @hThread, addr @Ctx
    invoke CloseHandle, @hThread
    ret
SetTF endp

; ---------------------------------------------------------------------------
ShowCtxWaitInput proc dwTid:DWORD, pEvent:ptr DEBUG_EVENT
    invoke ShowContext, dwTid     ;输出线程上下文
    invoke ShowCurCode, dwTid, 1
    invoke InputCommand, pEvent      ;等待用户操作
    ret
ShowCtxWaitInput endp

; ---------------------------------------------------------------------------
ShowContext proc uses ebx dwTid: DWORD      ;输出环境上下文
    LOCAL @hThread: HANDLE
    LOCAL @ctx: CONTEXT

    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, dwTid
    mov @hThread, eax
    invoke RtlZeroMemory, addr @ctx, size @ctx
    mov @ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @ctx
;    invoke crt_printf, offset g_szCtx, @Ctx.regEax, @Ctx.regEbx, @Ctx.regEcx, @Ctx.regEdx, @Ctx.regEsi, @Ctx.regEdi,\   
;                                @Ctx.regEip, @Ctx.regEsp, @Ctx.regEbp,\
;                                @Ctx.regCs, @Ctx.regSs, @Ctx.regDs, @Ctx.regEs, @Ctx.regFs, @Ctx.regGs, @Ctx.regFlag

    invoke crt_printf,addr g_szOutEAX,@ctx.regEax
     invoke crt_printf,addr g_szOutEBX,@ctx.regEbx
     invoke crt_printf,addr g_szOutECX,@ctx.regEcx
     invoke crt_printf,addr g_szOutEDX,@ctx.regEdx
     invoke crt_printf,addr g_szOutESI,@ctx.regEsi
     invoke crt_printf,addr g_szOutEDI,@ctx.regEdi
     invoke crt_printf,addr g_szOutEIP,@ctx.regEip
     invoke crt_printf,addr g_szOutESP,@ctx.regEsp
     invoke crt_printf,addr g_szOutEBP,@ctx.regEbp
     invoke crt_printf,addr g_szOutIOPL

     mov eax,@ctx.regFlag
     and eax,0800h
     .if eax == 0800h
         invoke crt_printf,addr g_szOutCY
     .else
         invoke crt_printf,addr g_szOutCY
     .endif
     
     mov eax,@ctx.regFlag
     and eax,0400h
     .if eax == 0400h
         invoke crt_printf,addr g_szOutPE
     .else
         invoke crt_printf,addr g_szOutPO
     .endif

     mov eax,@ctx.regFlag
     and eax,0200h
     .if eax == 0200h
         invoke crt_printf,addr g_szOutAC
     .else
         invoke crt_printf,addr g_szOutNA
     .endif

     mov eax,@ctx.regFlag
     and eax,0100h
     .if eax == 0100h
         invoke crt_printf,addr g_szOutZR
     .else
         invoke crt_printf,addr g_szOutNZ
     .endif
     
     mov eax,@ctx.regFlag
     and eax,080h
     .if eax == 080h
         invoke crt_printf,addr g_szOutNG
     .else
         invoke crt_printf,addr g_szOutPL
     .endif

     mov eax,@ctx.regFlag
     and eax,040h
     .if eax == 040h
         invoke crt_printf,addr g_szOutDI
     .else
         invoke crt_printf,addr g_szOutEI
     .endif

     mov eax,@ctx.regFlag
     and eax,010h
     .if eax == 010h
         invoke crt_printf,addr g_szOutDN
     .else
         invoke crt_printf,addr g_szOutUP
     .endif

     mov eax,@ctx.regFlag
     and eax,04h
     .if eax == 04h
         invoke crt_printf,addr g_szOutOV
     .else
         invoke crt_printf,addr g_szOutNV
     .endif

     invoke crt_printf,ADDR g_szOutGS,@ctx.regGs
     invoke crt_printf,ADDR g_szOutFS,@ctx.regFs
     invoke crt_printf,ADDR g_szOutES,@ctx.regEs
     invoke crt_printf,ADDR g_szOutDS,@ctx.regDs
     invoke crt_printf,ADDR g_szOutSS,@ctx.regSs
     invoke crt_printf,ADDR g_szOutCS,@ctx.regCs
     invoke crt_printf,ADDR g_szOutEFL,@ctx.regFlag
    invoke CloseHandle, @hThread
    ret
ShowContext endp

; ---------------------------------------------------------------------------
ShowCurCode proc uses ebx dwTid: DWORD, dwCnt: DWORD     ;输出反汇编代码
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @pBuf[1024]: BYTE
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, dwTid
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
    
    invoke ReadProcessMemory, g_hProc, @Ctx.regEip, addr @pBuf, 1024, NULL
    invoke DisAsm, @Ctx.regEip, addr @pBuf, 1024, dwCnt, g_hProc, GetFunctionName
    mov g_dwCurAsmEip, 0
    invoke CloseHandle, @hThread
    ret
ShowCurCode endp

; ---------------------------------------------------------------------------
CreateProc proc                                 ;创建进程
    LOCAL @szBuf[1024]: BYTE
    LOCAL @pBuf: DWORD
    LOCAL @si: STARTUPINFO 
    LOCAL @pi: PROCESS_INFORMATION 
    LOCAL @ofna:OPENFILENAME
    lea eax, @szBuf
    mov @pBuf, eax
    
    invoke RtlZeroMemory, addr @ofna, size @ofna
    mov @ofna.lStructSize, size @ofna
    mov @ofna.lpstrFilter, offset g_szFilter
    mov eax, @pBuf
    mov @ofna.lpstrFile, eax
    mov @ofna.nMaxFile, 1024
    mov @ofna.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
    invoke GetOpenFileName, addr @ofna
    
    invoke RtlZeroMemory, addr @si, size @si
    invoke RtlZeroMemory, addr @pi, size @pi
    mov @si.cb, size @si
    invoke CreateProcess, @pBuf, NULL, NULL, NULL, FALSE, DEBUG_ONLY_THIS_PROCESS or CREATE_NEW_CONSOLE, NULL, NULL, addr @si, addr @pi
    push eax
    mov eax, @pi.hProcess
    mov g_hProc, eax
    pop eax
    ret
CreateProc endp

; ---------------------------------------------------------------------------
EventLoop proc uses ebx             ;事件处理循环
    LOCAL @de:DEBUG_EVENT
@@: 
    invoke WaitForDebugEvent, addr @de, INFINITE
    .if eax == 0
        jmp EventLoop_End
    .endif
    .if @de.dwDebugEventCode == EXCEPTION_DEBUG_EVENT
        invoke ExceptionEvent, addr @de         
    .endif
    
    invoke ContinueDebugEvent, @de.dwProcessId, @de.dwThreadId, DBG_CONTINUE
    jmp @b
EventLoop_End:
    ret
EventLoop endp

; ---------------------------------------------------------------------------
InputCommand proc uses ebx pEvent: ptr DEBUG_EVENT          ;接收并处理用户输入
    LOCAL @pAddr: DWORD
    LOCAL @dwType:DWORD
    LOCAL @dwLen:DWORD
    LOCAL @dwTid:DWORD
    
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    mov ebx, [ebx].dwThreadId
    mov @dwTid, ebx
    assume ebx:nothing
@@:
    invoke crt_printf, offset g_sz
    .if g_dwIsScript == TRUE
        invoke ReadScriptCommand, offset g_szBuf
    .endif 
    .if g_dwIsScript != TRUE
        invoke crt_gets, offset g_szBuf
    .endif
    
    mov ebx, offset g_szBuf
    .if byte ptr[ebx] == 0
        jmp @b
        
    .elseif (byte ptr[ebx] == "g" || byte ptr[ebx] == "G") && byte ptr[ebx+1] == 0  ;g GO
        xor eax, eax
        mov g_dwCurAsmEip, eax
        invoke WriteScriptCommand, offset g_szBuf
        jmp InputCommand_End
        
    .elseif (byte ptr[ebx] == "g" || byte ptr[ebx] == "G") && (byte ptr[ebx+1] == "r" || byte ptr[ebx+1] == "R")    ;执行到返回
        invoke GoToRet, pEvent
        invoke WriteScriptCommand, offset g_szBuf
        jmp InputCommand_End
        
    .elseif (byte ptr[ebx] == "b" || byte ptr[ebx] == "B")&&(byte ptr[ebx+1] == "p" || byte ptr[ebx+1] == "P")  ; bp XXXXXXXX 设置断点
        add ebx, 2
        invoke crt_strtoul, ebx, NULL, 16
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov @pAddr, eax
        invoke SetBreakPoint, @pAddr, FALSE
        invoke WriteScriptCommand, offset g_szBuf
        
    .elseif (byte ptr[ebx]== 'b' || byte ptr[ebx] == 'B') && (byte ptr[ebx+1] == 'l' || byte ptr[ebx+1] == 'L')     ; bl 列出断点
        invoke ShowBreakPoint
        
        
    .elseif (byte ptr[ebx] == "b" || byte ptr[ebx] == "B")&&(byte ptr[ebx+1] == "c" || byte ptr[ebx+1] == "C")  ; bc 序号 删除断点
        add ebx, 2
        invoke crt_strtoul, ebx, NULL, 10
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        push eax
        call DelBreakPoint
        invoke WriteScriptCommand, offset g_szBuf
        
    .elseif (byte ptr[ebx] == "b" || byte ptr[ebx] == "B") && (byte ptr[ebx+1] == "h" || byte ptr[ebx+1] == "H") && byte ptr[ebx+2] == " " 
        ; bh XXXXXXXX 硬件断点
        invoke FindNextWord, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov ebx, eax
        invoke crt_strtoul, ebx, NULL, 16
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov @pAddr, eax
        
        invoke FindNextWord, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov ebx, eax
        .if byte ptr[ebx] == "E" || byte ptr[ebx] == "e"
            mov @dwType, 0
        .elseif byte ptr[ebx] == "W" || byte ptr[ebx] == "w"
            mov @dwType, 1
        .elseif byte ptr[ebx] == "R" || byte ptr[ebx] == "r"
            mov @dwType, 3
        .else
            invoke crt_printf, offset g_szInputErr
            jmp @b 
        .endif
        
        invoke FindNextWord, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov ebx, eax
        invoke crt_strtoul, ebx, NULL, 10
        .if eax > 4 || eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov @dwLen, eax
        
        invoke SetHWBreakPoint, pEvent, @pAddr, @dwType,  @dwLen
        .if eax == FALSE
            invoke crt_printf, offset g_szHWBPErr
        .endif
        invoke WriteScriptCommand, offset g_szBuf
        
    .elseif (byte ptr[ebx] == "b" || byte ptr[ebx] == "B") && (byte ptr[ebx+1] == "h" || byte ptr[ebx+1] == "H") &&\    ;bhl 查看硬件断点
     (byte ptr[ebx+2] == "l" || byte ptr[ebx+2] == "L") 
        invoke ShowHWBreakPoint, pEvent

    .elseif (byte ptr[ebx] == "b" || byte ptr[ebx] == "B") && (byte ptr[ebx+1] == "h" || byte ptr[ebx+1] == "H") &&\    ;bhc 删除硬件断点
     (byte ptr[ebx+2] == "c" || byte ptr[ebx+2] == "C") 
        invoke FindNextWord, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov ebx, eax
        invoke crt_strtoul, ebx, NULL, 10
        invoke DelHWBreakPoint, pEvent, eax
        invoke WriteScriptCommand, offset g_szBuf
        
    .elseif (byte ptr[ebx] == "b" || byte ptr[ebx] == "B") && (byte ptr[ebx+1] == "m" || byte ptr[ebx+1] == "M") && byte ptr[ebx+2] == " " 
        ;设置内存断点
        invoke FindNextWord, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov ebx, eax
        invoke crt_strtoul, ebx, NULL, 16
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov @pAddr, eax
        
        invoke FindNextWord, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov ebx, eax
        invoke crt_strtoul, ebx, NULL, 10
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov @dwLen, eax
        
        invoke FindNextWord, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov ebx, eax
        .if byte ptr[ebx] == "r" || byte ptr[ebx] == "R"
            mov @dwType, MM_READ
        .elseif byte ptr[ebx] == "w" || byte ptr [ebx] == "W"
            mov @dwType, MM_WRITE
        .else
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        invoke SetMemBreakPoint, @pAddr, @dwLen, @dwType
        .if eax == FALSE
            invoke crt_printf, offset g_szMemBPErr
        .endif
        invoke WriteScriptCommand, offset g_szBuf
        
    .elseif (byte ptr[ebx] == "b" || byte ptr[ebx] == "B") && (byte ptr[ebx+1] == "m" || byte ptr[ebx+1] == "M") &&\    ;查看内存断点
     (byte ptr[ebx+2] == "l" || byte ptr[ebx+2] == "L") 
        invoke ShowMemBreakPoint
    
    .elseif (byte ptr[ebx] == "b" || byte ptr[ebx] == "B") && (byte ptr[ebx+1] == "m" || byte ptr[ebx+1] == "M") &&\    ;删除内存断点
     (byte ptr[ebx+2] == "c" || byte ptr[ebx+2] == "C") 
        invoke FindNextWord, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        mov ebx, eax
        invoke crt_strtoul, ebx, NULL, 10
        invoke DelMemBreakPoint, eax
        invoke WriteScriptCommand, offset g_szBuf
        
    .elseif (byte ptr[ebx] == "t" || byte ptr[ebx] == "T")  ;t 单步步入
        xor eax, eax
        mov g_dwCurAsmEip, eax
        invoke StepInto, pEvent
        invoke WriteScriptCommand, offset g_szBuf
        jmp InputCommand_End

    .elseif (byte ptr[ebx] == "p" || byte ptr[ebx] == "P")  ;t 单步步过
        xor eax, eax
        mov g_dwCurAsmEip, eax
        invoke StepOver, pEvent
        invoke WriteScriptCommand, offset g_szBuf
        jmp InputCommand_End
        
    .elseif (byte ptr[ebx] == "u" || byte ptr[ebx] == "U")  ;u 查看反汇编
        invoke Unassemble, pEvent, 0
        invoke WriteScriptCommand, offset g_szBuf
        
    .elseif (byte ptr[ebx] == "l" || byte ptr[ebx] == "L") && (byte ptr[ebx+1] == "m" || byte ptr[ebx+1] == "M")    ;查看模块列表   
        invoke crt_printf, offset g_szModuleListTitle
        invoke ShowModuleList, g_hProc
        
    .elseif (byte ptr[ebx] == "r" || byte ptr[ebx] == "R") && (byte ptr[ebx+1] == 0)  ;查看寄存器
        invoke ShowContext, @dwTid
        invoke WriteScriptCommand, offset g_szBuf
        
    .elseif (byte ptr[ebx] == "r" || byte ptr[ebx] == "R") && (byte ptr[ebx+1] != 0)  ;修改寄存器
        invoke WriteReg, @dwTid, ebx
                
    .elseif (byte ptr[ebx+0] == "d" || byte ptr[ebx+0] == "D") &&\
            (byte ptr[ebx+1] == "u" || byte ptr[ebx+1] == "U") &&\
            (byte ptr[ebx+2] == "m" || byte ptr[ebx+2] == "M") &&\
            (byte ptr[ebx+3] == "p" || byte ptr[ebx+3] == "P") 
        lea ebx, byte ptr[ebx+5]
        invoke MemoryDump, ebx
        .if eax == 0
            invoke crt_printf, offset g_szDumpErr
        .endif
        
    .elseif (byte ptr[ebx] == "d" || byte ptr[ebx] == "D") && (byte ptr[ebx+1] == "d" || byte ptr[ebx+1] == "D")  ;查看内存
        ;INT 3
        .if byte ptr[ebx+2] != 0
            invoke FindNextWord, ebx
            .if eax == 0
                invoke crt_printf, offset g_szInputErr
                jmp @b  
            .endif
            mov ebx, eax
            invoke crt_strtoul, ebx, NULL, 16
            .if eax == 0
                invoke crt_printf, offset g_szInputErr
                jmp @b  
            .endif
            mov g_dwMemAddr, eax
            invoke ShowMemory, g_dwMemAddr, 4
            add g_dwMemAddr, eax
         .else
             .if g_dwMemAddr == 0
                invoke crt_printf, offset g_szShowMemErr
             .else
                invoke ShowMemory, g_dwMemAddr, 4
                add g_dwMemAddr, eax
             .endif
        .endif     
    .elseif (byte ptr[ebx] == "e" || byte ptr[ebx] == "E")
        invoke WriteMem, ebx
        
    .elseif (byte ptr[ebx] == "g" || byte ptr[ebx] == "G") && (byte ptr[ebx+1] == "t" || byte ptr[ebx+1] == "T")
        invoke StartTrace, pEvent, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            jmp @b  
        .endif
        jmp InputCommand_End
        
    .elseif (byte ptr[ebx] == "l" || byte ptr[ebx] == "L") && (byte ptr[ebx+1] == "s" || byte ptr[ebx+1] == "S")
        invoke LoadScript, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
        .endif
        jmp @b
        
    .elseif (byte ptr[ebx] == "s" || byte ptr[ebx] == "S") && (byte ptr[ebx+1] == "s" || byte ptr[ebx+1] == "S")
        invoke StartScript, ebx
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
        .endif
        jmp @b 
        
    .elseif (byte ptr[ebx] == "s" || byte ptr[ebx] == "S") && (byte ptr[ebx+1] == "e" || byte ptr[ebx+1] == "E")
        invoke SaveScript
        jmp @b  
        
    .else
        invoke crt_printf, offset g_szInputErr   
    .endif
    jmp @b  
InputCommand_End:
    ret
InputCommand endp

; ---------------------------------------------------------------------------
SetBreakPoint proc uses ebx pAddr:LPVOID, bDisposable:BYTE            ;设置断点
    LOCAL @dwOldProtect: DWORD
    LOCAL @bOldByte: BYTE
    LOCAL @bBP: BYTE
    LOCAL @pInfo : DWORD
    invoke VirtualProtectEx, g_hProc, pAddr, 1, PAGE_EXECUTE_READWRITE, addr @dwOldProtect
    invoke ReadProcessMemory, g_hProc, pAddr, addr @bOldByte, 1, NULL
    mov @bBP, 0CCh
    invoke WriteProcessMemory, g_hProc, pAddr, addr @bBP, 1, NULL
    invoke VirtualProtectEx, g_hProc, pAddr, 1, @dwOldProtect, addr @dwOldProtect
    
    ;保存断点信息
    invoke crt_malloc, size BPList
    assume eax: ptr BPList
    mov [eax].m_pNext, NULL
    mov [eax].m_bFlag, TRUE
    mov [eax].m_bTF, FALSE
    xor ebx, ebx
    mov bl, @bOldByte
    mov [eax].m_bOldByte, bl
    mov ebx, pAddr
    mov [eax].m_pAddr, ebx
    xor ebx, ebx
    mov bl, bDisposable
    mov [eax].m_bDisposable, bl
    
    ;断点信息加入链表
    .if g_pList != NULL
        mov ebx, g_pList
        assume ebx: ptr BPList
        .while [ebx].m_pNext != NULL
            mov ebx, [ebx].m_pNext
        .endw
        mov [ebx].m_pNext, eax
    .else
        mov g_pList, eax
    .endif
    
    assume ebx:nothing
    assume eax:nothing
    ret
SetBreakPoint endp

; ---------------------------------------------------------------------------
DelBreakPoint proc uses ebx ecx dwId:DWORD          ; 删除断点
    LOCAL @dwOldProtect: DWORD
    LOCAL @bOldByte: BYTE
    LOCAL @pLast: DWORD
    LOCAL @dwCnt: DWORD 
    
    mov ebx, g_pList
    assume ebx: ptr BPList
    .if g_pList == NULL
        ret
    .endif
    
    ;遍历链表
    mov @dwCnt, 1
    mov @pLast, NULL
    mov eax, dwId
    .while ebx != NULL
        .if @dwCnt == eax
           .break   
        .endif
        mov @pLast, ebx
        mov ebx, [ebx].m_pNext
        inc @dwCnt
    .endw 
    
    ;判断断点是否生效
    .if [ebx].m_bFlag == TRUE
        invoke VirtualProtectEx, g_hProc, [ebx].m_pAddr, 1, PAGE_EXECUTE_READWRITE, addr @dwOldProtect 
        push eax
        mov al, [ebx].m_bOldByte
        mov @bOldByte, al
        pop eax
        invoke WriteProcessMemory, g_hProc, [ebx].m_pAddr, addr @bOldByte, 1, NULL
        invoke VirtualProtectEx, g_hProc, [ebx].m_pAddr, 1, @dwOldProtect, addr @dwOldProtect 
    .endif
    
    ;处理链表
    .if @pLast == NULL
        mov eax, [ebx].m_pNext
        mov g_pList, eax
    .else
        mov ecx, @pLast
        assume ecx: ptr BPList
        mov eax, [ebx].m_pNext
        mov [ecx].m_pNext, eax
    .endif
    
    ;释放内存
    invoke crt_free, ebx
    assume ebx:nothing
    assume ecx:nothing
    ret
DelBreakPoint endp

; ---------------------------------------------------------------------------
ShowBreakPoint proc uses ebx        ;输出断点列表
    LOCAL @dwCnt: DWORD
    
    mov ebx, g_pList
    assume ebx: ptr BPList
    
    invoke crt_printf, offset g_szBreaPointTitle
    mov @dwCnt, 1
    .while ebx != NULL
        invoke crt_printf, offset g_szBreakPoint, @dwCnt, [ebx].m_pAddr
        mov ebx, [ebx].m_pNext
        inc @dwCnt
    .endw
    
    assume ebx: nothing
    ret
ShowBreakPoint endp

; ---------------------------------------------------------------------------
StepInto proc uses ebx pEvent: ptr DEBUG_EVENT            ;单步步入
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @dwOldProtect: DWORD
    LOCAL @bOldByte: BYTE
    
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, [ebx].dwThreadId
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
     
    ;TF位 置1
    or @Ctx.regFlag, 100h       
    invoke SetThreadContext, @hThread, addr @Ctx
    mov g_dwIsStepTF, 1
    invoke CloseHandle, @hThread
    assume ebx:nothing
    ret
StepInto endp

; ---------------------------------------------------------------------------
StepOver proc uses ebx pEvent: ptr DEBUG_EVENT            ;单步步过
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @dwOldProtect: DWORD
    LOCAL @bOldByte: BYTE
    LOCAL @pBuf[1024]: BYTE
    
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, [ebx].dwThreadId
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
    
     ;判断是否为call指令
    invoke ReadProcessMemory, g_hProc, @Ctx.regEip, addr @pBuf, 1024, NULL
    invoke IsCall, @Ctx.regEip, addr @pBuf, 1024
    .if eax == 0 
        ;如果不是call指令则TF位 置1
        or @Ctx.regFlag, 100h       
        invoke SetThreadContext, @hThread, addr @Ctx
        mov g_dwIsStepTF, 1
        invoke CloseHandle, @hThread
        assume ebx:nothing
    .else
        ;如果是call指令向下一条指令下个一次性断点
        add eax, @Ctx.regEip
        invoke SetBreakPoint, eax, TRUE
    .endif
    ret
StepOver endp

; ---------------------------------------------------------------------------
ExceptionEvent proc uses ebx pEvent: ptr DEBUG_EVENT        ;异常事件处理
    LOCAL @dwTid: DWORD
    assume ebx: ptr DEBUG_EVENT
    mov ebx, pEvent
    mov eax, [ebx].dwThreadId
    mov @dwTid, eax
    lea eax, [ebx].u
    assume ebx: ptr EXCEPTION_DEBUG_INFO
    mov ebx, eax
    lea eax, [ebx].pExceptionRecord
    assume ebx: ptr EXCEPTION_RECORD 
    mov ebx, eax
    
    .if [ebx].ExceptionCode == EXCEPTION_BREAKPOINT && g_dwSysBP == 0   ;断点异常(系统断点)
        mov g_dwSysBP, 1
        invoke SetEntryBreakPoint
        invoke ShowCtxWaitInput, @dwTid, pEvent
        
    .elseif [ebx].ExceptionCode == EXCEPTION_BREAKPOINT     ;断点异常(自己设置的断点)
        invoke RecoverCodeSetTF, pEvent     ;设置单步异常，用于恢复断点
        .if (eax != TRUE) || (g_dwIsGoRet != TRUE)      ;如果当前处于执行到返回状态，且断点是个一次性断点则跳过用户输入
            invoke ShowCtxWaitInput, @dwTid, pEvent
        .endif  
              
    .elseif [ebx].ExceptionCode == EXCEPTION_ACCESS_VIOLATION
        invoke RecoverProtectSetTF,pEvent, [ebx].ExceptionInformation[4], [ebx].ExceptionInformation[0]
        .if eax == TRUE
            invoke ShowCtxWaitInput, @dwTid, pEvent
        .endif
        
    .elseif [ebx].ExceptionCode == EXCEPTION_SINGLE_STEP        ;单步异常
        invoke StepHWBreakPoint, @dwTid     ;处理硬件断点异常
        .if (g_dwIsStepTF == 1 || g_dwIsHardwareTF != 0)        ;单步步入或硬件断点，则等待用户操作
            mov g_dwIsStepTF, 0
            
            .if g_dwIsGoRet == TRUE             ;判断是否处于GoRet状态
                invoke _IsRet, pEvent
                .if eax != 0
                    mov g_dwIsGoRet, FALSE
                .else
                   invoke StepOver, pEvent      ; 如果不是ret指令则继续设置单步断点
                .endif
            .endif 
            
            .if g_dwIsTrace == TRUE
                invoke WriteTraceFile, pEvent
            .endif
            
            .if (g_dwIsHardwareTF != 0 || (g_dwIsGoRet != TRUE && g_dwIsTrace != TRUE))
                invoke ShowCtxWaitInput, @dwTid, pEvent ;如果没有处于GoRet状态则等待用户输入
            .endif         
        .endif
        invoke ReSettingBraekPoint          ;处理软件断点产生的单步异常
        invoke ReSettingMemBreakPoint       ;处理内存断点产生的单步异常
    .endif
    
    assume ebx:nothing
    ret
ExceptionEvent endp

; ---------------------------------------------------------------------------
RecoverCodeSetTF proc uses ebx pEvent: ptr DEBUG_EVENT            ;取消断点,TF位置1
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @dwOldProtect: DWORD
    LOCAL @bOldByte: BYTE
    LOCAL @bDisposable: BYTE
    
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, [ebx].dwThreadId
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
     
    ;TF位 置1，EIP回退1字节(因为执行了INT3)
    or @Ctx.regFlag, 100h       
    mov eax, @Ctx.regEip
    dec eax
    mov @Ctx.regEip, eax
    
    ;遍历断点链表，找到当前断点处并暂时取消断点
    mov ebx, offset g_pList
    assume ebx: ptr BPList
    .while ebx != NULL
        .if [ebx].m_pAddr == eax
           invoke VirtualProtectEx, g_hProc, [ebx].m_pAddr, 1, PAGE_EXECUTE_READWRITE, addr @dwOldProtect 
           push eax
           mov al, [ebx].m_bOldByte
           mov @bOldByte, al
           xor eax, eax
           mov al, [ebx].m_bDisposable
           mov @bDisposable, al
           pop eax
           invoke WriteProcessMemory, g_hProc, [ebx].m_pAddr, addr @bOldByte, 1, NULL
           invoke VirtualProtectEx, g_hProc, [ebx].m_pAddr, 1, @dwOldProtect, addr @dwOldProtect 
           mov [ebx].m_bTF, TRUE
           .break   
        .endif
        mov ebx, [ebx].m_pNext
    .endw  
    ;设置目标线程的寄存器环境
    invoke SetThreadContext, @hThread, addr @Ctx

    invoke CloseHandle, @hThread
    assume ebx:nothing
    xor eax, eax
    mov al, @bDisposable
    ret
RecoverCodeSetTF endp

; ---------------------------------------------------------------------------
ReSettingBraekPoint proc uses ebx                ;重新设置断点
    LOCAL @bBP: BYTE    
    LOCAL @dwOldProtect: DWORD
    LOCAL @bRet: DWORD
    LOCAL @dwCnt: DWORD
    
    mov @dwCnt, 1
    mov @bRet, FALSE
    ;找链表中m_bTF成员为true的元素
    mov ebx, g_pList
    assume ebx: ptr BPList
    .while ebx != NULL
        .if [ebx].m_bTF == TRUE
            .if [ebx].m_bDisposable == TRUE
                invoke DelBreakPoint, @dwCnt
                .break
            .endif
            invoke VirtualProtectEx, g_hProc, [ebx].m_pAddr, 1, PAGE_EXECUTE_READWRITE, addr @dwOldProtect
            mov @bBP, 0CCh
            invoke WriteProcessMemory, g_hProc, [ebx].m_pAddr, addr @bBP, 1, NULL
            invoke VirtualProtectEx, g_hProc, [ebx].m_pAddr, 1, @dwOldProtect, addr @dwOldProtect
            mov [ebx].m_bTF, FALSE        ;恢复标志位
            .break
        .endif
        mov ebx, [ebx].m_pNext
        inc @dwCnt
    .endw
    
    assume ebx:nothing
    ret
ReSettingBraekPoint endp

; ---------------------------------------------------------------------------
Unassemble proc uses ebx pEvent: ptr DEBUG_EVENT, dwCnt:DWORD
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @pBuf[1024]: BYTE
    LOCAL @dwCnt: DWORD
    .if dwCnt == 0
        mov @dwCnt, 10
    .else
        mov eax, dwCnt
        mov @dwCnt, eax
    .endif
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    .if g_dwCurAsmEip == 0
        ;获取目标线程的寄存器环境
        invoke OpenThread, THREAD_ALL_ACCESS, FALSE, [ebx].dwThreadId
        mov @hThread, eax
        invoke RtlZeroMemory, addr @Ctx, size @Ctx
        mov @Ctx.ContextFlags, CONTEXT_ALL
        invoke GetThreadContext, @hThread, addr @Ctx
    
        invoke ReadProcessMemory, g_hProc, @Ctx.regEip, addr @pBuf, 1024, NULL
        invoke DisAsm, @Ctx.regEip, addr @pBuf, 1024, @dwCnt, g_hProc, GetFunctionName
        add eax, @Ctx.regEip
        mov g_dwCurAsmEip, eax
        invoke CloseHandle, @hThread
    .else
        invoke ReadProcessMemory, g_hProc, g_dwCurAsmEip, addr @pBuf, 1024, NULL
        invoke DisAsm, g_dwCurAsmEip, addr @pBuf, 1024, @dwCnt, g_hProc, GetFunctionName
        add g_dwCurAsmEip, eax
    .endif
    
    assume ebx: nothing
    ret
Unassemble endp
; ---------------------------------------------------------------------------
SetHWBreakPoint proc uses ebx edx pEvent:ptr DEBUG_EVENT, pAddr:LPVOID, dwType:DWORD, dwLen:DWORD      ;设置硬件断点
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @dwRet:DWORD 
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, [ebx].dwThreadId
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
    
    dec dwLen
    
    ;执行断点判断
    .if (dwType == 0 && dwLen != 0)
        mov @dwRet, FALSE
        jmp SetHWBreakPoint_End
    .endif
    
    ;访问/写入断点判断
    .if dwLen == 1
        xor edx, edx
        mov eax, pAddr
        mov ebx, 2
        div ebx
        test edx, edx
        mov @dwRet, FALSE
        jnz SetHWBreakPoint_End
    .elseif dwLen == 2
        mov @dwRet, FALSE
        jmp SetHWBreakPoint_End
    .elseif dwLen == 3
        xor edx, edx
        mov eax, pAddr
        mov ebx, 4
        div ebx
        test edx, edx
        mov @dwRet, FALSE
        jnz SetHWBreakPoint_End
    .endif

    mov eax, @Ctx.iDr7
    and eax, 55h
    .if eax == 55h          ;如果已经有4个硬件断点返回false
        mov @dwRet, FALSE
        jmp SetHWBreakPoint_End
    .endif
    
    ;将地址设置到空闲的dr0~3寄存器中，并设置dr7寄存器的标志位
    mov ebx, pAddr  
    mov eax, @Ctx.iDr7
    ;dr0
    mov eax, @Ctx.iDr7
    and eax, 1
    .if eax == 0 && g_dwIsHardwareTF != 1
        mov @Ctx.iDr0, ebx
        or @Ctx.iDr7, 1
        and @Ctx.iDr7, 0FFF0FFFFh
        mov ebx, dwType
        shl ebx, 16
        or @Ctx.iDr7, ebx
        mov ebx, dwLen
        shl ebx, 18
        or @Ctx.iDr7, ebx
        jmp lable1
    .endif

    ;dr1
    mov eax, @Ctx.iDr7
    and eax, 4
    .if eax == 0 && g_dwIsHardwareTF != 4
        mov @Ctx.iDr1, ebx
        or @Ctx.iDr7, 4
        and @Ctx.iDr7, 0FF0FFFFFh
        mov ebx, dwType
        shl ebx, 20
        or @Ctx.iDr7, ebx
        mov ebx, dwLen
        shl ebx, 22
        or @Ctx.iDr7, ebx
        jmp lable1
    .endif

    ;dr2
    mov eax, @Ctx.iDr7
    and eax, 10h
    .if eax == 0 && g_dwIsHardwareTF != 10h
        mov @Ctx.iDr2, ebx
        or @Ctx.iDr7, 10h
        and @Ctx.iDr7, 0F0FFFFFFh
        mov ebx, dwType
        shl ebx, 24
        or @Ctx.iDr7, ebx
        mov ebx, dwLen
        shl ebx, 26
        or @Ctx.iDr7, ebx
        jmp lable1
    .endif

    ;dr3
    mov eax, @Ctx.iDr7
    and eax, 40h
    .if eax == 0 && g_dwIsHardwareTF != 40h
        mov @Ctx.iDr3, ebx
        or @Ctx.iDr7, 40h
        and @Ctx.iDr7, 0FFFFFFFh
        mov ebx, dwType
        shl ebx, 28
        or @Ctx.iDr7, ebx
        mov ebx, dwLen
        shl ebx, 30
        or @Ctx.iDr7, ebx
        jmp lable1
    .endif
    
    mov @dwRet, FALSE
    jmp SetHWBreakPoint_End
lable1:
    invoke SetThreadContext, @hThread, addr @Ctx
    mov @dwRet, TRUE
SetHWBreakPoint_End:
    invoke CloseHandle, @hThread
    mov eax, @dwRet
    assume ebx: nothing
    ret
SetHWBreakPoint endp

; ---------------------------------------------------------------------------
StepHWBreakPoint proc uses ebx dwTid:DWORD
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @dwRet: DWORD
    mov @dwRet, FALSE
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, dwTid
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
    
    ;如果是硬件断点处理时设置的TF位产生的单步异常，那么恢复硬件断点
    .if g_dwIsHardwareTF != 0
        mov eax, @Ctx.iDr7
        or eax, g_dwIsHardwareTF
        mov @Ctx.iDr7, eax
        mov g_dwIsHardwareTF, 0
    .endif
    
    ;如果是硬件断点产生的单步异常，那么暂时取消断点并将TF位置1，之后下次单步异常时恢复硬件断点
    mov eax, @Ctx.regEip
    .if eax == @Ctx.iDr0
        and @Ctx.iDr7, 0FFFFFFFEh
        or @Ctx.regFlag, 100h  
        mov g_dwIsHardwareTF, 1
    .elseif eax == @Ctx.iDr1
        and @Ctx.iDr7, 0FFFFFFFBh
        or @Ctx.regFlag, 100h  
        mov g_dwIsHardwareTF, 4
    .elseif eax == @Ctx.iDr2
        and @Ctx.iDr7, 0FFFFFFEFh
        or @Ctx.regFlag, 100h  
        mov g_dwIsHardwareTF, 10h
    .elseif eax == @Ctx.iDr3
        and @Ctx.iDr7, 0FFFFFFBFh
        or @Ctx.regFlag, 100h  
        mov g_dwIsHardwareTF, 40h
    .endif
    
    ;内存断点做下特殊处理，通过将单步标志置1让流程走到用户输入处
    mov eax, @Ctx.iDr6
    and eax, 0Fh
    .if (g_dwIsHardwareTF == 0 && eax != 0)
        mov g_dwIsStepTF, 1
    .endif
    
    xor eax, eax
    mov @Ctx.iDr6, eax      ;每次提交异常前建议清空dr6
    invoke SetThreadContext, @hThread, addr @Ctx
    invoke CloseHandle, @hThread
    mov eax, g_dwIsHardwareTF
    ret
StepHWBreakPoint endp

; ---------------------------------------------------------------------------
ShowHWBreakPoint proc uses ebx pEvent: ptr DEBUG_EVENT
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @pszType: LPVOID
    LOCAL @dwLen: DWORD
    invoke crt_printf, offset g_szHWBreakPointTitle
    
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, [ebx].dwThreadId
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
    
    mov eax, @Ctx.iDr7
    and eax, 1
    .if (eax == 1 || g_dwIsHardwareTF == 1)
        ShowHWBP 0, 16, 18
    .endif

    mov eax, @Ctx.iDr7
    and eax, 4
    .if (eax == 4 || g_dwIsHardwareTF == 4)
        ShowHWBP 1, 20, 22
    .endif

    mov eax, @Ctx.iDr7
    and eax, 10h
    .if (eax == 10h || g_dwIsHardwareTF == 10h)
        ShowHWBP 2, 24, 26
    .endif
    
    mov eax, @Ctx.iDr7
    and eax, 40h
    .if (eax == 40h || g_dwIsHardwareTF == 40h)
        ShowHWBP 3, 28, 30
    .endif
    
    invoke CloseHandle, @hThread
    assume ebx:nothing
    ret
ShowHWBreakPoint endp
; ---------------------------------------------------------------------------
DelHWBreakPoint proc uses ebx pEvent: ptr DEBUG_EVENT, dwId:DWORD
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @pszType: LPVOID
    LOCAL @dwLen: DWORD
    
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, [ebx].dwThreadId
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
    
    ;删除硬件断点时需要判断一下当前挂起状态是不是由硬件断点导致的，如果是那么需要清空tf标志位防止硬件断点被恢复
    mov eax, @Ctx.regEip
    .if dwId == 0
        .if @Ctx.iDr0 == eax && g_dwIsHardwareTF != 0
            mov g_dwIsHardwareTF, 0
        .else
            and @Ctx.iDr7, 0FFFFFFFEh     
        .endif
    .elseif dwId == 1
        .if @Ctx.iDr1 == eax && g_dwIsHardwareTF != 0
            mov g_dwIsHardwareTF, 0
        .else
            and @Ctx.iDr7, 0FFFFFFFBh   
        .endif
    .elseif dwId == 2
        .if @Ctx.iDr2 == eax && g_dwIsHardwareTF != 0
            mov g_dwIsHardwareTF, 0
        .else
            and @Ctx.iDr7, 0FFFFFFEFh   
        .endif
    .elseif dwId == 3
        .if @Ctx.iDr3 == eax && g_dwIsHardwareTF != 0
            mov g_dwIsHardwareTF, 0
        .else
            and @Ctx.iDr7, 0FFFFFFBFh   
        .endif
    .endif
    
    invoke SetThreadContext, @hThread, addr @Ctx
    invoke CloseHandle, @hThread
    assume ebx:nothing
    ret
DelHWBreakPoint endp

; ---------------------------------------------------------------------------
SetMemBreakPoint proc uses ebx ecx pAddr:DWORD, dwLen:DWORD, dwType:DWORD
    LOCAL @mbi: MEMORY_BASIC_INFORMATION
    LOCAL @pEndAddr: DWORD
    LOCAL @pTmpAddr: DWORD
    LOCAL @pBp: DWORD
    LOCAL @pBpPage: DWORD
    LOCAL @pPage: DWORD
    LOCAL @dwStackCnt: DWORD
    LOCAL @pBaseAddr: DWORD
    LOCAL @dwProtect: DWORD
    LOCAL @dwId: DWORD
    LOCAL @dwOldProtect: DWORD
    mov @dwStackCnt, 0
    
    mov eax, pAddr
    add eax, dwLen
    mov @pEndAddr, eax
    mov eax, pAddr
    mov @pTmpAddr, eax
    
    mov ebx, @pEndAddr
    
    ;获取/检查内存页信息
    .while @pTmpAddr < ebx
        invoke VirtualQueryEx,g_hProc, @pTmpAddr, addr @mbi, size @mbi
        .if eax == 0
            xor ecx, ecx
            .while ecx < @dwStackCnt
                add esp, 8
                inc ecx
            .endw
            ret     ;return false
        .endif
        mov eax, @mbi.BaseAddress
        mov @pTmpAddr, eax
        add @pTmpAddr, 1000h
        ;如果内存无法访问返回false
        .if @mbi.State == 10000h
            xor ecx, ecx
            .while ecx < @dwStackCnt
                add esp, 8
                inc ecx
            .endw
            mov eax, FALSE
            ret
        .else
            ;把分页信息临时存到栈里
            push @mbi.BaseAddress
            push @mbi.Protect
            inc @dwStackCnt
        .endif
    .endw

    ;内存断点添加至链表
    invoke crt_malloc, size MemBPList
    mov @pBp, eax
    invoke RtlZeroMemory, eax, size MemBPList
    mov ebx, @pBp
    assume ebx:ptr MemBPList
    mov eax, g_dwIdCnt
    mov @dwId, eax
    mov [ebx].m_dwId, eax       ;id
    mov eax, pAddr
    mov [ebx].m_pAddr, eax      ;内存断点地址
    mov eax, dwLen
    mov [ebx].m_dwLen, eax      ;涉及内存的长度
    mov eax, dwType
    mov [ebx].m_dwType, eax     ;断点类型(读/写)
    inc g_dwIdCnt
    .if g_pMemBPList == NULL
        mov g_pMemBPList, ebx
    .else
        mov ebx, g_pMemBPList
        .while [ebx].m_pNext != NULL
            mov ebx, [ebx].m_pNext
        .endw
        mov eax, @pBp
        mov [ebx].m_pNext, eax
    .endif
    
    ;断点分页关系信息 以及 分页信息添加至链表
    xor ecx, ecx
    .while @dwStackCnt > 0
        pop @dwProtect
        pop @pBaseAddr
        
        ;断点分页表链表
        invoke crt_malloc, size BPPageList
        mov @pBpPage, eax
        invoke RtlZeroMemory, eax, size BPPageList
        mov ebx, @pBpPage
        assume ebx:ptr BPPageList
        mov eax, @dwId
        mov [ebx].m_dwBPId, eax     ;id
        mov eax, @pBaseAddr 
        mov [ebx].m_pBaseAddr, eax  ;分页基地址
        .if g_pBPPageList == NULL   ;如果链表中无元素，则直接添加到头部
            mov g_pBPPageList, ebx
        .else
            mov ebx, g_pBPPageList
            .while [ebx].m_pNext != NULL    ;否则添加至链表尾部
                mov ebx, [ebx].m_pNext
            .endw
            mov eax, @pBpPage
            mov [ebx].m_pNext, eax
        .endif
        
        ;分页表链表
        invoke crt_malloc, size PageList
        mov @pPage, eax
        invoke RtlZeroMemory, eax, size PageList
        mov ebx, @pPage
        assume ebx:ptr PageList
        mov eax, @pBaseAddr
        mov [ebx].m_pBaseAddr, eax      ;分页基地址
        mov eax, @dwProtect
        mov [ebx].m_dwProtect, eax      ;原内存属性
        mov [ebx].m_dwCnt, 1             ;引用计数
        .if g_pPageList == NULL
            mov g_pPageList, ebx        ;如果链表中无元素，则直接添加到头部
        .else
            mov ebx, g_pPageList
            .while [ebx].m_pNext != NULL    ;寻找链表尾并添加
                mov eax, @pBaseAddr
                .if [ebx].m_pBaseAddr == eax    ;如果之前记录过该地址，那么增加引用计数即可
                    inc [ebx].m_dwCnt
                    invoke crt_free, @pPage
                    jmp @f
                .endif 
                mov ebx, [ebx].m_pNext          
            .endw
            mov eax, @pPage
            mov [ebx].m_pNext, eax
@@:
        .endif
    dec @dwStackCnt     ;循环计数++
    .endw
    
    assume ebx:nothing
    invoke VirtualProtectEx, g_hProc, pAddr, dwLen, PAGE_NOACCESS, addr @dwOldProtect
    ret
SetMemBreakPoint endp

; ---------------------------------------------------------------------------
RecoverProtectSetTF proc uses ebx ecx esi edi pEvent: ptr DEBUG_EVENT, pAddr:LPVOID, dwType:DWORD
    LOCAL @mbi: MEMORY_BASIC_INFORMATION
    LOCAL @dwTid:DWORD
    LOCAL @dwId:DWORD
    LOCAL @pBaseAddr:DWORD
    LOCAL @dwProtect:DWORD
    LOCAL @dwOldProtect:DWORD
    mov @dwId, -1
    
    mov ebx, pEvent
    assume ebx:ptr DEBUG_EVENT
    mov eax, [ebx].dwThreadId
    mov @dwTid, eax
    
    invoke VirtualQueryEx, g_hProc, pAddr, addr @mbi, size @mbi
    mov eax, @mbi.BaseAddress
    mov @pBaseAddr, eax
    
    assume ebx: ptr PageList
    mov ebx, g_pPageList
    .while ebx != NULL
        mov eax, @pBaseAddr
        .if eax == [ebx].m_pBaseAddr
            invoke VirtualProtectEx, g_hProc,[ebx].m_pBaseAddr, 1, [ebx].m_dwProtect, addr @dwOldProtect
            mov [ebx].m_dwIsTF, 1
            invoke SetTF, @dwTid
            .break
        .endif
        mov ebx, [ebx].m_pNext
    .endw

    mov ebx, g_pMemBPList
    assume ebx:ptr MemBPList
    .while ebx != NULL
        mov esi, [ebx].m_pAddr
        mov edi, esi
        add edi, [ebx].m_dwLen
        mov eax, [ebx].m_dwType
        .if pAddr >= esi && pAddr < edi && dwType == eax    ;地址在断点范围内，并且异常类型与断点类型相同
            push [ebx].m_dwId
            pop @dwId
            mov [ebx].m_dwIsTF, 1       ;单步异常标志置1
        .endif
        mov ebx, [ebx].m_pNext
    .endw
    
    ;如果ID == -1表示不是断点引发的异常，返回FALSE
    .if @dwId == -1
        mov eax, FALSE
    .else
        mov eax, TRUE
    .endif
    assume ebx:nothing
    ret
RecoverProtectSetTF endp

; ---------------------------------------------------------------------------
ReSettingMemBreakPoint proc uses ebx ecx 
    LOCAL @dwOldProtect:DWORD
    
    ;遍历分页链表，找到TF置1的分页重新设置不可访问属性
    assume ebx: ptr PageList
    mov ebx, g_pPageList
    .while ebx != NULL
        .if [ebx].m_dwIsTF == 1
            invoke VirtualProtectEx, g_hProc,[ebx].m_pBaseAddr, 1, PAGE_NOACCESS, addr @dwOldProtect
            mov [ebx].m_dwIsTF, 0
            .break
        .endif
        mov ebx, [ebx].m_pNext
    .endw
    
    assume ebx:nothing
    ret
ReSettingMemBreakPoint endp

; ---------------------------------------------------------------------------
ShowMemBreakPoint proc uses ebx
    LOCAL @pType:DWORD
    
    invoke crt_printf, offset g_szHWBreakPointTitle   
    
    mov ebx, g_pMemBPList
    assume ebx:ptr MemBPList
    .while ebx != NULL
        .if [ebx].m_dwType == MM_READ
            mov eax, offset g_szAccess
        .else
            mov eax, offset g_szWrite
        .endif
        mov @pType, eax
        invoke crt_printf, offset g_szHWBreakPoint, [ebx].m_dwId, [ebx].m_pAddr, @pType, [ebx].m_dwLen
        mov ebx, [ebx].m_pNext
    .endw
    
    ret
ShowMemBreakPoint endp

; ---------------------------------------------------------------------------
DelMemBreakPoint proc uses ebx edx dwId:DWORD
    LOCAL @dwIsValid:DWORD
    LOCAL @pLastMemBPList:ptr MemBPList
    LOCAL @pLastBPPageList:ptr BPPageList
    LOCAL @pLastPageList:ptr PageList
    LOCAL @pTmpAddr:LPVOID
    LOCAL @dwOldProtect:DWORD
    LOCAL @dwStackCnt:DWORD
    
    ;遍历断点链表查找对应ID并删除
    mov @dwIsValid, NULL
    mov @pLastMemBPList, NULL
    mov ebx, g_pMemBPList
    assume ebx:ptr MemBPList
    assume edx:ptr MemBPList
    .while ebx != NULL
        mov eax, dwId
        .if [ebx].m_dwId == eax
                mov eax, [ebx].m_pNext
            .if ebx == g_pMemBPList
                mov g_pMemBPList, eax
            .else
                mov edx, @pLastMemBPList
                mov [edx].m_pNext, eax
            .endif
            invoke crt_free, ebx
            mov @dwIsValid, TRUE
            .break
        .endif
        mov @pLastMemBPList, ebx
        mov ebx, [ebx].m_pNext
    .endw
    
    ;ID无效提前退出
    .if @dwIsValid == FALSE
        mov eax, FALSE
        ret
    .endif
    
    mov @dwStackCnt, 0
    assume ebx:ptr BPPageList
    assume edx:ptr BPPageList
    mov @pLastBPPageList, NULL
    mov ebx, g_pBPPageList
    .while ebx != NULL
        mov eax, dwId
        .if [ebx].m_dwBPId == eax
            mov eax, [ebx].m_pNext
            .if ebx == g_pBPPageList
                mov g_pBPPageList, eax
            .else
                mov edx, @pLastBPPageList
                mov [edx].m_pNext, eax   
            .endif
            push [ebx].m_pBaseAddr          ;栈中临时存储页基址
            inc @dwStackCnt                 ;栈内存储计数++
            push eax         ;存储一下当前链表位置
            invoke crt_free, ebx 
            pop ebx          ;由于需要继续遍历链表中剩余元素, 所以下一轮从当前节点遍历
            .continue
        .endif
        mov @pLastBPPageList, ebx
        mov ebx, [ebx].m_pNext
    .endw

    assume ebx:ptr PageList
    assume edx:ptr PageList
    .while @dwStackCnt > 0
        pop @pTmpAddr                       ;从栈中弹出一个页基址
        mov @pLastPageList, NULL
        mov ebx, g_pPageList    
        .while ebx != NULL              
            mov eax, @pTmpAddr
            .if [ebx].m_pBaseAddr == eax    
                dec [ebx].m_dwCnt           ;如果页基址对得上,引用计数-1
                .if [ebx].m_dwCnt == 0      ;如果引用计数为0,从链表中删除该节点
                    mov eax, [ebx].m_pNext
                    .if ebx == g_pPageList
                        mov g_pPageList, eax
                     .else
                        mov edx, @pLastPageList
                        mov [edx].m_pNext, eax
                    .endif
                    invoke VirtualProtectEx, g_hProc, [ebx].m_pBaseAddr, 1, [ebx].m_dwProtect, addr @dwOldProtect ;删除节点前先恢复目标页属性
                    invoke crt_free, ebx
                .endif
                .break                      ;处理完跳出当前链表遍历循环,去匹配下一轮
            .endif
            mov @pLastPageList, ebx     ;保存父节点
            mov ebx, [ebx].m_pNext
        .endw
        dec @dwStackCnt
    .endw
    
    assume ebx:nothing
    assume edx:nothing
    ret
DelMemBreakPoint endp
; ---------------------------------------------------------------------------
ShowModuleList proc uses ebx edx esi edi hProc:DWORD
    ;未指定函数地址时输出所有模块列表
    ;指定函数地址时返回目标内存中函数名的字符串地址
    LOCAL @dwArySize:DWORD
    LOCAL @pModuleAry:ptr DWORD
    LOCAL @hMod:DWORD
    LOCAL @ModInfo[3]:DWORD
    LOCAL @dwCnt:DWORD
    LOCAL @pszFuncName:DWORD
    
    mov @dwArySize, 0
    
    ;获取模块数量
    invoke EnumProcessModules, hProc, NULL, 0, addr @dwArySize
    .if @dwArySize == 0
        xor eax, eax
        ret
    .endif
    invoke crt_malloc, @dwArySize
    mov @pModuleAry, eax
    
    ;获取模块信息
    invoke EnumProcessModules, hProc, @pModuleAry, @dwArySize, NULL
    xor eax, eax
    mov @dwCnt, eax
    xor ecx, ecx
    .while ecx < @dwArySize
        mov eax, @pModuleAry
        add eax, @dwCnt
        mov eax, [eax]
        mov @hMod, eax
        invoke GetModuleInformation, hProc, @hMod, addr @ModInfo, 12
        
        ;如果没有指定函数地址，则遍历输出模块
        invoke GetModuleFileNameEx, hProc, @hMod, offset g_szModFullName, 1000h
        .if eax == 0
            .continue
        .endif
        invoke GetModuleBaseName, hProc, @hMod, offset g_szModBaseName, 1000h
        .if eax == 0
            .continue
        .endif
        invoke crt_printf, offset g_szModuleList, @hMod, offset g_szModBaseName, offset g_szModFullName
            
        add @dwCnt, 4
        mov ecx, @dwCnt
    .endw
        
    ;清理资源
ShowModuleList_End:
    invoke crt_free, @pModuleAry
    mov eax, @pszFuncName
    ret
ShowModuleList endp
; ---------------------------------------------------------------------------
GetFunctionName proc uses ebx edx ecx hProc:DWORD, dwFuncAddr:DWORD
    ;函数失败返回-1
    ;函数成功返回目标进程中函数字符串地址或函数序号
    
    LOCAL @DosHeader:IMAGE_DOS_HEADER
    LOCAL @NtHeader:IMAGE_NT_HEADERS
    LOCAL @Export:IMAGE_EXPORT_DIRECTORY
    LOCAL @dwIdx:DWORD
    LOCAL @dwFuncRva: DWORD 
    LOCAL @dwTmp:DWORD
    LOCAL @wTmp:WORD
    LOCAL @dwCnt:DWORD
    LOCAL @dwOffset:DWORD
    LOCAL @dwModBase:DWORD
    LOCAL @dwModEnd:DWORD
    LOCAL @dwArySize:DWORD
    LOCAL @pModuleAry:ptr DWORD
    LOCAL @ModInfo[3]:DWORD
    LOCAL @dwOrdinal:DWORD
    
    mov @dwArySize, 0
    
    ;获取模块数量
    invoke EnumProcessModules, hProc, NULL, 0, addr @dwArySize
    .if @dwArySize == 0
        xor eax, eax
        ret
    .endif
    invoke crt_malloc, @dwArySize
    mov @pModuleAry, eax
    
    ;获取模块信息
    invoke EnumProcessModules, hProc, @pModuleAry, @dwArySize, NULL
    xor eax, eax
    mov @dwCnt, eax
    xor ecx, ecx
    .while ecx < @dwArySize
        mov eax, @pModuleAry
        add eax, @dwCnt
        mov eax, [eax]
        mov @dwModBase, eax
        invoke GetModuleInformation, hProc, @dwModBase, addr @ModInfo, 12
        mov eax, @dwModBase
        add eax, [@ModInfo+4]
        mov @dwModEnd, eax
        mov eax, dwFuncAddr
        
        .if eax >= @dwModBase && eax < @dwModEnd
            .break
        .endif
        
        add @dwCnt, 4
        mov ecx, @dwCnt
    .endw
    
    invoke GetModuleBaseName, hProc, @dwModBase, offset g_szModBaseName, 1000h
    
    mov eax, dwFuncAddr
    sub eax, @dwModBase
    mov @dwFuncRva, eax
    
    invoke ReadProcessMemory, hProc, @dwModBase, addr @DosHeader, size @DosHeader, NULL
    .if eax == 0
        mov eax, -1
        ret
    .endif
    
    ;判断MZ标志
    movzx eax, @DosHeader.e_magic
    .if eax != 5a4dh
        mov eax, -1
        ret
    .endif
    
    ;取nt头，判断PE标志
    mov ebx, @dwModBase
    add ebx, @DosHeader.e_lfanew
    invoke ReadProcessMemory, hProc, ebx, addr @NtHeader, size @NtHeader, NULL
    .if eax == 0
        ret
    .endif
    mov eax, @NtHeader.Signature
    .if eax != 4550h
        mov eax, -1
        ret
    .endif
    
    ;取导出表
    lea ebx, @NtHeader.OptionalHeader.DataDirectory
    assume ebx: ptr IMAGE_DATA_DIRECTORY
    mov ebx, [ebx].VirtualAddress
    add ebx, @dwModBase
    invoke ReadProcessMemory, hProc, ebx, addr @Export, size @Export, NULL
    .if eax == 0
        mov eax, -1
        ret
    .endif
    
    
    ;遍历函数表
    mov edx,@Export.AddressOfFunctions
    add edx, @dwModBase
    mov @dwOffset, edx
    mov @dwIdx, -1
    xor ecx, ecx
    mov @dwCnt, ecx
    .while ecx < @Export.NumberOfFunctions
        invoke ReadProcessMemory, hProc, @dwOffset, addr @dwTmp,size @dwTmp, NULL
        .if eax == 0
            mov eax, -1
            ret
        .endif
        
        mov eax, @dwTmp
        .if eax == @dwFuncRva
            mov ecx, @dwCnt
            mov @dwIdx, ecx
            .break
        .endif
        add @dwOffset, 4
        inc @dwCnt
        mov ecx, @dwCnt
    .endw
    .if @dwIdx == -1
        jmp GetFunctionName_End
        ret
    .endif
    
    ;遍历名称序号表
    mov edx, @Export.AddressOfNameOrdinals
    add edx, @dwModBase
    mov @dwOffset, edx
    xor ecx, ecx
    mov @dwCnt, ecx
    .while ecx < @Export.NumberOfNames
        invoke ReadProcessMemory, hProc, @dwOffset, addr @wTmp, size @wTmp, NULL
        .if eax == 0
            mov eax, -1
            ret
        .endif
        movzx eax, @wTmp
        .if eax == @dwIdx
            mov ecx, @dwCnt
            mov @dwIdx, ecx
            .break
        .endif
        add @dwOffset, 2
        inc @dwCnt
        mov ecx, @dwCnt
    .endw
    .if @dwIdx == -1
        add eax, @Export.nBase
        mov @dwOrdinal, eax
        invoke crt_printf, g_szOrdinal, offset g_szModBaseName, @dwOrdinal
        ret
    .else
        mov edx, @Export.AddressOfNames
        add edx, @dwModBase
        mov eax, @dwIdx
        shl eax, 2
        add edx, eax
        invoke ReadProcessMemory, hProc, edx, addr @dwTmp, size  @dwTmp, NULL
        .if eax == 0
            mov eax, -1
            ret
        .endif
        mov eax, @dwTmp
        add eax, @dwModBase
        mov @dwTmp, eax
        invoke ReadProcessMemory, hProc, @dwTmp, offset g_szBuf, 1024, NULL
        invoke crt_printf, offset g_szFuncName, offset g_szModBaseName, offset g_szBuf  
        ret
    .endif
GetFunctionName_End:  
    invoke crt_printf, offset g_szNoFunc, offset g_szModBaseName, dwFuncAddr
    ret
GetFunctionName endp
; ---------------------------------------------------------------------------
GoToRet proc uses ebx pEvent:ptr DEBUG_EVENT    ;执行到返回
    mov g_dwIsGoRet, TRUE
    invoke StepOver, pEvent
    ret
GoToRet endp

; ---------------------------------------------------------------------------
_IsRet proc uses ebx pEvent: ptr DEBUG_EVENT      ;IsRet进一步封装
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @pBuf[1024]: BYTE
    
    mov ebx, pEvent
    assume ebx: ptr DEBUG_EVENT
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, [ebx].dwThreadId
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
    invoke CloseHandle, @hThread
    
     ;判断是否为call指令
    invoke ReadProcessMemory, g_hProc, @Ctx.regEip, addr @pBuf, 1024, NULL
    invoke IsRet, @Ctx.regEip, addr @pBuf, 1024
    ret
_IsRet endp
; ---------------------------------------------------------------------------
MemoryDump proc uses ebx ecx pszDumpFile:LPCSTR
    LOCAL @DosHeader:IMAGE_DOS_HEADER
    LOCAL @NtHeader:IMAGE_NT_HEADERS
    LOCAL @FileHeader: IMAGE_FILE_HEADER
    LOCAL @SectionHeader:IMAGE_SECTION_HEADER
    LOCAL @hMod:DWORD
    LOCAL @hFile:DWORD
    LOCAL @dwOffset:DWORD
    LOCAL @pBuf:DWORD
    LOCAL @dwCnt:DWORD
    LOCAL @dwSectionNum:DWORD
    
    xor eax, eax
    mov @hMod, eax
    invoke EnumProcessModules, g_hProc, addr @hMod, 4, NULL
    .if @hMod == 0
        ret
    .endif
    
    ;创建文件
    invoke CreateFile, pszDumpFile, GENERIC_READ or GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    .if eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .endif
    mov @hFile, eax
    
    ;DOS头
    invoke ReadProcessMemory, g_hProc, @hMod, addr @DosHeader, size @DosHeader, NULL
    
    ;Nt头
    mov eax, @DosHeader.e_lfanew
    add eax, @hMod
    mov @dwOffset, eax
    invoke ReadProcessMemory, g_hProc, @dwOffset, addr @NtHeader, size @NtHeader, NULL
    
    ;偏移指向第一个节区头
    add @dwOffset, 4
    add @dwOffset, size @FileHeader
    movzx eax, @NtHeader.FileHeader.SizeOfOptionalHeader
    add @dwOffset, eax
    
    ;文件写入PE头
    invoke crt_malloc, @NtHeader.OptionalHeader.SizeOfHeaders
    mov @pBuf, eax
    invoke ReadProcessMemory, g_hProc, @hMod, @pBuf, @NtHeader.OptionalHeader.SizeOfHeaders, NULL
    invoke WriteFile, @hFile, @pBuf, @NtHeader.OptionalHeader.SizeOfHeaders, NULL, NULL
    invoke crt_free, @pBuf
     
    xor ecx, ecx
    mov @dwCnt, ecx
    movzx eax, @NtHeader.FileHeader.NumberOfSections
    mov @dwSectionNum, eax
    .while ecx < @dwSectionNum
        invoke ReadProcessMemory, g_hProc, @dwOffset, addr @SectionHeader, size @SectionHeader, NULL
        
        ;写入节区头
        mov ebx, @dwOffset
        sub ebx, @hMod
        invoke SetFilePointer, @hFile, ebx, NULL, FILE_BEGIN
        invoke WriteFile, @hFile, addr @SectionHeader, size @SectionHeader, NULL, NULL      ;文件中写入节区头
        
        ;写入节区数据
        invoke crt_malloc, @SectionHeader.SizeOfRawData
        mov @pBuf, eax
        mov ebx, @hMod
        add ebx, @SectionHeader.VirtualAddress
        invoke ReadProcessMemory, g_hProc, ebx, @pBuf, @SectionHeader.SizeOfRawData, NULL     ;内存读节区数据
        invoke SetFilePointer, @hFile, @SectionHeader.PointerToRawData, NULL, FILE_BEGIN    ;设置文件指针
        invoke WriteFile, @hFile, @pBuf, @SectionHeader.SizeOfRawData, NULL, NULL           ;文件中写入节区数据
        invoke crt_free, @pBuf
        
        add @dwOffset, size @SectionHeader
        inc @dwCnt
        mov ecx, @dwCnt
    .endw
    
    invoke CloseHandle, @hFile
    mov eax, 1 
    ret
MemoryDump endp
; ---------------------------------------------------------------------------
ShowMemory proc uses ebx ecx dwAddr:DWORD, dwCnt:DWORD
    LOCAL @bHexAry[17]:BYTE
    LOCAL @dwCnt:DWORD
    LOCAL @dwRet:DWORD
    LOCAL @dwLoopCnt:DWORD
    LOCAL @dwCurAddr:DWORD
    
    xor ecx, ecx
    mov @dwRet, ecx
    mov @dwLoopCnt, ecx
    .while ecx < dwCnt
        mov eax, dwAddr
        add eax, @dwRet
        mov @dwCurAddr, eax
        
        invoke RtlZeroMemory, addr @bHexAry, 17
        invoke ReadProcessMemory, g_hProc, @dwCurAddr, addr @bHexAry, 16, NULL
        
        mov @dwCnt, 15
        .while @dwCnt != -1
            lea ebx, @bHexAry
            mov ecx, @dwCnt
            xor eax, eax
            mov al, byte ptr ds:[ebx+ecx]
            push eax
            dec @dwCnt
        .endw
        push @dwCurAddr
        push offset g_szHex
        call crt_printf
        add esp, 48h
        invoke ShowMemoryString, addr @bHexAry
        
        add @dwRet, 16
        inc @dwLoopCnt
        mov ecx, @dwLoopCnt
    .endw
    mov eax, @dwRet
    ret
ShowMemory endp
; ---------------------------------------------------------------------------
ShowMemoryString proc uses ebx edx pszBuf:ptr BYTE
    LOCAL @dwCnt:DWORD  

    mov @dwCnt, 0
    .while @dwCnt < 16
        mov ebx, @dwCnt
        mov eax, pszBuf
        add eax, ebx
        .if byte ptr [eax] < 32 || byte ptr [eax] > 126
            mov byte ptr [eax], "."
        .endif
        inc @dwCnt
    .endw
    invoke crt_printf, offset g_szTmp, pszBuf
    ret
ShowMemoryString endp
; ---------------------------------------------------------------------------
WriteReg proc uses ebx dwTid:DWORD, pszBuf:ptr BYTE
    LOCAL @pCheck:ptr BYTE
    LOCAL @dwTid:DWORD
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT
    LOCAL @dwData:DWORD
    LOCAL @dwFlag:DWORD
    
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, dwTid
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx

@@:   
    mov ebx, pszBuf
    .if byte ptr[ebx+1] != " "
        invoke crt_printf, offset g_szInputErr
        invoke CloseHandle, @hThread
        xor eax, eax
        ret
    .endif 
    invoke FindNextWord, ebx
    .if eax == 0
        invoke crt_printf, offset g_szInputErr
        invoke CloseHandle, @hThread
        xor eax, eax
        ret
    .endif
    mov ebx, eax
    
    .if @dwFlag != 1
        invoke WriteScriptCommand, offset g_szBuf
        mov @dwFlag, 1 
    .endif
    
    .if (byte ptr[ebx+0] == "e"||byte ptr[ebx+0] == "E")&&\
        (byte ptr[ebx+1] == "a"||byte ptr[ebx+1] == "A")&&\
        (byte ptr[ebx+2] == "x"||byte ptr[ebx+2] == "X")
        _WriteReg regEax
    .elseif (byte ptr[ebx+0] == "e"||byte ptr[ebx+0] == "E")&&\
            (byte ptr[ebx+1] == "c"||byte ptr[ebx+1] == "C")&&\
            (byte ptr[ebx+2] == "x"||byte ptr[ebx+2] == "X")
        _WriteReg regEcx 
    .elseif (byte ptr[ebx+0] == "e"||byte ptr[ebx+0] == "E")&&\
            (byte ptr[ebx+1] == "d"||byte ptr[ebx+1] == "D")&&\
            (byte ptr[ebx+2] == "x"||byte ptr[ebx+2] == "X")
        _WriteReg regEdx  
    .elseif (byte ptr[ebx+0] == "e"||byte ptr[ebx+0] == "E")&&\
            (byte ptr[ebx+1] == "b"||byte ptr[ebx+1] == "B")&&\
            (byte ptr[ebx+2] == "x"||byte ptr[ebx+2] == "X")
        _WriteReg regEbx  
    .elseif (byte ptr[ebx+0] == "e"||byte ptr[ebx+0] == "E")&&\
            (byte ptr[ebx+1] == "s"||byte ptr[ebx+1] == "S")&&\
            (byte ptr[ebx+2] == "i"||byte ptr[ebx+2] == "I")
        _WriteReg regEsi  
    .elseif (byte ptr[ebx+0] == "e"||byte ptr[ebx+0] == "E")&&\
            (byte ptr[ebx+1] == "d"||byte ptr[ebx+1] == "D")&&\
            (byte ptr[ebx+2] == "i"||byte ptr[ebx+2] == "I")
        _WriteReg regEdi  
    .elseif (byte ptr[ebx+0] == "e"||byte ptr[ebx+0] == "E")&&\
            (byte ptr[ebx+1] == "s"||byte ptr[ebx+1] == "S")&&\
            (byte ptr[ebx+2] == "p"||byte ptr[ebx+2] == "P")
        _WriteReg regEsp  
    .elseif (byte ptr[ebx+0] == "e"||byte ptr[ebx+0] == "E")&&\
            (byte ptr[ebx+1] == "b"||byte ptr[ebx+1] == "B")&&\
            (byte ptr[ebx+2] == "p"||byte ptr[ebx+2] == "P")
        _WriteReg regEbp  
    .else
        invoke crt_printf, offset g_szInputErr
    .endif
    
    invoke SetThreadContext, @hThread, addr @Ctx
    invoke CloseHandle, @hThread
    ret
WriteReg endp
; ---------------------------------------------------------------------------
WriteMem proc uses ebx pszBuf:DWORD
    LOCAL @mbi: MEMORY_BASIC_INFORMATION
    LOCAL @dwCurAddr:DWORD
    LOCAL @pCheck:ptr BYTE
    LOCAL @bByte:DWORD
    LOCAL @dwOldProtect:DWORD
    
    mov ebx, pszBuf
    .if byte ptr[ebx+1] != " "
        invoke crt_printf, offset g_szInputErr
        xor eax, eax
        ret
    .endif 
    invoke FindNextWord, ebx
    .if eax == 0
        invoke crt_printf, offset g_szInputErr
        xor eax, eax
        ret
    .endif
    mov ebx, eax
    invoke crt_strtoul, ebx, addr @pCheck, 16
    mov ebx, @pCheck
    .if byte ptr[ebx] != 0
        invoke crt_printf, offset g_szInputErr
        ret
    .endif
    
    mov @dwCurAddr, eax
    invoke WriteScriptCommand, offset g_szBuf
    .while TRUE
        invoke VirtualQueryEx,g_hProc, @dwCurAddr, addr @mbi, size @mbi
        .if eax == 0
            invoke crt_printf, offset g_szInputErr
            ret
        .endif
        .if @mbi.State == 10000h
            invoke crt_printf, offset g_szMemErr, @dwCurAddr       ;目标内存不可访问
            ret
        .endif
        mov @bByte, 0
        invoke ReadProcessMemory, g_hProc, @dwCurAddr, addr @bByte, 1, NULL
        invoke crt_printf, offset g_szWriteMem, @dwCurAddr, @bByte
        
        .if g_dwIsScript == TRUE
            invoke ReadScriptCommand, offset g_szMemBuf
        .else
            invoke crt_gets, offset g_szMemBuf
        .endif 
        
        mov ebx, offset g_szMemBuf
        .if byte ptr[ebx] == 0
            invoke WriteScriptCommand, offset g_szMemBuf
            ret
        .endif
        invoke crt_strtoul, ebx, addr @pCheck, 16
        mov ebx, @pCheck
        .if byte ptr[ebx] != 0
            invoke crt_printf, offset g_szInputErr
            .continue
        .endif
        ;int 3
        mov @bByte, 0
        mov @bByte, eax
        invoke VirtualProtectEx, g_hProc, @dwCurAddr, 1, PAGE_EXECUTE_READWRITE, addr @dwOldProtect
        invoke WriteProcessMemory, g_hProc, @dwCurAddr, addr @bByte, 1, NULL
        invoke VirtualProtectEx, g_hProc, @dwCurAddr, 1, @dwOldProtect, addr @dwOldProtect
        invoke WriteScriptCommand, offset g_szMemBuf
        inc @dwCurAddr
    .endw
    
    ret
WriteMem endp
; ---------------------------------------------------------------------------
StartTrace proc uses ebx pEvent:ptr DEBUG_EVENT, pszBuf:ptr BYTE
    LOCAL @dwAddr:DWORD
    LOCAL @pszFileName:ptr BYTE
    LOCAL @pCheck:ptr BYTE
    LOCAL @szNumber[9]:BYTE
    
    invoke RtlZeroMemory, addr @szNumber, 9
    
    mov ebx, pszBuf
    .if byte ptr[ebx+2] != " "
        xor eax, eax
        ret
    .endif 
    
    invoke FindNextWord, ebx
    .if eax == 0
        xor eax, eax
        ret
    .endif
    
    mov ebx, eax
    push ebx
    invoke crt_memcpy, addr @szNumber, ebx, 8
    invoke crt_strtoul, addr @szNumber, addr @pCheck, 16
    mov ebx, @pCheck
    .if byte ptr[ebx] != 0
        xor eax, eax
        ret
    .endif
    mov @dwAddr, eax
    pop ebx
    
    invoke FindNextWord, ebx
    .if eax == 0
        xor eax, eax
        ret
    .endif
    mov @pszFileName, eax
    
    invoke CreateFile, @pszFileName, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    .if eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .endif
    
    mov g_hTraceFile, eax
    mov g_dwIsTrace, TRUE   
    mov eax, @dwAddr
    mov g_dwTraceEndAddr, eax
    invoke StepInto, pEvent
    
    mov eax, 1
    ret
StartTrace endp
; ---------------------------------------------------------------------------
WriteTraceFile proc uses ebx pEvent:ptr DEBUG_EVENT
    LOCAL @pCodeBuf[128]:BYTE
    LOCAL @pszBuf[128]:BYTE
    LOCAL @hThread: HANDLE
    LOCAL @Ctx: CONTEXT   
    LOCAL @dwStrLen:DWORD
    LOCAL @dwTid:DWORD
    LOCAL @dwCRLF:DWORD
    
    mov ebx, pEvent
    assume ebx:ptr DEBUG_EVENT
    mov eax, [ebx].dwThreadId
    mov @dwTid, eax
    assume ebx:nothing
    
    ;如果文件句柄无效则返回
    .if g_hTraceFile == 0 || g_dwIsTrace == FALSE
        xor eax, eax
        ret
    .endif
    
    mov @dwCRLF, 0A0Dh
    invoke RtlZeroMemory, addr @pCodeBuf, 128
    invoke RtlZeroMemory, addr @pszBuf, 128
    
    ;获取目标线程的寄存器环境
    invoke OpenThread, THREAD_ALL_ACCESS, FALSE, @dwTid
    mov @hThread, eax
    invoke RtlZeroMemory, addr @Ctx, size @Ctx
    mov @Ctx.ContextFlags, CONTEXT_ALL
    invoke GetThreadContext, @hThread, addr @Ctx
    
    ;获取反汇编
    invoke ReadProcessMemory, g_hProc, @Ctx.regEip, addr @pCodeBuf, 128, NULL
    invoke GetDisAsm, @Ctx.regEip, addr @pCodeBuf, 128, addr @pszBuf, 128, g_hProc, GetFunctionName2
    mov @dwStrLen, eax
    
    ;写入文件
    invoke WriteFile, g_hTraceFile, addr @pszBuf, @dwStrLen, NULL, NULL
    invoke WriteFile, g_hTraceFile, addr @dwCRLF, 2, NULL, NULL
    
    ;判断追踪结束
    mov eax, @Ctx.regEip
    .if eax == g_dwTraceEndAddr
        invoke EndTrace
    .else
        invoke StepInto, pEvent
    .endif
    
    invoke CloseHandle, @hThread
    ret
WriteTraceFile endp
; ---------------------------------------------------------------------------
EndTrace proc uses ebx 

    mov g_dwIsTrace, FALSE
    mov g_dwTraceEndAddr, 0
    invoke CloseHandle, g_hTraceFile
    mov g_hTraceFile, 0
    
    ret
EndTrace endp
; ---------------------------------------------------------------------------
GetFunctionName2 proc uses ebx edx ecx hProc:DWORD, dwFuncAddr:DWORD, pszBuf:DWORD
    ;函数失败返回-1
    ;函数成功返回目标进程中函数字符串地址或函数序号
    
    LOCAL @DosHeader:IMAGE_DOS_HEADER
    LOCAL @NtHeader:IMAGE_NT_HEADERS
    LOCAL @Export:IMAGE_EXPORT_DIRECTORY
    LOCAL @dwIdx:DWORD
    LOCAL @dwFuncRva: DWORD 
    LOCAL @dwTmp:DWORD
    LOCAL @wTmp:WORD
    LOCAL @dwCnt:DWORD
    LOCAL @dwOffset:DWORD
    LOCAL @dwModBase:DWORD
    LOCAL @dwModEnd:DWORD
    LOCAL @dwArySize:DWORD
    LOCAL @pModuleAry:ptr DWORD
    LOCAL @ModInfo[3]:DWORD
    LOCAL @dwOrdinal:DWORD
    
    mov @dwArySize, 0
    
    ;获取模块数量
    invoke EnumProcessModules, hProc, NULL, 0, addr @dwArySize
    .if @dwArySize == 0
        xor eax, eax
        ret
    .endif
    invoke crt_malloc, @dwArySize
    mov @pModuleAry, eax
    
    ;获取模块信息
    invoke EnumProcessModules, hProc, @pModuleAry, @dwArySize, NULL
    xor eax, eax
    mov @dwCnt, eax
    xor ecx, ecx
    .while ecx < @dwArySize
        mov eax, @pModuleAry
        add eax, @dwCnt
        mov eax, [eax]
        mov @dwModBase, eax
        invoke GetModuleInformation, hProc, @dwModBase, addr @ModInfo, 12
        mov eax, @dwModBase
        add eax, [@ModInfo+4]
        mov @dwModEnd, eax
        mov eax, dwFuncAddr
        
        .if eax >= @dwModBase && eax < @dwModEnd
            .break
        .endif
        
        add @dwCnt, 4
        mov ecx, @dwCnt
    .endw
    
    invoke GetModuleBaseName, hProc, @dwModBase, offset g_szModBaseName, 1000h
    
    mov eax, dwFuncAddr
    sub eax, @dwModBase
    mov @dwFuncRva, eax
    
    invoke ReadProcessMemory, hProc, @dwModBase, addr @DosHeader, size @DosHeader, NULL
    .if eax == 0
        mov eax, -1
        ret
    .endif
    
    ;判断MZ标志
    movzx eax, @DosHeader.e_magic
    .if eax != 5a4dh
        mov eax, -1
        ret
    .endif
    
    ;取nt头，判断PE标志
    mov ebx, @dwModBase
    add ebx, @DosHeader.e_lfanew
    invoke ReadProcessMemory, hProc, ebx, addr @NtHeader, size @NtHeader, NULL
    .if eax == 0
        ret
    .endif
    mov eax, @NtHeader.Signature
    .if eax != 4550h
        mov eax, -1
        ret
    .endif
    
    ;取导出表
    lea ebx, @NtHeader.OptionalHeader.DataDirectory
    assume ebx: ptr IMAGE_DATA_DIRECTORY
    mov ebx, [ebx].VirtualAddress
    add ebx, @dwModBase
    invoke ReadProcessMemory, hProc, ebx, addr @Export, size @Export, NULL
    .if eax == 0
        mov eax, -1
        ret
    .endif
    
    
    ;遍历函数表
    mov edx,@Export.AddressOfFunctions
    add edx, @dwModBase
    mov @dwOffset, edx
    mov @dwIdx, -1
    xor ecx, ecx
    mov @dwCnt, ecx
    .while ecx < @Export.NumberOfFunctions
        invoke ReadProcessMemory, hProc, @dwOffset, addr @dwTmp,size @dwTmp, NULL
        .if eax == 0
            mov eax, -1
            ret
        .endif
        
        mov eax, @dwTmp
        .if eax == @dwFuncRva
            mov ecx, @dwCnt
            mov @dwIdx, ecx
            .break
        .endif
        add @dwOffset, 4
        inc @dwCnt
        mov ecx, @dwCnt
    .endw
    .if @dwIdx == -1
        jmp GetFunctionName2_End
        ret
    .endif
    
    ;遍历名称序号表
    mov edx, @Export.AddressOfNameOrdinals
    add edx, @dwModBase
    mov @dwOffset, edx
    xor ecx, ecx
    mov @dwCnt, ecx
    .while ecx < @Export.NumberOfNames
        invoke ReadProcessMemory, hProc, @dwOffset, addr @wTmp, size @wTmp, NULL
        .if eax == 0
            mov eax, -1
            ret
        .endif
        movzx eax, @wTmp
        .if eax == @dwIdx
            mov ecx, @dwCnt
            mov @dwIdx, ecx
            .break
        .endif
        add @dwOffset, 2
        inc @dwCnt
        mov ecx, @dwCnt
    .endw
    .if @dwIdx == -1
        add eax, @Export.nBase
        mov @dwOrdinal, eax
        invoke wsprintf, pszBuf, g_szOrdinal, offset g_szModBaseName, @dwOrdinal
        ret
    .else
        mov edx, @Export.AddressOfNames
        add edx, @dwModBase
        mov eax, @dwIdx
        shl eax, 2
        add edx, eax
        invoke ReadProcessMemory, hProc, edx, addr @dwTmp, size  @dwTmp, NULL
        .if eax == 0
            mov eax, -1
            ret
        .endif
        mov eax, @dwTmp
        add eax, @dwModBase
        mov @dwTmp, eax
        invoke ReadProcessMemory, hProc, @dwTmp, offset g_szBuf, 1024, NULL
        invoke wsprintf, pszBuf, offset g_szFuncName, offset g_szModBaseName, offset g_szBuf  
        ret
    .endif
GetFunctionName2_End:  
    invoke wsprintf, pszBuf, offset g_szNoFunc, offset g_szModBaseName, dwFuncAddr
    ret
GetFunctionName2 endp
; ---------------------------------------------------------------------------
LoadScript proc uses ebx pszBuf:ptr BYTE
    LOCAL @pszFileName:ptr BYTE
    
    .if g_dwIsScript == TRUE || g_hScript != NULL
        xor eax, eax
        ret
    .endif
    
    mov ebx, pszBuf
    .if byte ptr[ebx+2] != " "
        xor eax, eax
        ret
    .endif 
    
    invoke FindNextWord, ebx
    .if eax == 0
        xor eax, eax
        ret
    .endif
    mov @pszFileName, eax
    
    invoke CreateFile, @pszFileName, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    .if eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .endif
    mov g_hScript, eax
    mov g_dwIsScript, TRUE
    mov eax, 1
    ret
LoadScript endp
; ---------------------------------------------------------------------------
ReadScriptCommand proc uses ebx pszBuf:ptr BYTE

    mov ebx, pszBuf
    .while TRUE
        invoke ReadFile, g_hScript, ebx, 1, NULL, NULL
        .if byte ptr[ebx] == 0Ah || byte ptr[ebx] == "$"
            .break
        .endif
        .if byte ptr[ebx] == 0Dh
            mov byte ptr[ebx], 0
        .endif
        inc ebx
    .endw
        
    .if byte ptr[ebx] == "$"
        invoke EndScript
        xor eax, eax
        ret
    .endif
    
    mov ebx, pszBuf
    .if byte ptr [ebx] == "$"
        invoke crt_printf, offset g_szScriptEnd
    .else
        invoke crt_printf, pszBuf
    .endif
    
    invoke crt_printf, offset g_szCRLF
    ret
ReadScriptCommand endp
; ---------------------------------------------------------------------------
EndScript proc uses ebx
    invoke CloseHandle, g_hScript
    mov g_hScript, 0
    mov g_dwIsScript, FALSE
    ret
EndScript endp

; ---------------------------------------------------------------------------
SetEntryBreakPoint proc uses ebx
    LOCAL @hHandle:DWORD
    LOCAL @DosHeader:IMAGE_DOS_HEADER
    LOCAL @NtHeader:IMAGE_NT_HEADERS
    LOCAL @dwOffset:DWORD
    LOCAL @EntryPoint:DWORD
    
    invoke EnumProcessModules, g_hProc, addr @hHandle, 4, NULL
    mov eax, @hHandle
    mov @dwOffset, eax
    
    invoke ReadProcessMemory, g_hProc, @dwOffset, addr @DosHeader, size @DosHeader, NULL
    mov eax, @DosHeader.e_lfanew
    add @dwOffset, eax
    
    invoke ReadProcessMemory, g_hProc, @dwOffset, addr @NtHeader, size @NtHeader, NULL
    mov eax, @NtHeader.OptionalHeader.AddressOfEntryPoint
    add eax, @hHandle
    mov @EntryPoint, eax
    
    invoke SetBreakPoint, @EntryPoint, TRUE
    ret
SetEntryBreakPoint endp
; ---------------------------------------------------------------------------
StartScript proc uses ebx pszBuf:ptr BYTE 
    LOCAL @pszFileName:ptr BYTE
    
    .if g_dwIsScript == TRUE || g_hScript != NULL
        xor eax, eax
        ret
    .endif
    
    mov ebx, pszBuf
    .if byte ptr[ebx+2] != " "
        xor eax, eax
        ret
    .endif 
    
    invoke FindNextWord, ebx
    .if eax == 0
        xor eax, eax
        ret
    .endif
    mov @pszFileName, eax
    
    invoke CreateFile, @pszFileName, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    .if eax == INVALID_HANDLE_VALUE
        xor eax, eax
        ret
    .endif
    mov g_hWriteScript, eax
    mov g_dwIsWriteScript, TRUE
    mov eax, 1
    ret
    
    ret
StartScript endp
; ---------------------------------------------------------------------------
WriteScriptCommand proc uses ebx pszBuf:ptr BYTE 
    LOCAL @Len:DWORD
    
    .if g_hWriteScript == 0 || g_dwIsWriteScript == FALSE
        xor eax, eax
        ret
    .endif
    
    invoke crt_strlen, pszBuf
    mov @Len, eax
    .if @Len == 0
        inc @Len
    .endif
    
    invoke WriteFile, g_hWriteScript, pszBuf, @Len, NULL, NULL
    invoke WriteFile, g_hWriteScript, offset g_szCRLF, 2, NULL, NULL
    
    ret
WriteScriptCommand endp
; ---------------------------------------------------------------------------
SaveScript proc uses ebx
    .if g_hWriteScript == 0 || g_dwIsWriteScript == FALSE
        xor eax, eax
        ret
    .endif
    invoke WriteFile, g_hWriteScript, offset g_szEnd, 1, NULL, NULL
    invoke CloseHandle, g_hWriteScript
    mov g_hWriteScript, 0
    mov g_dwIsWriteScript, FALSE
    
    ret
SaveScript endp
end start
