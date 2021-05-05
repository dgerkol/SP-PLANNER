#!/bin/bash
#
#
######################################################################################################
# SP-UPDATER init script.                                                                            #
# Used for mounting AP's sda, environment self tests, local logging and nfs mounting.                #
# To be used when booting via SP-PLANNER.                                                            #
#                                                                                                    #
#                                       -- SP TEAM  --                                            #
#                                                                                                    #
######################################################################################################
#
#
#
#
#=====================================================================================================
#set service parameters

### BEGIN INIT INFO
# Provides: SP-Updater
# Required-Start: $network $syslog
# Required-Stop: $network $syslog
# X-Start-Before: 
# X-Stop-After: 
# Default-Start: 2 3 4 5
# Default-Stop: 0 6
# Short-Description: This service starts and stops the SP-PLANNER flow up to the nfs mounting point.
### END INIT INFO

#=====================================================================================================
#Preconfiguration

#set session call timestamp
spcall=$(date +%d.%m.%y' '%T |sed s/:/./g)

#set initial session log format
log="updater_log $spcall"

#set work directory
workdir="/home/ubuntu/Desktop"

#set log directory
logdir="$workdir/$log"

#set vlan segments
bseg=xxx
rseg=xxx
pseg=xxx
wds="x.x.x.x"

#set remote share directory
nfsdir=spu

#set remote directory
netscript="nfs/ /main"

#set nfs log dir
netlogs=logs

#set primary NIC (to sp-net)
ip link show enp0s31f6 |grep "state UP"  && pnic=enp0s31f6 || { ip link show enp6s0 |grep "state UP"  && pnic=enp6s0 || pnic=enp5s0; }

#set self-test flags
wrn=0
err=0

#=====================================================================================================
#A collection of words we might need

#log main event
logmev() {
		printf "$(date +%d.%m.%y' '%T'| ') $1\n"  >> "$logdir"
	 }

#log sub event
logev() {
		printf "%20s$1\n"  >> "$logdir"
	}

#copy current session logstage to nfs and sp
copylog() {
                logmev "[INFO]: Updating logs on mounted filesystems"
                logev "Updating log in nfs share"; cp "$logdir" nfs/logs || { logev "Error while copying log to nfs share"; ((wrn++)); }
                logev "Updating log in sp"; cp "$logdir" sp/home || { logev "Error while copying log to sp"; ((wrn++)); }
          }

#save log and exit
spexit() {
                if ! (( $err )); then
                    logmev "[INFO]: Finished job successfully, entering safe termination procedure"
                    cd $workdir && logev "Returned to desktop workdir"
                    logev "[INFO]: Last log to nfs: copying log and unmounting filesystem"; cp "$logdir" "nfs/$netlogs" || { logev "[WARNING]: Error while copying log to nfs share"; ((wrn++)); }
                    umount nfs || { logev "[WARNING]: Error while safely unmounting nfs share; filesystem will forcibly unmount while rebooting"; ((wrn++)); }
                    logev "Copying log to sp; preparing to safely unmount and reboot"
                    cp "$logdir" sp/home && printf "%20sSuccess, writing directly to file on sp\n" >> "sp/home/$log" || ((wrn++))
                    (( $wrn )) && printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Task ended with $wrn warnings\n" >> "sp/home/$log" || printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Task ended successfully\n" >> "sp/home/$log"
                    printf "%20s[INFO]: Last log to sp: unmounting filesystem and rebooting SBC\n" >> "sp/home/$log"
                    umount sp || { printf "$(date +%d.%m.%y' '%T'| ') [ERROR]: IF YOU SEE THIS MESSAGE IT MEANS WE FUCKED UP WHILE SAFELY UNMOUNTING THE FILESYSTEM !\n" >> "sp/home/$log"; printf "%20s[WARNING]: Filesystem will forcibly unmounted during reboot, consider checking the sp for unexpected errors\n" >> "sp/home/$log"; }
                    reboot -f
                else
                    case $err in
                                '1')
                                    cd $workdir
                                    ls nfs || { mkdir nfs && mount -t nfs "$wds:/$nfsdir" nfs && logev "Successfully mounted nfs share" || { logev "Unable to mount nfs share"; }; }
                                    logmev "Updating log in nfs share"; cp "$logdir" "nfs/$netlogs" || { logev "Error while copying log to nfs share"; }
                                    printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Writing directly to nfs log\n" >> "nfs/$netlogs/$log"
                                    printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Last log to nfs: rebooting system\n" >> "nfs/$netlogs/$log"
                                    reboot -f
                                    ;;
                                    
                                '2')
                                    logmev "Updating log in sp"; cp "$logdir" sp/home || { logev "Error while copying log to nfs share"; }
                                    printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Writing directly to sp log\n" >> "sp/home/$log"
                                    printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Last log to sp: rebooting system\n" >> "sp/home/$log"
                                    umount sp
                                    reboot -f
                                    ;;
                                    
                                '3')
                                    logmev "OMG like wtf are you doing?? Unable to mount sp and nfs."
                                    logev "I'm leaving this system open so you can read some logs and get your shit together!"
                                    exit 3
                                    ;;
                                    
                                '4')
                                    cd $workdir
                                    mkdir sp && mount /dev/sda1 sp && logev "Successfully mounted sp partition" || { logmev "FFS can't even mount sp partition"; logev "What are you?? -An idiot sandwich."; logev "Leaving this system open so you can read some logs"; }
                                    exit 4
                                    ;;
                                    
                                '5')
                                    copylog
                                    printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Writing directly to nfs log\n" >> "nfs/$netlogs/$log"
                                    printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Writing directly to sp log\n" >> "sp/home/$log"
                                    printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Last log to nfs: unmounting share\n" >> "nfs/$netlogs/$log"
                                    umount nfs && printf "$(date +%d.%m.%y' '%T'| ') Successfully unmounted nfs share\n" >> "sp/home/$log" || printf "$(date +%d.%m.%y' '%T'| ') [WARNING]: Error while safely unmounting nfs share; filesystem will forcibly unmount while rebooting\n" >> "nfs/$netlogs/$log"
                                    printf "$(date +%d.%m.%y' '%T'| ') [INFO]: Last log to sp: unmounting filesystem and rebooting SBC\n" >> "sp/home/$log"
                                    umount sp || { printf "$(date +%d.%m.%y' '%T'| ') [ERROR]: IF YOU SEE THIS MESSAGE IT MEANS WE FUCKED UP WHILE SAFELY UNMOUNTING THE FILESYSTEM !\n" >> "sp/home/$log"; printf "%20s[WARNING]: Filesystem will forcibly unmounted during reboot, consider checking the sp for unexpected errors\n" >> "sp/home/$log"; }
                                    reboot -f
                                    ;;
                                    
                                '10')
                                    copylog
                                    exit 10
                                    ;;
                                
                                *)
                                    logmev "[ERROR]: An unexpected error has occurred; leaving system open"
                                    logev "You must have a bad habit of fucking things up, don't you?"
                                    exit 8
                                    ;;
                    esac
                    
                fi
        }

