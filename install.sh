#!/bin/bash

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to detect OS and version
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
        ARCH=$(uname -m)
    else
        echo "Unsupported OS"
        exit 1
    fi
}

# Function to fetch the latest Zabbix agent version
get_latest_version() {
    latest_version=$(curl -s https://repo.zabbix.com/zabbix/ | grep -oP 'href="([0-9]+\.[0-9]+)/"' | grep -oP '[0-9]+\.[0-9]+' | sort -V | tail -n 1)
    if [ -z "$latest_version" ]; then
        echo "Unable to determine the latest Zabbix agent version"
        exit 1
    fi
    echo "$latest_version"
}

# Function to disable Zabbix packages in EPEL repository
disable_zabbix_epel() {
    if [ -f /etc/yum.repos.d/epel.repo ]; then
        if ! grep -q "^excludepkgs=zabbix\*" /etc/yum.repos.d/epel.repo; then
            echo -e "\nexcludepkgs=zabbix*" >> /etc/yum.repos.d/epel.repo
        fi
    fi
}

# Function to install Zabbix agent on Debian-based systems
install_zabbix_agent_debian() {
    local server_address=$1
    local agent_version=$2

    case $OS in
        ubuntu)
            if [ "$ARCH" == "aarch64" ]; then
                wget https://repo.zabbix.com/zabbix/${agent_version}/ubuntu-arm64/pool/main/z/zabbix-release/zabbix-release_${agent_version}+ubuntu${VER}_all.deb -P /tmp/
            else
                wget https://repo.zabbix.com/zabbix/${agent_version}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${agent_version}+ubuntu${VER}_all.deb -P /tmp/
            fi
            ;;
        debian)
            if [ "$ARCH" == "aarch64" ]; then
                wget https://repo.zabbix.com/zabbix/${agent_version}/debian-arm64/pool/main/z/zabbix-release/zabbix-release_${agent_version}+debian${VER}_all.deb -P /tmp/
            else
                wget https://repo.zabbix.com/zabbix/${agent_version}/debian/pool/main/z/zabbix-release/zabbix-release_${agent_version}+debian${VER}_all.deb -P /tmp/
            fi
            ;;
        raspbian)
            wget https://repo.zabbix.com/zabbix/${agent_version}/raspbian/pool/main/z/zabbix-release/zabbix-release_${agent_version}+debian${VER}_all.deb -P /tmp/
            ;;
    esac
    dpkg -i /tmp/zabbix-release_${agent_version}+${OS}${VER}_all.deb
    apt update
    apt install -y zabbix-agent2
}

# Function to install Zabbix agent on Red Hat-based systems
install_zabbix_agent_redhat() {
    local server_address=$1
    local agent_version=$2

    disable_zabbix_epel
    case $OS in
        almalinux)
            rpm -Uvh https://repo.zabbix.com/zabbix/${agent_version}/alma/9/x86_64/zabbix-release-${agent_version}-4.el9.noarch.rpm
            ;;
        centos)
            rpm -Uvh https://repo.zabbix.com/zabbix/${agent_version}/centos/9/x86_64/zabbix-release-${agent_version}-4.el9.noarch.rpm
            ;;
        ol)
            rpm -Uvh https://repo.zabbix.com/zabbix/${agent_version}/oracle/9/x86_64/zabbix-release-${agent_version}-4.el9.noarch.rpm
            ;;
        rhel)
            rpm -Uvh https://repo.zabbix.com/zabbix/${agent_version}/rhel/9/x86_64/zabbix-release-${agent_version}-4.el9.noarch.rpm
            ;;
        rocky)
            rpm -Uvh https://repo.zabbix.com/zabbix/${agent_version}/rocky/9/x86_64/zabbix-release-${agent_version}-4.el9.noarch.rpm
            ;;
    esac
    yum clean all
    yum install -y zabbix-agent2
}

# Function to install Zabbix agent on SUSE-based systems
install_zabbix_agent_suse() {
    local server_address=$1
    local agent_version=$2

    rpm -Uvh --nosignature https://repo.zabbix.com/zabbix/${agent_version}/sles/15/x86_64/zabbix-release-${agent_version}-2.sles15.noarch.rpm
    zypper --gpg-auto-import-keys refresh 'Zabbix Official Repository'
    zypper refresh
    zypper install -y zabbix-agent2
}

# Function to configure Zabbix agent
configure_zabbix_agent() {
    local server_address=$1
    local hostname=$2

    config_file="/etc/zabbix/zabbix_agent2.d/zabbix_agent2.conf"
    if [ -z "$hostname" ]; then
        echo "Hostname=" > "$config_file"
        echo "HostnameItem=system.hostname" >> "$config_file"
    else
        echo "Hostname=$hostname" > "$config_file"
    fi
    echo "Server=$server_address" >> "$config_file"
    echo "ServerActive=$server_address" >> "$config_file"

    # Restart Zabbix agent service
    systemctl restart zabbix-agent2
}

# Main installation function
install_zabbix_agent() {
    local server_address=$1
    local agent_version=$2
    local hostname=$3

    if [ -z "$server_address" ]; then
        echo "Usage: $0 <Zabbix Server Address> [Zabbix Agent Version] [Hostname]"
        exit 1
    fi

    if [ -z "$agent_version" ]; then
        agent_version=$(get_latest_version)
    fi

    case $OS in
        ubuntu|debian|raspbian)
            install_zabbix_agent_debian "$server_address" "$agent_version"
            ;;
        rhel|centos|rocky|almalinux|ol)
            install_zabbix_agent_redhat "$server_address" "$agent_version"
            ;;
        opensuse-leap|sles)
            install_zabbix_agent_suse "$server_address" "$agent_version"
            ;;
        *)
            echo "Unsupported OS"
            exit 1
            ;;
    esac

    configure_zabbix_agent "$server_address" "$hostname"
}

# Script execution starts here
check_root
detect_os
install_zabbix_agent "$1" "$2" "$3"
