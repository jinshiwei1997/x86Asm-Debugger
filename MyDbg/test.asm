.586
.model flat,stdcall
option casemap:none

include MyDbg.inc

.code
testFunc proc far
    
    mov eax, 1
    ret
test endp

end