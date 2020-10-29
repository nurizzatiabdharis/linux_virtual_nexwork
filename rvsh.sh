#!/bin/bash

PROGRAMME_EN_COURS=0 
# Si PROGRAMME_EN_COURS=1, ca veut dire que on a rentre dans l'invite de commande rvsh'

# Fonction main : première fonction à exécuter lors de l'exécution du script
# $1 : mode connecté (admin/connect)
# $2 : mot de passe d'admin (en mode admin) 
#	 : nom de machine (en mode connect)
# $3 : nom utilisateur
function main {
	verifArguments $# $1 $2
	#ces fonctions sont lancés seuelement en mode connect
	verifNomMachine $2
	verifUtilisateur $3 $2
	verifMdp $3 
	ajoutLog $2 $3
	PROGRAMME_EN_COURS=1
	promptConnect $2 $3 # lancer le promtConnect
}

#------------------------------------- VERIFICATION -------------------------------------

# Fonction verifArguments : vérifier les arguments passés en parametre 
# Argument 1: le nombre de paramètres. Argument 2: mode (connect/admin).
# En mode admin il ya 1 arg, en mode -connect il ya 3 arg
function verifArguments { 
	if [[ $2 == "-connect" ]]; then
		if [[ ! $1 -eq 3 ]]; then
			erreur 1
		fi
	else 
		if [[ $1 -eq 1 && $2 == "-admin" ]]; then # Si le nombre d'arguments est égal à 2 et que celui-ci est égal à "-admin"
			stty -echo # Permet de désactiver l'echo 
			read -p "Mot de passe pour admin: " mdp 
			stty echo # Réactive l'echo sur le terminal
			echo ""
			if [[ $mdp == "admin" ]] ; then # On vérifier le mot de passe
				PROGRAMME_EN_COURS=1 
				promptAdmin # On lance le prompt administrateur
			else
				erreur 3
			fi;
		else
			erreur 1 
		fi
	fi
}

# Fonciton verifNomMachine : vérifier l'existence de la machine rentré par l'utilisateur
# Argument 1: nom de la machine 
function verifNomMachine { 
	monMachine=0
	while read ligne  
	do
		if [[ "$ligne" == "$1" ]]; then # machine existe
			monMachine=1
		fi	
	done < machines.txt
	if [[ $monMachine == 0 ]]; then # Machine n'existe pas
		erreur 4
	fi
}

# Fonction verifUtilisateur : vérifier l'existence de l'utilisateur
# Argument 1 : utilisateur   Argument 2 : machine
function verifUtilisateur { 
	if [[ $1 == $(grep -w $1 utilisateurs.txt | cut -f1 -d':') ]]; then 
		# grep : récupère la ligne de contient le nom de l'utilisateur 
		# cut : récupérer uniquement son nom  (1ere colonne)
		verifAcces $1 $2 # utilisateur existe, on lance la fonction verifAcces 
	else
		erreur 5
	fi
}

# Fonction verifAcces : vérifier si l'utilisateur a bien accès à la machine souhaitée
# Argument 1 : utilisateur   Argument 2 : machine
# Return 0 si c'est bon
function verifAcces { 
	if [[ $(grep -w $1 utilisateurs.txt | grep -w -o $2) == $2 ]] ; then 
		# 1ere grep : la ligne de contient le nom de l'utilisateur
		# 2eme grep : vérifie si la machine existe sur cette ligne
		return 0
	else
		erreur 6 #il n'a pas le droit
	fi
}

# Fonction verifMdp :vérifier si l'utilisateur rentre le bon mot de passe
# Argument 1: utilisateur
# Return 0 si c'est bon
function verifMdp { 
	mdp1=$(grep -w $1 utilisateurs.txt | cut -f2 -d':') #mdp dans le fichier utilisateurs.txt
	mdp2="" #mdp saisir par utilisateur
	nbEssai=3 
	while [[ $mdp2 != $mdp1 && $nbEssai -gt 0 ]] # Tant que le mot de passe donné par l'utilisateur est faux et que le nombre d'essais n'est pas nul
	do
		echo "Vous avez $nbEssai essais." # Affiche le nombre d'essais restant
		stty -echo # Permet de désactiver l'echo 
		read -p "Mot de passe : " mdp2  
		((nbEssai--)) 
		stty echo # Réactive l'echo sur le terminal
		echo "" # Saute une ligne
	done
	if [[ $mdp2 != $mdp1 ]]; then # Si le mot de passe n'a pas été trouvé au bout de 3 fois
		erreur 7
	else
		return 0
	fi
}

