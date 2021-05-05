param([string]$spnum)

cd "C:\inetpub\wwwroot\sp\repo_update\$spnum"
$timestamp="repo-$spnum $(Get-Date -Format "dd-MM-y HH-mm-ss")"
$logdir=(dir -name $(New-Item -Path "..\logs" -ItemType file -name $timestamp))
$logdir="..\logs\$logdir"

#--------------------------------------------------------------------
#Event logger 
function logev($logstr)
{
    $timestamp = (Get-Date -format hh:mm:ss-tt) + "|"
    $timestamp + " " + $logstr |Out-File -FilePath "$logdir" -Append -Force
}

#--------------------------------------------------------------------

logev "Begin:"

#--------------------------------------------------------------------
#Locate files

logev "Locating iso files..."

if ($core=$(dir -name *core*.iso))
{
    logev "Located file: $core"
}
else
{
    logev "No core iso found"
    logev "Locating manually extracted files..."

    if ((dir -name *Ycore*) -and (dir -name *Wcore*) -and (dir -name Packages) -and (dir -name Packages.gz))
    {
        logev "Located Package lists"
        if (((dir -name .\Wcore*) -replace 'Wcore.') -eq ((dir -name .\Ycore*) -replace 'Ycore.'))
        {
            $deb=$(dir -name .\Wcore*) -replace 'Wcore.'
            logev "Located debians: $(dir -name "*$deb")"
        }
        else
        {
            logev "Located debians: $(dir -name *Ycore*), $(dir -name *Wcore*)"
            logev "Detected debians with different revision number / name"
            logev "Aborting task - no changes were made"
            exit
        }
    }
    else
    {
        logev "One or more files are missing"
        logev "Aborting task - no changes were made"
        exit
    }
}

if ($SP-G=$(dir -name *SP-G*.iso))
{
    logev "Located file: $SP-G"
}
else
{
    logev "No SP-G iso found"
    logev "Locating manually extracted squash file..."

    if ($squash=$(dir -name *squash*))
    {
        logev "Located squash file"
    }
    else
    {
        logev "squash file is missing, aborting task"
        logev "Aborting task - no changes were made"
        exit
    }
}

#--------------------------------------------------------------------
#Mount and extract iso files

if ($core)
{
    $img=Mount-DiskImage "$(pwd)\$core" -PassThru
    
    if ($img=Get-Volume -DiskImage $img |Select-Object -ExpandProperty DriveLetter)
    {
        logev "Mounted core iso to virtual drive $img`:"
    }
    else
    {
        logev "An error occurred while mounting core iso file - aborting task"
        exit
    }
    
    cp "$img`:\pool\extras\Wcore*" .\
    cp "$img`:\pool\extras\Ycore*" .\
    cp "$img`:\dists\xenial\extras\binary-amd64\Pack*" .\
   
    Dismount-DiskImage "$(pwd)\$core"

    if ((dir -name "*.deb", Pack* |Measure-Object).Count -eq 4)
    {
        logev "Extracted files from core iso"
        $deb=$(dir -name .\Wcore*) -replace 'Wcore.'
    }
    else
    {
        logev "Some files faild to extract - aborting task"
        exit
    }
}

if ($SP-G)
{
    $img=Mount-DiskImage "$(pwd)\$SP-G" -PassThru

    if ($img=Get-Volume -DiskImage $img |Select-Object -ExpandProperty DriveLetter)
    {
        logev "Mounted SP-G iso to virtual drive $img`:"
    }
    else
    {
        logev "An error occurred while mounting SP-G iso file - aborting task"
        exit
    }

    cp "$img`:\casper\filesystem.squashfs" .\
   
    Dismount-DiskImage "$(pwd)\$SP-G"

    if ($squash=$(dir -name "filesystem.squashfs"))
    {
        logev "Extracted squash from SP-G iso"
    }
    else
    {
        logev "Squash file faild to extract - aborting task"
        exit
    }
}

#--------------------------------------------------------------------
#Update Release file

logev "Creating Release file"
cp "..\Release" .\

logev "Calculating hash sums..."
((Get-Content .\Release) -replace "0d2cf8f2a2204056e7cf7b4c905986eb", $(certutil -hashfile .\Packages md5)[1]) -join "`n" |Set-Content .\Release -Encoding UTF8 -NoNewline
((Get-Content .\Release) -replace "476b083ea1fb855c48141366de8913dd", $(certutil -hashfile .\Packages.gz md5)[1]) -join "`n" |Set-Content .\Release -Encoding UTF8 -NoNewline
((Get-Content .\Release) -replace "0ec6a85304c39205223cab7bd6cf428ae76310e5", $(certutil -hashfile .\Packages sha1)[1]) -join "`n" |Set-Content .\Release -Encoding UTF8 -NoNewline
((Get-Content .\Release) -replace "0f367368e5bdfb32cdd082e95ab19c34fd605598", $(certutil -hashfile .\Packages.gz sha1)[1]) -join "`n" |Set-Content .\Release -Encoding UTF8 -NoNewline
((Get-Content .\Release) -replace "ef2523d70101b0f2fccb42ca08bde62b82960c252d8ee16707dfce5432eaca9e", $(certutil -hashfile .\Packages sha256)[1]) -join "`n" |Set-Content .\Release -Encoding UTF8 -NoNewline
((Get-Content .\Release) -replace "1a3b02354c0ba26469a52fc30890162f870caba0b8bdf8211e904c24f5892e9a", $(certutil -hashfile .\Packages.gz sha256)[1]) -join "`n" |Set-Content .\Release -Encoding UTF8 -NoNewline

logev "Calculating file lengths..."
((Get-Content .\Release) -replace "174192", $(dir .\Packages |Select-Object -ExpandProperty length)) -join "`n" |Set-Content .\Release -Encoding UTF8 -NoNewline
((Get-Content .\Release) -replace "60803", $(dir .\Packages.gz |Select-Object -ExpandProperty length)) -join "`n" |Set-Content .\Release -Encoding UTF8 -NoNewline

#--------------------------------------------------------------------
#Update Repositories

logev "Removing old repository files"
rm "..\..\Ycore\$spnum\pool\extras\Ycore*" -Force
rm "..\..\Ycore\$spnum\dists\xenial\universe\binary-amd64\Pack*" -Force
rm "..\..\Ycore\$spnum\dists\xenial\Release" -Force
rm "..\..\Wcore\$spnum\pool\extras\Wcore*" -Force
rm "..\..\Wcore\$spnum\dists\xenial\universe\binary-amd64\Pack*" -Force
rm "..\..\Wcore\$spnum\dists\xenial\Release" -Force
rm "..\..\Purple\$spnum\casper\filesystem.squashfs" -Force

logev "Copying new repository files"
cp ".\Ycore.$deb" "..\..\Ycore\$spnum\pool\extras" -Force
cp ".\Pack*" "..\..\Ycore\$spnum\dists\xenial\universe\binary-amd64" -Force
cp ".\Release" "..\..\Ycore\$spnum\dists\xenial" -Force
cp ".\Wcore.$deb" "..\..\Wcore\$spnum\pool\extras" -Force
cp ".\Pack*" "..\..\Wcore\$spnum\dists\xenial\universe\binary-amd64" -Force
cp ".\Release" "..\..\Wcore\$spnum\dists\xenial" -Force
cp ".\filesystem.squashfs" "..\..\Purple\$spnum\casper" -Force

logev "Cleaning up..."
rm .\* -Force

logev "Done!"

exit