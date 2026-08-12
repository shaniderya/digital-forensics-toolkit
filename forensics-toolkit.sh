#!/bin/bash

HOME=$(pwd)
USER=$(whoami)
RED="\e[31m"
BLUE="\e[94m"
GREEN="\e[92m"
STOP="\e[0m"


printf "${GREEN}=================================\n"
printf "${BLUE}"
figlet -w 200 -f slant "MY FORENSICS TOOLKIT"
printf "${BLUE}"
printf "${GREEN}=================================\n${STOP}"

echo -e "\e[3mMake sure required tools are installed before running analysis.\e[0m\n"


function ZIP_RESULTS() {
    if [ ! -d "$HOME/My_Forensics/$NAME" ]; then
        echo "Error: Analysis directory does not exist. Ensure previous functions ran successfully."
        return 1
    fi

    ZIP_FILE="$HOME/My_Forensics/$NAME/results.zip"
    echo "Creating a zip file for extracted results..."
    zip -r "$ZIP_FILE" . > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "✅ Successfully created zip archive: $ZIP_FILE"
    else
        echo "❌ Error: Failed to create zip archive."
    fi
}


function CREATE_SUMMARY() {
    ELAPSED_TIME=$1
    if [ ! -d "$HOME/My_Forensics/$NAME" ]; then
        echo "Error: Analysis directory does not exist."
        return 1
    fi

    cd "$HOME/My_Forensics/$NAME" || exit 1
    touch SUMMARY.txt
    {
        echo "🕒 Time of Analysis: $(date)"
        echo "⏱️ Elapsed Time: $ELAPSED_TIME seconds"
        echo "📂 Files extracted by binwalk: $(ls binwalk 2>/dev/null | wc -l)"
        echo "📂 Files extracted by foremost: $(ls foremost 2>/dev/null | wc -l)"
        echo "📂 Files extracted by bulk_extractor: $(ls bulk 2>/dev/null | wc -l)"
        echo "🔑 Keywords extracted by strings: $(wc -l < strings.txt 2>/dev/null)"
    } | tee -a SUMMARY.txt
    echo "Summary saved in SUMMARY.txt"
}


SEARCH_FOR_PCAP()
{
	ls -l $HOME/My_Forensics/$NAME/bulk | grep packets > /dev/null 2>&1
	if [ "$?" == 0 ]
	then 
		SIZE=$(ls -l $HOME/My_Forensics/$NAME/bulk | grep packets | awk '{print $5}')
		echo -e "PCAP file was found! \nlocation:$HOME/My_Forensics/$NAME/bulk \nSize:$SIZE "
	else
		echo "Couldn't extract PCAP file :("
	fi

}



function HDD_ANALYSIS() {
    echo "💾 Running disk image analysis..."
    mkdir -p "$HOME/My_Forensics/$NAME/binwalk" "$HOME/My_Forensics/$NAME/foremost" "$HOME/My_Forensics/$NAME/bulk"

    echo "➡️ Running binwalk..."
    binwalk -e "$file" -C "$HOME/My_Forensics/$NAME/binwalk" > /dev/null 2>&1

    echo "➡️ Running foremost..."
    foremost -i "$file" -o "$HOME/My_Forensics/$NAME/foremost" > /dev/null 2>&1

    echo "➡️ Running bulk_extractor..."
    bulk_extractor "$file" -o "$HOME/My_Forensics/$NAME/bulk" > /dev/null 2>&1
	SEARCH_FOR_PCAP
	
    echo "➡️ Running strings to extract potential sensitive data..."
    strings "$file" | grep -iE "username|password|token|auth|key" > "$HOME/My_Forensics/$NAME/strings.txt" 2>/dev/null

    echo "💽 HDD analysis completed!"
}


function RAM_ANALYSIS() {
  
    PROFILE=$($HOME/vol -f "$file" imageinfo | grep "Suggested Profile" | awk -F',' '{print $1}' | awk -F':' '{print $2}' | sed 's/ //g')
    if [ -z "$PROFILE" ]; then
        echo "❌ Error: Unable to detect memory profile."
        return 1
    fi

    echo "🔍 Detected Memory Profile: $PROFILE"
    OUTPUT_DIR="$HOME/My_Forensics/$NAME"
    mkdir -p "$OUTPUT_DIR"

    PLUGINS=("pstree" "connscan" "hivelist" "printkey")

    for plugin in "${PLUGINS[@]}"; do
        echo "➡️ Running Volatility plugin: $plugin"
        $HOME/vol -f "$file" --profile="$PROFILE" $plugin > "$OUTPUT_DIR/$plugin.txt" 2>> "$OUTPUT_DIR/errors.log"

        if [ $? -ne 0 ]; then
            echo "❌ Plugin $plugin failed. Check errors.log."
        else
            echo "✅ Plugin $plugin completed successfully."
        fi
    done
    echo " RAM analysis completed!"
}


function INSTALL_TOOLS() {
    echo "🔧 Checking and installing missing tools..."
    apt-get update -y > /dev/null 2>&1

    tools=("binwalk" "foremost" "bulk-extractor" "strings")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            echo "📥 Installing $tool..."
            apt-get install "$tool" -y > /dev/null 2>&1
            echo "✅ $tool installed."
        else
            echo "✅ $tool is already installed."
        fi
    done
    echo "🔧 All tools are ready!"
}


function START_ANALYSIS() {
    echo "📂 Enter the full path to your memory file:"
    read -r file

    if [ -s "$file" ]; then
        NAME=$(basename "$file")
        mkdir -p "$HOME/My_Forensics/$NAME"
        INSTALL_TOOLS

        echo " Choose analysis type: HDD, RAM, or ALL"
        read -r analysis_type

        START_TIME=$(date +%s)

        case $analysis_type in
        HDD)
            HDD_ANALYSIS
            ;;
        RAM)
            RAM_ANALYSIS
            ;;
        ALL)
            HDD_ANALYSIS
            RAM_ANALYSIS
            ;;
        *)
            echo "❌ Invalid choice. Please try again."
            START_ANALYSIS
            ;;
        esac

        END_TIME=$(date +%s)
        ELAPSED_TIME=$((END_TIME - START_TIME))

        CREATE_SUMMARY "$ELAPSED_TIME"
        ZIP_RESULTS
    else
        echo "❌ File not found or invalid path. Please try again."
        START_ANALYSIS
    fi
}

if [ "$USER" == "root" ]; then
    echo "👋 Welcome, root user!"
    START_ANALYSIS
else
    echo "❌ Please run this script as root."
    exit 1
fi
