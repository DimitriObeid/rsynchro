#!/bin/bash

# Script de sauvegarde incrémentielle pour Linux ou tout autre système Unix
# Nativement compatible avec n'importe quel système Unix
# Version Bêta 0.1

# Pour débugguer ce script en cas de besoin, tapez la commande :
# sudo sh -x my_rsync.sh
# Exemple :
# sudo /bin/sh -x my_rsync.sh
# Ou encore
# sudo sh -x my_rsync.sh

# Ou débugguez le en utilisant l'excellent utilitaire Shell Check :
#	En ligne -> https://www.shellcheck.net/
#	En ligne de commandes -> shellcheck beta.sh
#		--> Commande d'installation : sudo $commande_d'installation_de_paquets shellcheck



# ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; #



################### DÉCLARATION DES VARIABLES ET AFFECTATION DE LEURS VALEURS ###################

## COULEURS
# Encodage des couleurs pour mieux lire les étapes de l'exécution du script
RS_C_JAUNE=$(tput setaf 226) 	# Jaune clair	--> Couleur d'affichage des messages de passage à la prochaine étapes
RS_C_RESET=$(tput sgr0)        	# Restauration de la couleur originelle d'affichage de texte selon la configuration du profil du terminal
RS_C_ROUGE=$(tput setaf 196)   	# Rouge clair	--> Couleur d'affichage des messages d'erreur d'une étape
RS_C_VERT=$(tput setaf 82)     	# Vert clair	--> Couleur d'affichage des messages de succès d'une étape


## DOSSIERS ET FICHIERS
# Définition du dossier personnel de l'utilisateur
RS_HOMEDIR="/home/${USER}"		 # Dossier personnel de l'utilisateur
RS_LOG="my_rsync.log"          	     		# Nom du fichier de logs
RS_LOGPATH="$PWD/$RS_LOG"      # Chemin du fichier de logs depuis la racine, dans le dossier actuel


## MATÉRIEL
# Nom des disques durs
RS_HARD_DRIVE_ONE_NAME="Disque dur"


## TEXTE
RS_TAB=">>>>"   # Nombre de chevrons à afficher avant les chaînes de caractères d'étapes, de succès ou d'échec
RS_VOID=""


# Affichage de chevrons suivant l'encodage de la couleur d'une chaîne de caractères
RS_J_TAB="$RS_C_JAUNE$RS_TAB"           # Encodage de la couleur en jaune et affichage de 4 chevrons
RS_R_TAB="$RS_C_ROUGE$RS_TAB$RS_TAB"    # Encodage de la couleur en rouge et affichage de 4 * 2 chevrons
RS_V_TAB="$RS_C_VERT$RS_TAB$RS_TAB"     # Encodage de la couleur en vert et affichage de 4 * 2 chevrons



# ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; #



############################################# DÉFINITIONS DES FONCTIONS #############################################


#### DÉFINITION DES FONCTIONS INDÉPENDANTES DE L'AVANCEMENT DU SCRIPT ####


## DÉFINITION DES FONCTIONS DE DÉCORATION DU SCRIPT
# Affichage d'un message en jaune avec des chevrons, sans avoir à encoder la couleur au début et la fin de la chaîne de caractères
function j_echo() { j_string=$1; echo "$RS_J_TAB $j_string $RS_C_RESET" 2>&1 | tee -a "$RS_LOGPATH"; $RS_SLEEP; }

# Affichage d'un message en rouge avec des chevrons, sans avoir à encoder la couleur au début et la fin de la chaîne de caractères
function r_echo_nolog() { r_n_string=$1; echo "$RS_R_TAB $r_n_string $RS_C_RESET"; }
# Appel de la fonction précédemment créée redirigeant les sorties standard et les sorties d'erreur vers le fichier de logs
function r_echo() { r_string=$1; r_echo_nolog "$r_string" 2>&1 | tee -a "$RS_LOGPATH"; $RS_SLEEP; }

# Affichage d'un message en vert avec des chevrons, sans avoir à encoder la couleur au début et la fin de la chaîne de caractères
function v_echo_nolog() { v_n_string=$1; echo "$RS_V_TAB $v_n_string $RS_C_RESET"; }
# Appel de la fonction précédemment créée redirigeant les sorties standard et les sorties d'erreur vers le fichier de logs
function v_echo() { v_string=$1; v_echo_nolog "$v_string" 2>&1 | tee -a "$RS_LOGPATH"; $RS_SLEEP; }


## GESTION D'ERREURS FATALES
function fatal_error()
{
	error_str=$1

	r_echo_nolog "Une erreur fatale s'est produite :" 2>&1 | tee -a "$RS_LOGPATH"
	r_echo_nolog "$error_str" 2>&1 | tee -a "$RS_LOGPATH"
	echo "$RS_VOID" 

	r_echo_nolog "Arrêt de l'exécution du script" 2>&1 | tee -a "$RS_LOGPATH"
	echo "$RS_VOID"

	echo "En cas de bug, veuillez m'envoyer le fichier de logs situé dans votre dossier personnel. Il porte le nom de \"$RS_LOG\" et se trouve dans le dossier $(echo "$RS_LOGPATH")"
	echo "$RS_VOID"

	exit 1
} 


