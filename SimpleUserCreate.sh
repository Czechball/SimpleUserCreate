#!/bin/bash
#SimpleUserCreate.sh

OKFORMAT="[\e[32mOK\e[0m   ]     "
ERRORFORMAT="[\e[38;5;196mERROR\e[0m]     "
INFOFORMAT="[\e[38;5;44mINFO\e[0m ]     "
QUESTIONFORMAT="[?    ]     "

userCreateError () {
printf "\n$ERRORFORMAT Vytvoření uživatele bylo přerušeno.\n$INFOFORMAT Zadejte prosím znovu své údaje\n--------------\n\n"
readPrimaryName	
}

readPrimaryName () {
printf "$INFOFORMAT Zadejte prosím své jméno:"
read primaryName
if [[ $primaryName = "" ]];
	then
		printf "$ERRORFORMAT Vaše jméno nesmí být prázdné.\n"
		readPrimaryName
fi

}

readSecondaryName () {
printf "$INFOFORMAT Zadejte prosím vaše příjmení:"
read secondaryName
if [[ $secondaryName = "" ]];
	then
		printf "$ERRORFORMAT Vaše příjmení nesmí být prázdné.\n"
		readSecondaryName
fi

}

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

userCheck () {
	if id "$nickname" >/dev/null 2>&1;
	then
        printf "$ERRORFORMAT Uživatel jménem $nickname již existuje. Prosím vyberte si jiný nickname.\n"
        readNickname
	fi
}

userPrompt () {
printf "$INFOFORMAT Vaše jméno: $primaryName $secondaryName\n$INFOFORMAT Název vašeho účtu: $nickname\n"
read -p "$QUESTIONFORMAT Chcete vytvořit uživatelský účet s těmito údaji? A/n " -n 1 -r
echo
	if [[ $REPLY =~ ^[AaYy]$ ]];
	then
		sudo useradd $nickname -c "$primaryName $secondaryName"
		printf "$INFOFORMAT Vytváření uživatele $nickname s komentářem '$primaryName $secondaryName' ...\n"
	else
		userCreateError
	fi
}

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

groupCreate () {
	printf "\n$INFOFORMAT Vytváření skupiny 'sales'...\n"
	sudo groupadd sales
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

userModAddGroup () {
printf "$INFOFORMAT Přidávání uživatele $nickname do skupiny 'sales'...\n"
sudo usermod -a -G sales $nickname
printf "$INFOFORMAT Kontrola skupin uživatele $nickname...\n"
if getent group sales | grep&>/dev/null "\b$nickname\b";
then
	printf "$OKFORMAT Uživatel $nickname je ve skupině 'sales'.\n"
else
	printf "\e[38;5;196mCHYBA: Uživatel $nickname není ve skupině 'sales'.\nMáte oprávnění root?\nSkript nespouštějte jako sudo, ale zadejte root heslo až k tomu budete vyzváni.\e[0m\n"
fi
}

userDeletePrompt () {
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

splash () {
	printf "Simple User Create Script\n"
	printf " ******* Verze 1.4  *******\n"
	printf " ----Vytvořil Czechball----\n"
	printf " https://github.com/Czechball\n"
	printf " \n"
}

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
userDeletePrompt
groupDeletePrompt
repeatPrompt
mainLoop
}

splash
printf "$INFOFORMAT Dobrý Den. Vítejte v SimpleUserCreate skriptu.\n"
mainLoop