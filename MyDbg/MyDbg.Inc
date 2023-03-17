.586
.model flat,stdcall
option casemap:none

ifndef SECOND_1		;���û�ж����SECOND_1,�������´���
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
    m_pNext                         dd      0         ;ָ���¸��ڵ�ĵ�ַ
    m_bDisposable                   db      0           ;�Ƿ�Ϊһ���Զϵ�
    m_bFlag                         db      0           ;�ϵ��Ƿ���Ч
    m_bTF                           db      0       ;�����쳣ʱ�ָ��öϵ�
    m_bOldByte                      db      0       ;�ϵ㴦ԭָ��
    m_pAddr                         dd      0        ; �ϵ��ַ
BPList ends

MemBPList struc
    m_pNext         dd      0
    m_dwId          dd      0       ;�ϵ�ID
    m_pAddr         dd      0       ;�ϵ��ַ
    m_dwLen         dd      0       ;�ϵ㳤��
    m_dwType        dd      0       ;�ϵ����ͣ���/д��
    m_dwIsTF        dd      0       ;����
MemBPList ends

BPPageList struc
    m_pNext         dd      0
    m_dwBPId        dd      0       ;�ϵ�ID
    m_pBaseAddr     dd      0       ;ҳ��ַ
BPPageList ends

PageList struc
    m_pNext         dd      0       
    m_pBaseAddr     dd      0       ;ҳ��ַ
    m_dwProtect     dd      0       ;ԭ�ڴ�����
    m_dwCnt         dd      0       ;���ü���
    m_dwIsTF        dd      0       ;TF������־
PageList ends

MM_READ equ 0
MM_WRITE equ 1

CreateProc              proto                                           ;���̴���
ShowCtxWaitInput        proto dwTid:DWORD, pEvent:ptr DEBUG_EVENT       ;���������Ϣ���ȴ��û�����
EventLoop               proto                                           ;�¼�����ѭ��
SetTF                   proto dwTid:DWORD
SetBreakPoint           proto pAddr:LPVOID, bDisposable:BYTE            ;���������ϵ�
SetHWBreakPoint         proto pEvent:ptr DEBUG_EVENT, pAddr:LPVOID, dwType:DWORD, dwLen:DWORD       ;����Ӳ���ϵ�
SetMemBreakPoint        proto pAddr:DWORD, dwLen:DWORD, dwType:DWORD    ;�����ڴ�ϵ�
DelBreakPoint           proto dwId:DWORD                                ;ɾ���ϵ�
DelHWBreakPoint         proto pEvent: ptr DEBUG_EVENT, dwId:DWORD       ;ɾ��Ӳ���ϵ�
DelMemBreakPoint        proto dwId:DWORD
StepHWBreakPoint        proto dwTid:DWORD                               ;Ӳ������
StepInto                proto pEvent: ptr DEBUG_EVENT                   ;��������
StepOver                proto pEvent: ptr DEBUG_EVENT                   ;��������
ExceptionEvent          proto pEvent: ptr DEBUG_EVENT                   ;�쳣�¼�����
InputCommand            proto pEvent: ptr DEBUG_EVENT                   ;���ղ������û�����
RecoverCodeSetTF        proto pEvent: ptr DEBUG_EVENT                   ;TFλ��1����ʱȡ�������ϵ�
RecoverProtectSetTF     proto pEvent: ptr DEBUG_EVENT, pAddr:LPVOID, dwType:DWORD   ;��λTF����ʱȡ���ڴ�ϵ�
ReSettingBraekPoint     proto                                           ;�����쳣��ָ������ϵ�
ReSettingMemBreakPoint  proto                                           ;�����쳣��ָ��ڴ�ϵ�
ShowContext             proto  dwTid: DWORD                             ;����߳�������
ShowBreakPoint          proto                                           ;�г����жϵ�
ShowHWBreakPoint        proto pEvent: ptr DEBUG_EVENT                   ;�г�����Ӳ���ϵ�
ShowMemBreakPoint       proto                                           ;�г������ڴ�ϵ�
ShowCurCode             proto dwTid: DWORD, dwCnt: DWORD                ;�����������
Unassemble              proto pEvent: ptr DEBUG_EVENT, dwCnt:DWORD      ;�鿴��������
IsCall                  proto dwEIP:DWORD, bCode:DWORD, dwLen:DWORD     ;�ж��Ƿ�Ϊcallָ��
IsRet                   proto dwEIP:DWORD, bCode:DWORD, dwLen:DWORD     ;�ж��Ƿ�ΪRetָ��
_IsRet                  proto pEvent: ptr DEBUG_EVENT                   ;IsRet��һ����װ
DisAsm                  proto dwEIP:DWORD, bCode:DWORD, dwLen:DWORD, dwCnt:DWORD, hProc:DWORD, pfn:DWORD        ;�����
ShowModuleList          proto hProc:DWORD                               ;�������ģ��
GetFunctionName         proto hProc:DWORD, dwFuncAddr:DWORD             ;��ȡ������
GoToRet                 proto pEvent: ptr DEBUG_EVENT                   ;ִ�е�����
MemoryDump              proto pszDumpFile:LPCSTR                        ;�ڴ�Dump
ShowMemory              proto dwAddr:DWORD, dwCnt:DWORD                 ;�鿴�ڴ�
ShowMemoryString        proto pszBuf:ptr BYTE
WriteReg                proto dwTid:DWORD, pszBuf:ptr BYTE              ;�޸ļĴ���
WriteMem                proto pszBuf:DWORD                              ;�޸��ڴ�
GetDisAsm               proto dwEIP:DWORD, pCode:DWORD, dwLen:DWORD, pBuf:DWORD, pBufLen:DWORD, hProc:DWORD, pfn:DWORD       ;����ࣨ�������л�ȡһ�У�
GetFunctionName2        proto hProc:DWORD, dwFuncAddr:DWORD, pszBuf:DWORD   ;��ȡ������2(׷�ٹ��ܴ�ʹ��)
StartTrace              proto pEvent:ptr DEBUG_EVENT, pszBuf:ptr BYTE   ;��ʼ׷��
WriteTraceFile          proto pEvent:ptr DEBUG_EVENT                    ;д��׷�ټ�¼
EndTrace                proto                                           ;����׷��
LoadScript              proto pszBuf:ptr BYTE                           ;���ؽű�
ReadScriptCommand       proto pszBuf:ptr BYTE                           ;��ȡ�ű�����
EndScript               proto                                           ;�����ű�
SetEntryBreakPoint      proto                                           ;������ڵ�ϵ�
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