#------------------------------------- LOG -------------------------------------
# Fonction ajoutLog : ajouter un log au fichier connexion.log à chaque fois qu'un utilisateur se connecte
# Argument 1 : nom machine Argument 2 : nom utilisateur
function ajoutLog { 
	d=$(date) # Date à laquelle l'utilisateur s'est connecté
	t=$(tty) # Numéro du terminal sur lequel il s'est connecté
	echo "$1 $2 $d $t" >> connexion.log # Ajoute les données dans le fichier connexion.log
}

# Fonction supprimeLog : supprimer le log quand l'utilisateur se déconnecte
# Argument 1 : nom machine Argument 2 : nom utilisateur
function supprimeLog { 
	sed '/'$1' '$2'/d' connexion.log > temp_connexion.log && mv temp_connexion.log connexion.log; 
	# Sed : cherche la ligne de l'utilisateur et la machine associée pour être supprimer
}


#------------------------------------- MODE CONNECT -------------------------------------
# Fonction promptConnect affichant le prompt si on a rentré l'option -connect
# Argument 1 : machine   Argument 2 : utilisateur
function promptConnect { 
	echo "---------------Vous êtes connecté-------------------------------"
	echo "Tapez help pour voir le commande disponible"
	echo "Tapez exit pour sortir de l'invite de commandes."
	echo ""
	while [ true ] # Boucle infinie
	do
		read -p "$2@$1>" reponse arg1 arg2
		# En fonction de la réponse écrite, on vérifie les paramètres entrés et lance la commande
		
		case $reponse in 
			help )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					commande-help $2 # Lance la commande help
				else
					erreur 8 
				fi;;
			who )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					commande-who $1 # Lance la commande who
				else
					erreur 8 
				fi;;
			rusers )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					commande-rusers # Lance la commande rusers
				else
					erreur 8 
				fi;;
			rhost )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					commande-rhost # Lance la commande rhost
				else
					erreur 8 
				fi;;
			connect )
				if [[ -z $arg1 ]]; then # Si arg est null 
					erreur 8 
				elif [[ "$1" == "$arg2" ]]; then #si l'utilisateur est déjà connecté à cette machine
					erreur 2
				elif [[ "$2" != "$arg1" ]]; then #si l'utilisateur connecté n'est pas égal à utilisateur entré
					erreur 9
				else
					commande-connect $2 $arg2 # Sinon on lance la commande connect
				fi;;
			su )
				if [[ -z $arg1 || ! -z $arg2 ]]; then # Si arg1 sont et arg2 n'est pas null
					erreur 8 
				else
					commande-su $arg1 $1 # Sinon on lance la commande su
					if [[ $? == 0 ]]; then # Si la commande su renvoie 0
						ajoutLog $1 $arg1 # On ajoute le log
						promptConnect $1 $arg1 # On relance un prompt
					fi
				fi;;
			passwd )
				if [[ ! -z $arg1 ]]; then # Si arg ne sont pas null
					erreur 8
				else	
					commande-passwd $2 # On lance la commande passwd
				fi;;
			write )
				if [[ ! -z $arg1 && ! -z $arg2 ]]; then # Si arg1 et arg2 ne sont pas nuls et que arg3 est nul
					commande-write $2 $1 $arg1 $arg2 # On lance la commande write
				else
					erreur 8 
				fi;;
			finger )
				if [[ ! -z $arg1 && -z $arg2 ]]; then # Si arg1 n'est pas nul et que arg2 est nul
					commande-finger $arg1; # On lance la commande finger
				else
					erreur 8 
				fi;;
			exit )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					supprimeLog $1 $2 # Suppression du log
					return 1 # Sortie de la fonction avec un 1
				else
					erreur 8 # On lance l'erreur 8
				fi;;
			*)
				erreur 12;; # Si l'utilisateur n'entre pas une commande correcte on lance l'erreur 12
		esac
	done
}