## DÉFINITION DES FONCTIONS DE CRÉATION DE FICHIERS
# Fonction de création de fichiers ET d'attribution des droits de lecture et d'écriture à l'utilisateur
function makefile()
{
	file_dirparent=$1	# Dossier parent du fichier à créer
	filename=$2			# Nom du fichier à créer
	filepath="$file_dirparent/$filename"

	# Si le fichier à créer n'existe pas
	if test ! -f "$filepath"; then
		touch "$file_dirparent/$filename" 2>&1 | tee -a "$RS_LOGPATH" \
			|| fatal_error "LE FICHIER \"$filename\" n'a pas pu être créé dans le dossier \"$file_dirparent\"" \
			&& v_echo "Le fichier \"$filename\" a été créé avec succès dans le dossier \"$file_dirparent\""

		chown -v "$RS_USERNAME" "$filepath" >> "$RS_LOGPATH" \
			|| {
				r_echo "Impossible de changer les droits du fichier \"$filepath\""
				r_echo "Pour changer les droits du fichier \"$filepath\","
				r_echo "utilisez la commande :"
				echo "	chown $RS_USERNAME $filepath"

				return
			} \
			&& v_echo "Les droits du fichier $filepath ont été changés avec succès"

		return

	# Sinon, si le fichier à créer existe déjà ou qu'il n'est pas vide
	elif test -f "$filepath" || test -s "$filepath"; then
		true > "$filepath" \
			|| r_echo_nolog "Le contenu du fichier \"$filepath\" n'a pas été écrasé" >> "$RS_LOGPATH" \
			&& v_echo_nolog "Le contenu du fichier \"$filepath\" a été écrasé avec succès" >> "$RS_LOGPATH"

		return
	fi
}


# ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; #

#### DÉFINITION DES FONCTIONS DÉPENDANTES DE L'AVANCEMENT DU SCRIPT ####



## INITIALISATION DU PROGRAMME
# Fonction de création du fichier de logs
function create_log_file()
{
	# On évite d'appeler les fonctions d'affichage propre "v_echo()" ou "r_echo()" pour éviter d'écrire deux fois le même texte,
	# vu que ces fonctions appellent chacune une commande écrivant dans le fichier de logs

	# Si le fichier de logs n'existe pas, le script le crée via la fonction "makefile"
	makefile "$PWD" "$RS_LOG" > /dev/null
	echo "$RS_VOID" >> "$RS_LOGPATH" 	# Au moment de la création du fichier de logs, la variable "$RS_LOGPATH" correspond au dossier actuel de l'utilisateur

	v_echo_nolog "Fichier de logs créé avec succès" >> "$RS_LOGPATH"
	echo "$RS_VOID" >> "$RS_LOGPATH"

	# Récupération d'éléments servant à mieux identifier le système d'exploitation de l'utilisateur
	echo "Kernel : $(uname -s)" >> "$RS_LOGPATH"				# Récupération du nom du noyau
	echo "Version du Kernel : $(uname -r)" >> "$RS_LOGPATH"		# Récupération du numéro de version du noyau
	# Récupération des informations sur le système d'exploitation de l'utilisateur
	echo "Informations sur le système d'exploitation :" >> "$RS_LOGPATH"
	echo "$RS_VOID" "$RS_VOID" >> "$RS_LOGPATH"
	
	cat "/etc/os-release" >> "$RS_LOGPATH"
	echo "$RS_VOID" "$RS_VOID" >> "$RS_LOGPATH"

	v_echo_nolog "Fin des informations sur le système d'exploitation" >> "$RS_LOGPATH"
	echo "$RS_VOID" >> "$RS_LOGPATH"

	return
}

# Détection de l'exécution en mode super-utilisateur
is_executed_in_root()
{
    if test $UID = 0; then
		fatal_error "N'exécutez pas ce script en mode super-utilisateur"
	fi

	return
}

# Affichage d'un message de sécurité
function warning()
{
    j_echo "ATTENTION : LE SCRIPT QUE VOUS SOUHAITEZ LANCER PEUT NE PAS ÊTRE ADAPTÉ À L'ARBORESCENCE DE VOTRE SUPPORT DE SAUVEGARDE"
    j_echo "PRENEZ LE TEMPS DE LIRE LE SCRIPT ET DE MODIFIER LES CHEMINS DE LA FONCTION \"backup()\" EN LES ADAPTANT À L'ARBORESCENCE DU SUPPORT DE STOCKAGE CIBLE"
    echo "$RS_VOID"
    
    j_echo "Êtes-vous sûr de vouloir lancer le script ?"
    echo "$RS_VOID"
    
    echo "$RS_C_VERT"
    echo "Note :$RS_C_RESET Vous pouvez désactiver ce message en commentant ou en supprimant l'appel de la fonction \"warning()\" au début de la fonction \"script_init()\""
        
    read -r -p "Entrez votre réponse : " rep_warning
    
    function read_warning()
    {
        case ${rep_warning,,} in
            "oui")
                v_echo "Lancement du script"
                echo "$RS_VOID"
                
                return
                ;;
            "non")
                r_echo "Abandon"
                
                exit 1
                ;;
            *)
                j_echo "Veuillez répondre par \"oui\" ou par \"non\""
                echo "$RS_VOID"
                
                read_warning
                ;;
        esac
    }
}


## DÉTECTION DU MATÉRIEL
# Détection du disque dur externe
function detect_hard_drive()
{
    if test ! -d "/media/$USER/$RS_HARD_DRIVE_ONE_NAME"; then
        fatal_error "Le disque dur externe n'est pas branché"
    else
        v_echo "Le disque dur externe est bien branché"
    fi

	return
}


## SAUVEGARDE
# Fonction de backup des données
backup()
{
    rsync 
}

## APPEL DE FONCTIONS
create_log_file
is_executed_in_root
warning
detect_hard_drive
