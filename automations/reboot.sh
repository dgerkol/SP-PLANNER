#!/bin/bash

target_sp=$1
cert_path=$2

{ ssh -i $cert_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$target_sp "reboot" 2>/dev/null; ssh administrator@pxe -t ".\Desktop\autogp.ps1" 2>/dev/null; }