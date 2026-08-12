# Digital Forensics Toolkit

A Bash-based digital forensics toolkit designed to automate HDD and RAM analysis in Linux environments.

## Overview

This project provides an automated workflow for analyzing disk images and memory dumps using several common digital forensics tools.

The script can perform HDD analysis, RAM analysis, or both, and automatically organizes the extracted results into a dedicated analysis directory.

## Features

### HDD Analysis

* File extraction using **Binwalk**
* File carving using **Foremost**
* Data extraction using **Bulk Extractor**
* PCAP detection in extracted results
* Sensitive keyword extraction using **Strings**
* Searches for keywords such as:

  * username
  * password
  * token
  * auth
  * key

### RAM Analysis

* Automatic Volatility profile detection
* Process tree analysis using `pstree`
* Network connection analysis using `connscan`
* Registry hive analysis using `hivelist`
* Registry key analysis using `printkey`

## Tools Used

* Bash
* Binwalk
* Foremost
* Bulk Extractor
* Strings
* Volatility
* Zip
* Figlet

## Requirements

The script is designed to run on a Linux-based system.

Root privileges are required.

The script automatically checks for and installs several required tools.

Volatility is expected to be available as:

```bash
$HOME/vol
```

## Usage

Make the script executable:

```bash
chmod +x forensics-toolkit.sh
```

Run the script as root:

```bash
sudo ./forensics-toolkit.sh
```

Enter the full path to the disk image or memory dump when prompted.

Then choose the analysis mode:

```text
HDD
RAM
ALL
```

## Output

Analysis results are stored inside:

```text
My_Forensics/<image-name>/
```

Depending on the selected analysis type, the directory may contain:

```text
binwalk/
foremost/
bulk/
strings.txt
pstree.txt
connscan.txt
hivelist.txt
printkey.txt
errors.log
SUMMARY.txt
results.zip
```

## Summary Report

After the analysis is completed, the toolkit automatically generates a summary containing information such as:

* Analysis date and time
* Total analysis duration
* Number of extracted files
* Number of extracted strings
* Analysis output information

The results are also compressed into a ZIP archive.

## Purpose

This project was created as part of my cybersecurity studies to practice digital forensics automation, disk analysis, memory analysis, evidence extraction, and Linux Bash scripting.

## Disclaimer

This project is intended for educational purposes and authorized cybersecurity and digital forensics environments only.

Only analyze systems, disk images, memory dumps, or data that you own or have explicit permission to examine.

## Author

**Derya Shani**
