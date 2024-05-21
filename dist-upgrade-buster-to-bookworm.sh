#!/bin/bash

# Dist-Upgrade Debian 10 Buster to Debian 12 Bookworm

#...............Declaring the colors............
BW='\033[1;37m' # Bold white color code ${BW}
RED='\033[0;31m'
GREEN='\033[0;32m' #${GREEN}
LBLUE='\033[1;34m' #${LBLUE}
NC='\033[0m' # No Color ${NC}
#...............................................

#Declaring current OS version
debian_version=$(lsb_release -cs)

#
restart_pending=0

display_menu() {
    clear
    echo -e "${BW}====================================${NC}"
    echo -e "${BW}============| Main Menu |===========${NC}"
    echo -e "${BW}====================================${NC}"
    echo -e "${LBLUE} 1.${BW} Upgrade to Debian 11 (bullseye)${NC}"
    echo -e "${LBLUE} 2.${BW} Upgrade to Debian 12 (bookworm)${NC}"
    echo -e "${LBLUE} 3.${BW} Fix libcrypt1 (optional)${NC}"
    echo -e "${BW}====================================${NC}"
    echo -e "${LBLUE} 4.${RED} Restart system.${NC}"
    echo -e "${BW}====================================${NC}"
    echo -e "${LBLUE} 0. Exit${NC}"
    echo -e "${BW}====================================${NC}"
}

config_fixes() {
    
        # Fixing the typo in modprobe.d/cis.conf
        if grep -q '^nstall' /etc/modprobe.d/cis.conf; then
            sed -i '/^nstall/s/^nstall/install/' /etc/modprobe.d/cis.conf
            echo ""
            echo -e "${BW}Fixed 'nstall' at the start of a line in /etc/modprobe.d/cis.conf${NC}"
        fi


        # Fixing deprecated PAM configurations in common-auth
        if grep -q 'tally2' /etc/pam.d/common-auth; then
            sed -i 's/.*tally2.*/# Deleted pam_tally module settings as it is deprecated/g' /etc/pam.d/common-auth
            echo ""
            echo -e "${BW}Fixed deprecated PAM config in /etc/pam.d/common-auth${NC}"
        fi

        # Fixing deprecated PAM configurations in common-account
        if grep -q 'tally2' /etc/pam.d/common-account; then
            sed -i 's/.*tally2.*/# Deleted pam_tally module settings as it is deprecated/g' /etc/pam.d/common-account
            echo ""
            echo -e "${BW}Fixed deprecated PAM config in /etc/pam.d/common-account${NC}"
        fi
}

update_to_11() {

    echo ""
    echo -e "${BW}Looking for faulty configs.{NC}"
    config_fixes
    
    while [ "$restart_pending" -eq 1 ]; do
        echo ""
        echo -e "${BW}Restart is pending after an upgrade, please reboot before doing another upgrade!${NC}"
        read
        echo ""
        display_menu
    done

    if [ "$debian_version" != "buster" ]; then
        echo -e "Current Debian version is ${RED}$debian_version${NC}, not ${GREEN}buster${NC} (Debian 10). Please use the correct updater."
        read
        display_menu
    else

        echo "Upgrading the OS to the latest current version."
        echo ""
        apt-get -y update
        apt-get -y upgrade

        echo "Starting the distribution upgrade from buster to bullseye"
        echo ""
        cp /etc/apt/sources.list /etc/apt/sources.list.buster

        sed -i 's/buster/bullseye/g' /etc/apt/sources.list

            if grep -q "This list was created by our custom upgrade script at" /etc/apt/sources.list; then
                    sudo sed -i "1s/#This list was created by our custom upgrade script at.*/#This list was created by our custom upgrade script at $(date)/" /etc/apt/sources.list
                else
                    sudo sed -i '1i\#This list was created by our custom upgrade script at '"$(date)"'' /etc/apt/sources.list
            fi


        # cat > /etc/apt/sources.list <<"EOF"
        # deb http://security.debian.org/debian-security stable-security/updates main
        # deb-src http://security.debian.org/debian-security stable-security/updates main
        # EOF
            echo ""
            echo "sources.list was updated to bullseye."
            echo ""
            apt-get clean
            apt-get -y update
            echo ""
            echo "Repolist was updated, starting upgrade."
            echo ""
            apt-get -y upgrade
            apt-get -y full-upgrade
            echo ""
            echo -e "${RED}Upgrade is done, please restart for changes to take effect.${NC}"
            echo ""
            touch /forcefsck
            restart_pending=1
    fi
}

