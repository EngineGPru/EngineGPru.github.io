#!/bin/bash

clear
echo "Инициализация..."

# Запись логов авто-установщика
:<<WRITELOG_OFF
    LOG_PIPE=log.pipe
    rm -f LOG_PIPE
    mkfifo ${LOG_PIPE}
    LOG_FILE=log.file
    tee < ${LOG_PIPE} ${LOG_FILE} &
    
    exec  > ${LOG_PIPE}
    exec  2> ${LOG_PIPE}
WRITELOG_OFF

echo "Определение версии операционной системы..."

# Определение версии ОС и задание переменной для избирания нужных команд
VER=`cat /etc/issue.net | awk '{print $1$3}'`
case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
    Debian)     type="deb" ;;
    Ubuntu)     type="ubn" ;;
    *)          type="rhl" ;;
esac

if [ $type = "rhl" ]; then
	echo "Подготовка системы..."
	yum -y install wget
fi

DOMAIN="https://enginegp.ru" # Основной домен для работы
SHVER="2.0" # Версия установщика

echo "Получение данных с сервера..."

# GitHub
#GITUSER=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '33p') # Логин для доступа к приватному репозиторию EngineGP (пока не используется)
#GITTOKEN=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '36p') # Токен для доступа к приватному репозиторию EngineGP (пока не используется)
GITLINK=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '39p') # Ссылка для клонирования репозитория
GITREQLINK=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '42p') # Ссылка для клонирования репозитория с надстройками

# Получение переменных с сервера
LASTSHVER=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '2p')  # Последняя доступная версия установщика
GAMES=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '11p')  # Адрес репозитория игр
PHPVER=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '14p') # Версия PHP
PMALINK=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '29p') # Ссылка на phpMyAdmin
PMAVER=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '26p') # Версия phpMyAdmin
SQLLINK=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '23p') # Ссылка на MySQL
SQLVER=$(wget -qO- $DOMAIN"/installers_variables/all" | sed -n '20p') # Версия MySQL

echo "Определение IP-адреса..."

IPADDR=$(echo "${SSH_CONNECTION}" | awk '{print $3}') # Определение IP VDS первым методом
if [ "empty$IPADDR" = "empty" ] || [ "empty" = "empty$IPADDR" ]; then
	IPADDR=$(wget -qO- eth0.me) # Определение IP VDS вторым методом
	if [ "empty$IPADDR" = "empty" ] || [ "empty" = "empty$IPADDR" ]; then
		IPADDR="ErrorIP"
	fi
fi

SWP=`free -m | awk '{print $2}' | tail -1` # Определение свободного места в оперативной памяти для создания файла подкачки

echo "Запуск программы установки..."

HOSTBIRTHDAY=`date +%s` # Дата установки панели

NUMS=1 # Счетчик всегда начинается с единицы
NUML=4 # Магическое число, НЕ ТРОГАТЬ!
PIMS=22 # Количество этапов установки EngineGP без настройки локации
LSMS=22 # Количество этапов настройки только локации
PLAI=31 # Количество этапов установки EngineGP и настройки локации
LSFE=14 # Количество этапов настройки локации на установленной панели EngineGP

# Элементы дизайна консольной версии установщика
Infon() {
    printf "\033[1;32m$@\033[0m"
}
Info() {
    Infon "$@\n"
}
Error() {
    printf "\033[1;31m$@\033[0m\n"
}
Error_n() {
    Error "$@"
}
Error_s() {
    Error "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
}
log_s() {
    Info "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - "
}
log_n() {
    Info "$@"
}
log_t() {
    log_s
    Info "- - - $@"
    log_s
}