#error check
chkerr() {
				[[ $err = 1 ]] && logmev "Terminating job due to sp-related error (exit code 1)\n" && spexit
                [[ $err = 2 ]] && logmev "Terminating job due to nfs-related error (exit code 2)\n" && spexit
                [[ $err = 3 ]] && logmev "Terminating job due to environment-related error (exit code 3)\n" && spexit
                [[ $err = 4 ]] && logmev "Terminating job due to connection error (exit code 4)\n" && spexit
                [[ $err = 5 ]] && logmev "Terminating job due to missing / inaccessible critical files (exit code 5)\n" && spexit
                [[ $err = 10 ]] && logmev "Remote script ended successfully with exit code 10: entering debug mode"
                [[ $err = 15 ]] && logmev "Remote script ended successfully, but reported task-related errors (exit code 15)"
                [[ $err = 20 ]] && logmev "Failed to configure one or more critical packages - terminating job (exit code 20)\n" && spexit
	 }

#=====================================================================================================
#Base environment configuration 

logmev "[INFO]: Initial session call: $spcall" 
logmev "[INFO]: sp-Updater init script: Begin:\n"

logmev "Setting up the environment:"
cd /home
#the following packages are already installed
#dpkg --install net-tools* && logev "Installed net-tools" || err=20

#dpkg --install libt* && logev "Installed libtirpc" || err=20

#dpkg --install key* && logev "Installed keyutils" || err=20

#dpkg --install libn* && logev "Installed libnfsidmap" || err=20

#dpkg --install rpc* && logev "Installed rpcbind" || err=20

#dpkg --install nfs* && logev "Installed nfs-common" || err=20

chkerr
logmev "Done\n"

#=====================================================================================================
#Basic environment diagnostics

logmev "Performing environment diagnostics:"

lip=$(ifconfig $pnic |grep "inet " |sed s/".*inet\ "// |sed -r s/" .*"// ) && logev "IPv4 address: $lip"
ping -c 5 -I $pnic $wds && logev "sp-PLANNER is alive!" || { logev "[ERROR]: No connection to SP-PLANNER"; err=4; }

spnum=$(echo $lip |cut -d . -f 4 |sed s/0//) && logev "Detected sp number: $spnum" || { logev "[ERROR:] Unable to detect sp number"; err=1; }
case $(echo $lip |cut -d . -f 2) in
                                    $wseg)
                                        spcpu=wseg && logev "Detected sp cpu type: $spcpu"
                                        ;;
                                        
                                    $yseg)
                                        spcpu=yseg && logev "Detected sp cpu type: $spcpu"
                                        ;;
                                    
                                    $gseg)
                                        spcpu=gseg && logev "Detected sp cpu type: $spcpu"
                                        ;;
                                        
                                    *)
                                        spcpu=undefined && logev "[WARNING]: Unable to detect sp cpu type"; err=1
                                        ;;
esac

chkerr
logmev "Diagnostics complete\n"

#=====================================================================================================
#Begin mounting procedure

logmev "Begin mounting stage:"

cd $workdir && logev "[INFO]: Changed workdir to desktop"
logmev "[INFO]: Changed log's name according to standard" 
mv "$log" "$spcpu.$spnum $spcall" && logev "Name changed to $spcpu.$spnum $spcall" && log="$spcpu.$spnum $spcall" && logdir="$workdir/$log" || { logev "[WARNING]: Unable to change log's name"; ((wrn++)); }

mkdir sp && mount /dev/sda1 sp && logev "Successfully mounted sp partition" || { logev "Unable to mount sp partition"; ((err+=1)); }
mkdir nfs && mount -t nfs "$wds:/$nfsdir" nfs && logev "Successfully mounted nfs share" || { logev "Unable to mount nfs share"; ((err+=2)); }

chkerr
copylog

(( $wrn )) && logmev "Task ended with $wrn warnings\n" && wrn=0 || logmev "Task ended successfully\n"

#=====================================================================================================
#Begin remote script handling

logmev "Running remote script... "

netscript=$(echo $netscript |sed "s| |$spcpu/$spnum|")
$netscript "$logdir" || chkerr

(( $wrn )) && logmev "Task ended with $wrn warnings\n" && wrn=0 || logmev "Task ended successfully\n"
spexit

exit 0