# Fonction who : permet de voir qui est connecté sur la machine passée en argument
# Argument 1 : machine
function commande-who { 
	#echo "machine: $1"
	sed -n '/'$1'/ p' connexion.log | sed 's/'$1' //'  
	# 1ere sed : afficher les lignes du log ou la machine est présente 
	# 2eme sed : supprimer la machine afin de voir uniquement les infos qui nous intéressent
}

# Fonction rusers : afficher les utilisateurs connectés au réseau virtuel
# Elle va simplement lire la contenu du fichier connexion.log 
function commande-rusers {
	while read ligne 
	do
		echo $ligne
	done < connexion.log
}

# Fonction rhost : afficher toutes les machines connectées au réseau virtuel
# Elle va simplement lire la contenu du fichier machines.txt
function commande-rhost {
	while read ligne 
	do
		echo $ligne
	done < machines.txt
}

# Fonction connect permettant à un utilisateur de se connecter sur une autre machine
# Argument 1 : utilisateur Argument 2 : machine
# Syntexe : connect nomUser nomMachine
function commande-connect { 
	verifAcces $1 $2 # Vérifie access d'utilisateur sur cette machine
	if [[ $? == 0 ]]; then # Si oui
		ajoutLog $2 $1 # On ajoute le log pour dire qu'il est connecté
		promptConnect $2 $1 # On relance un nouveau prompt pour cette connexion
	fi
}

# Fonction su : changer d'utilisateur 
# Argument 1 : utilisateur Argument 2 : machine
# Syntexe : su nomUser
# Return 0 si c'est bon et 1 sinon
function commande-su { 
	# Verifie si l'utilisateur existe
	verifUtilisateur $1 $2 
	if [[ $? == 1 ]] ; then #utilisateur non existe
		return 1
	fi
	# Vérifie que l'utilisateur rentre le bon mot de passe
	verifMdp $1; 
	if [[ $? == 0 ]] ; then # Mdp bon
		return 0 
	else
		return 1 
	fi;
}

# Fonction passwd permettant à un utilisateur de changer son mot de passe
# Argument 1: utilisateur 
function commande-passwd { 
	echo "Change mot de passe pour $1"
	oldMdp=$(grep -w $1 utilisateurs.txt | cut -f2 -d':'); 
	# grep : récupérer la ligne correspondant à l'utilisateur
	# cut : récupérer que son mot de passe
	# touch temp_user; # Crée un fichier temp_user

	stty -echo
	read -p "Mot de passe actuel: " mdpActuel  	
	echo ""
	read -p "Nouveau mot de passe: " mdpNew1 
	echo ""
	read -p "Confirmer le nouveau mot de passe: " mdpNew2
	echo ""
	stty echo

	if [[ $oldMdp == $mdpActuel ]] ; then
		if [[ $mdpNew1 == $mdpNew2 ]] ; then
				while read ligne # Lit le fichier utilisateurs.txt
				do
					if [[ $ligne == $(grep -w $1 utilisateurs.txt) ]] ; then #cherche la ligne correspondant à l'utilisateur
						echo $ligne | sed 's/'$oldMdp'/'$mdpNew1'/g' >> temp_utilisateurs.txt  
						# on change l'ancien mot de passe par le nouveau 
						# puis on met cette ligne dans le fichier intermediaire
						echo "Mot de passe changé !" 
					else
						echo $ligne >> temp_utilisateurs.txt #d'autre ligne d'utilisateur
					fi
				done < utilisateurs.txt
				
				rm utilisateurs.txt; # On supprime le fichier utilisateurs existant
				mv temp_utilisateurs.txt  utilisateurs.txt # Le fichier temp_utilisateurs.txt devient le nouveau fichier utilisateurs
				chmod 777 utilisateurs.txt # On change le droit du fichier
		else
			erreur 14
		fi
	else
		erreur 14
	fi

}