# Установка EngineGP
install_enginegp() {
    clear
    log_t "Start Install EngineGP/Detected OS Version: "$VER
    echo -en "(${NUMS}/${PIMS}) Install packages..."
        necPACK
        addREPO
        infoStats
    echo -en "(${NUMS}/${PIMS}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${PIMS}) Upgrade system..."
        sysUPGRADE
        infoStats
    echo -en "(${NUMS}/${PIMS}) Adding swap..."
        swapADD
        infoStats
    echo -en "(${NUMS}/${PIMS}) Install packages..."
        popPACK
        packPANEL
        varPOP
        varPANEL
        infoStats
    echo -en "(${NUMS}/${PIMS}) Adding php$PHPVER... "
        addPHP
        infoStats
    echo -en "(${NUMS}/${PIMS}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${PIMS}) Install php$PHPVER..."
        installPHP
        infoStats
    echo -en "(${NUMS}/${PIMS}) Install php$PHPVER modules..."
        installPHPPACK
        infoStats
    echo -en "(${NUMS}/${PIMS}) Install apache2..."
        installAPACHE
        infoStats
    echo -en "(${NUMS}/${PIMS}) Setting apache2..."
        setAPACHE
        infoStats
    echo -en "(${NUMS}/${PIMS}) Service restart..."
        serPANELRES
        infoStats
    echo -en "(${NUMS}/${PIMS}) Adding MySQL... "
        setMYSQL
        infoStats
    echo -en "(${NUMS}/${PIMS}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${PIMS}) Install MySQL5.7..."
        installMYSQL
        infoStats
    echo -en "(${NUMS}/${PIMS}) Install phpMyAdmin..."
        setPMA
        infoStats
    echo -en "(${NUMS}/${PIMS}) Setting cron..."
        setCRON
        infoStats
    echo -en "(${NUMS}/${PIMS}) Restart cron..."
        serCRONRES
        infoStats
    echo -en "(${NUMS}/${PIMS}) Download EngineGP..."
        dwnPANEL
        infoStats
    echo -en "(${NUMS}/${PIMS}) Install EngineGP..."
        installPANEL
        infoStats
    echo -en "(${NUMS}/${PIMS}) Setting time..."
        setTIMEPANEL
        infoStats
    echo -en "(${NUMS}/${PIMS}) Service restart..."
        serPANELRES
        serMYSQLRES
        infoStats
    echo "Данные для входа в EngineGP:">>$SAVE
    echo "Адрес: http://$IPADDR/">>$SAVE
    echo "Логин: root">>$SAVE
    echo "Пароль: $ENGINEGPPASS">>$SAVE
    echo "">>$SAVE
    echo "Данные для входа в MySQL:">>$SAVE
    echo "Логин: root">>$SAVE
    echo "Пароль: $MYSQLPASS">>$SAVE
    echo "">>$SAVE
    echo "">>$SAVE
    echo "Обязательные действия:">>$SAVE
    echo "1. Авторизируйтесь в phpMyAdmin: http://$IPADDR/phpmyadmin">>$SAVE
    echo "2. Перейдите в базу данных: enginegp">>$SAVE
    echo "3. Найдите и откройте таблицу: panel">>$SAVE
    echo "4. Вместо «ROOTPASSWORD», введите пароль от сервера, на котором установлена EngineGP.">>$SAVE
    log_n "================ Установка EngineGP успешно завершена ==============="
    Error_n "Ссылка на EngineGP: http://$IPADDR"
    Error_n "Данные для входа, можно посмотреть в файле: /root/enginegp.cfg"
    Error_n "Так-же, там хранится необходимое действие для работы панели!"
    log_n "======================================================================"
}
# Установка EngineGP + Настройка локации
install_enginegp_location() {
    clear
    log_t "Start Install And Setting/Detected OS Version: "$VER
    echo -en "(${NUMS}/${PLAI}) Install packages..."
        necPACK
        addREPO
        infoStats
    echo -en "(${NUMS}/${PLAI}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${PLAI}) Upgrade system..."
        sysUPGRADE
        infoStats
    echo -en "(${NUMS}/${PLAI}) Adding swap..."
        swapADD
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install packages..."
        popPACK
        packPANEL
        varPOP
        varPANEL
        varLOCATION
        infoStats
    echo -en "(${NUMS}/${PLAI}) Adding php$PHPVER... "
        addPHP
        infoStats
    echo -en "(${NUMS}/${PLAI}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install php$PHPVER..."
        installPHP
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install php$PHPVER modules..."
        installPHPPACK
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install apache2..."
        installAPACHE
        infoStats
    echo -en "(${NUMS}/${PLAI}) Setting apache2..."
        setAPACHE
        infoStats
    echo -en "(${NUMS}/${PLAI}) Service restart..."
        serPANELRES
        infoStats
    echo -en "(${NUMS}/${PLAI}) Adding MySQL... "
        setMYSQL
        infoStats
    echo -en "(${NUMS}/${PLAI}) Adding i386..."
        addi386
        infoStats
    echo -en "(${NUMS}/${PLAI}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install MySQL5.7..."
        installMYSQL
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install phpMyAdmin..."
        setPMA
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install Java..."
        installJAVA
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install packages..."
        packLOCATION1
        packLOCATION2
        infoStats
    echo -en "(${NUMS}/${PLAI}) Setting cron..."
        setCRON
        infoStats
    echo -en "(${NUMS}/${PLAI}) Restart cron..."
        serCRONRES
        infoStats
    echo -en "(${NUMS}/${PLAI}) Setting rclocal..."
        setRCLOCAL
        infoStats
    echo -en "(${NUMS}/${PLAI}) Setting iptables..."
        setIPTABLES
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install nginx..."
        installNGINX
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install proftpd..."
        installPROFTPD
        infoStats
    echo -en "(${NUMS}/${PLAI}) Setting configuration..."
        setCONF
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install SteamCMD..."
        installSTEAMCMD
        infoStats
    echo -en "(${NUMS}/${PLAI}) Download EngineGP..."
        dwnPANEL
        infoStats
    echo -en "(${NUMS}/${PLAI}) Install EngineGP..."
        installPANEL
        infoStats
    echo -en "(${NUMS}/${PLAI}) Setting time..."
        setTIMEPANEL
        infoStats
    echo -en "(${NUMS}/${PLAI}) Service restart..."
        serPANELRES
        serMYSQLRES
        infoStats
    echo "Данные для входа в EngineGP:">>$SAVE
    echo "Адрес: http://$IPADDR/">>$SAVE
    echo "Логин: root">>$SAVE
    echo "Пароль: $ENGINEGPPASS">>$SAVE
    echo "">>$SAVE
    echo "Данные для входа в MySQL:">>$SAVE
    echo "Логин: root">>$SAVE
    echo "Пароль: $MYSQLPASS">>$SAVE
    echo "">>$SAVE
    echo "">>$SAVE
    echo "Данные для локации:">>$SAVE
    echo "SQL_Логин: root">>$SAVE
    echo "SQL_Пароль: $MYSQLPASS">>$SAVE
    echo "SQL_FileTP: ftp">>$SAVE
    echo "SQL_Порт: 3306">>$SAVE
    echo "Пароль базы данных ftp: $FTPPASS">>$SAVE
    echo "">>$SAVE
    echo "Обязательные действия:">>$SAVE
    echo "1. Авторизируйтесь в phpMyAdmin: http://$IPADDR/phpmyadmin">>$SAVE
    echo "2. Перейдите в базу данных: enginegp">>$SAVE
    echo "3. Найдите и откройте таблицу: panel">>$SAVE
    echo "4. Вместо «ROOTPASSWORD», введите пароль от сервера, на котором установлена EngineGP.">>$SAVE
    log_n "================ Установка EngineGP успешно завершена ==============="
    Error_n "Ссылка на EngineGP: http://$IPADDR"
    Error_n "Данные для входа, можно посмотреть в файле: /root/enginegp.cfg"
    Error_n "Так-же, там хранится необходимое действие для работы панели!"
    log_n "======================================================================"
	menu_finish
}
# Настройка локации на чистой машине
setting_location() {
    clear
    log_t "Setting location/Detected OS Version: "$VER
    echo -en "(${NUMS}/${LSMS}) Install packages..."
        necPACK
        addREPO
        infoStats
    echo -en "(${NUMS}/${LSMS}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${LSMS}) Upgrade system..."
        sysUPGRADE
        infoStats
    echo -en "(${NUMS}/${LSMS}) Adding swap..."
        swapADD
        infoStats
    echo -en "(${NUMS}/${LSMS}) Install packages..."
        popPACK
        varPOP
        varLOCATION
        infoStats
    echo -en "(${NUMS}/${LSMS}) Adding MySQL..."
        setMYSQL
        infoStats
    echo -en "(${NUMS}/${LSMS}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${LSMS}) Install MySQL5.7..."
        installMYSQL
        infoStats
    echo -en "(${NUMS}/${LSMS}) Install Java..."
        installJAVA
        infoStats
    echo -en "(${NUMS}/${LSMS}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${LSMS}) Install packages..."
        packLOCATION1
        infoStats
    echo -en "(${NUMS}/${LSMS}) Adding i386..."
        addi386
        infoStats
    echo -en "(${NUMS}/${LSMS}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${LSMS}) Install packages..."
        packLOCATION2
        infoStats
    echo -en "(${NUMS}/${LSMS}) Setting rclocal..."
        setRCLOCAL
        infoStats
    echo -en "(${NUMS}/${LSMS}) Setting iptables..."
        setIPTABLES
        infoStats
    echo -en "(${NUMS}/${LSMS}) Install nginx..."
        installNGINX
        infoStats
    echo -en "(${NUMS}/${LSMS}) Install proftpd..."
        installPROFTPD
        infoStats
    echo -en "(${NUMS}/${LSMS}) Setting configuration..."
        setCONF
        infoStats
    echo -en "(${NUMS}/${LSMS}) Install SteamCMD..."
        installSTEAMCMD
        infoStats
    echo -en "(${NUMS}/${LSMS}) Setting time..."
        setTIME
        infoStats
    echo -en "(${NUMS}/${LSMS}) Service restart..."
        serMYSQLRES
        serLOCATIONRES
        infoStats
    echo "Данные для локации:">>$SAVE
    echo "SQL_Логин: root">>$SAVE
    echo "SQL_Пароль: $MYSQLPASS">>$SAVE
    echo "SQL_FileTP: ftp">>$SAVE
    echo "SQL_Порт: 3306">>$SAVE
    echo "Пароль базы данных ftp: $FTPPASS">>$SAVE
    log_n "=============== Настройка локации успешно завершена ==============="
    Error_n "Все данные, можно посмотреть в файле: /root/enginegp.cfg"
    log_n "==================================================================="
	menu_finish
}
# Настройка локации на сервере с EngineGP
setting_location_enginegp() {
	clear
	log_t "Setting location/Detected OS Version: "$VER
    echo -en "(${NUMS}/${LSFE}) Setting server..."
        readMySQL
        varLOCATION
        infoStats
    echo -en "(${NUMS}/${LSFE}) Install Java..."
        installJAVA
        infoStats
    echo -en "(${NUMS}/${LSFE}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${LSFE}) Install packages..."
        packLOCATION1
        infoStats
    echo -en "(${NUMS}/${LSFE}) Adding i386..."
        addi386
        infoStats
    echo -en "(${NUMS}/${LSFE}) Update packages..."
        sysUPDATE
        infoStats
    echo -en "(${NUMS}/${LSFE}) Install packages..."
        packLOCATION2
        infoStats
    echo -en "(${NUMS}/${LSFE}) Setting rclocal..."
        setRCLOCAL
        infoStats
    echo -en "(${NUMS}/${LSFE}) Setting iptables..."
        setIPTABLES
        infoStats
    echo -en "(${NUMS}/${LSFE}) Install nginx..."
        installNGINX
        infoStats
    echo -en "(${NUMS}/${LSFE}) Install proftpd..."
        installPROFTPD
        infoStats
    echo -en "(${NUMS}/${LSFE}) Setting configuration..."
        setCONF
        infoStats
    echo -en "(${NUMS}/${LSFE}) Install SteamCMD..."
        installSTEAMCMD
        infoStats
    echo -en "(${NUMS}/${LSFE}) Service restart..."
        serMYSQLRES
        serLOCATIONRES
        infoStats
    echo "">>$SAVE
    echo "Данные для локации:">>$SAVE
    echo "SQL_Логин: root">>$SAVE
    echo "SQL_Пароль: $MYSQLPASS">>$SAVE
    echo "SQL_FileTP: ftp">>$SAVE
    echo "SQL_Порт: 3306">>$SAVE
    echo "Пароль базы данных ftp: $FTPPASS">>$SAVE
    log_n "=============== Настройка локации успешно завершена ==============="
    Error_n "Все данные, можно посмотреть в файле: /root/enginegp.cfg"
    log_n "==================================================================="
	menu_finish
}

