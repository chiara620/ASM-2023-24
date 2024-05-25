.section .data

flag:
    .int 0

dim:
    .int 0

scadenza:
    .int 0

scadenzaSucc: 
    .int 0


.section .text
	.global EDF


.type EDF, @function

EDF:
# Ordino i prodotti, partendo dalla cima, da quello che 
# deve essere prodotto per primo a quello che dev'essere prodotto per ultimo

    # in %al è contenuto in numero di valori nello stack
    movb $4, %bl
    divb %bl

    movb %al, dim       # dim (numero prdodotti) = nvalori / 4

    movl $0, flag       # azzero le variabili perchè la funzione puo' venire rieseguita
    

# Eseguiamo "bubble sort" dei prodotti secondo la scadenza
_while:

    cmpb $0, flag       # La flag torna a zero se è stato eseguito uno scambio -
    jne _next           # dunque se entro nel while ed è a 1, è tutto ordinato

    movl $1, flag

    movl $0, %ecx       # %ECX è la "i" dell'indice

    movl $8, scadenza   # la prima scadenza è a 8 bit di distanza dalla cima 
                        # dello stack (dove si trova l'indirizzo del main a cui ritornare)


_ciclo:
    
    movl dim, %ebx
    subl $1, %ebx
    cmpl %ebx, %ecx
    je _while           # Controlliamo se siamo arrivati alla fine del ciclo: usciamo quando ECX = DIM - 1

    movl scadenza, %edx
    addl $16, %edx
    movl %edx, scadenzaSucc     # scadenzaSucc = Scadenza + 16
    movl scadenza, %eax         # salvo la scadenza successiva in una variabile

    # Quello che contiene ESP alla distanza "scadenza" lo mettiamo all'interno di edx
    movl (%esp, %eax), %ebx # EBX = (ESP + Scadenza) (Scadenza del primo prodotto)

    # Comparo le scadenze di distanza "un prodotto"
    movl scadenzaSucc, %eax # EAX = Valore che accede al valore successivo 
    cmpl (%esp, %eax), %ebx # Accediamo al valore successivo; EDX (Scadenza Primo Prodotto)  > (ESP + ScadenzaSuccessiva)
    # Se la scadenza contenuta in EDX è maggiore della scadenza contenuta nel prossimo prodotto allora si fa lo swap
    jg _swap  

    cmpl (%esp, %eax), %ebx     # In caso le scadenze siano uguali
    je _uguali 

    incl %ecx                   # Incrementiamo il nostro iteratore
    addl $16, scadenza

    jmp _ciclo                  # ricomincio il ciclo finche' l'indice non avra' superato DIM - 1


_uguali:
# se la scadenza e' la medesima, ordino secondo la maggior priorita'

    # Sappiamo che priorita = (esp + priorita) - 4
    #              prioritaSucc = (esp + prioritaSucc) - 4

    movl scadenza, %eax
    subl $4, %eax    
    movl (%esp, %eax), %eax     # EAX <- priorita'

    movl scadenzaSucc, %ebx
    subl $4, %ebx   
    movl (%esp, %ebx), %ebx     # EBX <- prioritaSucc

    cmpl %ebx, %eax             # priorita <= prioritaSucc
    jle _swap        
                                
    incl %ecx                   # priorita > prioritaSucc
    addl $16, scadenza
    jmp _ciclo 


_swap:
    # Se i due elementi presi in considerazione vanno scambiati, effettuo lo scambio
    # Per ogni elemento di ciascuna categoria, swappare con quello corrispondente

    movl scadenza, %edx         # mi "posiziono" nel primo elemento da swappare: la priorita'
    subl $4, %edx               # (in quanto è la categoria piu' in alto nella PILA)
    movl %edx, %eax

    movl scadenzaSucc, %edx
    subl $4, %edx 
    movl %edx, %ebx
    
    # EAX = primo - scadenza
    # EBX = secondo - scadenzaSucc

    # Priorità                 # swap effettivo di ogni categoria, tramite registri "temporanei"
    movl (%esp, %eax), %edx
    movl (%esp, %ebx), %edi    # EAX = PRIMO (prodotto) | EBX = SECONDO (prodotto)
    movl %edi, (%esp, %eax)    
    movl %edx, (%esp, %ebx)

    # Scadenza
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
