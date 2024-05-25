.section .data

frase_errore:
    .ascii "Il file selezionato e' vuoto, presenta dei valori non validi oppure il numero di valori contenuti al suo interno non e' multiplo di quattro. Ricontrollare il file.\n"
frase_errore_len:
    .long .-frase_errore

fd:
    .int 0                          # File descriptor

buffer: 
    .string ""                      # Spazio per il buffer di input
newline: 
    .byte 10                        # Valore del simbolo di nuova linea
cf:             # Carriage Feed
    .byte 13
comma:          # Virgola
    .byte 44 

valore: 
    .int 0
oldValue:
    .int 0

nvalori:
    .int 0

check: 
    .int 1

NUL:
    .ascii "NUL"


.section .text
	.global lettura

.type lettura, @function 

lettura:

    popl %esi           # Ottengo l'indirizzo della riga di codice dopo la CALL e la metto in ESI, 
                        # cosi' che poi riesco a ritornare nel main
    movl %ebx, fd                   

    cmpl NUL, %ebx 

    je _errore 
    

_read_loop:

    # Legge il file riga per riga
    mov $3, %eax        # syscall read
    mov fd, %ebx        # File descriptor
    mov $buffer, %ecx   # Buffer di input 
    mov $1, %edx        # Lunghezza massima
    int $0x80           # Interruzione del kernel

    cmp $0, %eax        # Controllo se ci sono errori o EOF
    jle _endoffunction   # Se ci sono errori o EOF, chiudo il file 
    
    # Controllo se ho una nuova linea
    movb buffer, %al    # copio il carattere dal buffer ad AL

    cmp newline, %al    # confronto AL con il carattere \n
    jne _insertProduct  # Inserisce il prodotto nello STACK (SE appunto non siamo arrivati alla fine del FILE)

    jmp _check


_check:     
                        # controllo che i valori all'interno del file selezionato siano validi
    cmpb $1, check      # se l'indice e' uno sono al'ID, e mi sposto nella sezione
    je _ck1             # relativa ad esso
    cmpb $2, check
    je _ck2
    cmpb $3, check      # ...
    je _ck3
    cmpb $4, check
    je _ck4
    

_ifComma:
# incontrata una virgola (o \n) pusco l'intero calcolato nello stack
    push valore         # Variabile contente il valore intero
    cmpb comma, %al
    jne _nvalori
    cmpb cf, %al        # Controlliamo i valori se non sono {newline, comma, cf}
    jne _nvalori
    cmpb newline, %al
    jne _nvalori
    movb $0, valore     # Resettiamo il valore di somma a 0
    movl $0, oldValue
    jmp _read_loop
 

_nvalori:
# conto i valori inseriti nello stack per poterlo poi svuotare (e stampare)
    incl nvalori
    movb $0, valore         # Resettiamo il valore di somma a 0
    movl $0, oldValue       # e OldValue a 0
    jmp _read_loop


_ck1:
# Controlli sui valori validi del file: ID
    cmpb $1, valore
    jl _errore
    cmpb $127, valore
    jg _errore
    
    incl check
    jmp _ifComma


_ck2: 
# durata
    cmpb $1, valore
    jl _errore
    cmpb $10, valore
    jg _errore
    
    incl check
    jmp _ifComma


_ck3:
# scadenza
    cmpb $1, valore
    jl _errore
    cmpb $100, valore
    jg _errore
    
    incl check
    jmp _ifComma


_ck4:
# priorita'
    cmpb $1, valore
    jl _errore
    cmpb $5, valore
    jg _errore

    movl $1, check
    jmp _ifComma


_insertProduct:

    cmpb cf, %al            
    je _read_loop           # Controlliamo se {comma, cf}
    cmpb comma, %al
    je _check

    # Convertire il carattere in un intero 

    movb %al, valore        # Muovo il contenuto della stringa in valore
    subl $48, valore        # Converto il codice ASCII della cifra corrispondente

    # Concateno le cifre se non ho finito di leggere il numero con la virgola
    
    movb oldValue, %al      # Muovo il valore di OldValue in EAX
    movl $10, %edx
    mulb %dl                # in EAX e' contenuto 10 (EAX * 10)
    movb %al, oldValue
    movb valore, %al
    addb oldValue, %al      # 30 (oldValue)= + 5 (Value) = 35 (Nuovo valore)
    movb %al, valore

    movb %al, oldValue
        
    jmp _read_loop          # Abbiamo inserito un intero prodotto nello stack (tutti e 4 i campi)


_errore:
    movl $4, %eax           # Stampo frase sugli errori concernenti il file
    movl $2, %ebx
    leal frase_errore, %ecx
    movl frase_errore_len, %edx
    int $0x80
    
    movl $77, %ebx         # FLAG DI CONTROLLO
    jmp _endoffunction


_endoffunction:

    movl nvalori, %ecx
    
    # Pusho quindi il valore a cui deve ritornare la ret

    pushl %esi

    ret
