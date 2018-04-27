<#
Description: An HTTP server written in PowerShell for exporting data gathered to prometheus
  In order to gather data, you must have other .ps1 scrips placed in the same folder as this one.
  Those scripts must output in the following format
    # HELP ps_filesize The filesize of the file being watched
    # TYPE ps_filesize bytes gauge
    ps_filesize 643759567
    # HELP ps_database_size The size of database being watched
    # TYPE ps_database_size bytes gauge
    ps_database_size 9378363738
    # HELP ps_port_listener Test to see if port is open
    # Type ps_port_listener gauge
    ps_port_listener 1

Author: Chad Mills

Version: 0.1
#>

param (
    [int]$port = 8889,
    $WriteSplunkLog = $false
)

$CR = [char]13
$LF = [char]10
$CRLF = [char]13 + [char]10
$SP = [char]32


#Set location for grabbing modules
$pseHome = $myInvocation.MyCommand.Path | Split-Path
Set-Location $pseHome

################################
###Function Declaration Start###
################################

function WriteLog($str) {
    $dateTime = Get-Date -Format "dd-MM-yyyy hh:mm:ss:ms"
    return $dateTime + "- " + $str
}


##############################
###Function Declaration End###
##############################

#Grab port for tcpListener, fail if its taken
try {
    $server = [system.net.sockets.tcplistener]$port
} catch {
    write-error "cannot open port $port"
    exit
}

################################
###Function Declaration Start###
################################

function WriteSplunkLog($str) {
    $date = Get-Date -format o
    $splunk_out = New-Object -TypeName PSObject
    $splunk_out | Add-Member -MemberType NoteProperty -name "_time" -Value $date
    $splunk_log = $str -split '[\r\n]'
    foreach ($line in $splunk_log) {
        if ($line -like "#*" -or $line -eq "") {
            continue
        }
        $name, $value = $line -split ' '
        $splunk_out | Add-Member -MemberType NoteProperty -Name $name -Value $value
        $splunk_out | ConvertTo-Json -Compress | Add-Content "$pseHome\splunklog.log"
    }
}

    

##############################
###Function Declaration End###
##############################

#start tcplistener
$server.Start()
WriteLog -str "Started HTTP server" | Add-Content "$pseHome\exporter.log"

#begin loop to listen for connection attempts
$run = $true
while ($run) {
    $modules = (Get-ChildItem "$pseHome\modules" -Filter "*.ps1").FullName

    $client = $server.AcceptTcpClient()
    WriteLog -str "Got a request" | Add-Content "$pseHome\exporter.log"

    $stream = $client.GetStream()
    $stream

    if ($stream.CanRead) {
        $avail = $client.Available
        WriteLog -str "[Read Request] $avail bytes available" | Add-Content "$pseHome\exporter.log"

        $bytes = new-object system.byte[] $avail
        $stream.read($bytes, 0, $bytes.length)
        $resp_msg = "HTTP/1.1 200 OK" + $LF
        $resp_msg += "Content-Type: text/plain; charset=utf-8" + $LF
        $resp_msg += $LF
        $splunk_log = ""
        foreach ($script in $modules) {
            $info = . $script
            $info += "`n"
            $resp_msg += $info
            $splunk_log += $info
            }
            $resp_msg += $LF
        #$resp_msg = $notfoundpage
        if($stream.canwrite -and $resp_msg){
            WriteLog -str "[Send Response]" | Add-Content "$pseHome\exporter.log"
            $msg = [system.text.encoding]::utf8.getbytes($resp_msg)
            $stream.write($msg, 0, $msg.length)
        }
    }

    $client.close()
    $stream.close()
    WriteLog -str "finished request" | Add-Content "$pseHome\exporter.log"
    if($writesplunklog -eq $true){
        $splunk_log | select-string -InputObject {$_} -Pattern "TYPE" -AllMatches
        WriteSplunkLog($splunk_log)
    }
   
}

$server.Stop()
WriteLog -str "Server listening loop stopped.  HTTP server closed down" | Add-Content "$pseHome\exporter.log"
exit