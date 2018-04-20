# define installer name
OutFile "PSEinstaller.exe"
 
# set C:\ProgramData\PSE\ as install directory
InstallDir C:\ProgramData\PSE\

# section start
Section "install"
#Define registry paths
!define PRODUCT_CALL_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\PSE.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\PSE"
!define PRODUCT_UNINST_KEY_OTHER "Software\Microsoft\Windows\CurrentVersion\Uninstall\Prometheus Exporter"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_SERVICE_CONFIG "\SYSTEM\CurrentControlSet\Services\PSE\Parameters"

#include the powershell plugin to add the firewall exception
!include psexec.nsh

    # define output path
    SetOutPath $INSTDIR
    CreateDirectory $INSTDIR\Modules
    File "C:\ProgramData\PSE\ps_exporter.ps1" 
    File "C:\ProgramData\PSE\nssm.exe"

    #Create Service
    nsExec::Exec 'nssm.exe install PSE $INSTDIR\PSE.exe'
    nsExec::Exec 'nssm.exe set PSE Description Prometheus exporter'
    nsExec::Exec 'nssm.exe set PSE Application C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
    nsExec::Exec 'nssm.exe set PSE AppDirectory $INSTDIR'
    nsExec::Exec 'nssm.exe set PSE AppParameters powershell .\ps_exporter.ps1'
    nsExec::Exec 'nssm.exe set PSE Start SERVICE_AUTO_START'
    nsExec::Exec 'nssm.exe start PSE'

    #Create firewall rule exception
 ${PowerShellExec} "powershell -ExecutionPolicy Bypass  New-NetFirewallRule -DisplayName PSE -Direction inbound -LocalPort 8889 -Protocol TCP -Action Allow"

    # define uninstaller name
    WriteUninstaller "$INSTDIR\uninst.exe"

    ; Uninstall Registry Entries
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
        "DisplayName" "PSE"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
        "UninstallString" "$INSTDIR\uninst.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" \
        "DisplayVersion" "0.1"
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\services\PSE" \
        "DependOnService" "nsi"
#-------
# default section end
SectionEnd
 
# create a section to define what the uninstaller does.
Section "Uninstall"
    # delete uninstaller first
    Delete $INSTDIR\uninst.exe
 
    # delete installed files
    Delete $INSTDIR\nssm.exe
    Delete $INSTDIR\ps_exporter.ps1
    RMDir /r $INSTDIR
    nsExec::exec '$INSTDIR\nssm.exe remove PSE confirm'
    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY_OTHER}"
    DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_CALL_REGKEY}"
    Pop $0 ; returns an errorcode (<>0) otherwise success (0)
 
SectionEnd