#!/bin/bash
#SimpleUserCreate.sh

#>>> text formatting variables
OKFORMAT="[\e[32mOK\e[0m   ]"
ERRORFORMAT="[\e[38;5;196mERROR\e[0m]"
INFOFORMAT="[\e[38;5;44mINFO\e[0m ]"
QUESTIONFORMAT="[?    ]"

#>>> core functions

#>> splash screen
splash () {
	printf "Simple User Create Script\n"
	printf " ******* Verze 1.4  *******\n"
	printf " ----Vytvořil Czechball----\n"
	printf " https://github.com/Czechball\n"
	printf " \n"
}

#>> main function (loop)
mainLoop () {
readPrimaryName
readSecondaryName
readNickname
userCheck
userPrompt
userAfterCheck
groupPrompt
groupCheck
groupCreate
userModAddGroup
accountsFileCheck
userDeletePrompt
groupDeletePrompt
fileDeletePrompt
repeatPrompt
mainLoop
}

sudoCheck () {
if [ "$EUID" -ne 0 ]
then printf "$ERRORFORMAT Prosím spusťte tento skript jako root.\n"
exit
else :
fi
}

#>> reading user's primary name
readPrimaryName () {
printf "$INFOFORMAT Zadejte prosím své jméno:"
read primaryName
if [[ $primaryName = "" ]];
	then
		printf "$ERRORFORMAT Vaše jméno nesmí být prázdné.\n"
		readPrimaryName
fi

}

#>> reading user's secondary name
readSecondaryName () {
printf "$INFOFORMAT Zadejte prosím vaše příjmení:"
read secondaryName
if [[ $secondaryName = "" ]];
	then
		printf "$ERRORFORMAT Vaše příjmení nesmí být prázdné.\n"
		readSecondaryName
fi

}

#>> reading users desired username
readNickname () {
printf "$INFOFORMAT Zadejte prosím váš nickname (přihlašovací jméno):"
read nickname
if [[ $nickname = "" ]];
	then
		printf "$ERRORFORMAT Uživatelské jméno nesmí být prázdné.\n"
		readNickname
	else
		userCheck
fi

}

#>> checking if entered username already exists in system
userCheck () {
	if id "$nickname" >/dev/null 2>&1;
	then
        printf "$ERRORFORMAT Uživatel jménem $nickname již existuje. Prosím vyberte si jiný nickname.\n"
        readNickname
	fi
}


#>> prompting user to confirm entered info and account creation
userPrompt () {
printf "$INFOFORMAT Vaše jméno: $primaryName $secondaryName\n$INFOFORMAT Název vašeho účtu: $nickname\n"
read -p "$QUESTIONFORMAT Chcete vytvořit uživatelský účet s těmito údaji? A/n " -n 1 -r
echo
	if [[ $REPLY =~ ^[AaYy]$ ]];
	then
		useradd $nickname -c "$primaryName $secondaryName"
		printf "$INFOFORMAT Vytváření uživatele $nickname s komentářem '$primaryName $secondaryName' ...\n"
	else
		userCreateError
	fi
}


#>> checking if the account was created succesfully (probably not necessary but whatever)
userAfterCheck () {
printf "$INFOFORMAT Kontrola ID...\n"
	if id "$nickname" >/dev/null 2>&1;
	then
    	printf "$OKFORMAT Účet '$nickname' existuje v id.\n$OKFORMAT Účet byl úspěšně vytvořen.\n"
	else
		printf "\e[38;5;196mCHYBA: Účet se nepodařilo zkontrolovat. Máte oprávnění root?\nSkript nespouštějte jako sudo, ale zadejte root heslo až k tomu budete vyzváni.\e[0m\n"
		exit
	fi
}


#>> prompting user to begin the group creation process
groupPrompt () {
	read -p "$QUESTIONFORMAT Nyní bude přidána skupina 'sales' a do ní přiřazen uživatel $nickname. Chcete pokračovat? A/n " -n 1 -r
	echo
		if [[ $REPLY =~ ^[AaYy]$ ]];
		then
			:
		else
			repeatPrompt
		fi
}

#>> checking if group named 'sales' exists in system, then prompt its creation
groupCheck () {
	printf "$INFOFORMAT Kontrola existence skupiny 'sales'...\n"
if grep -q sales /etc/group
	then
		read -p "$QUESTIONFORMAT Skupina 'sales' již existuje. Chcete přiřadit uživatele '$nickname' do skupiny 'sales'? A/n " -n 1 -r
		echo
	if [[ $REPLY =~ ^[AaYy]$ ]];
		then
			userModAddGroup
		else
			repeatPrompt
	fi
	else
			read -p "$QUESTIONFORMAT Skupina 'sales' nebyla v /etc/group nalezena. Chcete vytvořit skupinu 'sales'? A/n " -n 1 -r
		if [[ $REPLY =~ ^[AaYy]$ ]];
			then
				:
			else
				groupDeletePrompt
		fi
fi
}

#>> creating a group calles 'sales'
groupCreate () {
	printf "\n$INFOFORMAT Vytváření skupiny 'sales'...\n"
	groupadd sales
	printf "$INFOFORMAT Kontrola existence skupiny 'sales'...\n"
	if grep -q sales /etc/group
	then
		printf "$OKFORMAT Skupina 'sales' byla úspěšně vytvořena.\n"
		read -p "$QUESTIONFORMAT Chcete přiřadit uživatele '$nickname' do skupiny 'sales'? A/n " -n 1 -r
		echo
		if [[ $REPLY =~ ^[AaYy]$ ]];
		then
			:
		else
			printf "\e[38;5;196mCHYBA: Skupina nebyla vytvořena.\nMáte oprávnění root?\nSkript nespouštějte jako sudo, ale zadejte root heslo až k tomu budete vyzváni.\e[0m\n"
			exit
		fi
	fi
}

