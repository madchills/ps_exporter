<#
Description: Testing Module to explain how the exporter works.  This simplistic script will 
explain and show a user how to create a 'module' for ps_exporter. 

Author: Chad Mills (madchills)

Version: 0.1
#> 

#Get Path of log file
$dir = $MyInvocation.MyCommand.Path | Split-Path
$pseLog = (Split-Path $dir) + "\exporter.log"

#The return NEEDS to have name and value. but should also contain HELP and TYPE
[string]$ret = "# HELP pse_log_filesize Current size of ps_exporter log in bytes`n"
$ret += "# TYPE pse_log_filesize gauge`n"

#The data you gather must be numbers only.  this one will be file size in bytes 
$size = (Get-item $pseLog).Length
$ret += "pse_log_filesize $size"

return $ret