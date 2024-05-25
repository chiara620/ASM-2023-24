.section .data

penalty:
    .int 0

tempo:
    .int 0

nv:
    .int 0

i:
    .int 0
    
fd2:
    .int 0

due_punti:
    .ascii ":"
due_punti_len:
    .long .-due_punti

a_capo:
    .ascii "\n"
a_capo_len:
    .long .-a_capo

conclusione:
    .ascii "Conclusione: "
conclusione_len:
    .long .-conclusione

frase_penalty:
    .ascii "Penalty: "
frase_penalty_len:
    .long .-frase_penalty


.section .text
	.global stampafile


.type stampafile, @function

stampafile:
   
    movl %ebx, fd2      # salvo il file descriptor del file sul quale devo stampare
    movl $0, tempo
    movl $0, penalty    # resetto le variabili perche' la funzione puoì essere chiamata piu' volte
    
    # in %al è contenuto in numero di valori nello stack
    movl $4, %edx
    mull %edx
   
    movl %eax, nv

    movl $4, %ecx       # ECX è la "i"   


_for:

    movl %ecx, i

    cmp nv, %ecx            # se ho terminato tutti i valori esco dal for
    jg _last

    movl %ecx, %ebx         # ottengo l'id del successivo prodotto da stampare
    addl $12, %ebx
    movl (%esp, %ebx), %eax

    movl fd2, %ebx
    call itoafile           # Stampo l'id dopo averlo convertito in ascii

    movl $4, %eax           # Stampo i due punti
    movl fd2, %ebx
    leal due_punti, %ecx
    movl due_punti_len, %edx
    int $0x80

    movl tempo, %eax 

    movl fd2, %ebx
    call itoafile           # Stampo il tempo in cui il prodotto corrente inizia la produzione

    movl $4, %eax           # Stampo l'andata a capo
    movl fd2, %ebx
    leal a_capo, %ecx
    movl a_capo_len, %edx
    int $0x80

    movl i, %ecx

    movl $0, %eax
    movl %ecx, %ebx     
    addl $8, %ebx
    addl (%esp, %ebx), %eax
    addl %eax, tempo            # aggiorno il tempo sommandogli la durata del prodotto corrente

    movl %ecx, %ebx     
    addl $4, %ebx               # ottengo il valore di scadenza del prodotto corrente
    movl (%esp, %ebx), %eax     # per evenualmente calcolarne la penalita'

    cmpl %eax, tempo        # comparo il tempo con la scadenza
    jg _if                  # se e' maggiore, mi sposto per calcolare la penalita'

    addl $16, %ecx          # aggiorno l'indice per passare al prodotto successivo

    jmp _for


_if:

    # stack[i+1]
    movl %ecx, %ebx     
    addl $4, %ebx
    movl (%esp, %ebx), %eax     # %eax = stack[i+1]

    # (tempo-stack[i+1])
    movl tempo, %ebx
    subl %eax, %ebx     # %ebx = tempo - stack[i+1] 
    movl %ebx, %eax     # sposto per poterlo moltiplicare con la priorita

    # (stack[i] * (tempo-stack[i+1])
    movl (%esp, %ecx), %edx     # stack[i] (= priorita) -> %edx
    mull %edx 

    # penalty + (stack[i] * (tempo-stack[i+1]))
    addl penalty, %eax

    # penalty = penalty + (stack[i] * (tempo-stack[i+1]));
    movl %eax, penalty

    addl $16, %ecx

    jmp _for        # ricomincio


_last:

    movl $4, %eax           # Stampo "Conclusione: "
    movl fd2, %ebx
    leal conclusione, %ecx
    movl conclusione_len, %edx
    int $0x80

    movl tempo, %eax
    movl fd2, %ebx
    call itoafile           # Stampo il tempo conclusivo

    movl $4, %eax           # Stampo l'andata a capo
    movl fd2, %ebx
    leal a_capo, %ecx
    movl a_capo_len, %edx
    int $0x80

    movl $4, %eax           # Stampo "Penalty: "
    movl fd2, %ebx
    leal frase_penalty, %ecx
    movl frase_penalty_len, %edx
    int $0x80

    movl penalty, %eax
    movl fd2, %ebx
    call itoafile           # Stampo la penalita' calcolata precedentemente

    movl $4, %eax           # Stampo l'andata a capo
    movl fd2, %ebx
    leal a_capo, %ecx
    movl a_capo_len, %edx
    int $0x80

    movl $4, %eax           # Stampo l'andata a capo
    movl fd2, %ebx
    leal a_capo, %ecx
    movl a_capo_len, %edx
    int $0x80

    ret                     # torno al main per ricominciare eventualmente un nuovo calcolo