# Fonction write : envoyer un message à un autre utilisateur
# Argument 1 : expediteur Argument 2 : machine expediteur 
# Argument 3 : destination (nomUser@nomMachine)  Argument 4 : message
function commande-write { 
	ttyDest=O;
	dest=$(echo $3 | cut -f1 -d'@');
	macDest=$(echo $3 | cut -f2 -d'@');
	ttyDest=$(grep -w "$macDest $dest" connexion.log | tail -n 1 | cut -f9 -d' ' ) #recuperer le termial du destinataire
	#1 ere grep : recuperer la ligne du log de destinataire
	#tail -n 1 : prendre le derniere connexion si destinataire connecte depuis plusieur terminal
	#cut : recuperer le terminal

	if [[ -z $ttyDest || -z $3 ]]; then
	 	erreur 15
	else
	 	echo "Message envoyé à $dest au terminal $ttyDest";
	 	echo "Message de $1@$2 : $arg2" >> $ttyDest; #informe le destinataire qu'il a recu un message

	fi
}

# Fonction finger : afficher les commentaires liés à un utilisateur
# Argument 1 : utilisateur
function commande-finger { 
	if [[ -f finger/$1_finger.txt ]] ; then # Si le fichier finger propre à l'utilisateur existe
		while read ligne 
		do
			echo $ligne;
		done < finger/$1_finger.txt
	else
		erreur 10 ; 
	fi	
}

#------------------------------------- MODE ADMIN -------------------------------------

# Fonction promptAdmin affichant le prompt si on a rentré l'option -admin
function promptAdmin {
	echo "Vous êtes connecté en tant qu'administrateur !"; # Confirme à l'utilisateur qu'il est en mode admin
	echo "Tapez help pour voir le commande disponible"
	echo "Tapez exit pour sortir de l'invite de commandes."
	echo ""
	while [ true ] # Boucle infinie
	do
		read -p "rvsh> " reponse arg1 arg2 arg3 arg4; # Attend une réponse de l'utilisateur
		case $reponse in # En fonction de la réponse écrite le prompt lance une commande
			help )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					commande-help "rvsh"; # Lance la commande help
				else
					erreur 8; 
				fi
				;;
			host )
				if [[ ! -z $arg3 ]] ; then # Si arg3 n'est pas nul
					erreur 8; 
				else
					if [[ $arg1 == "-a" ]]; then # Si l'option est -a
						commande-host-a $arg2; # On lance la commande host-a
					elif [[ $arg1 == '-d' ]]; then # Si l'option est -d
						commande-host-d $arg2; # On lance la commande host-d
					else
						erreur 11; 
					fi;
				fi
				;;
			users )
				if [[ ! -z $arg1 && ! -z $arg2 && ! -z $arg3 && -z $arg4 ]]; then # Si arg1 arg2 et arg3 ne sont pas nuls et que arg4 est nul
					commande-users $arg1 $arg2 $arg3; # On lance la commande useres
				else 
					erreur 8; 
				fi
				;;
			afinger )
				if [[ -z $arg2 ]]; then # Si arg1 est nul
					commande-afinger $arg1; # On lance la commande afinger
				else
					erreur 8; 
				fi
				;;
			exit )
				if [[ -z $arg1 ]]; then # Si arg1 est nul
					exit 1; # Sortie du programme
				else
					erreur 8; 
				fi
				;;
			*)
				erreur 12;; 
		esac
	done
}

# Fonction host-a permettant d'ajouter une nouvelle machine sur le réseau virtuel
# Argument 1: machine à ajouter
function commande-host-a { 
	if [[ $1 == $(grep -w $1 machines.txt) ]] ; then
		erreur 16
	else
		read -p "Etes-vous sûr de vouloir ajouter la machine \"$1\" au réseau ? (O/N)" rep ; # Message de confirmation
		if [[ $rep == O || $rep == o ]] ; then # Si l'utilisateur confirme
			echo "$1" >> machines.txt; # On ajoute la machine dans le fichier machines
			echo "$1 ajoutée au réseau !"; # On indique que l'opération s'est bien effectuée
		else
			echo "Ajout annulé"; # Sinon l'opération est annulée
		fi;
	fi
}

