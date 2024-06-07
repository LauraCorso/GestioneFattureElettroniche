#!/bin/bash

#-------------------------------------------------------------COLORI-------------------------------------------------------
rosso='\e[1;31m' #errori
giallo='\e[1;33m' #warnings
verde='\e[1;32m' #ok
grassetto='\e[1m'
fine='\e[0m'

#------------------------------------------------------------ FUNZIONI-----------------------------------------------------

function importaFatture {
	# Il comando consente, dopo aver digitato la directory dove ricercare le nuove
	# fatture, (si considerano fatture i file con estensione .xml) di copiarle
	# all’interno della directory di lavoro del programma suddivisi per anno.
	# Qualora in quella cartella esiste già una fattura uguale (ovvero un file con
	# lo stesso nome) deve essere visualizzato un messaggio di errore ed
	# eventualmente proposta una soluzione.
	
	clear
	echo -e "$grassetto IMPORTAZIONE FATTURE $fine"
	echo

	# Faccio digitare la directory controllando che sia valida
	valido=0
	while [ $valido -eq 0 ]
	do		
		echo -n "Inserire il percorso della directory dove cercare le nuove fatture: "	
		read path

		# Controllo che esista il path indicato
		if [ ! -d $path ]; then
			echo -e "$rosso $path : percorso non valido $fine"
		else
			# Elimino l'eventuale "/" finale dal path
			n_campi=$(echo $path | awk -F \/ '{print NF}')
			last_campo=$(echo $path | cut -d \/ -f $n_campi)

			if [ -z $last_campo ]; then
				path=$(echo $path | rev | cut -c2- | rev)	
			fi
			valido=1
		fi
	done
	
	n_file=$(ls $path | grep .xml) #seleziono nel path specificato tutti i nomi dei file .xml
	
	# Controllo se sono state trovate fatture
	if [[ -z $n_file ]]; then
		echo -e "$giallo Nessuna fattura trovata nella cartella $path $fine"
	else
		for f in $n_file
		do
			# Seleziono l'anno della fattura $f
			anno=$(awk -v RS="</DatiGeneraliDocumento>" -F "<DatiGeneraliDocumento>" '{print $2}' $path/$f | awk -v RS="</Data>" -F "<Data>" '{print $2}' | cut -d \- -f1)

			# Creo la cartella con l'anno specificato se non esistente
			if [ ! -d $path_home/$anno ]; then
				mkdir $path_home/$anno
				cp $path/$f $path_home/$anno
				echo -e "$verde File $f copiato nella cartella $path_home/$anno $fine"
				echo
			else
				# Controllo se esiste un file con lo stesso nome
				if [ -e $path_home/$anno/$f ]; then
					# controllo se i due file con lo stesso nome sono uguali
					if [[ -z $(diff -q $path_home/$anno/$f $path/$f) ]]; then
						r="g"
						while [ $r != "y" ] && [ $r != "n" ]
						do
							echo -n -e "$giallo $f già esistente. Sostituire il file? (y/n) $fine"
							read r
							echo
							if [ $r = "y" ]; then
								cp $path/$f $path_home/$anno
								echo -e "$verde File $f copiato nella cartella $path_home/$anno sovrascrivendo il file esistente $fine"
								echo	
							elif [ $r = "n" ]; then
								# Determino tutti i numeri delle copie
								numeri=$(ls $path_home/$anno | grep $f. | cut -d \( -f2 | cut -d \) -f1) 
								max=0
								for n in $numeri #trovo il numero maggiore
								do
									if [ $max -lt $n ]; then
										max=$n
									fi
								done
								nuovo_nome=$f"($(($max+1)))"
								# Copio il file in un nuovo file con il numero aggiornato
								cp $path/$f $path_home/$anno/$nuovo_nome
								echo -e "$verde File $nuovo_nome copiato nella cartella $path_home/$anno $fine"
								echo
							else
								echo -e "$rosso Risposta non valida $fine"
								echo
							fi
						done
					else
						r=5
						while [ $r -ne 1 ] && [ $r -ne 2 ]
						do							
							echo -e "$giallo Nella cartella $path_home/$anno esiste un file diverso ma con lo stesso nome di $f $fine"
							echo "Le opzioni possibili sono:"
							echo "  1. Rinominare il file corrente e salvarlo nella cartella $path_home/$anno"
							echo "  2. Sovrascrivere il file nella cartella $path_home/$anno"
							echo -n "Scegliere un opzione (1/2): "
							read r
							echo
							case $r in
								1)  echo -n "Inserire il nuovo nome: ";
									read nome
									cp $path/$f $path_home/$anno/$nome
									echo -e "$verde $nome copiato in $path_home/$anno tenendo $f $fine"
									echo
								;;
								2)	cp $path/$f $path_home/$anno
									echo -e "$verde $f copiato in $path_home/$anno sovrascrivendo $fine"
									echo
								;;
								*)      echo -e "$rosso Risposta non valida $fine"
									echo
								;;
							esac
						done
					
					fi
				else
					cp $path/$f $path_home/$anno
					echo -e "$verde File $f copiato nella cartella $path_home/$anno $fine"
					echo
				fi
			fi
		done
	fi
}