# Меню установки игр
install_games() {
    clear
    log_t "Install games"
    upd
    clear
    log_t "Список доступных игр"
    Info "- 1 - Counter-Strike: 1.6"
    Info "- 2 - Counter-Strike: Source v34"
    Info "- 3 - Counter-Strike: Source"
    Info "- 4 - Counter-Strike: GO"
    Info "- 5 - GTA: San Andreas Multiplayer"
    Info "- 6 - GTA: Criminal Russia MP"
    Info "- 7 - GTA: Multi Theft Auto"
    Info "- 8 - Minecraft"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case
    
    case $case in
        1)
            install_csv16;;
        2)
            install_cssv34;;
        3)
            install_css;;
        4)
            install_csgo;;
        5)
            install_samp;;
        6)
            install_crmp;;
        7)
            install_mta;;
        8)
            install_mc;;
        0)
            menu;;
    esac
}
# Меню установки Counter-Strike: 1.6
install_csv16() {
    clear
    log_t "Install Counter-Strike: 1.6"
    upd
    clear
    log_t "Список доступных версий Counter-Strike: 1.6"
    Info "- 1 - Steam [ Чистый сервер ]"
    Info "- 2 - Build ReHLDS"
    Info "- 3 - Build 8308"
    Info "- 4 - Build 8196"
    Info "- 5 - Build 7882"
    Info "- 6 - Build 7559"
    Info "- 7 - Build 6153"
    Info "- 8 - Build 5787"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1)
            mkdir -p /path/cs/steam
            cd /path/cs/steam/
            wget $GAMES/cs/steam.zip
            unzip steam.zip
            rm steam.zip
            install_csv16
        ;;
        2)
            mkdir -p /path/cs/rehlds
            cd /path/cs/rehlds/
            wget $GAMES/cs/rehlds.zip
            unzip rehlds.zip
            rm rehlds.zip
            install_csv16
        ;;
        3)
            mkdir -p /path/cs/8308
            cd /path/cs/8308/
            wget $GAMES/cs/8308.zip
            unzip 8308.zip
            rm 8308.zip
            install_csv16
        ;;
        4)
            mkdir -p /path/cs/8196
            cd /path/cs/8196/
            wget $GAMES/cs/8196.zip
            unzip 8196.zip
            rm 8196.zip
            install_csv16
        ;;
        5)
            mkdir -p /path/cs/7882
            cd /path/cs/7882/
            wget $GAMES/cs/7882.zip
            unzip 7882.zip
            rm 7882.zip
            install_csv16
        ;;
        6)
            mkdir -p /path/cs/7559
            cd /path/cs/7559/
            wget $GAMES/cs/7559.zip
            unzip 7559.zip
            rm 7559.zip
            install_csv16
        ;;
        7)
            mkdir -p /path/cs/6153
            cd /path/cs/6153/
            wget $GAMES/cs/6153.zip
            unzip 6153.zip
            rm 6153.zip
            install_csv16
        ;;
        8)
            mkdir -p /path/cs/5787
            cd /path/cs/5787/
            wget $GAMES/cs/5787.zip
            unzip 5787.zip
            rm 5787.zip
            install_csv16
        ;;
        0)
            install_games;;
    esac
}

