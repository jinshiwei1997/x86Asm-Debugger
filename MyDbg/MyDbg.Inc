.586
.model flat,stdcall
option casemap:none

ifndef SECOND_1		;如果没有定义宏SECOND_1,包含以下代码
SECOND_1 equ 1

   include windows.inc
   include user32.inc
   include kernel32.inc
   include comdlg32.inc
   include msvcrt.inc
   include psapi.inc
   
   includelib user32.lib
   includelib kernel32.lib
   includelib comdlg32.lib
   includelib msvcrt.lib
   includelib udis86.lib
   includelib psapi.lib

  
BPList struc
    m_pNext                         dd      0         ;指向下个节点的地址
    m_bDisposable                   db      0           ;是否为一次性断点
    m_bFlag                         db      0           ;断点是否有效
    m_bTF                           db      0       ;单步异常时恢复该断点
    m_bOldByte                      db      0       ;断点处原指令
    m_pAddr                         dd      0        ; 断点地址
BPList ends

MemBPList struc
    m_pNext         dd      0
    m_dwId          dd      0       ;断点ID
    m_pAddr         dd      0       ;断点地址
    m_dwLen         dd      0       ;断点长度
    m_dwType        dd      0       ;断点类型（读/写）
    m_dwIsTF        dd      0       ;保留
MemBPList ends

BPPageList struc
    m_pNext         dd      0
    m_dwBPId        dd      0       ;断点ID
    m_pBaseAddr     dd      0       ;页基址
BPPageList ends

PageList struc
    m_pNext         dd      0       
    m_pBaseAddr     dd      0       ;页基址
    m_dwProtect     dd      0       ;原内存属性
    m_dwCnt         dd      0       ;引用计数
    m_dwIsTF        dd      0       ;TF单步标志
PageList ends

MM_READ equ 0
MM_WRITE equ 1

