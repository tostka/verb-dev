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
        * 9:16 AM 8/26/2026 default -whatif:$true; added -Report, added -DateOld ANY support, to blanket update any match on the variable name assignment instance ;
            added default -Datenew to today's M/dd/yyyy date when not specified. 
            added -Files (array of leaf files to be processed), added bnrs, reworked logic to generate rawfiles that get processed.
        * 12:50 PM 8/25/2026 INIT
        .DESCRIPTION
        Update-DebugDateTDO - Search specified path for .ps1 files, optionally filtered by -Days 'old' parameter, and replace specified `$dbgdate variable mm/dd/yyyy value with an updated value (defaults to current date)
        .PARAMETER Path
        Array of folder paths containing scripts/functions to be updated[-Path c:\path-to\]
        .PARAMETER Files
        Optional variant: Explicit Leaf File paths to be processed[-path c:\pathto\file.ext]
        .PARAMETER Report
        Switch to hunt up stock variable name (`$dbgdate) and report it's presence in specified path/files[-Report]
        .PARAMETER DateOld
        Existing `$dbgdate= 'mm/dd/yyyy' Date value to be updated FROM (supports 'ANY' to blanket replace any matching pattern date assignment for `$dbgdate)[-DateOld '8/21/2026']
        .PARAMETER DateNew
        New `$dbgdate= 'mm/dd/yyyy' Date value to be updated TO (defaults to today's m/dd/yyyy date if not specified)[-DateNew '8/25/2026']
        .PARAMETER Days
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
        .EXAMPLE
        PS> Update-DebugDateTDO -Files D:\scripts\test-EXOConnectionTDO_func.ps1 -DateOld '8/21/2026' -DateNew '8/25/2026' -Days 21 -whatIf:$true;  
        Demo updating all (default extension:.ps1) files Lastwritten in 21d, updating dbgdate variable references from DateOld to DateNew
        .EXAMPLE
        PS> Update-DebugDateTDO -Files D:\scripts\test-EXOConnectionTDO_func.ps1 -DateOld 'ANY'  -Days 21 -whatIf:$true;  
        Demo use of -DateOld ANY and permitting DateNew to default to today's date.
        .LINK
        https://github.com/tostka/verb-dev
        #>
        [CmdletBinding(DefaultParameterSetName='Directory')]
        #[Alias('get-ScriptProfileAST')]
        PARAM(
            [Parameter(Position = 0, ParameterSetName='Directory', Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Array of folder paths containing scripts/functions to be updated[-Path c:\path-to\]")]
                [ValidateScript({Test-Path $_ -PathType 'Container'})]
                #[ValidateScript({Test-Path})]
                [Alias('Folder')]
                [System.IO.DirectoryInfo[]]$Path,
                #[string[]]$Path,
            [Parameter(Mandatory = $False, ParameterSetName='File', HelpMessage = 'Array of leaf file paths to be processed[-path c:\pathto\file.ext]')]
                [Alias('PsPath')]                
                [ValidateScript({Test-Path $_ -Pathtype Leaf})]
                [system.io.fileinfo[]]$Files,
            [Parameter(Mandatory = $False, HelpMessage = "Switch to hunt up stock variable name (`$dbgdate) and report it's presence in specified path/files[-Report]")]
                [switch]$Report,
            [Parameter(Position = 1, Mandatory = $true, HelpMessage = "Existing `$dbgdate= 'mm/dd/yyyy' Date value to be updated FROM (supports 'ANY' to blanket replace any matching pattern date assignment for `$dbgdate)[-DateOld '8/21/2026']")]
                [ValidatePattern('\d{1,2}/\d{2}/\d{4}|ANY')]
                #[string]
                $DateOld,
            [Parameter(Position = 2, Mandatory = $false, HelpMessage = "New `$dbgdate= 'mm/dd/yyyy' Date value to be updated TO (defaults to today's m/dd/yyyy date if not specified)[-DateNew '8/25/2026']")]               
                [AllowEmptyString()][AllowNull()]
                [ValidatePattern('\d{1,2}/\d{2}/\d{4}')]
                [string]$DateNew,
            [Parameter(Position = 3, Mandatory = $false, HelpMessage = "Days back to filter for LastWriteTimd[-Days 14]")]
                [int]$Days,
            [Parameter(Position = 2,ParameterSetName='Directory', Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Array of extensions to be filtered[-Extension '.psm1']")]                [ValidatePattern( "\.(ps1|psm1)$")]
                [ValidatePattern( "\.(ps1|psm1)$")]
                [string[]]$Extension = '.ps1',
            [Parameter(HelpMessage = "Whatif Flag (defaults `$true, use -whatif:`$false to override)[-whatIf]")]
                [switch] $whatIf=$true
        ) ;
        BEGIN {
            [regex]$DateLineFilterANY = "dbgdate((\s)*)=((\s)*)'\d{1,2}/\d{2}/\d{4}'"
            if($DateOld -eq 'ANY'){
                [regex]$DateLineFilter = $DateLineFilterANY ; 
            } elseif($DateOld = [string]$DateOld){
                [regex]$DateLineFilter = "dbgdate((\s)*)=((\s)*)'$([regex]::Escape($dateOld))'"
            }
            #[regex]$DateLineFilter = "\`$dbgdate((\s+)*)=((\s+)*)'$([regex]::Escape($DateOld))'"
            if($null -eq $datenew -OR $DateNew.length -eq 0){
                $DateNew = (get-date -format 'M/dd/yyyy') ; 
                write-host -foregroundcolor yellow "No -DateNew specified, defaulting to: $($DateNew )" ; 
            }
            $UpdatedDateLine = "dbgdate = '$($dateNew)'"
            
            $rawfiles = @() ; 
            $procFiles = @() ; 
        } ;
        PROCESS {            
            foreach($Pth in $Path){               
                $rawfiles += Get-ChildItem -Path (join-path $pth.fullname "*") -Filter "*$($extension)" -File ; 
            } ; 
            foreach($File in $Files){               
                $rawfiles += $File ; 
            } ; 
            if($Days){
                write-verbose "Reducing hits by specified recent -Days:$($Days)" 
                $rawfiles = $rawfiles | ?{$_.LastWriteTime -ge (get-date ).adddays(-1 * $Days)} ; 
            } ; 
            $ttl = ($rawfiles| measure | select -expand count)
            $prcd = 0 
            $rawfiles  | ForEach-Object {
                $thisitem = $_ ; 
                $prcd++ ; 
                $sBnrS="`n#*------v PROCESSING ($($prcd)/$($ttl) $([math]::round($prcd/$ttl * 100))%): $($thisitem.fullname) v------" ;
                write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnrS)" ;
                if($Report){
                    if($referenceLines = $thisitem | sls -Pattern $DateLineFilter){
                        <# obj returned by sls:
                        IgnoreCase : True
                        LineNumber : 257
                        Line       :         $dbgdate = '8/25/2026' ;
                        Filename   : Connect-EXO_func.ps1
                        Path       : D:\scripts\Connect-EXO_func.ps1
                        Pattern    : dbgdate((\s)*)=((\s)*)'\d{1,2}/\d{2}/\d{4}'
                        Context    :
                        Matches    : {0}
                        #>
                        write-host -foregroundcolor green "Hits on $($DateLineFilter):`n$(($referenceLines| ft -a LineNumber,Line,Path| out-string).trim())" ; 
                        $procFiles += $referenceLines.Path ; 
                    }else{
                        write-host -foregroundcolor yellow "No matches found for: $($DateLineFilterANY)" ; 
                    } 
                }else{
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
                                $procFiles += $thisitem.FullName ; 
                            } else {
                                #Write-Host "You chose No. Aborting..." -ForegroundColor Red
                                write-host -foregroundcolor red "(skipped:$($thisitem.fullname))"
                            } ; 
                        }else{
                            write-host -foregroundcolor gray "unrevised content" ; 
                        } ; 
                    } ;
                    write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
                } ;  # if-E if $Report
            } ;                         
            
        } ;
        END {
            if($procFiles){
                if($whatif){
                    $smsg = "-whatif:" ; 
                }else{
                    $smsg = "-EXEC:" ; 
                } ; 
                $smsg += "Returning ($($procFiles| measure | select -expand count))" ; 
                if($Report){
                    $smsg += " matching (-Report)" ;
                }else{
                    $smsg += " processed" ;                    
                } ; 
                $smsg += " files paths to pipeline..." ; 
                write-host -foregroundcolor yellow $smsg ; 
                $procFiles  | write-output 
            } ;  
        } ;
    } ; 
#} ; 
#endregion UPDATE_DEBUGDATETDO ; #*------^ END Update-DebugDateTDO ^------