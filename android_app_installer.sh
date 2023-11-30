#!/bin/bash
# Android Application Installation Tool via ADB Wireless
# Created by Leonardo Fonseca
# License: MIT License (Open Source)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the script directory
DIR=$(dirname "$(readlink -f "$0")")

# URL for downloading ADB
ADB_ZIP_URL="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"
ADB_ZIP_FILE="$DIR/platform-tools-latest-darwin.zip"
ADB_DIR="$DIR/platform-tools"

# Function to display terms and conditions
display_terms_and_conditions() {
    clear
    echo -e "${CYAN}Terms and Conditions of Use${NC}"
    echo "-------------------------"
    echo "This script uses Android Debug Bridge (ADB) to install applications."
    echo "For more information on enabling debug mode on your device, visit:"
    echo "https://developer.android.com/studio/command-line/adb?hl=en"
    echo -e "\nDISCLAIMER: This software is provided 'as is', without any kind of warranty. Use is at the user's own risk."
    echo "The creator of this script is not responsible for any damages resulting from the use of this software."
    echo -e "\nPress Enter to accept the terms and conditions and continue or any other key to exit."
    read -s -n 1 acceptance
    if [ "$acceptance" != "" ]; then
        echo -e "${RED}You have chosen to exit. Terms and conditions were not accepted.${NC}"
        exit 4
    fi
}

# Function to count APKs in the directory
count_apks() {
    find "$1" -maxdepth 1 -name "*.apk" | wc -l
}

# Check if there are APKs in the apk folder
APK_DIR="$DIR/apk"
if [ $(count_apks "$APK_DIR") -eq 0 ]; then
    echo -e "${RED}No APK found in the 'apk' folder.${NC}"
    exit 5
fi

# Function to check and download ADB
download_adb() {
    if [ ! -f "$ADB_DIR/adb" ]; then
        echo -e "${YELLOW}ADB not found. Would you like to download ADB now? (y/n):${NC}"
        read -r resp
        if [[ $resp == "y" ]]; then
            echo "Downloading ADB for macOS..."
            curl -L -o "$ADB_ZIP_FILE" "$ADB_ZIP_URL" --progress-bar && {
                unzip -q "$ADB_ZIP_FILE" -d "$DIR" && {
                    chmod +x "$ADB_DIR/adb"
                    echo -e "${GREEN}ADB successfully downloaded and configured.${NC}"
                } || {
                    echo -e "${RED}Failed to unzip ADB.${NC}"
                    exit 2
                }
            } || {
                echo -e "${RED}Error downloading ADB.${NC}"
                exit 1
            }
        fi
    fi
}

# Function to connect to the device
connect_device() {
    local device_ip
    local device_name

    # Check if the last connection file exists
    if [ -f "$DIR/last_connection.txt" ]; then
        read -r device_ip device_name < "$DIR/last_connection.txt"
        echo "Last connection was with the device '$device_name' with IP $device_ip."
        echo -e "${YELLOW}Do you want to use the data from the last connection? (y/n):${NC}"
        read resp
        if [[ $resp != "y" ]]; then
            echo -e "${YELLOW}Enter the device IP:${NC}"
            read device_ip
            device_name=""  # Reset the device name, as it will be obtained again
        fi
    else
        echo "No previous connection found."
        echo -e "${YELLOW}Enter the device IP:${NC}"
        read device_ip
    fi

    if ! "$ADB_DIR/adb" connect "$device_ip"; then
        echo -e "${RED}Failed to connect to the device. Check the connection and the IP entered.${NC}"
        exit 3
    fi

    # Check if the connection was successful before proceeding
    if ! "$ADB_DIR/adb" -s "$device_ip" shell echo "successful connection" &> /dev/null; then
        echo -e "${RED}Failed to establish a stable connection with the device.${NC}"
        exit 4
    fi

    if [ -z "$device_name" ]; then
        device_name=$("$ADB_DIR/adb" -s "$device_ip" shell getprop ro.product.model)
    fi
    echo "$device_ip $device_name" > "$DIR/last_connection.txt"
    echo -e "${GREEN}Successfully connected to the device '$device_name' with IP $device_ip.${NC}"
}

# Function to list APKs found
list_found_apks() {
    if [ $(count_apks "$APK_DIR") -gt 0 ]; then
        echo -e "${CYAN}Applications found for installation:${NC}"
        for apk in "$APK_DIR"/*.apk; do
            echo "$(basename "$apk")"
        done
    fi
}

# Function to list and install APKs
list_and_install_apks() {
    INSTALLED_DIR="$APK_DIR/installed"
    [ ! -d "$INSTALLED_DIR" ] && mkdir -p "$INSTALLED_DIR"

    list_found_apks

    for apk in "$APK_DIR"/*.apk; do
        apk_name="$(basename "$apk")"
        echo -e "${YELLOW}Do you want to install $apk_name on the device? (y/n):${NC}"
        read -r resp
        if [[ $resp == "y" ]]; then
            "$ADB_DIR/adb" -s "$device_ip" install -r "$apk" && {
                mv "$apk" "$INSTALLED_DIR"
                echo -e "${GREEN}$apk_name successfully installed.${NC}"
            } || {
                echo -e "${RED}Failed to install $apk_name.${NC}"
            }
        fi
    done

    echo -e "${CYAN}Installation summary:${NC}"
    for apk in "$INSTALLED_DIR"/*.apk; do
        apk_name="$(basename "$apk")"
        echo "$apk_name: Installed"
    done
    if [ $(count_apks "$INSTALLED_DIR") -eq 0 ]; then
        echo "No APK was installed."
    fi
}

disconnect_device() {
    local device_ip="$1"

    if [ -z "$device_ip" ]; then
        echo "Disconnecting all devices..."
        "$ADB_DIR/adb" disconnect
    else
        echo "Disconnecting the device with IP $device_ip..."
        "$ADB_DIR/adb" disconnect "$device_ip"
    fi
}

# Start of the script
display_terms_and_conditions
download_adb
connect_device
list_and_install_apks
disconnect_device