#>> adding the created user to the group 'sales'
userModAddGroup () {
printf "$INFOFORMAT Přidávání uživatele $nickname do skupiny 'sales'...\n"
usermod -a -G sales $nickname
printf "$INFOFORMAT Kontrola skupin uživatele $nickname...\n"
if getent group sales | grep&>/dev/null "\b$nickname\b";
then
	printf "$OKFORMAT Uživatel $nickname je ve skupině 'sales'.\n"
else
	printf "\e[38;5;196mCHYBA: Uživatel $nickname není ve skupině 'sales'.\nMáte oprávnění root?\nSkript nespouštějte jako sudo, ale zadejte root heslo až k tomu budete vyzváni.\e[0m\n"
fi
}

accountsFileCheck () {
	printf "$INFOFORMAT Nyní bude vytvořen soubor s informacemi v '/root/accounts'\n"
	printf "$INFOFORMAT Kontrola existence souboru '/root/accounts'...\n"
	if [ -f /root/accounts ]; 
	then
		printf "$INFOFORMAT /root/accounts již existuje. Budou do něj zapsány informace o vytvořeném uživateli.\n"
		read -p "$QUESTIONFORMAT Chcete zapsat informace o uživateli? A/n " -n 1 -r
		echo
		if [[ $REPLY =~ ^[AaYy]$ ]];
		then
			:
		else
			repeatPrompt
		fi
		accountsFileAppend
	else
		printf "$INFOFORMAT /root/accounts neexistuje. Bude vytvořen a budou do něj zapsány informace o vytvořeném uživateli.\n"
		read -p "$QUESTIONFORMAT Chcete vytvořit soubor /etc/accounts a zapsat do něj informace u uživateli? A/n " -n 1 -r
		echo
		if [[ $REPLY =~ ^[AaYy]$ ]];
		then
			:
		else
			repeatPrompt
		fi
		accountsFileCreate
	fi
}

accountsFileCreate () {
	printf "$INFOFORMAT Vytváření souboru '/root/accounts'...\n"
	echo "$primaryName, $secondaryName, $nickname" > /root/accounts
	printf "$INFOFORMAT Kontrola souboru '/root/accounts'..."
	if [ -f /root/accounts ];
	then
		printf "$OKFORMAT Soubor byl úspěšně vytvořen a uživatel zapsán.\n"
		printf "$INFOFORMAT Obsah souboru /root/accounts :\n"
		cat /root/accounts
	else
		printf "$ERRORFORMAT \e[38;5;196mCHYBA: Soubor '/root/accounts' nebyl nalezen. Máte oprávnění root?\e[0m\n"
	fi
}

accountsFileAppend () {
	printf "$INFOFORMAT Zapisování údajů o uživateli do '/root/accounts'...\n"
	echo "$primaryName, $secondaryName, $nickname" >> /root/accounts
	printf "$OKFORMAT Údaje byly zapsány.\n"
	printf "$INFOFORMAT Obsah souboru '/root/accounts' :\n"
	cat /root/accounts
}

#>> cleanup prompt, deleting user
userDeletePrompt () {
	printf "$INFOFORMAT Celý skript byl nyní úspěšně dokončen. Budou vymazány jeho úpravy systému.\n"
	read -p "$QUESTIONFORMAT Chcete vymazat vytvořeného uživatele? a/N " -n 1 -r
	echo
		if [[ $REPLY =~ ^[AaYy]$ ]];
		then
			sudo userdel -f $nickname
			printf "$INFOFORMAT Mazání uživatele '$nickname' ...\n"
			printf "$INFOFORMAT Kontrola ID...\n"
			if id "$nickname" >/dev/null 2>&1;
			then
				printf "\e[38;5;196mCHYBA: Účet stále existuje v ID. Máte oprávnění root?\nSkript nespouštějte jako sudo, ale zadejte root heslo až k tomu budete vyzváni.\e[0m\n"
				exit
			else
				printf "$OKFORMAT Účet $nickname již neexistuje v id.\n$OKFORMAT Účet byl úspěšně vymazán.\n"
			fi
		else
			:
		fi
}

#>> cleanup prompt, deleting group
groupDeletePrompt () {
	read -p "$QUESTIONFORMAT Chcete vymazat skupinu 'sales'? a/N " -n 1 -r
	echo
		if [[ $REPLY =~ ^[AaYy]$ ]];
		then
			sudo delgroup sales
		else
			:
		fi
}

fileDeletePrompt () {
	read -p "$QUESTIONFORMAT Chcete vymazat soubor '/root/accounts'? a/N " -n 1 -r
	echo
		if [[ $REPLY =~ ^[AaYy]$ ]];
		then
			sudo rm /root/accounts
		else
			:
		fi
}

#>> asking the user if another account should be created
repeatPrompt () {
read -p "$QUESTIONFORMAT Chcete vytvořit další účet? a/N " -n 1 -r
echo
	if [[ $REPLY =~ ^[AaYy]$ ]];
	then
		:
	else
		printf "$OKFORMAT Skript dokončen.\n"
		exit
	fi
}

#>>> misc functions

#>> if there is a user induced error in the account creation process, this function is called
userCreateError () {
printf "\n$ERRORFORMAT Vytvoření uživatele bylo přerušeno.\n$INFOFORMAT Zadejte prosím znovu své údaje\n--------------\n\n"
readPrimaryName	
}

#>>> the main code
sudoCheck
splash
printf "$INFOFORMAT Dobrý Den. Vítejte v SimpleUserCreate skriptu.\n"
mainLoop