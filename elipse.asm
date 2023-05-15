assume cs:code , ds:data

data segment
    X_axle              db 0                    ; os pozioma elipsy
    Y_axle              db 0                    ; os pionowa elipsy

    error_1             db "Zle dane wejsciowe! $"

data ends

code segment

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; "deklaracja" używanych zmiennych
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
X_semi_axle  dw ?                               ; polos pozioma elipsy
Y_semi_axle  dw ?                               ; polos pionowa elipsy

X            dw ?                               ; X punktu
Y            dw ?                               ; Y punktu

p_color      db 13                              ; poczatkowy kolor punktu
background   db 0                               ; kolor tła

last_key     db 0                               ; ostatni wcisniety klawisz
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej jest glowna funckja sterujaca programem
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
main:
set_stack_segment:
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

    call    draw_elipse

handle_keys:
    jmp     handle_key

enable_text:
    mov     al, 3h
    mov     ah, 0
    int     10h

end_:
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

    mov     ax, 0a000h                          ; podaje adres pamieci obrazu w trybie graficznym
    mov     es, ax                              ; do es wrzucam segment pamieci obrazu

    mov     di, 0                               ; wpisuje do di pierwszy wskaznik na komorke obrazu
    mov     cx, 64000                           ; tyle razy ma sie powtorzyc  zeby wyczyscic ekran (320*200=64000)
    mov     al, byte ptr cs:[background]        ; wpisuje do al kolor tla
    cld                                         ; ustawiam flagi na zero
    rep     stosb                               ; powtarzam te instrukcje az cx bedzie rowne 0, czyli bede miec pewnosc ze tlo bedzie zamazane

    ret

;---------------------------------------------------------------
setX   dw ?                                     ; wyliczana zmienna
setY   dw ?                                     ; zmienna służącą do wyliczenia
a      dw ?                                     ; półoś zgodna z wsp wyliczaną
b      dw ?                                     ; druga półoś
set_point:
    ; ustala wspolrzedne punktu (x, y) na podstawie danego X = (x, sqrt((1-x^2/a^2)b^2))

    finit                                       ; inicjuje jednostke zmiennoprzecinkowa
    fild    word ptr cs:[setX]                  ; x -> wpisuje setX z pamieci jako liczbe zmiennoprzecinkowa
    fimul   word ptr cs:[setX]                  ; x^2 -> mnoze x przez siebie
    fidiv   word ptr cs:[a]                     ; x^2/a -> dzielę x^2 przez a
    fidiv   word ptr cs:[a]                     ; x^2/a^2 -> dzielę x^2/a przez a
    fld1                                        ; wkładam 1 na wierzch stosu
    fsub                                        ; x^2/a^2-1 -> odejmuję 1 od x^2/a^2
    fchs                                        ; 1-x^2/a^2 ->  zmieniam znak na przeciwny
    fimul   word ptr cs:[b]                     ; (1-x^2/a^2)b -> mnoze (1-x^2/a^2) przez b
    fimul   word ptr cs:[b]                     ; (1-x^2/a^2)b^2 -> mnoze (1-x^2/a^2)b przez b
    fsqrt                                       ; sqrt((1-x^2/a^2)b^2) -> pierwiastkuje poprzednie

    fist word ptr cs:[setY]                     ; zaokraglam i zapisuje wynik do setY

    ret

;---------------------------------------------------------------
turn_point:
    ; zapala punkt (x, y)

    mov     ax, 0a000h                          ; zapisuje adres pamięci obrazu
    mov     es, ax                              ; ustawiam segment pamieci ekranu w es

    mov     ax, word ptr cs:[Y]                 ; wstawiam wspolrzedna Y
    mov     bx, 320                             ; wpisuje 320 do bx (320 to szerokosc ekranu)
    mul     bx                                  ; mnoze Y przez 320 ( 320 * Y )

    mov     bx, word ptr cs:[X]                 ; wstawiam wspolrzedna X
    add     bx, ax                              ; dodaje do bx 320*Y ( 320 * Y + X ), wskazuje na polozenie punktu w pamieci

    mov     al, byte ptr cs:[p_color]           ; wpisuje jaki kolor elipsy chce narysowac
    mov     byte ptr es:[bx], al                ; do komórki o adresie bx przypisuje chciany kolor

    ret

