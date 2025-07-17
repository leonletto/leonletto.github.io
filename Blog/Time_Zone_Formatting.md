---
layout: default
title: Time Zone Formatting
---
# Time Zone Formatting

_Note: Moved from my old blog site_

I work with a lot of log files and trying to remember the date in UTC ( or others ) and convert in your 
head gets tiresome when you have logs from different systems that you are trying to correlate. 

Lets say you are working in the console and want to quickly know what the date is in some other 
timezone, these are the commands to do that on Linux, MacOS and Windows Powershell

**Query the list of Timezones**

_Note: Using London England here_

**On Linux ( for London)**

    timedatectl list-timezones | grep London

**On MacOS**

    sudo systemsetup -listtimezones | grep London

**On Windows Powershell**

    (Get-TimeZone -Name "*GMT*").Id 

**To use the above to show the current date and time in the place you queried from in your terminal**

**Current time in London and give me the date in 24hour format**

**On Linux**

    TZ=$(timedatectl list-timezones | grep London) date +"%a %b %d %Y %T"

**Same with 12 hour time format**

    TZ=$(timedatectl list-timezones | grep London) date +"%a %b %d %Y %I:%M:%S") 

**On MacOS**

_Note: you have to know the Zone ( can’t query easily in the terminal without sudo - see above)_

    echo $(TZ="Europe/London" date +"%a %b %d %Y  %T")

**On Powershell you have to know the Zone ( `_“Get-TimeZone -ListAvailable” to see the list_` )**

    [datetime]::UtcNow, (Get-TimeZone -Name "*GMT*").Id 

**To create an Alias in your current terminal ( not persistent)!**

_( I am using “gt” as Great Britain Timezone here )_

**Current time in London - 24 hour time**

    alias gt='echo $(TZ=$(timedatectl list-timezones | grep London) date +"%a %b %d %Y  %T")'

**Same with 12 hour time format**

    alias gt='echo $(TZ=$(timedatectl list-timezones | grep London) date +"%a %b %d %Y %I:%M:%S")’

**On MacOS**

    alias gt='echo $(TZ="Europe/London" date +"%a %b %d %Y  %T")'

**On Powershell its Two Lines**

    Function WD {Write-Host ([datetime]::UtcNow, (Get-TimeZone -Name "*GMT*").Id)}Set-Alias gt WD

**Finally - If you want to make this persistent on your OS by putting an Alias in your profile**

_Note: I am using ~/.zshrc here but you can also use ~/.profile or ~/.bash\_profile depending on where your current settings are stored._

**_Notice all the_ “\\” _backslashes so that you can echo “’s and $’s_**

**For Linux**

    echo "alias gt='echo \$(TZ=\$(timedatectl list-timezones | grep London) date +\"%a %b %d %Y  %T\")'" >> ~/.zshrc

**For MacOS**

    echo "alias gt='echo \$(TZ=\”Europe/London\” date +\"%a %b %d %Y  %T\")'" >> ~/.zshrc

**For Powershell:**

_For your Persistent Profile in Powershell its quite complicated:_

**You need to decide whether only your username will use the profile**

*   If only your user:
    
    *   whether you want it while just running a Powershell terminal ($myProfile)
        
    *   or also when you are in the ISE editor ($myISEProfile)
        

_Note: the default I have shown below is for both…_

**If you want all users to use the profile:**

*   Then decide:
    
    *   whether you want it while just running a Powershell terminal ($globalProfile64)
        
    *   or also when you are in the ISE editor as well ($globalISEProfile64)
        
*   And finally whether you want the 32-bit Powershell profile available:
    
    *   in Powershell32 ($globalProfile32)
        
    *   in ISE editor on Powershell32 ($globalISEProfile32)
        

**I have tried to make it easy enough to set for your user by default.**

**You just copy and paste the following and run it.**

_Note: You need to modify $profiles if you want to set it globally (bottom of the script)_

    #You need this folder anywaymd $HOME\Documents\WindowsPowershell -ErrorAction SilentlyContinue#If you want to execute in powershell windows for you only$myProfile="$HOME\Documents\WindowsPowershell\Microsoft.PowerShell_profile.ps1"#If you want to execute in powershell ISE windows for you only$myISEProfile="$HOME\Documents\WindowsPowershell\Microsoft.PowerShellISE_profile.ps1"#If you want to execute in powershell 64-bit windows for All Users$globalProfile64="C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1"#If you want to execute in powershell ISE 64-bit windows for All Users$globalISEProfile64="C:\Windows\System32\WindowsPowerShell\v1.0\Microsoft.PowerShellISE_profile.ps1"# This is weird but but the 32-bit profile is in the syswow64 folder#If you want to execute in powershell 32-bit windows for All Users$globalProfile32="C:\Windows\SysWow64\WindowsPowerShell\v1.0\Microsoft.PowerShell_profile.ps1"#If you want to execute in powershell ISE 64-bit windows for All Users$globalISEProfile32="C:\Windows\SysWow64\WindowsPowerShell\v1.0\Microsoft.PowerShellISE_profile.ps1"#Change the $profiles here to whatever you want to set from above$profiles=@($myProfile,$myISEProfile)$profiles | ForEach-Object -Process {Add-Content -Path $_ -Value 'Function WD {Write-Host ([datetime]::UtcNow, (Get-TimeZone -Name "*GMT*").Id)}'Add-Content -Path $_ -Value 'Set-Alias gt WD'} 

I hope this helps you out. Drop me a line or comment if there are mistakes obviously.

Leon