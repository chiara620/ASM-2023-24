.section .data

frase_usage:
    .ascii "Usage: ./bin/pianificatore <Ordini/nome_file.txt> <Ordini/pianificazione_facoltativa.txt>\n"
frase_usage_len:
    .long .-frase_usage

frase_errorefile:
    .ascii "Ri-eseguire utilizzando un file valido\n"
frase_errorefile_len:
    .long .-frase_errorefile

frase_menu:
    .ascii "Selezionare l'algoritmo di pianificazione:\n  [1] EDF - Earliest Deadline First\n  [2] HPF - Highest Priority First\n  [q] per uscire dal programma\n"
frase_menu_len:
    .long .-frase_menu

frase_EDF:
    .ascii "\nPianificazione EDF:\n"
frase_EDF_len:
    .long .-frase_EDF

frase_HPF:
    .ascii "\nPianificazione HPF:\n"
frase_HPF_len:
    .long .-frase_HPF

ascii_1:
    .ascii "1"
ascii_2:
    .ascii "2"  
ascii_q:
    .ascii "q"

file_name:
    .ascii "\0\0\0\0\0\0\0\0\0"

argc:
    .int 0

file_desc:
    .int 0

file_desc_due:
    .int 0

nval:
    .int 0

controllo:
    .int 0

.section .bss
    algoritmo: .string ""


.section .text
	.global _start

_start:

    movl $0, controllo 
                            # elimino i primi due valori nello stack
	popl %esi			    # Contiene il numero dei parametri totali
    movl %esi, argc        # spostiamo il numero di argomenti

    cmpl $3, %esi 
    je _flag                # Viene gestita la stampa su file (parte facoltativa)
    
    cmpl $3, %esi
    jg _usage               # Controlla che i parametri non siano maggiori di 3

	popl %esi               # Nome del programma

	popl %esi			    # Recupera l'indirizzo della stringa relativa al parametro
	testl %esi, %esi	    # controlla se ESI e' 0 (NULL)
	jz _usage               # Non e' stato fornito un parametro

	movl $5, %eax		    # system call "open file"
	movl %esi, %ebx
	movl $0, %ecx		    # "r"

	int $0x80

	cmp $0, %eax            
	jl _errorefile              # Il parametro fornito non va bene :(

    movl %eax, file_desc        # Salva il file descriptor in una variabile

    # chiamo la funzione che legge il file e ne carica ogni valore nello stack
    
    movl file_desc, %ebx        # Salvo il file descriptor in %ebx

    call lettura

    cmpl $77, %ebx              # Caso di errore nella lettura del FILE -> 77 e' un flag di riconoscimento dell'errore che manda in end          
    je _end
    
    movl %ecx, nval


_menu:
    movl $4, %eax           # Stampo richiesta di inserimento algoritmo
    movl $1, %ebx
    leal frase_menu, %ecx
    movl frase_menu_len, %edx
    int $0x80

    xorl %ecx, %ecx

    movl $3, %eax           # system call read
    movl $0, %ebx           # Tastiera
    leal algoritmo, %ecx    # Destinazione
    movl $60, %edx          # Lunghezza della stringa

    int $0x80

    movb ascii_1, %al
    movb ascii_2, %bl
    movb ascii_q, %cl

    cmp %al, algoritmo      # Controllo l'input dell'utente 
    je _EDF

    cmp %bl, algoritmo
    je _HPF

    cmp %cl, algoritmo
    je _fine                # Se non e' stato inserito ne 1 ne 2 ne q, richiedo un nuovo input

    jmp _menu


_EDF:
    movb nval, %al          # Passo come parametro il numero di valori alla funzione EDF
    call EDF

    cmpl $3, argc          # Se è stato inserito il terzo parametro per la stampa su file
    je _stampafile_EDF      # mi sposto in una diversa parte del menu' strutturata appositamente

    movl $4, %eax
    movl $1, %ebx
    leal frase_EDF, %ecx        # incipit del "risultato"
    movl frase_EDF_len, %edx
    int $0x80
    
    movb nval, %al
    call stampa                 # stampa su stdout - emette i risultati

    jmp _menu                   # loop del menu'


