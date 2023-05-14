assume cs:code , ds:data

data segment
    X_axle     db 0                             ; os pozioma elipsy
    Y_axle     db 0                             ; os pionowa elipsy

    error_1    db "Zle dane wejsciowe! $"

data ends

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

code segment

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; "deklaracja" używanych zmiennych
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
X_semi_axle  dw ?                               ; polos pozioma elipsy
Y_semi_axle  dw ?                               ; polos pionowa elipsy

X           dw ?                                ; X punktu
Y           dw ?                                ; Y punktu

p_color      db 13                              ; fioletowy kolor punktu
background   db 0                               ; czarny kolor tła

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej jest glowna funckja sterujaca programem
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main:
    mov     ax, seg stack_                     ; ustawiam segment stosu
    mov     ss, ax
    mov     sp, offset stack_

get_arguments:
    ; ponizej rozpoznaje podane argumenty

    mov     ax, seg data
    mov     es, ax
    mov     si, 082h                           ; do si wrzucam offset w ktorym znajduje sie wywolanie z lini komend
    mov     di, offset X_axle                  ; do di wrzucam offset dla pierwszego argumentu ktory chce pobrac
    call    str_to_int                         ; pobieram wielkosc X
    mov     di, offset Y_axle
    call    str_to_int                         ; pobieram wielkosc Y

set_start_dimensions:
    ; ustawiam wymiary potrzebne do narysowania elipsy

    mov     ax, seg data                       ; do ds wrzucam segment danych
    mov     ds, ax

    mov     al, byte ptr ds:[X_axle]           ; do polosi x wrzucam polowe dlugosci X
    mov     ah, 0
    mov     bl, 2
    div     bl
    mov     ah, 0
    mov     word ptr cs:[X_semi_axle], ax

    mov     al, byte ptr ds:[Y_axle]           ; do polosi y wrzucam polowe dlugosci Y
    mov     ah, 0
    mov     bl, 2
    div     bl
    mov     ah, 0
    mov     word ptr cs:[Y_semi_axle], ax

enable_graphics:
    ; wlaczam tryb graficzny

    mov     al, 13h                             ; 320x200 256 kolorów
    mov     ah, 0
    int     10h

    mov     byte ptr cs:[p_color], 13           ; do ke przypisany losowy kolor początkowy elipsy
    call    draw_elipse

handle_keys:
    in      al, 60h                             ; kod klawiatury

    escape:
        cmp     al, 1                           ; 1 = ESC (zakoncz program)
        jne     left

        jmp     enable_text

    left:
        cmp     al, 75                          ; 75 - lewa strzałka
        jne     right

        dec     byte ptr cs:[X_semi_axle]
        jmp     draw_again

    right:
        cmp     al, 77                          ; 77 - prawa strzałka
        jne     up

        inc     byte ptr cs:[X_semi_axle]
        jmp     draw_again

    up:
        cmp     al, 72                          ; 72 - strzałka do góry
        jne     down

        inc     byte ptr cs:[Y_semi_axle]
        jmp     draw_again

    down:
        cmp     al, 80                          ; 80 - strzałka w dol
        jne     handle_keys

        dec     byte ptr cs:[Y_semi_axle]
        jmp     draw_again

    draw_again:
        call    check_dimensions
        call    draw_elipse
        jmp     handle_keys

enable_text:
    mov     al, 3h
    mov     ah, 0
    int     10h

    jmp     end_program

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej jest funkcja do operacji na podanych argumentach
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
str_to_int:
    mov     bh, 0                               ; zeruje rejestr w ktorym przechowam wynik
    mov     cx, 0                               ; zeruje licznik zczytanych cyfr
    mov     bl, byte ptr ds:[si]                ; wrzucam kod ascii pierwszego znaku do bl

    ignore_spaces:
        ; dzieki tej petli ignoruje ilosc spacji pomiedzy argumentami
        cmp     bl, 32                          ; jesli znak nie jest spacja to zaczynam wczytywanie
        jne     loop_sti

        inc     si                              ; przesun offset na kolejny znak
        mov     bl, byte ptr ds:[si]            ; pobieram kolejny znak
        jmp     ignore_spaces

    loop_sti:
        cmp     cx, 3                           ; wprowadzona cyfra moze byc max. 3-cyfrowa
        jg      bad_input_exception

        cmp     bl, 48                          ; jesli znak nie jest cyfra to przerywam funkcje
        jl      return_sti
        cmp     bl, 57
        jg      return_sti

        inc     cx                              ; inkrementacja licznika wczytanych cyfr

        sub     bl, 48                          ; zkonwersuj char na int

        mov     al, 10                          ; pomnazam wynik razy 10
        mul     bh

        mov     bh, 0                           ; zeruje bh
        add     ax, bx                          ; dodaje aktualna cyfre z bl ( dlatego zeruje bh )

        cmp     ax, 200                         ; jesli jest wieksze od 200 to wypisz blad
        jg      bad_input_exception

        mov     bh, al                          ; wpisuje do bh aktualny wynik

        inc     si                              ; przesuwam offset na kolejny znak
        mov     bl, byte ptr ds:[si]            ; do ah wrzucam kod ascii kolejnego znaku
        jmp     loop_sti


    return_sti:
        cmp     cx, 0                           ; jesli nie ma zadnej cyfry to wyrzuc blad
        je      bad_input_exception

        cmp     bh, 0                           ; jesli argumenty nie mieszcza sie w przedziale to wyrzuc blad
        je      bad_input_exception

        mov     byte ptr es:[di], bh            ; zapisz otrzymana liczbe
        ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej znajduja sie funkcje odpowiadajace za rysowanie elipsy
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
clean_screen:
    ; funkcja zajmująca sie czyszczeniem ekranu

    mov     ax, 0a000h                          ; podaje adres pamieci obrazu
    mov     es, ax

    mov     di, 0                               ; wpisuje do di pierwszy adres komorki pamieci obrazu
    mov     cx, 64000                           ; tyle razy ma sie powtorzyc  zeby wyczyscic ekran
    mov     al, byte ptr cs:[background]
    cld
    rep     stosb

    ret

