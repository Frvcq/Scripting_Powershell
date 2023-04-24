#Get-Command -name *net* 
#Get-command -name *ad*

if (!(Test-Path -Path $PROFILE)){

New-Item -Type File -Path $PROFILE -Force

}