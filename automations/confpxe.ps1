param([string]$spcpu, [string]$spnum, [string]$util)


cd "C:\RemoteInstall\Boot\x64\pxeLinux.cfg"

$menu_name="01-$((Get-Content '.\autoinstall\mac list' |Select-String -Pattern "$spcpu $spnum") -replace "$spcpu $spnum ")"
New-Item -ItemType File -name "$menu_name"

switch ($util)
{ 
    i {break}
    l {$spcpu='live'; $spnum='live'}
    u {$spcpu='updater'; $spnum='updater'}
}
    
Copy-Item -Path ".\autoinstall\$spcpu\SP$spnum\default" -Destination ".\$menu_name"

Start-Sleep 60

Remove-Item -Path ".\$menu_name"

exit