# Fonction host-d permettant de supprimer une machine du réseau virtuel
# Argument 1: machine à supprimer
function commande-host-d { 
	if [[ $1 == $(grep -w $1 machines.txt) ]] ; then # Vérifie si la machine entrée existe bien
		sed '/^'$1'$/d' machines.txt > nmachines.txt && mv nmachines.txt machines.txt; # Supprimer la machine du fichier machines.txt
		rm -f nmachines.txt; # Supprime le fichier temporaire
		echo "Machine supprimée !"; # Indique à l'utilisateur que l'opération est effectuée
		sed 's/:'$1'//g' utilisateurs.txt > nutilisateurs.txt && mv nutilisateurs.txt utilisateurs.txt; # Supprime la machine en question dans le fichier utilisateur
	else
		erreur 4
	fi
}

# Fonction users permettant d'ajouter, de supprimer ou de modifier un utilisateur
# Argument 1: option Argument 2: utilisateur  Argument 3: machine à ajouter ou mot de passe en fonction de l'option
function commande-users { 
	if [[ $1 == "-a" && ! -z $3 ]]; then # Si l'option choisie et -a
		if [[ $2 == $3 ]]; then
			erreur 17
		else 
			if [[ $2 == $(egrep -w $2 utilisateurs.txt | cut -f1 -d':') ]]; then # On regarde si le nom de l'utilisateur deja existe
				echo "Utilisateur déjà existe. Choisir d'autre nom d'utilisateur"
			else
				echo "$2:$3">> utilisateurs.txt; # On ajoute un nouvel utilisateur dans le fichier utilisateurs.txt
				touch finger/$2_finger.txt; #On creer aussi une fichier vide
				echo "$2 creé !"
			fi
		fi
	elif [[ $1 == "-d" ]]; then # Si l'option choisie est -d
		if [[ $2 == $(egrep -w $2 utilisateurs.txt | cut -f1 -d':') ]] ; then # On regarde si l'utilisateur existe
			sed '/'^$2'[:]/ d' utilisateurs.txt > nutilisateurs.txt && mv nutilisateurs.txt utilisateurs.txt; # On supprime l'utilisateur du fichier utilisateur avec un sed
			rm -f nutilisateurs.txt; # On supprimer le fichier temporaire
			rm finger/$2_finger.txt;
			echo "Utilisateur supprimé"; # On indique à l'utilisateur que l'opération s'est bien effectuée
		else 
			echo "Cet utilisateur n'existe pas."; # Sinon on indique à l'utilisateur que l'utilisateur n'existe pas
		fi
	elif [[ $1 == "-ma" ]]; then # Si l'option choisie est -ma
		if [[ $3 == $(grep -w $3 machines.txt) ]] ; then # Vérifie si la machine entrée existe bien
			l=$(grep -w $2 utilisateurs.txt); # On récupère la ligne de l'utilisateur
			if [[ $l != $(grep -w $2 utilisateurs.txt | grep -w $3) ]] ; then # Permet de vérifier si l'utilisateur n'a pas déjà accès à la machine souhaitée
				sed '/'^$2'[:]/ d' utilisateurs.txt > temp_utilisateurs.txt && mv temp_utilisateurs.txt utilisateurs.txt; # Supprime la ligne de l'utilisateur en question
				rm -f temp_utilisateurs.txt; # Supprime le fichier temporaire
				echo "$l:$3" >> utilisateurs.txt; # On ajoute la nouvelle ligne avec la machine en plus
				echo "C'est bon! $2 a le droit d'accès à $3";
			else
				echo "Erreur : $2 avait déjà accès à $3"; # Sinon on indique à l'utilisateur qu'il a déjà accès à cette machine
			fi
		else
			erreur 4
		fi
	else
		erreur 13
	fi
}

# Fonction afinger permettant de modifier le fichier finger
# Argument 1 : utilisateur
function commande-afinger { 
	if [[ -f finger/$1_finger.txt ]] ; then # Vérifie si le fichier finger existe
		nano finger/$1_finger.txt; # On lance un editeur pour l'utilisateur puisse modifier le fichier
	else
		echo "L'utilisateur n'existe pas"; # Sinon on l'indique à l'utilisateur
	fi
}