function esportaA {
	# Il comando consente, dopo aver selezionato un anno di lavoro, di esportare
	# nella cartella “Allegati” tutti gli allegati contenuti nel file .xml delle
	# fatture. Gli allegati dovranno avere il nome specificato all’interno del
	# file .xml

	clear
	echo -e "$grassetto ESPORTA ALLEGATI $fine"
	echo

	anni=$(ls $path_home | grep -v Allegati) #selziono gli anni nella cartella di lavoro

	# Controllo che esistano cartelle in Fatture
	if [[ -z $anni ]]; then
		echo -e "$rosso Nessuna fattura importata nella cartella di lavoro $fine"
	else
		# Faccio inserire un anno e controllo che sia valido
		valido=0
		while [ $valido -eq 0 ]
		do
			echo "Selezionare un anno tra quelli possibili:"
			echo $anni
			echo -n " --> "
			read anno
			if [ ! -d $path_home/$anno ]; then
				echo -e "$rosso Anno selezionato non esistente $fine"
			else 
				valido=1
			fi
		done
		
		# Controllo se non esiste la cartella allegati
		if [ ! -d $path_home/Allegati ]; then
			echo
			echo "Creo la cartella $path_home/Allegati"
			mkdir $path_home/Allegati
		fi
	
		# Controllo se non esiste la cartella dell'anno selezionato in Allegati
		if [ ! -d $path_home/Allegati/$anno ]; then
			echo
			echo "Creo la cartella $anno nella cartella $path_home/Allegati"
			mkdir $path_home/Allegati/$anno
		fi
	
		file_list=$(ls $path_home/$anno | grep .xml) #seleziono nella cartella anno inserita i file .xml
		
		# Controllo che la cartella $anno non sia vuota
		if [[ -z $file_list ]]; then
			echo -e "$giallo Cartella $path_home/$anno non contiene fatture $fine"
		else
			for f in $file_list
			do
				# Seleziono il nome del file attachment
				nome=$(awk -v RS="</NomeAttachment>" -F "<NomeAttachment>" '{print $2}' $path_home/$anno/$f)
	
				# Se il file non contiene attachment non ci sarà il campo NomeAttachment --> nome sarà vuoto
				if [[ -z "$nome" ]]; then
					echo -e "$giallo Per il file $f non esiste l'allegato $fine"
				else
					# Copio l'attachment in un file di appoggio
					awk -v RS="</Attachment>" -F "<Attachment>" '{print $2}' $path_home/$anno/$f > $path_home/temporary.txt
		
					# Controllo se nella cartella $path_home/Allegati/$anno esiste un file con lo stesso nome
					if [[ -e $path_home/Allegati/$anno/"$nome" ]]; then
						echo -e "$giallo Nella cartella $path_home/Allegati/$anno esiste già il file $nome attachment del file $f $fine"
						echo
						op=5
						while [ $op -ne 1 ] && [ $op -ne 2 ]
						do
							echo "Opzioni possibili:"
							echo "   1. Aggiornare il file esistente con quello corrente"
							echo "   2. Rinominare il file corrente e aggiungerlo alla cartella"
							echo -n "Scegliere un opzione: "
							read op
							case $op in
								1) 	# Copio l'attachement nel file $nome nella cartella ./Allegati/$anno
									base64 -d $path_home/temporary.txt > $path_home/Allegati/$anno/"$nome"
									rm $path_home/temporary.txt
									echo -e "$verde Attachement di $f copiato nella cartella $path_home/Allegati/$anno aggiornando il file esistente $fine"
								;;
								2) 	echo -n "Inserire il nuovo nome del file: "
									read n_nome
									base64 -d $path_home/temporary.txt > $path_home/Allegati/$anno/"$n_nome"
									rm $path_home/temporary.txt
									echo -e "$verde Attachement di $f copiato nella cartella $path_home/Allegati/$anno con il nome $n_nome $fine"
								;;
								*)
									echo -e "$rosso Opzione non valida $fine"
								;;
							esac
								
						done
					else 
						# Copio l'attachement nel file $nome nella cartella ./Allegati/$anno
						base64 -d $path_home/temporary.txt > $path_home/Allegati/$anno/"$nome"
						rm $path_home/temporary.txt
						echo -e "$verde Attachement di $f copiato nella cartella $path_home/Allegati/$anno $fine"	
					fi
				fi
			done
		fi
	fi
}