# Меню установки Counter-Strike: Source v34
install_cssv34() {
    clear
    log_t "Install Counter-Strike: Source v34"
    upd
    clear
    log_t "Список доступных версий Counter-Strike: Source v34"
    Info "- 1 - Steam [ Чистый сервер ]"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1)
            mkdir -p /path/cssold/steam
            cd /path/cssold/steam/
            wget $GAMES/cssold/steam.zip
            unzip steam.zip
            rm steam.zip
            install_cssv34
        ;;
        0)
            install_games;;
    esac
}
# Меню установки Counter-Strike: Source
install_css() {
    clear
    log_t "Install Counter-Strike: Source"
    upd
    clear
    log_t "Список доступных версий Counter-Strike: Source"
    Info "- 1 - Steam [ Чистый сервер ]"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1)
            mkdir -p /path/css/steam
            cd /path/css/steam/
            wget $GAMES/css/steam.zip
            unzip steam.zip
            rm steam.zip
            install_css
        ;;
        0)
            install_games;;
    esac
}
# Меню установки Counter-Strike: GO
install_csgo() {
    clear
    log_t "Install Counter-Strike: GO"
    upd
    clear
    log_t "Список доступных версий Counter-Strike: GO"
    Info "- 1 - Steam [ Чистый сервер ]"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1)
            mkdir -p /path/csgo/steam
            cd /path/cmd/
            ./steamcmd.sh +login anonymous +force_install_dir /path/csgo/steam +app_update 740 validate +quit
            install_csgo
        ;;
        0)
            install_games
        ;;
    esac
}
# Меню установки GTA: San Andreas Multiplayer
install_samp() {
    clear
    log_t "Install GTA: San Andreas Multiplayer"
    upd
    clear
    log_t "Список доступных версий San Andreas Multiplayer"
    Info "- 1 - 0.3DL-R1"
    Info "- 2 - 0.3.7-R2"
    Info "- 3 - 0.3z-R4"
    Info "- 4 - 0.3x-R2"
    Info "- 5 - 0.3e-R2"
    Info "- 6 - 0.3d-R2"
    Info "- 7 - 0.3c-R5"
    Info "- 8 - 0.3b-R2"
    Info "- 9 - 0.3a-R8"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1)
            mkdir -p /path/samp/03DLR1
            cd /path/samp/03DLR1/
            wget $GAMES/samp/03DL_R1.zip
            unzip 03DL_R1.zip
            rm 03DL_R1.zip
            install_samp
        ;;
        2)
            mkdir -p /path/samp/037R2
            cd /path/samp/037R2/
            wget $GAMES/samp/037_R2.zip
            unzip 037_R2.zip
            rm 037_R2.zip
            install_samp
        ;;
        3)
            mkdir -p /path/samp/03ZR4
            cd /path/samp/03ZR4/
            wget $GAMES/samp/03Z_R4.zip
            unzip 03Z_R4.zip
            rm 03Z_R4.zip
            install_samp
        ;;
        4)
            mkdir -p /path/samp/03XR2
            cd /path/samp/03XR2/
            wget $GAMES/samp/03X_R2.zip
            unzip 03X_R2.zip
            rm 03X_R2.zip
            install_samp
        ;;
        5)
            mkdir -p /path/samp/03ER2
            cd /path/samp/03ER2/
            wget $GAMES/samp/03E_R2.zip
            unzip 03E_R2.zip
            rm 03E_R2.zip
            install_samp
        ;;
        6)
            mkdir -p /path/samp/03DR2
            cd /path/samp/03DR2/
            wget $GAMES/samp/03D_R2.zip
            unzip 03D_R2.zip
            rm 03D_R2.zip
            install_samp
        ;;
        7)
            mkdir -p /path/samp/03CR5
            cd /path/samp/03CR5/
            wget $GAMES/samp/03C_R5.zip
            unzip 03C_R5.zip
            rm 03C_R5.zip
            install_samp
        ;;
        8)
            mkdir -p /path/samp/03BR2
            cd /path/samp/03BR2/
            wget $GAMES/samp/03B_R2.zip
            unzip 03B_R2.zip
            rm 03B_R2.zip
            install_samp
        ;;
        9)
            mkdir -p /path/samp/03AR8
            cd /path/samp/03AR8/
            wget $GAMES/samp/03A_R8.zip
            unzip 03A_R8.zip
            rm 03A_R8.zip
            install_samp
        ;;
        0)
            install_games;;
    esac
}
# Меню установки GTA: Criminal Russia MP
install_crmp() {
    clear
    log_t "Install GTA: Criminal Russia MP"
    upd
    clear
    log_t "Список доступных версий GTA: Criminal Russia MP"
    Info "- 1 - 0.3.7-C5"
    Info "- 2 - 0.3e-C3"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1)
            mkdir -p /path/crmp/037C5
            cd /path/crmp/037C5/
            wget $GAMES/crmp/037_C5.zip
            unzip 037_C5.zip
            rm 037_C5.zip
            install_crmp
        ;;
        2)
            mkdir -p /path/crmp/03EC3
            cd /path/crmp/03EC3/
            wget $GAMES/crmp/03E_C3.zip
            unzip 03E_C3.zip
            rm 03E_C3.zip
            install_crmp
        ;;
        0)
            install_games;;
    esac
}
# Меню установки GTA: Multi Theft Auto
install_mta() {
    clear
    log_t "Install GTA: Multi Theft Auto"
    upd
    clear
    log_t "Список доступных версий GTA: Multi Theft Auto"
    Info "- 1 - 1.5.5-R2"
    Info "- 2 - 1.5.4-R3"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1)
            mkdir -p /path/mta/155R2
            cd /path/mta/155R2/
            wget $GAMES/mta/155_R2.zip
            unzip 155_R2.zip
            rm 155_R2.zip
            install_mta
        ;;
        2)
            mkdir -p /path/mta/154R3
            cd /path/mta/154R3/
            wget $GAMES/mta/154_R3.zip
            unzip 154_R3.zip
            rm 154_R3.zip
            install_mta
        ;;
        0)
            install_games;;
    esac
}
# Меню установки Minecraft
install_mc() {
    clear
    log_t "Install Minecraft"
    upd
    clear
    log_t "Список доступных версий Minecraft"
    Info "- 1 - Craftbukkit-1.8.5-R 0.1"
    Info "- 2 - Craftbukkit-1.8-R 0.1"
    Info "- 3 - Craftbukkit-1.7.9-R 0.2"
    Info "- 4 - Craftbukkit-1.6.4-R 1.0"
    Info "- 5 - Craftbukkit-1.5.2-R 1.0"
    Info "- 6 - Craftbukkit-1.5-R 0.1"
    Info "- 7 - Craftbukkit-1.12-R 0.1"
    Info "- 8 - Craftbukkit-1.11.2-R 0.1"
    Info "- 9 - Craftbukkit-1.11-R 0.1"
    Info "- 10 - Craftbukkit-1.10.2-R 0.1"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1)
            mkdir -p /path/mc/CB185R01
            cd /path/mc/CB185R01/
            wget $GAMES/mc/craftbukkit-1.8.5-R0.1.zip
            unzip craftbukkit-1.8.5-R0.1.zip
            rm craftbukkit-1.8.5-R0.1.zip
            install_mc
        ;;
        2)
            mkdir -p /path/mc/CB18R01
            cd /path/mc/CB18R01/
            wget $GAMES/mc/craftbukkit-1.8-R0.1.zip
            unzip craftbukkit-1.8-R0.1.zip
            rm craftbukkit-1.8-R0.1.zip
            install_mc
        ;;
        3)
            mkdir -p /path/mc/CB179R02
            cd /path/mc/CB179R02/
            wget $GAMES/mc/craftbukkit-1.7.9-R0.2.zip
            unzip craftbukkit-1.7.9-R0.2.zip
            rm craftbukkit-1.7.9-R0.2.zip
            install_mc
        ;;
        4)
            mkdir -p /path/mc/CB164R10
            cd /path/mc/CB164R10/
            wget $GAMES/mc/craftbukkit-1.6.4-R1.0.zip
            unzip craftbukkit-1.6.4-R1.0.zip
            rm craftbukkit-1.6.4-R1.0.zip
            install_mc
        ;;
        5)
            mkdir -p /path/mc/CB152R10
            cd /path/mc/CB152R10/
            wget $GAMES/mc/craftbukkit-1.5.2-R1.0.zip
            unzip craftbukkit-1.5.2-R1.0.zip
            rm craftbukkit-1.5.2-R1.0.zip
            install_mc
        ;;
        6)
            mkdir -p /path/mc/CB15R01
            cd /path/mc/CB15R01/
            wget $GAMES/mc/craftbukkit-1.5-R0.1.zip
            unzip craftbukkit-1.5-R0.1.zip
            rm craftbukkit-1.5-R0.1.zip
            install_mc
        ;;
        7)
            mkdir -p /path/mc/CB112R01
            cd /path/mc/CB112R01/
            wget $GAMES/mc/craftbukkit-1.12-R0.1.zip
            unzip craftbukkit-1.12-R0.1.zip
            rm craftbukkit-1.12-R0.1.zip
            install_mc
        ;;
        8)
            mkdir -p /path/mc/CB1112R01
            cd /path/mc/CB1112R01/
            wget $GAMES/mc/craftbukkit-1.11.2-R0.1.zip
            unzip craftbukkit-1.11.2-R0.1.zip
            rm craftbukkit-1.11.2-R0.1.zip
            install_mc
        ;;
        9)
            mkdir -p /path/mc/CB111R01
            cd /path/mc/CB111R01/
            wget $GAMES/mc/craftbukkit-1.11-R0.1.zip
            unzip craftbukkit-1.11-R0.1.zip
            rm craftbukkit-1.11-R0.1.zip
            install_mc
        ;;
        10)
            mkdir -p /path/mc/CB1102R01
            cd /path/mc/CB1102R01/
            wget $GAMES/mc/craftbukkit-1.10.2-R0.1.zip
            unzip craftbukkit-1.10.2-R0.1.zip
            rm craftbukkit-1.10.2-R0.1.zip
            install_mc
        ;;
        0)
            install_games;;
    esac
}