#------------------------------------- AUTRE -------------------------------------
# Fonction help : affichage des commandes disponibles
function commande-help {
	echo "Help : La liste des commandes disponibles:"
	if [[ $1 == 'rvsh' ]] ; then 
		#En mode admin
		echo "	- host : permet de gerer le machine"
		echo "		Ajouter un machine : host -a nomMachine"
		echo "		Enlever un machine : host -d nomMachine"
		echo "	- users : permet de gerer l'utilisateur"
		echo "		Ajouter utilisateur: users -a nomUser mdp"
		echo "		Enlever un utilisateur: users -d nomUser mdp"
		echo "	  	Donner les droits d’accès au machines a l'utlisateur : users -ma nomUser nomMachine"
		echo "	 	et de lui fixer un mot de passe "
		echo "	- afinger : permet à l’administrateur de renseigner les informations complémentaires sur l’utilisateur." 
	else
		#En mode connect
		echo "	- who : permet d’accéder à l’ensemble des utilisateurs connectés sur la machine."
		echo "	- rusers : permet d’accéder à la liste des utilisateurs connectés sur le réseau."
		echo "	- rhost : renvoie la liste des machines rattachées au réseau virtuel."
		echo "	- connect : permet de se connecter à une autre machine du réseau."
		echo "		connect nomUser nomMachine"
		echo "	- su : permet de changer d’utilisateur "
		echo "		su nomUser"
		echo "	- passwd : permet à l’utilisateur de changer de mot de passe sur l’ensemble du réseau virtuel."
		echo "	- write : permet d’envoyer un message à un utilisateur connecté sur une machine du réseau."
		echo "		write nomUser@nomMachine message"
		echo "	- finger : permet de renvoyer des éléments complémentaires sur l’utilisateur."
		echo "		finger nomUser"
	fi
}

# Fonction erreur qui affiche différents types d'erreurs en fonction de l'argument passé en entrée de la fonction
function erreur {
	case $1 in
		1 )
			echo "Erreur 1. Le nombre d'arguments n'est pas bon. Veuillez réessayer"
			echo "En mode connect: ./rvsh.sh -connect nomMachine nomUtilisateur"
			echo "En mode admin: ./rvsh.sh -admin";;
		2 )
			echo "Erreur 2. Vous êtes actuellement connecté à cette machine";;
		3 )
			echo "Erreur 3. Mot de passe administrateur incorrect.";;
		4 )
			echo "Erreur 4. La machine n'est pas existe.";;
		5 )
			echo "Erreur 5. Le nom d'utilisateur que vous avez entré n'existe pas.";;
		6 )
			echo "Erreur 6. Cet utilisateur n'a pas l'accès sur cette machine ou cette machine n'existe pas.";;
		7 )
			echo "Erreur 7. Vous avez rentré le mauvais de mot de passe à plus de 3 reprises.";
			echo "L'authentification a échoué.";;
		8 ) 
			echo "Erreur 8. Nombre d'arguments incorrect, tapez la commande help pour plus d'informations.";;
		9 ) 
			echo "Erreur 9. Le nom d'utilisateur n'est pas bon";; 
		10 )
			echo "Erreur 10. L'utilisateur n'existe pas.";;
		11 ) 
			echo "Erreur 11. Option invalide. -a pour ajouter une machine -d pour supprimer une machine.";;
		12 ) 
			echo "Erreur 12. Commande incorrecte. Utilisez la commande help afficher l'aide." ;;
		13 )
			echo "Erreur 13. L'option entrée n'existe pas. Les options disponibles sont les suivantes:"
			echo "-a (pour ajouter un utilisateur -d (pour supprimer) -ma (pour modifier les accès).";;
		14)
			echo "Erreur 14. Mot de passe n'est pas bon."
			echo "Changement de mot de passe a échoué";;
		15) 
			echo "Erreur 15. L'utilisateur n'est pas connecté sur le machine";;
		16)
			echo "Erreur 16. La machine que vous souhaitez ajouter est déjà existe";;
		17) 
			echo "Erreur 17. Vous ne pouvez pas mettre votre login comme le mot de passe";;
	esac
	
	if [[ $PROGRAMME_EN_COURS == 0 ]]; then #on a pas encore entre dans le programme
		exit 1; # sort du programme
	else
		return 1; # reste dans la commande 
	fi
}

main "$@"; # Lance la fonciton main avec tous les arguments passés en entrée de la commande
exit 0; # Sortie du programme avec un 0