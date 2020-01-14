#*------v Function get-VersionInfo v------
function get-VersionInfo {
    <#
    .SYNOPSIS
    get-VersionInfo.ps1 - get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).
    .NOTES
    Version     : 0.1.0
    Author      : Todd Kadrie
    Website     :	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    CreatedDate : 02/07/2019
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    AddedCredit : Based on code & concept by Alek Davis
    AddedWebsite:	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    AddedTwitter:
    REVISIONS
    * 9:36 AM 12/30/2019 added CBH .INPUTS & OUTPUTS, including description of the hashtable of key/value pairs returned, for existing CBH .NOTES block
    * added explicit -path param to get-help
    * 8:39 PM 11/21/2019 added test for returned get-help
    * 8:27 AM 11/5/2019 Todd rework: Added Path param, parsed to REVISIONS: block, & return the top rev as LastRevision key in returned object.
    * 02/07/2019 Posted version
    .DESCRIPTION
    get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).
    .PARAMETER  Path
    Path to target script (defaults to $PSCommandPath)
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .INPUTS
    None
    .OUTPUTS
    Returns a hashtable of key-value pairs for each of the entries in the .NOTES CBH block in a given file.
    .EXAMPLE
    .\get-VersionInfo
    Default process from $PSCommandPath
    .EXAMPLE
    .\get-VersionInfo -Path .\path-to\script.ps1
    Explicit file via -Path
    .LINK
    https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    #>
    PARAM(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to target script (defaults to `$PSCommandPath) [-Path -Path .\path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $notes = $null ; $notes = @{ } ;
    # Get the .NOTES section of the script header comment.
    if (!$Path) {
        $Help = Get-Help -Full -path $PSCommandPath
    }
    else { $Help = Get-Help -Full -path $Path } ;
    if($Help){
        $notesLines = ($Help.alertSet.alert.Text -split '\r?\n').Trim() ;
        foreach ($line in $notesLines) {
            if (!$line) { continue } ;
            $name = $null ; $value = $null ;
            if ($line -eq 'REVISIONS') { $bRevBlock = $true ; Continue } ;
            if ($bRevBlock) {
                $notes.Add("LastRevision", "$line") ;
                break ;
            } ;
            if ($line.Contains(':')) {
                $nameValue = $null ;
                $nameValue = @() ;
                # Split line by the first colon (:) character.
                $nameValue = ($line -split ':', 2).Trim() ;
                $name = $nameValue[0] ;
                if ($name) {
                    $value = $nameValue[1] ;
                    if ($value) { $value = $value.Trim() } ;
                    if (!($notes.ContainsKey($name))) { $notes.Add($name, $value) } ;
                } ;
            } ;
        } ;
        $notes | write-output ;
    } else {
        $false | write-output ;
    } ;
} ; #*------^ END Function get-VersionInfo ^------
# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUj1bd32F5uHT7jkXBEVhiLUqf
# bD2gggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDEyMjkxNzA3MzNaFw0zOTEyMzEyMzU5NTlaMBUxEzARBgNVBAMTClRvZGRT
# ZWxmSUkwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALqRVt7uNweTkZZ+16QG
# a+NnFYNRPPa8Bnm071ohGe27jNWKPVUbDfd0OY2sqCBQCEFVb5pqcIECRRnlhN5H
# +EEJmm2x9AU0uS7IHxHeUo8fkW4vm49adkat5gAoOZOwbuNntBOAJy9LCyNs4F1I
# KKphP3TyDwe8XqsEVwB2m9FPAgMBAAGjdjB0MBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MF0GA1UdAQRWMFSAEL95r+Rh65kgqZl+tgchMuKhLjAsMSowKAYDVQQDEyFQb3dl
# clNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3SCEGwiXbeZNci7Rxiz/r43gVsw
# CQYFKw4DAh0FAAOBgQB6ECSnXHUs7/bCr6Z556K6IDJNWsccjcV89fHA/zKMX0w0
# 6NefCtxas/QHUA9mS87HRHLzKjFqweA3BnQ5lr5mPDlho8U90Nvtpj58G9I5SPUg
# CspNr5jEHOL5EdJFBIv3zI2jQ8TPbFGC0Cz72+4oYzSxWpftNX41MmEsZkMaADGC
# AWAwggFcAgEBMEAwLDEqMCgGA1UEAxMhUG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZp
# Y2F0ZSBSb290AhBaydK0VS5IhU1Hy6E1KUTpMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBT6+MCi
# jjKB5UOEcm9T4gkF7W19NTANBgkqhkiG9w0BAQEFAASBgDaQuhLzLfXGPCdw7J2c
# 4vT7WaYY+wgV7a9A3BVwX2BtOGYWjpVMoGuz82oMGZvjO0qf+rKIETOlQXNMz64K
# hz9+Socoes8vGL3qIq2lY/gHpgAktNivcoVHaJc6lhJul2ighJbj2vGvwInAo/A8
# iteAbsXOEwAmi2cbT15mn6L8
# SIG # End signature block