function elencoF {
	# Il comando consente, dopo aver selezionato un anno di lavoro, di
	# visualizzare in ordine alfabetico crescente (senza duplicati) l’elenco dei
	# fornitori, ovvero i mittenti non ripetuti delle fatture di quel dato anno.
	
	clear
	echo -e "$grassetto ELENCO FORNITORI $fine"
	echo

	anni=$(ls $path_home | grep -v Allegati) #seleziono gli anni nella cartella di lavoro

	# Controllo che esistano cartelle nella cartella di lavoro
	if [[ -z $anni ]]; then
		echo -e "$rosso Nessuna fattura importata nella cartella di lavoro $fine"
	else
		# Faccio inserire un anno e controllo che sia valido
		valido=0
		while [ $valido -eq 0 ]
		do
			echo "Selezionare un anno tra quelli possibili:"
			echo $anni
			echo -n " --> "
			read anno
			if [ ! -d $path_home/$anno ]; then
				echo -e "$rosso Anno selezionato non esistente $fine"
			else 
				valido=1
			fi
		done

		file_list=$(ls $path_home/$anno | grep .xml) #seleziono nella cartella anno inserita i file .xml
		
		# Controllo che la cartella $anno non sia vuota
		if [[ -z $file_list ]]; then
			echo -e "$giallo Cartella $path_home/$anno non contiene fatture $fine"
		else
			for f in $file_list
			do
				# Seleziono i nomi e li metto nel file nomi.txt
				if [ -e $path_home/nomi.txt ]; then
					awk -v RS="</CedentePrestatore>" -F "<CedentePrestatore>" '{print $2}' $path_home/$anno/$f | awk -v RS="</Denominazione>" -F "<Denominazione>" '{print $2}' >> $path_home/nomi.txt
				else
					awk -v RS="</CedentePrestatore>" -F "<CedentePrestatore>" '{print $2}' $path_home/$anno/$f | awk -v RS="</Denominazione>" -F "<Denominazione>" '{print $2}' > $path_home/nomi.txt
				fi
			done
			
			# Visualizzo in ordine alfabetico senza duplicati i nomi
			echo
			echo "I fornitori dell'anno $anno sono:"
			sort -u $path_home/nomi.txt | cat
			rm $path_home/nomi.txt
		fi
	fi
}

