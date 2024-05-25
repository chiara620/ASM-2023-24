.section .data

flag:
    .int 0

dim:
    .int 0

priorita:
    .int 0

prioritaSucc: 
    .int 0


.section .text
	.global HPF


.type HPF, @function

HPF:
# Ordino i prodotti, partendo dalla cima, da quello che 
# deve essere prodotto per primo a quello che dev'essere prodotto per ultimo
    # in %al è contenuto in numero di valori nello stack
    movb $4, %bl
    divb %bl

    movb %al, dim       # dim = nvalori / 4

    movl $0, flag       # azzero le variabili perchè la funzione puo' venire rieseguita
    

# Eseguiamo "bubble sort" dei prodotti secondo la priorita
_while:

    cmpb $0, flag       # La flag torna a zero se è stato eseguito uno scambio -
    jne _next           # dunque se entro nel while ed è a 1, è tutto ordinato

    movl $1, flag

    movl $0, %ecx       # %ECX è la "i"

    movl $4, priorita   # la prima priorita' è a 4 bit di distanza dalla cima 
                        # dello stack (dove si trova l'indirizzo del main a cui ritornare)


_ciclo:
    
    movl dim, %ebx
    subl $1, %ebx
    cmpl %ebx, %ecx
    je _while           # Controlliamo se siamo arrivati alla fine del ciclo: usciamo quando ECX = DIM - 1

    movl priorita, %edx
    addl $16, %edx
    movl %edx, prioritaSucc     # prioritaSucc = priorita + 16
    movl priorita, %eax         # salvo la priorita' successiva in una variabile

    # Quello che contiene ESP alla distanza "priorita" lo mettiamo all'interno di edx
    movl (%esp, %eax), %ebx # EBX = (ESP + priorita) (priorita del primo prodotto)

    # Comparo le priorita di distanza "un prodotto"
    movl prioritaSucc, %eax # EAX = Valore che accede al valore successivo 
    cmpl (%esp, %eax), %ebx # Accediamo al valore successivo; EDX (priorita Primo Prodotto)  > (ESP + prioritaSuccessiva)
    # Se la priorita contenuta in EDX è maggiore della priorita contenuta nel prossimo prodotto allora si fa lo swap
    jl _swap  

    cmpl (%esp, %eax), %ebx     # In caso le priorità siano uguali
    je _uguali 

    incl %ecx                   # Incrementiamo il nostro iteratore
    addl $16, priorita

    jmp _ciclo                  # ricomincio il ciclo finche' l'indice non avra' superato DIM - 1


_uguali: 
# se la priorita' e' la medesima, ordino secondo la scadenza piu' vicina

    # Sappiamo che scadenza = (esp + priorita) + 4
    #              scadenzaSucc = (esp + prioritaSucc) + 4

    movl priorita, %eax
    addl $4, %eax    
    movl (%esp, %eax), %eax   # EAX <- Scadenza

    movl prioritaSucc, %ebx
    addl $4, %ebx   
    movl (%esp, %ebx), %ebx  # EBX <- ScadenzaSucc

    cmpl %ebx, %eax         # scadenza > scadenzaSucc
    jg _swap        
                            # scadenza <= scaden
    incl %ecx 
    addl $16, priorita
    jmp _ciclo 


_swap:
    # Se i due elementi presi in considerazione vanno scambiati, effettuo lo scambio
    # Per ogni elemento di ciascuna categoria, swappare con quello corrispondente


    movl priorita, %eax         # sono gia' "posizionato" sul primo elemento da swappare
    movl prioritaSucc, %ebx
    
    # EAX = primo - priorita
    # EBX = secondo - prioritaSucc

    # Priorità
    movl (%esp, %eax), %edx
    movl (%esp, %ebx), %edi    # EAX = PRIMO (prodotto) | EBX = SECONDO (prodotto)
    movl %edi, (%esp, %eax)    
    movl %edx, (%esp, %ebx)

    # Scadenza                 # swap effettivo di ogni categoria, tramite registri "temporanei"
    addl $4, %eax
    addl $4, %ebx

    movl (%esp, %eax), %edx
    movl (%esp, %ebx), %edi    # EAX = PRIMO (prodotto) | EBX = SECONDO (prodotto)
    movl %edi, (%esp, %eax)    
    movl %edx, (%esp, %ebx)

    # Durata
    addl $4, %eax
    addl $4, %ebx

    movl (%esp, %eax), %edx
    movl (%esp, %ebx), %edi    
    movl %edi, (%esp, %eax)   
    movl %edx, (%esp, %ebx)

    # ID
    addl $4, %eax
    addl $4, %ebx

    movl (%esp, %eax), %edx
    movl (%esp, %ebx), %edi    
    movl %edi, (%esp, %eax)    
    movl %edx, (%esp, %ebx)

    movl $0, flag   # Swap effettuato quindi cambio flag

    jmp _ciclo      # ricomincio il ciclo finche' lo stack non sara' completamente ordinato


_next:
    # Torniamo nel main dopo aver ordinato lo stack
	ret
