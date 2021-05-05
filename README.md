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

