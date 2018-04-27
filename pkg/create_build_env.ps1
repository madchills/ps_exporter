#If path to see if the directory exists. If not it is created. 
if(!(test-path C:\ProgramData\PSE\)){
    New-Item C:\ProgramData\PSE\ -ItemType Directory
}
#Download nssm zip from URL
Invoke-WebRequest -uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "C:\ProgramData\PSE\nssm.zip"
#Extracts the zip file
Expand-Archive -LiteralPath C:\ProgramData\PSE\nssm.Zip -DestinationPath C:\ProgramData\PSE\ 
#sleep 5 seconds to give the extraction time to finish
sleep -seconds 5
#If statement to check for system architecture
if ((Get-WmiObject -Class Win32_OperatingSystem -ea 0).OSArchitecture -eq '64-bit') {            
    $architecture = "64-Bit"            
} 
else{            
    $architecture = "32-Bit"            
} 
#Copies the proper exe dependant on the system architecture.
if($architecture -eq "64-Bit"){
    copy-item "C:\ProgramData\PSE\nssm-2.24\win64\nssm.exe" -Destination "C:\ProgramData\PSE\nssm.exe"
}
else{
     copy-item "C:\ProgramData\PSE\nssm-2.24\win32\nssm.exe" -Destination "C:\ProgramData\PSE\nssm.exe"
}   