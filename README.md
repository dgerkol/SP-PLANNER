# SP-PLANNER

A PXE automated system for installation of Linux &amp; Windows OS, based on modified binaries of Windows Server's WDS role &amp; Syslinux, with private package repositories for offline networks. 

## Requirements:

To fully realize and execute this automated environment, some requirements and role installments must be met prior to integration of this project.
This repository documentation will only list the basic requirements and will not cover any implementations steps of server roles, as they may vary from one organization policy and environment to another.

1. OS:
   - Windows Server 2012 and above.
   - PowerShell version 5.1 and above.

2. Architecture:
   - DHCP server role or external DHCP services with NetBoot / PXE DHCP options enabled.
   - DNS server role or external DHCP services.
   - WDS server role enabled.
   - Web services for package repositories (for OS installations that fully rely on a web-repository):
     - IIS server role enabled (or any other web-apphost such as apache) with an HTTP site **OR** FTP site.
   - NFS server role for hosting NFS storage shares that'll hold *squashfs* files (for OS installations that use a *"live install"* methods with *squashfs* files).


## Project Installation:

This repository is an example of a real working architecture and automation concept. 
It is merely a file skeleton to serve as a POC of a workaround implementation issue of WDS based PXE for Linux installations and automations.

Although you may clone this repository straight to your WDS default working directories (such as '\remoteinstall\boot\x64'), it is **highly recommended not to do so**, as we modified our core WDS 'COM' & 'c32' files, and combined Syslinux files as well.

Also: pay attention that any scripts, menu files, preseed files and overall any directories, network locations, kernel & ramdisks should be adjusted according to any newly integrated environment according to our required architecture, Linux OS installation distribution and OS technical documentation.

**Lastly:** keep in mind that although is a working solution adjusted to installations Linux using the *Debian-Installer* and the *Live-Installer*, it is perfectly suited for RHL-based OS and even standard Windows OS installations.
- Some basic documentation resource links (such as WS roles, Debian install procedure, syslinux utilsand etc..) to be added soon.


## General Workflow:

SP-PLANNER provides two work methods:
1. **Manuall PXE menu selection** and boot order as configured in the [pxeLinux.cfg default](https://github.com/dgerkol/SP-PLANNER/blob/main/wds_pxe/pxeLinux.cfg/default) file:
   - When Syslinux menu loads to user's screen they are able to manually select any menu entry they would like, including a standard Hard Drive boot or exit the PXE procedure and move on to the next boot order as configured in their BIOS/UEFI.
   - If no selection is made (or generally no keyboard input recived within 10 seconds), a default option is configured to be selected: "Boot from local HD".

2. **Automated PXE menu selection:**
   - When using an automated selection for a Syslinux menu for a specific machine, that machine must be provided with a specific Syslinux menu that is intended only to it, and will not affect any other machines using out PXE service.
     - Defining a specific menu for a specific machine is done by creating a menu file with target machine NIC MAC address as the name of the file.
   - Users integrate their systems to call the [confpxe.ps1](https://github.com/dgerkol/SP-PLANNER/tree/main/automationsconfpxe.ps1) script using SSH or any other method, stating an aplliance id, and a desired util to be ran.
     - In our project, every automation is ran seperatly and one time only, thus creating a one time specific menu file for a target machine and is removed after a fixed amount of time (optional).
     - For this purpose we provide an [appliance MAC list](https://github.com/dgerkol/SP-PLANNER/blob/main/wds_pxe/pxeLinux.cfg/autoinstall/mac%20list) the script reads from, and creates a file based on list's entries.
   - Our project offers three automation utils:
     - **System installation**: when no util flag is sent to our script, is simply directs the target machine to download an installation kernel & initrd files, and begin a system installation form a pre-defind repository for that machine.
     - **System LIVE-BOOT** of a custom made *squashfs* file - this is very useful if you would like to include OpenSSH-Server in your live system and study its resources with an external OS or perform automations on a remote filesystem with or without OS installed on it.
     - **SP-UPDATER**: A custom made live system with a set of scripts defined as services that run on system init, mount a network storage, and run a set of network stored scripts, while logging every step executed by it.

### Automated PXE menu selection workflow:

![SP-PLANNER](https://github.com/dgerkol/SP-PLANNER/blob/main/design/SP-PLANNER.png)

### Automated SP-UPDATER util:

![SP-UPDATER](https://github.com/dgerkol/SP-PLANNER/blob/main/design/SP-UPDATER.png)