center_point:
    ; umieszcza na srodku ekranu

    push    word ptr cs:[X]                     ; zapisuje wspolrzedne punktu na stosie
    push    word ptr cs:[Y]

    mov     ax, word ptr cs:[X]                 ; przesuwam punkt X o polowe szerokosci w prawo
    add     ax, 160
    mov     word ptr cs:[X], ax

    mov     ax, word ptr cs:[Y]                 ; przesuwam punkt Y o polowe wysokosci w dol
    add     ax, 100
    mov     word ptr cs:[Y], ax

    call    turn_point                          ; zapalam punkt

    pop     word ptr cs:[Y]                     ; przywracam wspolrzedne punktu
    pop     word ptr cs:[X]

    ret

mirror_point:
    ; rysuje punkt w 4 cwiartkach symetrycznie

    call    center_point                        ; (x, y)

    mov     ax, 0                               ; zeruje ax
    sub     ax, word ptr cs:[X]                 ; odejmuje od ax wspolrzedna x, wiec otrzymuje odbicie lustrzane (-x)
    mov     word ptr cs:[X], ax                 ; wpisuje do X -x
    call    center_point                        ; centruje punkt (-x, y)

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

    draw_X:
        ; rysuje punkty wzdłuz osi X

        mov     cx, word ptr cs:[X_semi_axle]       ; wpisuje do cx pół oś X
        X_point:
            push    cx                              ; zapisuje cx na stosie, aby nie stracić jej wartości

            mov     word ptr cs:[X], cx             ; wpisuje do X aktualny x punktu
            mov     word ptr cs:[setX], cx          ; wpisuje do setX aktualny x punktu

            mov     ax, word ptr cs:[X_semi_axle]   ; wpisuje do a długosc pol osi X
            mov     word ptr cs:[a], ax

            mov     ax, word ptr cs:[Y_semi_axle]   ; wpisuje do b długosc pol osi Y
            mov     word ptr cs:[b], ax

            call    set_point                       ; wyliczam współrzędne punktu

            mov     ax, word ptr cs:[setY]          ; przypisuje do y wyliczona współrzędną Y
            mov     word ptr cs:[Y], ax

            call    mirror_point                    ; rysuje punkt w 4 cwiartkach symetrycznie

            pop     cx                              ; przywracam cx
            loop    X_point                         ; powtarzam to dla wszystkich punktów

    draw_Y:
        ; rysuje punkty wzdłuz osi Y

        mov     cx, word ptr cs:[Y_semi_axle]       ; wpisuje do cx pół oś Y
        Y_point:
            push    cx                              ; zapisuje cx na stosie, aby nie stracić jej wartości

            mov     word ptr cs:[Y], cx             ; wpisuje do Y aktualny y punktu
            mov     word ptr cs:[setX], cx          ; wpisuje do setX aktualny y punktu

            mov     ax, word ptr cs:[Y_semi_axle]   ; wpisuje do a długosc pol osi Y
            mov     word ptr cs:[a], ax

            mov     ax, word ptr cs:[X_semi_axle]   ; wpisuje do b długosc pol osi X
            mov     word ptr cs:[b], ax

            call    set_point                       ; wyliczam współrzędne punktu

            mov     ax, word ptr cs:[setY]          ; przypisuje do y wyliczona współrzędną Y
            mov     word ptr cs:[X], ax

            call    mirror_point                    ; rysuje punkt w 4 cwiartkach symetrycznie

            pop     cx                              ; przywracam cx
            loop    Y_point                         ; powtarzam to dla wszystkich punktów
        ret

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej są funckje zarzadzajace klawiatura
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
handle_key:
    in      al, 60h                             ; kod klawiatury

    cmp     last_key, al                        ; sprawdzam czy ostatni klawisz jest taki sam jak aktualny
    je      handle_key                          ; jeśli tak to rysuje jeszcze raz
    mov     byte ptr ds:[last_key], al          ; jeśli nie to zapisuje aktualny klawisz

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
        jne     change_color

        dec     byte ptr cs:[Y_semi_axle]
        jmp     draw_again
    change_color:
        pink:
            cmp     al, 2                      ; 2 - 1
            jne     blue

            mov     byte ptr cs:[p_color], 5
            jmp     draw_again
        blue:
            cmp     al, 3                      ; 3 - 2
            jne     green

            mov     byte ptr cs:[p_color], 11
            jmp     draw_again
        green:
            cmp     al, 4                      ; 4 - 3
            jne     yellow

            mov     byte ptr cs:[p_color], 10
            jmp     draw_again
        yellow:
            cmp     al, 5                      ; 5 - 4
            jne     orange

            mov     byte ptr cs:[p_color], 14
            jmp     draw_again
        orange:
            cmp     al, 6                      ; 6 - 5
            jne     red

            mov     byte ptr cs:[p_color], 12
            jmp     draw_again
        red:
            cmp     al, 7                      ; 7 - 6
            jne     white

            mov     byte ptr cs:[p_color], 4
            jmp     draw_again
        white:
            cmp     al, 8                      ; 8 - 7
            jne     draw_circle

            mov     byte ptr cs:[p_color], 15
            jmp     draw_again
    draw_circle:
        cmp     al, 46                          ; 46 - ALT + C
        jne     draw_again

        mov     byte ptr cs:[p_color], 10
        mov     ax, word ptr cs:[Y_semi_axle]
        mov     word ptr cs:[X_semi_axle], ax

        call    draw_elipse
        jmp     handle_circle_key

    draw_again:
        call    check_dimensions
        call    draw_elipse
        jmp     handle_key

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej są funckje zarzadzajace klawiatura dla koła
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
flag_circle    db 0 ; jesli 0 to sie zmniejszal jesli 1 to sie zwiekszal

