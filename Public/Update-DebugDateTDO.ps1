# Update-DebugDateTDO.ps1.ps1

#region UPDATE_DEBUGDATETDO ; #*------v Update-DebugDateTDO v------
#if(-not (get-childitem function:Update-DebugDateTDO -ea 0)){
    function Update-DebugDateTDO {
        <#
        .SYNOPSIS
        Update-DebugDateTDO - Search specified path for .ps1 files, optionally filtered by -Days 'old' parameter, and replace specified `$dbgdate variable mm/dd/yyyy value with an updated value (defaults to current date)
        .NOTES
        Version     : 1.1.0
        Author      : Todd Kadrie
        Website     : https://www.toddomation.com
        Twitter     : @tostka / http://twitter.com/tostka
        CreatedDate : 3:56 PM 12/8/2019
        FileName    : Update-DebugDateTDO.ps1.ps1
        License     : MIT License
        Copyright   : (c) 2025 Todd Kadrie
        Github      : https://github.com/tostka/verb-dev
        AddedCredit :
        AddedWebsite:
        AddedTwitter:
        REVISIONS
        * 12:50 PM 8/25/2026 INIT
        .DESCRIPTION
        Update-DebugDateTDO - Search specified path for .ps1 files, optionally filtered by -Days 'old' parameter, and replace specified `$dbgdate variable mm/dd/yyyy value with an updated value (defaults to current date)
        .PARAMETER DateOld
        Existing `$dbgdate= 'mm/dd/yyyy' Date value to be updated [-DateOld '8/21/2026']
        .PARAMETER DateOld
        Existing `$dbgdate= 'mm/dd/yyyy' Date value to be updated FROM[-DateOld '8/21/2026']
        .PARAMETER DateNew
        New `$dbgdate= 'mm/dd/yyyy' Date value to be updated TO[-DateNew '8/25/2026']
        .PARAMETER 
        Days back to filter for LastWriteTimd[-Days 14]
        .PARAMETER Extension
        Array of extensions to be filtered[-Extension '.psm1']
        .PARAMETER Whatif
        Parameter to run a Test no-change pass [-Whatif switch]
        .INPUTS
        None
        .OUTPUTS
        Outputs a system.object containing:
        * Parameters : Details on all Parameters in the file
        * Functions : Details on all Functions in the file
        * VariableAssignments : Details on all Variables assigned in the file
        .EXAMPLE
        PS> Update-DebugDateTDO -Path d:\scripts\ -DateOld '8/21/2026' -DateNew '8/25/2026' -Days 21 -whatIf:$true;  
        Demo updating all (default extension:.ps1) files Lastwritten in 21d, updating dbgdate variable references from DateOld to DateNew
        .LINK
        https://github.com/tostka/verb-dev
        #>
        [CmdletBinding()]
        [Alias('get-ScriptProfileAST')]
        PARAM(
            [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Path to folder containing scripts/functions to be updated[-Path c:\path-to\]")]
                [ValidateScript({Test-Path $_ -PathType 'Container'})]
                [Alias('Folder')]
                [System.IO.DirectoryInfo[]]$Path,            
            [Parameter(Position = 1, Mandatory = $true, HelpMessage = "Existing `$dbgdate= 'mm/dd/yyyy' Date value to be updated [-DateOld '8/21/2026']")]
                [ValidatePattern('\d{1,2}/\d{2}/\d{4}')]
                [string]$DateOld,
            [Parameter(Position = 2, Mandatory = $true, HelpMessage = "New `$dbgdate= 'mm/dd/yyyy' Date value to be updated TO[-DateNew '8/25/2026']")]               
                [ValidatePattern('\d{1,2}/\d{2}/\d{4}')]
                [string]$DateNew,
            [Parameter(Position = 3, Mandatory = $false, HelpMessage = "Days back to filter for LastWriteTimd[-Days 14]")]
                [int]$Days,
            [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Array of extensions to be filtered[-Extension '.psm1']")]                [ValidatePattern( "\.(ps1|psm1)$")]
                [ValidatePattern( "\.(ps1|psm1)$")]
                [string[]]$Extension = '.ps1',
            [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
                [switch] $whatIf
        ) ;
        BEGIN {            
        } ;
        PROCESS {
            #[regex]$DateLineFilter = "\`$dbgdate((\s+)*)=((\s+)*)'$([regex]::Escape($DateOld))'"
            [regex]$DateLineFilter = "dbgdate((\s)*)=((\s)*)'$([regex]::Escape($dateOld))'"
            $UpdatedDateLine = "dbgdate = '$($dateNew)'"
            foreach($Pth in $Path){
                $rawfiles = Get-ChildItem -Path (join-path $pth.fullname "*") -Filter "*$($extension)" -File ; 
                if($Days){
                    write-verbose "Reducing hits by specified recent -Days:$($Days)" 
                    $rawfiles = $rawfiles | ?{$_.LastWriteTime -ge (get-date ).adddays(-1 * $Days)} ; 
                } ; 
                $rawfiles  | ForEach-Object {
                    $thisitem = $_ ; 
                    $content = Get-Content $thisitem.FullName -Raw ;
                    #if ($content -match [regex]($DateOld)) {                    
                    if ($content -match $DateLineFilter) {
                        $referenceLines = $thisitem | sls -Pattern $DateLineFilter ;                                                     
                        $newContent = $content ; 
                        $revd = $false; 
                        $referencelines | foreach-object{ 
                            $thisSlsHit = $_  ;
                            if($thisSlsHit.matches[0].groups[0].Captures.value){
                                $newContent = $newContent.replace($thisSlsHit.matches[0].groups[0].Captures.value,$UpdatedDateLine) ; 
                                $revd = $true; 
                                #$newContent | 
                                #    Set-Content $thisitem.FullName -WhatIf:$($whatif) -Verbose:$true ; 
                                #Write-Host "Updated: $($thisitem.FullName)" ;
                            } ;                                 
                        } ; 
                        if($revd -eq $true){                                
                            $ref = $content.Split([Environment]::NewLine)  | %{$i = 1} { new-object psobject -prop @{LineNum=$i;Text=$_}; $i++} ;
                            $rev = $newcontent.Split([Environment]::NewLine) | %{$i = 1} { new-object psobject -prop @{LineNum=$i;Text=$_}; $i++} ;
                            #$diff = Compare-Object $ref $rev -Property Text -PassThru  ; 
                            $diff = Compare-Object $rev $ref -Property Text -PassThru  ; 
                            write-host -foregroundcolor green "Diff:$($thisitem.fullname))`n$(($diff | ft -a LineNum,Text,SideIndicator|out-string).trim())" ;    
                            $PTitle  = "# Confirm Update:" ; 
                            $PMsg = "Update?: $($thisitem.fullname)"
                            $PMsg += "`n$(($referenceLines | ft -a LineNumber,Line|out-string).trim())" ; 
                            # Define choices. The '&' character sets the keyboard shortcut key.
                            $PChoices = [System.Management.Automation.Host.ChoiceDescription[]] @(
                                [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Proceed."),
                                [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Cancel.")
                            )
                            $iPDefault = 0
                            $PResult = $Host.UI.PromptForChoice($PTitle, $PMsg, $PChoices, $iPDefault)
                            if ($PResult -eq 0) {
                                $newContent | 
                                    Set-Content $thisitem.FullName -WhatIf:$($whatif) -Verbose:$true -Encoding utf8; 
                            } else {
                                #Write-Host "You chose No. Aborting..." -ForegroundColor Red
                                write-host -foregroundcolor red "(skipped:$($thisitem.fullname))"
                            } ; 
                        }else{
                            write-host -foregroundcolor gray "unrevised content" ; 
                        } ; 
                    } ;
                } ;                         
            } ;  # loop-E
        } ;
        END {
            
        } ;
    } ; 
#} ; 
#endregion UPDATE_DEBUGDATETDO ; #*------^ END Update-DebugDateTDO ^------