update_to_12() {

    echo ""
    echo -e "${BW}Looking for faulty configs.{NC}"
    config_fixes

    while [ "$restart_pending" -eq 1 ]; do
        echo ""
        echo -e "${BW}Restart is pending after an upgrade, please reboot before doing another upgrade!${NC}"
        read
        echo ""
        display_menu
    done

    if [ "$debian_version" != "bullseye" ]; then
        echo -e "Current Debian version is ${RED}$debian_version${NC}, not ${GREEN}bullseye${NC} (Debian 11). Please use the ${BW}bullseye${NC} version of the updater."
        read
        display_menu
    else

        echo "Upgrading the OS to the latest current version."
        echo ""
        apt -y update
        apt -y upgrade

        echo "Starting the distribution upgrade from buster to bullseye"
        echo ""

        cp /etc/apt/sources.list /etc/apt/sources.list.bullseye

            if grep -q "This list was created by our custom upgrade script at" /etc/apt/sources.list; then
                    sudo sed -i "1s/#This list was created by our custom upgrade script at.*/#This list was created by our custom upgrade script at $(date)/" /etc/apt/sources.list
                else
                    sudo sed -i '1i\#This list was created by our custom upgrade script at '"$(date)"'' /etc/apt/sources.list
            fi

        sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list

        # cat > /etc/apt/sources.list <<"EOF"
        # deb http://security.debian.org/debian-security stable-security/updates main
        # deb-src http://security.debian.org/debian-security stable-security/updates main
        # EOF

        #apt-key adv --keyserver keyserver.ubuntu.com --recv-keys BDE6D2B9216EC7A8
        echo ""
        echo "sources.list was updated to bookworm."
        echo ""
        apt clean
        apt -y update
        echo ""
        echo "Repolist was updated, starting upgrade"
        echo ""
        apt -y upgrade
        apt -y full-upgrade
        echo ""
        echo -e "${RED}Upgrade is done, please restart for changes to take effect.${NC}"
        echo ""
        touch /forcefsck
        restart_pending=1
    fi
}

libcrypt_fix(){

    while [ "$debian_version" != "bookworm" ]; do
        echo ""
        echo -e "${BW}This fix is only needed for Debian 12!${NC}"
        read
        echo ""
        display_menu
    done

    # issue with libcrypt.so.1
    cd /tmp
    apt -y download libcrypt1
    dpkg-deb -x libcrypt1_1%3a4.4.25-2_amd64.deb .
    cp -av lib/x86_64-linux-gnu/* /lib/x86_64-linux-gnu/
    apt -y --fix-broken install
    
    apt-get -y upgrade
    apt-get -y full-upgrade
    
    apt-get -y auto-remove
}

reboot_system(){
            
        clear

        echo -e -n "Are you sure you want to ${RED}reboot the system${NC} now? (yes/no): " && read answer

        if [[ $answer == "yes" ]]; then
            reboot
        elif [[ $answer == "no" ]]; then
            clear
            display_menu
        else
            echo "Invalid response. Please answer 'yes' or 'no'."
        fi
}

while true; do
    display_menu
    read -rp "Enter your choice: " choice
    case $choice in
        1) clear; update_to_11 ;;
        2) clear; update_to_12 ;;
        3) clear; libcrypt_fix ;;
        4) clear; reboot_system ;;
        0) echo "Exiting..."; break ;;
        *) echo "Invalid choice. Please enter a number between 0 and 4." ;;
    esac
    if [[ $choice != 0 ]]; then
        read -rp "Press Enter to return to the menu."
    fi
done