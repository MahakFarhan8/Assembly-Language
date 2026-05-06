; Project: Vigenere Cipher Tool with Fixed Logic (NASM 8086)
org 100h


start:
    mov dx, menu
    mov ah, 09h
    int 21h

    mov ah, 01h
    int 21h
    
    cmp al, '1'
    je near manual_mode    
    cmp al, '2'
    je near file_mode
    cmp al, '3'
    je near exit_prog
    jmp near start

manual_mode:
    mov dx, msg_m
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    sub al, '1'
    mov [mode], al

    mov dx, msg_p
    mov ah, 09h
    int 21h
    mov dx, buffer
    mov ah, 0Ah
    int 21h

    mov dx, msg_k
    mov ah, 09h
    int 21h
    mov dx, key_buf
    mov ah, 0Ah
    int 21h
    
    mov word [f_handle], 0  
    jmp near run_logic

file_mode:
    mov dx, msg_ifn
    mov ah, 09h
    int 21h
    mov dx, in_fname_buf
    mov ah, 0Ah
    int 21h
    xor bx, bx
    mov bl, [in_fname_buf + 1]
    mov byte [in_fname_buf + 2 + bx], 0

    mov dx, msg_ofn
    mov ah, 09h
    int 21h
    mov dx, out_fname_buf
    mov ah, 0Ah
    int 21h
    xor bx, bx
    mov bl, [out_fname_buf + 1]
    mov byte [out_fname_buf + 2 + bx], 0

    mov dx, msg_m
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    sub al, '1'
    mov [mode], al

    mov dx, msg_k
    mov ah, 09h
    int 21h
    mov dx, key_buf
    mov ah, 0Ah
    int 21h

    mov ax, 3D00h           
    mov dx, in_fname_buf + 2
    int 21h
    jc  near f_error
    mov [f_handle], ax

    mov ah, 3Fh
    mov bx, [f_handle]
    mov cx, 200             
    mov dx, buffer + 2
    int 21h
    mov [buffer+1], al      
    
    mov ah, 3Eh             
    int 21h
    jmp near run_logic

run_logic:
    mov si, buffer + 2      
    mov di, result          
    xor bx, bx              ; BX will be key index
    mov cl, [buffer+1]      
    xor ch, ch
    test cx, cx
    jz near done_proc

v_loop:
    mov al, [si]
    
    ; Check if UpperCase
    cmp al, 'A'
    jb  store_char
    cmp al, 'Z'
    jbe is_upper
    
    ; Check if LowerCase
    cmp al, 'a'
    jb  store_char
    cmp al, 'z'
    ja  store_char
    
    mov dl, 'a'             
    jmp apply_vigenere

is_upper:
    mov dl, 'A'             

apply_vigenere:
    sub al, dl              
    
    push si
    mov si, key_buf + 2     ; Get key start
    add si, bx              ; Current key pos
    mov ah, [si]            ; Get key char
    pop si
    
    ; Normalize key char to 0-25
    cmp ah, 'a'
    jae lower_key
    sub ah, 'A'
    jmp key_ready
lower_key:
    sub ah, 'a'
key_ready:

    cmp byte [mode], 1      ; 1 = Decrypt
    je  decrypting
    add al, ah              ; Encrypt
    jmp math_mod
decrypting:
    sub al, ah
    add al, 26              ; Handle negative
math_mod:
    xor ah, ah
    mov dh, 26
    div dh                  ; AH = remainder (0-25)
    mov al, ah
    add al, [si-1]          ; Add base back (bug fix: use stored base)
    ; Note: Re-calculating base simpler
    mov al, ah
    cmp byte [si], 'a'      ; Simple check for original case
    jb use_cap
    add al, 'a'
    jmp key_inc
use_cap:
    cmp byte [si], 'A'
    jb store_char           ; Not a letter
    add al, 'A'

key_inc:
    ; Increment key index
    inc bx
    push dx
    xor dx, dx
    mov dl, [key_buf+1]
    cmp bx, dx
    jb pop_skip
    xor bx, bx
pop_skip:
    pop dx

store_char:
    mov [di], al
    inc si
    inc di
    loop v_loop

done_proc:
    mov byte [di], '$'      
    cmp word [f_handle], 0
    jne near save_file

    mov dx, msg_res
    mov ah, 09h
    int 21h
    mov dx, result
    mov ah, 09h
    int 21h
    jmp near start

save_file:
    mov ah, 3Ch             
    mov cx, 0
    mov dx, out_fname_buf + 2
    int 21h
    jc near f_error
    mov [f_handle], ax

    mov ah, 40h             
    mov bx, [f_handle]
    xor ch, ch
    mov cl, [buffer+1]
    mov dx, result
    int 21h

    mov ah, 3Eh             
    int 21h
    mov dx, msg_f
    mov ah, 09h
    int 21h
    jmp near start

f_error:
    mov dx, msg_err
    mov ah, 09h
    int 21h
    jmp near start

exit_prog:
    mov ax, 4C00h
    int 21h

menu    db 13,10,'====== VIGENERE TOOL ======'
            db 13,10,'1. Encrypt/Decrypt Manual'
            db 13,10,'2. Process File'
            db 13,10,'3. Exit'
            db 13,10,'Choice: $'
    
    msg_m   db 13,10,'Choose (1: Encrypt, 2: Decrypt): $'
    msg_p   db 13,10,'Enter Text: $'
    msg_k   db 13,10,'Enter Key: $'
    msg_ifn db 13,10,'Enter Input Filename: $'
    msg_ofn db 13,10,'Enter Output Filename: $'
    msg_res db 13,10,'Result: $'
    msg_f   db 13,10,'File processed successfully!$'
    msg_err db 13,10,'File Error!$'

    in_fname_buf  db 40, 0
                  times 45 db 0
    out_fname_buf db 40, 0
                  times 45 db 0
    
    buffer    db 200, 0
              times 205 db 0
    key_buf   db 50, 0
              times 55 db 0
    result    times 205 db '$'
    
    f_handle dw 0
    mode     db 0