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
    [int]$port = 8889
)

$pseParams = @{}
$notfoundpage = @"
<html>
<head><title>404 Not Found</title></head>
<body><h1>404 Not Found</h1><hr><p>psExporter</p></body>
</html>
"@

$CR = [char]13
$LF = [char]10
$CRLF = [char]13 + [char]10
$SP = [char]32


#Set location for grabbing modules
$pseHome = $myInvocation.MyCommand.Path | Split-Path
Set-Location $pseHome

$modules = (Get-ChildItem "$pseHome\modules" -Filter "*.ps1").FullName

################################
###Function Declaration Start###
################################

function WriteLog($str) {
    $dateTime = Get-Date -Format "dd-MM-yyyy hh:mm:ss:ms"
    return $dateTime + "- " + $str
}

function RunModules {
    pass
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

#start tcplistener
$server.Start()
WriteLog -str "Started HTTP server" | Add-Content "$pseHome\exporter.log"

#begin loop to listen for connection attempts
$run = $true
while ($run) {
    $client = $server.AcceptTcpClient()
    WriteLog -str "Got a request" | Add-Content "$pseHome\exporter.log"

    #Clear params per connection
    $pseParams = @{}

    $stream = $client.GetStream()

    if ($stream.CanRead) {
        $avail = $client.Available
        WriteLog -str "[Read Request] $avail bytes available" | Add-Content "$pseHome\exporter.log"

        $bytes = new-object system.byte[] $avail
        $stream.read($bytes, 0, $bytes.length)
        $req_msg = [system.text.encoding]::utf8.getstring($bytes)

        #$resp_msg = GenerateMessage $req_msg
        [string]$resp_msg = $null
        foreach ($script in $modules) {
            $resp_msg += . $script
        }

        if($stream.canwrite -and $resp_msg){
            WriteLog -str "[Send Response]" | Add-Content "$pseHome\exporter.log"
            $msg = [system.text.encoding]::utf8.getbytes($resp_msg)
            $stream.write($msg, 0, $msg.length)
        }
    }

    $client.close()
    $stream.close()
    WriteLog -str "finished request" | Add-Content "$pseHome\exporter.log"
}

$server.Stop()
WriteLog -str "Server listening loop stopped.  HTTP server closed down" | Add-Content "$pseHome\exporter.log"
exit