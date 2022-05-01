Progr           segment
                assume  cs:Progr, ds:dane, ss:stosik

;convert array to number
atoi:
                mov         cl,ds:[1] ;get text length into cl
                mov         ch,0      ;clear upper cx
                mov         bx,10     ;divisor 10d
                mov         si,cx     ;put text length into si (from cx because ch is cleared)
                add         si,1
atoiloop:
                mov         al,ds:[si]  ;get symbol as char at ds:[si]
                mov         ah,0        ;clear upper ax
                sub         ax,30h      ;convert char to num
                mul         atoistep    ;multiply num by position

                ;shl         dx,8
                ;or          ax,dx       ;join multiplied value

                mov         temp,ax     ;create backup
                add         ax,decval   ;check if decval would exceed 65535
                jo          invalid
                jc          invalid     ;when decval would exceed 65535, o=1, c=1
                mov         ax,temp     ;restore value from backup
                add         decval,ax   ;add when sure result <= 65535

                mov         ax,atoistep ;-
                mul         bx          ;-increase multiplier
                mov         atoistep,ax ;-

                dec         si
                dec         cx
                jnz         atoiloop

                ret
;end of convert array to number

;input validation
validation:
                mov         si,offset dectext
                mov         cl,ds:[1] ;repeating for symbol count

validationloop:
                mov         al,30h ;'0'
                mov         ah,39h ;'9'
                cmp         ds:[si],al ;check if number at ds:[si] >= '0'
                jc          invalid
                cmp         ds:[si],ah ;check if number at ds:[si] <= '9'
                jnc         invalid
                inc         si
                dec         cl
                jnz         validationloop

                ret         ;returns when no problem

invalid:
                mov     ax,0600h  ;-
                mov     bh,7      ;-
                mov     cx,0      ;-clear screen
                mov     dx,184fh  ;-
                int     10h       ;-

                lea     dx,msgerr ;-
                mov     ah,9      ;-display error message
                int     21h       ;-

                mov     ah,4ch    ;-
                mov     al,0      ;-terminate program execution
                int     21h       ;-
;end of input validation

;print decimal
printdec:
               lea      dx,dectext
               mov      ah,9
               int      21h

               ret
;end of print decimal

;print binary
printbin:
               mov      si,offset bintext
               add      si,17             ;v
               mov      al,'$'            ;-add '$' at the end of binval
               mov      ds:[si],al        ;^
               dec      si                ;v
               mov      al,'b'            ;-add 'b' before '$' of binval
               mov      ds:[si],al        ;^
               dec      si
               mov      bx,2              ;set divisor to 2
               mov      ax,[decval]       ;get decimal value
               mov      dx,0
               mov      cx,16             ;reapeting for all bits

binloop:
               div      bx                ;divide by 2
               add      dx,30h            ;convert divison remainder to char
               mov      ds:[si],dl        ;remainder is bit
               dec      si
               mov      dx,0              ;clear dx after divison
               dec      cx
               jnz      binloop

               lea      dx,bintext        ;
               mov      ah,9              ;print text binary value
               int      21h               ;

               ret
;end of print binary

;print hexadecimal
printhex:
               mov      si,offset hextext

               add      si,5              ;
               mov      al,'$'            ;add '$' at the end of hexval
               mov      ds:[si],al        ;

               dec      si                ;
               mov      al,'h'            ;add 'h' before '$' of hexval
               mov      ds:[si],al        ;
               dec      si

               mov      bx,16             ;set divisor to 16
               mov      ax,[decval]       ;get decimal value
               mov      dx,0
               mov      cx,4              ;repeating for all hex digits

hexloop:
               div      bx                ;divide by 16
               cmp      dx,10             ;check if remainder is >= 10
               jnc      isletter
               add      dx,30h            ;remainder < 10, convert to num char
               jmp      isnumber

isletter:
               add      dx,37h            ;remainder >= 10, convert to letter char

isnumber:
               mov      ds:[si],dl        ;remainder is digit of hex
               dec      si
               mov      dx,0
               dec      cx
               jnz      hexloop

               lea      dx,hextext        ;
               mov      ah,9              ;print text hex value
               int      21h               ;

               ret
;end of print hexadecimal

start:          mov     ax,dane
                mov     ds,ax
                mov     ax,stosik
                mov     ss,ax
                mov     sp,offset szczyt
;----------------------------------------------------------------------------

                mov     ax,0600h      ;
                mov     bh,7          ;
                mov     cx,0          ;clear screen
                mov     dx,184fh      ;
                int     10h           ;

                lea     dx,wlcmmsg    ;
                mov     ah,9          ;print welcome message
                int     21h           ;

                mov     dx,offset max ;
                mov     ah,0Ah        ;get user input
                int     21h           ;

                mov     al,5          ;max number of input symbols
                cmp     al,ds:[1]     ;check if input doesn't exceed 5 symbols
                jnc     ok
                call    invalid

ok:
                mov     si,offset len ;
                mov     dl,ds:[1]     ;
                mov     dh,0          ;
                inc     dx            ;replace 'Enter' with '$' in input text
                add     si,dx         ;
                mov     al,'$'        ;
                mov     ds:[si],al    ;

                mov     ax,0600h      ;
                mov     bh,7          ;
                mov     cx,0          ;clear screen
                mov     dx,184fh      ;
                int     10h           ;

                call    validation    ;validate
                call    atoi          ;convert array to number

                lea     dx,msgdec
                mov     ah,9
                int     21h

                call    printdec      ;print decimal value

                lea     dx,newline
                mov     ah,9
                int     21h

                lea     dx,msgbin
                mov     ah,9
                int     21h

                call    printbin      ;print binary value

                lea     dx,newline
                mov     ah,9
                int     21h

                lea     dx,msghex
                mov     ah,9
                int     21h

                call    printhex      ;print hexadecimal value

;----------------------------------------------------------------------------
                mov         ah,4ch
                mov         al,0
                int         21h
Progr           ends

dane            segment
                max     db      0FFh     ;max buffer size
                len     db      ?        ;array size
                dectext db      6 dup(0) ;array elements

                decval     dw      0 ;decimal value as number
                atoistep   dw      1 ;converting step (multiplier)
                temp       dw      0 ;backup for validation

                hextext    db      6 dup(0)  ;hexadecimal value as text
                bintext    db      18 dup(0) ;binary value as text

                wlcmmsg db      "Input decimal number: ",'$'
                msgdec  db      "Decimal value: ",'$'
                msgbin  db      "Binary value: ",'$'
                msghex  db      "Hexadecimal value: ",'$'
                newline db      10,13,'$'
                msgerr  db      "Invalid input!",'$'

dane            ends

stosik          segment
                dw    100h dup(0)
szczyt          Label word
stosik          ends

end start