;---------------------------------------------------------------
setX   dw ?                                     ; wyliczana zmienna
setY   dw ?                                     ; zmienna służącą do wyliczenia
a      dw ?                                     ; półoś zgodna z wsp wyliczaną
b      dw ?                                     ; druga półoś
set_point:
    ; ustala punkt (x, y) = (x, sqrt((1-x^2/a^2)b^2))

    finit
    fild    word ptr cs:[setX]                  ; x
    fimul   word ptr cs:[setX]                  ; x^2
    fidiv   word ptr cs:[a]                     ; x^2/a
    fidiv   word ptr cs:[a]                     ; x^2/a^2
    fld1
    fsub                                        ; x^2/a^2-1
    fchs                                        ; 1-x^2/a^2
    fimul   word ptr cs:[b]                     ; (1-x^2/a^2)b
    fimul   word ptr cs:[b]                     ; (1-x^2/a^2)b^2
    fsqrt

    fist word ptr cs:[setY]                     ; zapisz wynik do setY

    ret

;---------------------------------------------------------------
turn_point:
    ; zapala punkt (x, y)

    mov     ax, 0a000h                          ; adres pamięci obrazu
    mov     es, ax

    mov     ax, word ptr cs:[Y]                 ; ax=320*Y
    mov     bx, 320
    mul     bx

    mov     bx, word ptr cs:[X]                 ; bx=ax+X=320*Y+X
    add     bx, ax

    mov     al, byte ptr cs:[p_color]           ; al=numer koloru k
    mov     byte ptr es:[bx], al                ; do komórki o adresie bx przypisz kolor k

    ret

center_point:
    ; umieszcza na srodku ekranu

    push    word ptr cs:[X]
    push    word ptr cs:[Y]

    mov     ax, word ptr cs:[X]
    add     ax, 160
    mov     word ptr cs:[X], ax

    mov     ax, word ptr cs:[Y]
    add     ax, 100
    mov     word ptr cs:[Y], ax

    call    turn_point

    pop     word ptr cs:[Y]
    pop     word ptr cs:[X]

    ret

mirror_point:
    ; rysuje punkt w 4 cwiartkach symetrycznie

    call    center_point                        ; (x, y)

    mov     ax, 0
    sub     ax, word ptr cs:[X]
    mov     word ptr cs:[X], ax
    call    center_point                        ; (-x, y)

    mov     ax, 0
    sub     ax, word ptr cs:[Y]
    mov     word ptr cs:[Y], ax
    call    center_point                        ; (-x, -y)

    mov     ax, 0
    sub     ax, word ptr cs:[X]
    mov     word ptr cs:[X], ax
    call    center_point                        ; (x, -y)

    ret

;---------------------------------------------------------------
draw_elipse:
    ; funkcja rysująca elipse

    call    clean_screen

    mov     cx, word ptr cs:[Y_semi_axle]

    draw_X:
        mov     cx, word ptr cs:[X_semi_axle]
        X_point:
            push    cx
            mov     word ptr cs:[X], cx
            mov     word ptr cs:[setX], cx
            mov     ax, word ptr cs:[X_semi_axle]
            mov     word ptr cs:[a], ax
            mov     ax, word ptr cs:[Y_semi_axle]
            mov     word ptr cs:[b], ax
            call    set_point
            mov     ax, word ptr cs:[setY]
            mov     word ptr cs:[Y], ax
            call    mirror_point
            pop     cx
            loop    X_point

    draw_Y:
        mov     cx, word ptr cs:[Y_semi_axle]
        Y_point:
            push    cx
            mov     word ptr cs:[Y], cx
            mov     word ptr cs:[setX], cx
            mov     ax, word ptr cs:[Y_semi_axle]
            mov     word ptr cs:[a], ax
            mov     ax, word ptr cs:[X_semi_axle]
            mov     word ptr cs:[b], ax
            call    set_point
            mov     ax, word ptr cs:[setY]
            mov     word ptr cs:[X], ax
            call    mirror_point
            pop     cx
            loop    Y_point
        ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej są funckje zarzadzajace pomocnicze
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

check_dimensions:
    ; sprawdza czy nowe wymiary mieszcza sie w wymaganych

    X_overflow:
        cmp     word ptr cs:[X_semi_axle], 160
        jl      X_underflow
        mov     word ptr cs:[X_semi_axle], 159
    X_underflow:
        cmp     word ptr cs:[X_semi_axle], 0
        jg      Y_overflow
        mov     word ptr cs:[X_semi_axle], 1
    Y_overflow:
        cmp     word ptr cs:[Y_semi_axle], 100
        jl      Y_underflow
        mov     word ptr cs:[Y_semi_axle], 99
    Y_underflow:
        cmp     word ptr cs:[Y_semi_axle], 0
        jg      return_cd
        mov     word ptr cs:[Y_semi_axle], 1
    return_cd:
        ret

bad_input_exception:
    ; wyrzuca blad zlych danych

    mov     ax, seg error_1                     ; wypisuje co to za blad
    mov     ds, ax
    mov     dx, offset error_1
    mov     ah, 9
    int     21h
    jmp     end_program

end_program:
    ; konczy program

    mov     al, 0
    mov     ah, 4ch
    int     21h

code ends

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

stack_ segment stack
        dw      300 dup(?)
wstack  dw      ?
stack_ ends

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

end main