function stampaNFatt {
	# Stampa un report che indica quante fatture sono presenti per ogni anno.

	clear
	echo -e "$grassetto REPORT $fine"
	echo

	anni=$(ls $path_home | grep -v Allegati) #seleziono gli anni nella cartella di lavoro

	# Controllo che siano state importate fatture
	if [[ -z $anni ]]; then
		echo -e "$rosso Nessuna fattura importata nella cartella di lavoro $fine"
	else
		echo "------------------------------"
		echo -n -e "|$grassetto Anno $fine | $grassetto Numero di Fatture $fine"
		echo "|"
		for a in $anni
		do		
			file_list=$(ls $path_home/$a | grep .xml) #creo la lista delle fatture nella cartella $anno
			n=0 
			# Conto il numero di file
			for f in $file_list
			do			
				n=$(($n+1))
			done
			
			# Stampo il risultato
			echo "|-------|--------------------|"
			echo "| $a  |          $n         |"
		done
		echo "------------------------------"
	fi
}


#-----------------------------------------------------------------MAIN------------------------------------------

clear

# Imposto il path di lavoro di default
path_home=$HOME/Fatture

# Controllo cosa inserisce l'utente da riga di comando
flagBackup=false
if [ $# -gt 0 ]; then
	if [ $# -eq 1 ]; then
		# Imposto il path di lavoro con il path inserito dall'utente eliminando l'eventuale "/" finale
		n_campi=$(echo $1 | awk -F \/ '{print NF}')
		last_campo=$(echo $1 | cut -d \/ -f $n_campi)

		if [ -z $last_campo ]; then
			path_home=$(echo $1 | rev | cut -c2- | rev)
		else
			path_home=$1
		fi

	elif [ $# -eq 2 ]; then
		if [ $1 = "-backup" ]; then
			flagBackup=true
			path_backup=$2
		else
			echo -e "$rosso Comando non valido $fine"
			exit 0
		fi
	elif [ $# -eq 3 ]; then
		if [ $2 = "-backup" ]; then
			# Imposto il path di lavoro con il path inserito dall'utente eliminando l'eventuale "/" finale
			n_campi=$(echo $1 | awk -F \/ '{print NF}')
			last_campo=$(echo $1 | cut -d \/ -f $n_campi)

			if [ -z $last_campo ]; then
				path_home=$(echo $1 | rev | cut -c2- | rev)
			else
				path_home=$1
			fi

			# Controllo che il path inserito esista
			if [ ! -d $path_home ]; then
				echo -e "$rosso $path_home non esistente: impossibile eseguire il backup $fine" 
			else
				flagBackup=true
				path_backup=$3
			fi
		else
			echo -e "$rosso Comando non valido $fine"
			exit 0
		fi
	else
		echo -e "$rosso Comando non valido $fine"
		exit 0
	fi
fi

# Creo la cartella del programma
if [ ! -d $path_home ]; then
	echo "Creo la cartella di lavoro $path_home"
	mkdir $path_home
fi
echo

# Controllo se devo eseguire il backup
if [ $flagBackup = true ]; then
	zip -r $path_backup $path_home
fi

# Eseguo il menù finchè l'utente non vuole uscire dal programma
risp=0
while [ $risp -ne 5 ]
do
	echo -e "$grassetto GESTIONE FATTURE $fine"
	echo "Opzioni possibili:"
	echo "	1. Importazione fatture"
	echo "	2. Esporta allegati"
	echo "	3. Elenco fornitori"
	echo "	4. Stampa numero fatture per anno"
	echo "	5. Esci"
	echo
	echo -n "Scegliere un opzione: "
	read risp
	
	case $risp in
	1)  importaFatture
		echo
	;;
	2)	esportaA
		echo
	;;
	3)  elencoF
		echo
	;;
	4)  stampaNFatt
		echo
	;;
	5)  clear
		echo -e "$verde Programma terminato correttamente $fine"
		echo
	;;
	*)  echo -e "$rosso Opzione non disponibile. Inserire un numero tra 1 e 5. $fine"
		echo
	;;
	esac
done


# VR429604
# Laura Corso
# 24/04/2020
# Elaborato: 1 - SHELL ~ myFatt.sh