_HPF:
    movb nval, %al           # Passo come parametro il numero di valori alla funzione HPF
    call HPF    

    cmpl $3, argc
    je _stampafile_HPF

    movl $4, %eax
    movl $1, %ebx
    leal frase_HPF, %ecx
    movl frase_HPF_len, %edx
    int $0x80

    movb nval, %al
    call stampa             # Stampiamo la pianificazione

    jmp _menu               # loop del menu'


_stampafile_EDF:
    
    movl $4, %eax                   # stesso funzionamento dell'etichetta "stampafile"
    movl file_desc_due, %ebx        # ma passa anche come argomento il file descriptor 
    leal frase_EDF, %ecx
    movl frase_EDF_len, %edx
    int $0x80
    
    movl nval, %eax
    movl file_desc_due, %ebx

    call stampafile

    jmp _menu


_stampafile_HPF:

    movl $4, %eax
    movl file_desc_due, %ebx
    leal frase_HPF, %ecx
    movl frase_HPF_len, %edx
    int $0x80

    movb nval, %al
    movl file_desc_due, %ebx

    call stampafile

    jmp _menu


_usage:

    movl $4, %eax           # Stampo frase errore di usage
    movl $2, %ebx
    leal frase_usage, %ecx
    movl frase_usage_len, %edx
    int $0x80
    jmp _fine


_errorefile:
    movl $4, %eax           # Stampo frase errore del file
    movl $2, %ebx
    leal frase_errorefile, %ecx
    movl frase_errorefile_len, %edx
    int $0x80
    jmp _fine


_fine:                      # mette il numero di valori inseriti nello stack in ECX
    movl nval, %ecx


_end: 
    cmp $0, %ecx            # controlla se lo stack è stato svuotato completamente
    jne _ciclo

    mov $6, %eax            # syscall close file
    mov file_desc, %ecx     # File descriptor
    int $0x80               # Interruzione del kernel

    cmpl $0, file_desc_due
    jne _chiudo             # se e'stato richiesto un secondo parametro, chiudo il file appositamente aperto

    jmp _finissima          # altrimenti procedo a terminare


_chiudo:
    mov $6, %eax                # syscall close file
    mov file_desc_due, %ecx     # File descriptor
    int $0x80                   # Interruzione del kernel


_finissima:

    movl $1, %eax               # syscall end
    movl $0, %ebx
    int $0x80


_ciclo:
    # svuoto lo stack
    popl %eax

    loop _ciclo

    jmp _end


_flag: 
    # aprire l'altro file e poppare i due parametri 
    popl %esi # Nome programma
    popl %esi # PRIMO PARAMETRO (ORDINI.TXT)

    testl %esi, %esi	    # controlla se ESI e' 0 (NULL)
	jz _usage               # Non è stato fornito un parametro

	movl $5, %eax		    # system call "open file"
	movl %esi, %ebx
	movl $0, %ecx		    # "r"

	int $0x80

	cmp $0, %eax            
	jl _errorefile              # Il parametro fornito non va bene

    movl %eax, file_desc        # Salva il file descriptor in una variabile

    popl %esi  # SECONDO PARAMETRO (Pianificazione.txt)
    
    testl %esi, %esi
    jz _usage 

    # Creo il file 
    movl $8, %eax		    # system call "create-open file"
	movl %esi, %ebx         # Nome del file
	movl $1, %ecx	        # "w"
    int $0x80

    cmp $0, %eax 
    jl _errorefile              # Il parametro fornito non va bene 
    
    movl %eax, file_desc_due
    
    movl file_desc, %ebx        # Salvo il file descriptor in %ebx per poterlo usare nelle funzioni

    call lettura

    cmpl $77, %ebx              # Caso di errore nella lettura del FILE -> 77 e' un flag            
    je _end
    
    movl %ecx, nval

jmp _menu 