CreateProc              proto                                           ;进程创建
ShowCtxWaitInput        proto dwTid:DWORD, pEvent:ptr DEBUG_EVENT       ;输出环境信息、等待用户输入
EventLoop               proto                                           ;事件处理循环
SetTF                   proto dwTid:DWORD
SetBreakPoint           proto pAddr:LPVOID, bDisposable:BYTE            ;设置软件断点
SetHWBreakPoint         proto pEvent:ptr DEBUG_EVENT, pAddr:LPVOID, dwType:DWORD, dwLen:DWORD       ;设置硬件断点
SetMemBreakPoint        proto pAddr:DWORD, dwLen:DWORD, dwType:DWORD    ;设置内存断点
DelBreakPoint           proto dwId:DWORD                                ;删除断点
DelHWBreakPoint         proto pEvent: ptr DEBUG_EVENT, dwId:DWORD       ;删除硬件断点
DelMemBreakPoint        proto dwId:DWORD
StepHWBreakPoint        proto dwTid:DWORD                               ;硬件步过
StepInto                proto pEvent: ptr DEBUG_EVENT                   ;单步步入
StepOver                proto pEvent: ptr DEBUG_EVENT                   ;单步步过
ExceptionEvent          proto pEvent: ptr DEBUG_EVENT                   ;异常事件处理
InputCommand            proto pEvent: ptr DEBUG_EVENT                   ;接收并处理用户输入
RecoverCodeSetTF        proto pEvent: ptr DEBUG_EVENT                   ;TF位置1，暂时取消软件断点
RecoverProtectSetTF     proto pEvent: ptr DEBUG_EVENT, pAddr:LPVOID, dwType:DWORD   ;置位TF，暂时取消内存断点
ReSettingBraekPoint     proto                                           ;单步异常后恢复软件断点
ReSettingMemBreakPoint  proto                                           ;单步异常后恢复内存断点
ShowContext             proto  dwTid: DWORD                             ;输出线程上下文
ShowBreakPoint          proto                                           ;列出所有断点
ShowHWBreakPoint        proto pEvent: ptr DEBUG_EVENT                   ;列出所有硬件断点
ShowMemBreakPoint       proto                                           ;列出所有内存断点
ShowCurCode             proto dwTid: DWORD, dwCnt: DWORD                ;输出反汇编代码
Unassemble              proto pEvent: ptr DEBUG_EVENT, dwCnt:DWORD      ;查看反汇编代码
IsCall                  proto dwEIP:DWORD, bCode:DWORD, dwLen:DWORD     ;判断是否为call指令
IsRet                   proto dwEIP:DWORD, bCode:DWORD, dwLen:DWORD     ;判断是否为Ret指令
_IsRet                  proto pEvent: ptr DEBUG_EVENT                   ;IsRet进一步封装
DisAsm                  proto dwEIP:DWORD, bCode:DWORD, dwLen:DWORD, dwCnt:DWORD, hProc:DWORD, pfn:DWORD        ;反汇编
ShowModuleList          proto hProc:DWORD                               ;输出所有模块
GetFunctionName         proto hProc:DWORD, dwFuncAddr:DWORD             ;获取函数名
GoToRet                 proto pEvent: ptr DEBUG_EVENT                   ;执行到返回
MemoryDump              proto pszDumpFile:LPCSTR                        ;内存Dump
ShowMemory              proto dwAddr:DWORD, dwCnt:DWORD                 ;查看内存
ShowMemoryString        proto pszBuf:ptr BYTE
WriteReg                proto dwTid:DWORD, pszBuf:ptr BYTE              ;修改寄存器
WriteMem                proto pszBuf:DWORD                              ;修改内存
GetDisAsm               proto dwEIP:DWORD, pCode:DWORD, dwLen:DWORD, pBuf:DWORD, pBufLen:DWORD, hProc:DWORD, pfn:DWORD       ;反汇编（缓冲区中获取一行）
GetFunctionName2        proto hProc:DWORD, dwFuncAddr:DWORD, pszBuf:DWORD   ;获取函数名2(追踪功能处使用)
StartTrace              proto pEvent:ptr DEBUG_EVENT, pszBuf:ptr BYTE   ;开始追踪
WriteTraceFile          proto pEvent:ptr DEBUG_EVENT                    ;写入追踪记录
EndTrace                proto                                           ;结束追踪
LoadScript              proto pszBuf:ptr BYTE                           ;加载脚本
ReadScriptCommand       proto pszBuf:ptr BYTE                           ;读取脚本命令
EndScript               proto                                           ;结束脚本
SetEntryBreakPoint      proto                                           ;设置入口点断点
StartScript             proto pszBuf:ptr BYTE 
WriteScriptCommand      proto pszBuf:ptr BYTE 
SaveScript              proto
ShowHWBP macro regNum, typeOff, lenOff
    mov eax, @Ctx.iDr7
    shr eax, typeOff
    and eax, 3
    .if eax == 0
        mov @pszType, offset g_szExecute
    .elseif eax == 1
        mov @pszType, offset g_szWrite
    .else
        mov @pszType, offset g_szAccess
    .endif
    mov eax, @Ctx.iDr7
    shr eax, lenOff
    and eax, 3
    inc eax
    mov @dwLen, eax
    invoke crt_printf, offset g_szHWBreakPoint, regNum, @Ctx.iDr&regNum, @pszType, @dwLen
endm

_WriteReg macro reg
    invoke crt_printf, offset g_szReg, ebx

    .if g_dwIsScript == TRUE
        invoke ReadScriptCommand, offset g_szRegBuf
    .else
        invoke crt_gets, offset g_szRegBuf
    .endif 
    mov ebx, offset g_szRegBuf
    
    .if byte ptr[ebx] == 0
        xor eax, eax
        ret
    .endif
    invoke crt_strtoul, ebx, addr @pCheck, 16
    mov ebx, @pCheck
    .if byte ptr[ebx] == 0
        mov @Ctx.reg, eax
        invoke WriteScriptCommand, offset g_szRegBuf
    .else
        invoke crt_printf, offset g_szInputErr
        jmp @b 
    .endif
endm

endif