handle_circle_key:
    in      al, 60h                             ; kod klawiatury

    escape_c:
        cmp     al, 1                           ; 1 = ESC (zakoncz program)
        jne     draw_elipse_from_c

        jmp     enable_text

    draw_elipse_from_c:
        cmp     al, 18                          ; 46 - ALT + E
        jne     draw_again_c

        mov     byte ptr cs:[p_color], 13
        call    draw_elipse
        jmp     handle_key

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej są funckje odpowiadajce za animacje
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
draw_again_c:
    cmp     flag_circle, 0
    je      draw_again_down_c

    cmp     flag_circle, 1
    je      draw_again_up_c

    draw_again_down_c:
        dec     byte ptr cs:[X_semi_axle]
        dec     byte ptr cs:[Y_semi_axle]
        call    too_small

    draw_again_down:
        mov     byte ptr cs:[flag_circle], 0
        call    draw_elipse
        jmp     handle_circle_key

    draw_again_up_c:
        inc     byte ptr cs:[X_semi_axle]
        inc     byte ptr cs:[Y_semi_axle]
        call    too_big

    draw_again_up:
        mov     byte ptr cs:[flag_circle], 1
        call    draw_elipse
        jmp     handle_circle_key

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ponizej są funckje zarzadzajace pomocnicze
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
check_dimensions:
    ; sprawdza czy nowe wymiary mieszcza sie w wymaganych

    X_overflow_c:
        cmp     word ptr cs:[X_semi_axle], 160      ; sprawdza czy nowy rozmiar nie jest za duzy
        jl      X_underflow_c
        mov     word ptr cs:[X_semi_axle], 159      ; jesli tak to zmniejsza rozmiar
    X_underflow_c:
        cmp     word ptr cs:[X_semi_axle], 0        ; sprawdza czy nowy rozmiar nie jest za maly
        jg      Y_overflow_c
        mov     word ptr cs:[X_semi_axle], 1        ; jesli tak to zwieksza rozmiar
    Y_overflow_c:
        cmp     word ptr cs:[Y_semi_axle], 100
        jl      Y_underflow_c
        mov     word ptr cs:[Y_semi_axle], 99
    Y_underflow_c:
        cmp     word ptr cs:[Y_semi_axle], 0
        jg      return_cd
        mov     word ptr cs:[Y_semi_axle], 1
    return_cd:
        ret

too_small:
    ; sprawdza czy nowe wymiary kola mieszcza sie w wymaganych
    cmp     word ptr cs:[X_semi_axle], 10           ; sprawdza czy nowy rozmiar nie jest za maly
    jg      draw_again_down
    mov     word ptr cs:[X_semi_axle], 11           ; jesli tak to zwieksza rozmiar i skocz do zwiekszania
    jmp     draw_again_up

too_big:
    cmp     word ptr cs:[X_semi_axle], 100          ; sprawdza czy nowy rozmiar nie jest za duzy
    jl      draw_again_up
    mov     word ptr cs:[X_semi_axle], 99           ; jesli tak to zmniejsza rozmiar i skocz do zmniejszania
    jmp     draw_again_down

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