# Определение статуса
infoStats() {
    if [ $? -eq 0 ]; then
        echo -en "\E[${NUML};39f \033[1;32m [УСПЕШНО] \033[0m\n"
        tput sgr0
    else
        echo -en "\E[${NUML};39f \033[1;31m [ОШИБКА] \033[0m\n"
        tput sgr0
    fi
    ((NUMS += 1))
    ((NUML += 1))
}
# Установка обязательных пакетов
necPACK() {
	if [ $type = "ubn" ]; then
		apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install git lsb-release apt-utils > /dev/null 2>&1
	elif [ $type = "rhl" ]; then
		yum -y install redhat-lsb-core yum-utils epel-release wget git
	fi
}
# Добавление репозиториев
addREPO() { 
	if [ $type = "ubn" ]; then
		echo "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) main restricted universe multiverse" >> /etc/apt/sources.list
        echo "deb-src http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc) main restricted universe multiverse" >> /etc/apt/sources.list
        echo "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse" >> /etc/apt/sources.list
        echo "deb-src http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse" >> /etc/apt/sources.list
        echo "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiversen" >> /etc/apt/sources.list
        echo "deb-src http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiverse" >> /etc/apt/sources.list
		echo "deb http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse" >> /etc/apt/sources.list
		echo "deb-src http://archive.ubuntu.com/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse" >> /etc/apt/sources.list
        echo "deb http://mirror.yandex.ru/ubuntu/ $(lsb_release -sc) main" >> /etc/apt/sources.list
        echo "deb-src http://mirror.yandex.ru/ubuntu/ $(lsb_release -sc) main" >> /etc/apt/sources.list
		echo "deb http://archive.canonical.com/ubuntu $(lsb_release -sc) partner" >> /etc/apt/sources.list
		echo "deb-src http://archive.canonical.com/ubuntu $(lsb_release -sc) partner" >> /etc/apt/sources.list
		echo "deb http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security main restricted" >> /etc/apt/sources.list
		echo "deb-src http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security main restricted" >> /etc/apt/sources.list
		echo "deb http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security universe" >> /etc/apt/sources.list
		echo "deb-src http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security universe" >> /etc/apt/sources.list
		#echo "deb http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security multiverse" >> /etc/apt/sources.list
		#echo "deb-src http://security.ubuntu.com/ubuntu $(lsb_release -sc)-security multiverse" >> /etc/apt/sources.list
	elif [ $type = "deb" ]; then
	#if [ $VER != "Debian11" ]; then
		echo "deb http://ftp.ru.debian.org/debian/ $(lsb_release -sc) main" > /etc/apt/sources.list
        echo "deb-src http://ftp.ru.debian.org/debian/ $(lsb_release -sc) main" >> /etc/apt/sources.list
        echo "deb http://security.debian.org/ $(lsb_release -sc)/updates main" >> /etc/apt/sources.list
        echo "deb-src http://security.debian.org/ $(lsb_release -sc)/updates main" >> /etc/apt/sources.list
        echo "deb http://ftp.ru.debian.org/debian/ $(lsb_release -sc)-updates main" >> /etc/apt/sources.list
        echo "deb-src http://ftp.ru.debian.org/debian/ $(lsb_release -sc)-updates main" >> /etc/apt/sources.list
	elif [ $type = "rhl" ]; then
		yum -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
		wget -y --force-yes https://download-ib01.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/p/pwgen-2.08-3.el8.x86_64.rpm
		rpm -Uvh pwgen-2.08-3.el8.x86_64.rpm
		wget https://download-ib01.fedoraproject.org/pub/epel/8/x86_64/Packages/q/qstat-2.11-13.20080912svn311.el7.x86_64.rpm ## ССЫЛКА СДОХЛА!
		rpm -Uvh qstat-2.11-13.20080912svn311.el7.x86_64.rpm ## ЭТО СООТВЕТСТВЕННО ТОЖЕ НЕ ВСТАНЕТ
    fi
    git clone $GITREQLINK > /dev/null 2>&1
}
# Получение списка пакетов с репозитория
sysUPDATE() {
	if [ $type = deb ] || [ $type = ubn ]; then
		apt -y --force-yes update $something > /dev/null 2>&1
	elif [ $type = "rhl" ]; then
		yum -y check-update
		yum -y update
	fi
}
# Обновление пакетов
sysUPGRADE() {
	if [ $type = deb ] || [ $type = ubn ]; then
		apt -y --force-yes upgrade $something > /dev/null 2>&1
	elif [ $type = "rhl" ]; then
		yum -y upgrade
	fi
}
# Добавление файла подкачки
swapADD() {
    if [ $SWP = 0 ]; then
        dd if=/dev/zero of=/swapfile bs=1024k count=1024 > /dev/null 2>&1
        chmod 600 /swapfile > /dev/null 2>&1
        mkswap /swapfile > /dev/null 2>&1
        swapon /swapfile > /dev/null 2>&1
    fi
}
# Популярные пакеты
popPACK() {
	if [ $type = deb ] || [ $type = ubn ]; then
		apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install pwgen dialog sudo bc lib32z1 screen htop nano tcpdump zip unzip mc lsof apt-transport-https ca-certificates safe-rm > /dev/null 2>&1
	elif [ $type = "rhl" ]; then
		yum -y install pwgen htop screen dialog sudo bc net-tools bash-completion curl vim nano tcpdump zip unzip mc lsof
	fi
}
# Пакеты для работы панели
packPANEL() {
	if [ $type = deb ] || [ $type = ubn ]; then
		apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install cron curl ssh nload gdb lsof qstat > /dev/null 2>&1
	elif [ $type = "rhl" ]; then
		yum -y install qstat crontabs openssh-clients openssh-server nload gdb
		yum -y install nginx
		yum install mariadb-server mariadb
	fi
}
# Популярные переменные
varPOP() {
    MYSQLPASS=$(pwgen -cns -1 12)
    SAVE='/root/enginegp.cfg'
}
# Создание переменных панели
varPANEL() {
    ENGINEGPPASS=$(pwgen -cns -1 12)
    ENGINEGPHASH=$(echo -n "$ENGINEGPPASS" | md5sum | cut -d " " -f1)
    CRONKEY=$(pwgen -cns -1 6)
    CRONPANEL="/etc/crontab"
    DIR="/var/enginegp"
    APACHEDIR='/etc/apache2/conf-available'
    APACHECFG=${APACHEDIR}'/enginegp.conf'
}
# Настройка MySQL
setMYSQL() {
	if [ $type = deb ] || [ $type = ubn ]; then
		wget $SQLLINK > /dev/null 2>&1
		export DEBIAN_FRONTEND=noninteractive > /dev/null 2>&1
		echo mysql-apt-config mysql-apt-config/select-server select mysql-5.7 | debconf-set-selections > /dev/null 2>&1
		echo mysql-apt-config mysql-apt-config/select-product select Ok | debconf-set-selections > /dev/null 2>&1
		apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install ./$SQLVER.deb > /dev/null 2>&1
		dpkg -i $SQLVER.deb > /dev/null 2>&1
		echo mysql-community-server mysql-community-server/root-pass password "$MYSQLPASS" | debconf-set-selections > /dev/null 2>&1
		echo mysql-community-server mysql-community-server/re-root-pass password "$MYSQLPASS" | debconf-set-selections > /dev/null 2>&1
		mkdir /resegp > /dev/null 2>&1
		echo "$MYSQLPASS" >> /resegp/conf.cfg
		rm $SQLVER.deb > /dev/null 2>&1
	elif [ $type = "rhl" ]; then
		yum install mariadb-server mariadb
	fi
}
# Добавление PHP
addPHP() {
	# Для Debian
	if [ $type = deb ] || [ deb = $type ]; then
		wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg > /dev/null 2>&1
		sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' > /dev/null 2>&1
	fi
}
# Установка PHP
installPHP() {
	if [ ubn = $type ] || [ ubn = $type ]; then
		if [ $PHPVER = "7.4" ] || [ "7.4" = $PHPVER ]; then
			PHPVER=""
		else
			apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install software-properties-common
			add-apt-repository ppa:ondrej/php
		fi
	fi
	apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install php$PHPVER > /dev/null 2>&1
}
# Установка пакетов PHP
installPHPPACK() {
    apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install php$PHPVER-cli php$PHPVER-common php$PHPVER-curl php$PHPVER-mbstring php$PHPVER-mysql php$PHPVER-xml php$PHPVER-memcache php$PHPVER-memcached memcached php$PHPVER-gd php$PHPVER-zip php$PHPVER-ssh2 > /dev/null 2>&1
    mv EngineGP-requirements/php/php /etc/php/$PHPVER/apache2/php.ini > /dev/null 2>&1
}
# Установка Apache
installAPACHE() {
    apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install apache2 > /dev/null 2>&1
}
# Настройка Apache
setAPACHE() {
    cd /etc/apache2/sites-available > /dev/null 2>&1

    sed -i "/Listen 80/d" * > /dev/null 2>&1
    cd ~ > /dev/null 2>&1
    echo "Listen 80">$APACHECFG
    echo "<VirtualHost *:80>">$APACHECFG
    echo " ServerName $IPADDR">>$APACHECFG
    echo " DocumentRoot $DIR">>$APACHECFG
    echo " <Directory $DIR/>">>$APACHECFG
    echo " AllowOverride All">>$APACHECFG
    echo " Require all granted">>$APACHECFG
    echo " </Directory>">>$APACHECFG
    echo " ErrorLog \${APACHE_LOG_DIR}/error.log">>$APACHECFG
    echo " LogLevel warn">>$APACHECFG
    echo " CustomLog \${APACHE_LOG_DIR}/access.log combined">>$APACHECFG
    echo "</VirtualHost>">>$APACHECFG
    sudo a2enconf enginegp.conf > /dev/null 2>&1
    
    mv EngineGP-requirements/apache2/security /etc/apache2/conf-available/security.conf > /dev/null 2>&1
    sudo systemctl reload apache2 > /dev/null 2>&1
}
# Перезагрузка сервисов
serPANELRES() {
    a2enmod rewrite > /dev/null 2>&1
    a2enmod php$PHPVER > /dev/null 2>&1
    service apache2 restart > /dev/null 2>&1
}
# Установка MySQL
installMYSQL() {
	if [ ubn = $type ] || [ ubn = $type ]; then
		apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install mysql-server > /dev/null 2>&1
	elif [ $type = "rhl" ]; then
		yum install mariadb-server mariadb -y
	fi
}
# Настройка phpMyAdmin
setPMA() {
    if [ $VER = "Debian9" ]; then
        echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections > /dev/null 2>&1
        echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | debconf-set-selections > /dev/null 2>&1
        echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQLPASS" | debconf-set-selections > /dev/null 2>&1
        echo "phpmyadmin phpmyadmin/mysql/app-pass password $MYSQLPASS" |debconf-set-selections > /dev/null 2>&1
        echo "phpmyadmin phpmyadmin/app-password-confirm password $MYSQLPASS" | debconf-set-selections > /dev/null 2>&1
        echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections > /dev/null 2>&1
        apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install phpmyadmin > /dev/null 2>&1
    else
        wget $PMALINK > /dev/null 2>&1
        tar xvf $PMAVER.tar.gz > /dev/null 2>&1
        rm $PMAVER.tar.gz > /dev/null 2>&1
        sudo mv $PMAVER/ /usr/share/phpmyadmin > /dev/null 2>&1
        sudo mkdir -p /var/lib/phpmyadmin/tmp > /dev/null 2>&1
        sudo mkdir -p /usr/share/phpmyadmin/tmp > /dev/null 2>&1
        sudo chown -R www-data:www-data /var/lib/phpmyadmin > /dev/null 2>&1
        sudo cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php > /dev/null 2>&1
        GENPASPMA=$(pwgen -cns -1 12)
        GENKEYPMA=$(pwgen -cns -1 32)
        KEYPMAOLD="\$cfg\\['blowfish_secret'\\] = '';"
        KEYPMANEW="\$cfg\\['blowfish_secret'\\] = '${GENKEYPMA}';"
        sed -i "s/${KEYPMAOLD}/${KEYPMANEW}/g" /usr/share/phpmyadmin/config.inc.php > /dev/null 2>&1
        sed -i "s/pmapass/${GENPASPMA}/g" /usr/share/phpmyadmin/config.inc.php > /dev/null 2>&1
        mysql -u root -p$MYSQLPASS < /usr/share/phpmyadmin/sql/create_tables.sql > /dev/null 2>&1 | grep -v "Using a password on the command"
        mysql -u root -p$MYSQLPASS -e "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY '$GENPASPMA';" > /dev/null 2>&1 | grep -v "Using a password on the command"
        mysql -u root -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON *.* TO 'pma'@'localhost' IDENTIFIED BY '$GENPASPMA' WITH GRANT OPTION;" > /dev/null 2>&1 | grep -v "Using a password on the command"
        mv EngineGP-requirements/phpmyadmin/phpmyadmin.conf $APACHEDIR > /dev/null 2>&1
        sudo a2enconf phpmyadmin.conf > /dev/null 2>&1
        sudo systemctl reload apache2 > /dev/null 2>&1
    fi
}
# Настройка CRON
setCRON() {
    sed -i "s/320/0/g" $CRONPANEL > /dev/null 2>&1
    echo "# Default Crontab by EngineGP" >> $CRONPANEL
    echo "*/2 * * * * root screen -dmS scan_servers bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers'" >> $CRONPANEL
    echo "*/5 * * * * root screen -dmS scan_servers_load bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_load'" >> $CRONPANEL
    echo "*/5 * * * * root screen -dmS scan_servers_route bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_route'" >> $CRONPANEL
    echo "* * * * * root screen -dmS scan_servers_down bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_down'" >> $CRONPANEL
    echo "*/10 * * * * root screen -dmS notice_help bash -c 'cd ${DIR} && php cron.php ${CRONKEY} notice_help'" >> $CRONPANEL
    echo "*/15 * * * * root screen -dmS scan_servers_stop bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_stop'" >> $CRONPANEL
    echo "*/15 * * * * root screen -dmS scan_servers_copy bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_copy'" >> $CRONPANEL
    echo "*/30 * * * * root screen -dmS notice_server_overdue bash -c 'cd ${DIR} && php cron.php ${CRONKEY} notice_server_overdue'" >> $CRONPANEL
    echo "*/30 * * * * root screen -dmS preparing_web_delete bash -c 'cd ${DIR} && php cron.php ${CRONKEY} preparing_web_delete'" >> $CRONPANEL
    echo "0 * * * * root screen -dmS scan_servers_admins bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads scan_servers_admins'" >> $CRONPANEL
    echo "* * * * * root screen -dmS control_delete bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_delete'" >> $CRONPANEL
    echo "* * * * * root screen -dmS control_install bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_install'" >> $CRONPANEL
    echo "*/2 * * * * root screen -dmS scan_control bash -c 'cd ${DIR} && php cron.php ${CRONKEY} scan_control'" >> $CRONPANEL
    echo "*/2 * * * * root screen -dmS control_scan_servers bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers'" >> $CRONPANEL
    echo "*/5 * * * * root screen -dmS control_scan_servers_route bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers_route'" >> $CRONPANEL
    echo "* * * * * root screen -dmS control_scan_servers_down bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers_down'" >> $CRONPANEL
    echo "0 * * * * root screen -dmS control_scan_servers_admins bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers_admins'" >> $CRONPANEL
    echo "*/15 * * * * root screen -dmS control_scan_servers_copy bash -c 'cd ${DIR} && php cron.php ${CRONKEY} control_threads control_scan_servers_copy'" >> $CRONPANEL
    echo "0 0 * * * root screen -dmS graph_servers_day bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads graph_servers_day'" >> $CRONPANEL
    echo "0 * * * * root screen -dmS graph_servers_hour bash -c 'cd ${DIR} && php cron.php ${CRONKEY} threads graph_servers_hour'" >> $CRONPANEL
    echo "# Default Crontab by EngineGP" >> $CRONPANEL
    sed -i '/^$/d' /etc/crontab > /dev/null 2>&1

    crontab -u root /etc/crontab > /dev/null 2>&1
}
# Перезагрузка CRON
serCRONRES() {
    service cron restart > /dev/null 2>&1
}
# Скачивание EngineGP
dwnPANEL() {
	cd > /dev/null 2>&1
    git clone $GITLINK > /dev/null 2>&1
}
# Установка EngineGP
installPANEL() {
    mkdir /var/lib/mysql/enginegp > /dev/null 2>&1
    chown -R mysql:mysql /var/lib/mysql/enginegp > /dev/null 2>&1
    sed -i "s/IPADDR/${IPADDR}/g" /root/EngineGP/enginegp.sql > /dev/null 2>&1
    sed -i "s/ENGINEGPHASH/${ENGINEGPHASH}/g" /root/EngineGP/enginegp.sql > /dev/null 2>&1
    sed -i "s/1517667554/${HOSTBIRTHDAY}/g" /root/EngineGP/enginegp.sql > /dev/null 2>&1
    sed -i "s/1577869200/${HOSTBIRTHDAY}/g" /root/EngineGP/enginegp.sql > /dev/null 2>&1
    mysql -uroot -p$MYSQLPASS enginegp < EngineGP/enginegp.sql > /dev/null 2>&1 | grep -v "Using a password on the command"
    rm EngineGP/enginegp.sql > /dev/null 2>&1
    rm -rf EngineGP/.git/ > /dev/null 2>&1
    mv EngineGP $DIR > /dev/null 2>&1
    sed -i "s/MYSQLPASS/${MYSQLPASS}/g" $DIR/system/data/mysql.php > /dev/null 2>&1
    sed -i "s/IPADDR/${IPADDR}/g" $DIR/system/data/config.php > /dev/null 2>&1
    sed -i "s/CRONKEY/${CRONKEY}/g" $DIR/system/data/config.php > /dev/null 2>&1
    chown -R www-data:www-data $DIR/ > /dev/null 2>&1
    chmod -R 775 $DIR/ > /dev/null 2>&1
}
# Настройка времени
setTIME() {
    timedatectl set-timezone Europe/Moscow > /dev/null 2>&1
}
# Настройка времени PHP
setTIMEPANEL() {
    setTIME
    sudo sed -i -r 's~^;date\.timezone =$~date.timezone = "Europe/Moscow"~' /etc/php/$PHPVER/cli/php.ini > /dev/null 2>&1
    sudo sed -i -r 's~^;date\.timezone =$~date.timezone = "Europe/Moscow"~' /etc/php/$PHPVER/apache2/php.ini > /dev/null 2>&1
}
# Перезагрузка MySQL
serMYSQLRES() {
	if [ ubn = $type ] || [ ubn = $type ]; then
		service mysql restart > /dev/null 2>&1
	elif [ $type = "rhl" ]; then
		systemctl start mariadb
		systemctl enable mariadb
	fi
}
# Создание переменных локации
varLOCATION() {
    FTPPASS=$(pwgen -cns -1 12)
}
# Установка Java
installJAVA() {
    tar xvfz EngineGP-requirements/java/jre-linux.tar.gz > /dev/null 2>&1
    mkdir /usr/lib/jvm > /dev/null 2>&1
    mv jre1.8.0_45 /usr/lib/jvm/jre1.8.0_45 > /dev/null 2>&1
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/jre1.8.0_45/bin/java 1 > /dev/null 2>&1
    update-alternatives --config java > /dev/null 2>&1
}
# Пакеты для работы локации №1
packLOCATION1() {
    apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install libbabeltrace1 libc6-dbg libdw1 lib32stdc++6 libreadline5 ssh qstat gdb-minimal lib32gcc1 ntpdate lsof safe-rm htop mc > /dev/null 2>&1
}
# Добавление i386
addi386() {
    dpkg --add-architecture i386
}
# Пакеты для работы локации №2
packLOCATION2() {
    apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install gcc-multilib > /dev/null 2>&1
}
# Настройка rclocal
setRCLOCAL() {
    sed -i '14d' /etc/rc.local > /dev/null 2>&1
    cat EngineGP-requirements/rclocal/rclocal >> /etc/rc.local > /dev/null 2>&1
}
# Настройка iptables
setIPTABLES() {
    touch /root/iptables_block > /dev/null 2>&1
    chmod 500 /root/iptables_block > /dev/null 2>&1
}
# Установка nginx
installNGINX() {
    apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install nginx > /dev/null 2>&1
    mv EngineGP-requirements/nginx/nginx /etc/nginx/nginx.conf > /dev/null 2>&1
    mkdir -p /var/nginx > /dev/null 2>&1
    systemctl restart nginx > /dev/null 2>&1
}
# Установка proftpd
installPROFTPD() {
    echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections
    apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install proftpd-basic > /dev/null 2>&1
    apt -y --force-yes --allow-unauthenticated --allow-downgrades --allow-remove-essential --allow-change-held-packages install proftpd-mod-mysql > /dev/null 2>&1
    service proftpd start > /dev/null 2>&1
    mv EngineGP-requirements/proftpd/proftpd /etc/proftpd/proftpd.conf > /dev/null 2>&1
    mv EngineGP-requirements/proftpd/proftpd_modules /etc/proftpd/modules.conf > /dev/null 2>&1
    mv EngineGP-requirements/proftpd/proftpd_sql /etc/proftpd/sql.conf > /dev/null 2>&1
    mysql -uroot -p$MYSQLPASS -e "CREATE DATABASE ftp;" > /dev/null 2>&1 | grep -v "Using a password on the command"
    mysql -uroot -p$MYSQLPASS -e "CREATE USER 'ftp'@'localhost' IDENTIFIED BY '$FTPPASS';" > /dev/null 2>&1 | grep -v "Using a password on the command"
    mysql -uroot -p$MYSQLPASS -e "GRANT ALL PRIVILEGES ON ftp . * TO 'ftp'@'localhost';" > /dev/null 2>&1 | grep -v "Using a password on the command"
    mysql -uroot -p$MYSQLPASS ftp < EngineGP-requirements/proftpd/sqldump.sql > /dev/null 2>&1 | grep -v "Using a password on the command"
    sed -i 's/passwdfor/'$MYSQLPASS'/g' /etc/proftpd/sql.conf > /dev/null 2>&1
    chmod -R 750 /etc/proftpd > /dev/null 2>&1
    service proftpd restart > /dev/null 2>&1
}
# Настройка конфигурации
setCONF() {
    echo "UseDNS no" >> /etc/ssh/sshd_config > /dev/null 2>&1
    echo "TCPKeepAlive yes" >> /etc/ssh/sshd_config > /dev/null 2>&1
    echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config > /dev/null 2>&1
    echo "ClientAliveCountMax 360" >> /etc/ssh/sshd_config > /dev/null 2>&1
    echo "UTC=no" >> /etc/default/rcS > /dev/null 2>&1
}
# Установка SteamCMD
installSTEAMCMD() {
    mkdir -p /path /path/cmd /path/maps /servers /copy > /dev/null 2>&1
    mkdir -p /path/cs /path/css /path/cssold /path/csgo /path/samp /path/crmp /path/mta /path/mc /path/update > /dev/null 2>&1
    mkdir -p /path/update/cs /path/update/css /path/update/cssold /path/update/csgo /path/update/mta /path/update/crmp /path/update/samp /path/update/mc > /dev/null 2>&1
    mkdir -p /path/maps/cs /path/maps/css /path/maps/cssold /path/maps/csgo > /dev/null 2>&1
    mkdir -p /servers/cs /servers/css /servers/cssold /servers/csgo /servers/mta /servers/samp /servers/crmp /servers/mc > /dev/null 2>&1
    chmod -R 711 /servers > /dev/null 2>&1
    chown root:servers /servers > /dev/null 2>&1
    chmod -R 755 /path > /dev/null 2>&1
    chown root:servers /path > /dev/null 2>&1
    chmod -R 750 /copy > /dev/null 2>&1
    chown root:root /copy > /dev/null 2>&1
    groupmod -g 998 `cat /etc/group | grep :1000 | awk -F":" '{print $1}'` > /dev/null 2>&1
    groupadd -g 1000 servers > /dev/null 2>&1
    cd /path/cmd/ > /dev/null 2>&1
    wget http://media.steampowered.com/client/steamcmd_linux.tar.gz > /dev/null 2>&1
    tar xvzf steamcmd_linux.tar.gz > /dev/null 2>&1
    rm steamcmd_linux.tar.gz > /dev/null 2>&1
}
# Перезагрузка сервисов
serLOCATIONRES() {
    systemctl restart nginx > /dev/null 2>&1
    service proftpd restart > /dev/null 2>&1
}
# Чтение пароля MySQL
readMySQL() {
    MYSQLPASS=`cat /resegp/conf.cfg | awk '{print $1}'`
    SAVE='/root/enginegp.cfg'
}

