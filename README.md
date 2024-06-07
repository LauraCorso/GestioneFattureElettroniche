# Gestione Fatture Elettroniche

Progetto per l'esame *Elementi di Architettura e Sistemi Operativi* all'Università degli Studi di Verona (anno 2020).

## Descrizione
Il progetto permette la gestione di fatture elettroniche in ambiente UNIX/Linux tramite uno script *bash*.
In particolare, lo script può eseguire le seguenti operazioni:
- importazione di fatture: le fatture vengono copiate dalla cartella sorgente alla directory di lavoro del programma.
- esportazione degli allegati: gli allegati delle fatture vengono esportati nella cartella "Allegati".
- elenco fornitori: i fornitori delle fatture sono elencati.
- stampa numero fatture: il numero delle fatture per ogni anno è stampato a video.


Le operazioni sono gestite tramite stampa di menù e messaggi testuali. Il codice gestisce anche il controllo dei casi particolari. Per esempio, controllo della validità e correttezza di tutti i dati inseriti dall'utente tramite tastiera, gestione di copie multiple di fatture nella directory di lavoro, ecc.
