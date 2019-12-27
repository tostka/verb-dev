
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
    AddedWebsite:	URLhttps://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    AddedTwitter:	
    REVISIONS
    * 8:27 AM 11/5/2019 Todd rework: Added Path param, parsed to REVISIONS: block, & return the top rev as LastRevision key in returned object.
    * 02/07/2019 Posted version
    .DESCRIPTION
    get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs). 
    .PARAMETER  Path
    Path to target script (defaults to $PSCommandPath)
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
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
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to target script (defaults to `$PSCommandPath) [-Path -Path .\path-to\script.ps1]")]
        [ValidateScript({Test-Path $_})]$Path,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf=$true
    ) ;
    $notes = $null ; $notes = @{} ; 
    # Get the .NOTES section of the script header comment.
    if(!$Path){$Help = Get-Help -Full $PSCommandPath 
    } else { $Help = Get-Help -Full $Path } ; 
    $notesLines = ($Help.alertSet.alert.Text -split '\r?\n').Trim() ; 
    #$lines = ($notesText -split '\r?\n').Trim() ; 
    foreach ($line in $notesLines) {
        if (!$line) {continue } ; 
        $name  = $null ; $value = $null ; 
        if ($line -eq 'REVISIONS') {$bRevBlock=$true ; Continue } ; 
        if ($bRevBlock){
            $notes.Add("LastRevision","$line") ; 
            break ; 
        } ; 
        if ($line.Contains(':')) {
            $nameValue = $null ; 
            $nameValue = @() ; 
            # Split line by the first colon (:) character.
            $nameValue = ($line -split ':',2).Trim() ; 
            $name = $nameValue[0] ; 
            if ($name) {
                $value = $nameValue[1] ; 
                if ($value) {$value = $value.Trim() } ; 
                if (!($notes.ContainsKey($name))) {$notes.Add($name, $value) } ; 
            } ; 
        } ; 
    } ; 
    $notes | write-output ;  
} ; #*------^ END Function get-VersionInfo ^------