# Главное навигационное меню
menu() {
    clear
    log_t "Добро пожаловать в установочное меню EngineGP"
    Info "- 1 - Меню установки EngineGP"
    Info "- 2 - Меню настройки локации"
    Info "- 3 - Установить игры"
    Info "- 0 - Выход"
	Info ""
	Info " Версия установщика: $SHVER"
	Info " Последняя доступная версия: $LASTSHVER"
	Info ""
	Info " < Информация о системе >"
	Info " Операционная система: $VER"
	Info " IP-адрес: $IPADDR"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1) menu_install_enginegp;;   
        2) menu_setting_location;;   
        3) install_games;;
        0) exit;;
    esac
}
# Меню установки EngineGP
menu_install_enginegp() {
    clear
    log_t "Добро пожаловать в меню установки EngineGP"
    Info "- 1 - Установка EngineGP [Без настройки локации]"
    Info "- 2 - Установка EngineGP [С настройкой локации]"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1) install_enginegp;;
        2) install_enginegp_location;;
        0) menu;;
    esac
}
# Меню установки EngineGP
menu_setting_location() {
    clear
    log_t "Добро пожаловать в меню настройки локации"
    Info "- 1 - Настройка локации [На чистый сервер]"
    Info "- 2 - Настройка локации [На сервер с EngineGP]"
    Info "- 0 - Назад"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1) setting_location;;
        2) setting_location_enginegp;;
        0) menu;;
    esac
}
# Меню после настройки локации
menu_finish() {
    log_t "Хотите установить сборки для игр сейчас?"
    Info "- 1 - Да, перейти в меню установки игр"
    Info "- 2 - Нет, выйти из установки"
    Info "- 0 - Вернуться в главное меню"
    log_s
    Info
    read -p "Пожалуйста, введите пункт меню: " case

    case $case in
        1) install_games;;
        0) menu;;
    esac
}

connection_check() {
	if [ "empty$PHPVER" != "empty" ] || [ "empty" != "empty$PHPVER" ]; then
	  os_version_check
	 else
	  clear
	  echo " Ошибка соединения с сервером!"
	  tput sgr0
	fi
}

os_version_check() {
if [ $type = deb ] || [ $type = ubn ] || [ $type = rhl ]; then
  clear
  menu
 else
  echo " Данная ОС временно не поддерживается!"
  tput sgr0
fi
}

connection_check