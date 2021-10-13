#*------^ split-CommandLine.ps1 ^------

#*------v Step-ModuleVersionCalculated.ps1 v------
function Step-ModuleVersionCalculated {
    <#
    .SYNOPSIS
    Step-ModuleVersionCalculated.ps1 - Increment a fresh revision of specified module via profiled changes compared to prior semantic-version 'fingerprint' (or Percentage change).
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-09
    FileName    : 
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell
    AddedCredit : Kevin Marquette
    AddedWebsite: https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    AddedTwitter: 
    AddedCredit : Martin Pugh (revision code on file change percent)
    AddedWebsite: www.thesurlyadmin.com
    AddedTwitter: @thesurlyadm1n
    REVISIONS
    * 2:51 PM 10/13/2021 subbed pswls's for wv's ; added else block to catch mods with inconsistent names between root dir, and .psm1 file, (or even .psm1 location); added path to sBnr
    * 3:55 PM 10/10/2021 added output of final psd1 info on applychange ; recoded to use buildhelper; added -applyChange to exec step-moduleversion, and -NoBuildInfo to bypass reliance on BuildHelpers mod (where acting up for a module). 
    * 9:08 PM 10/9/2021 init version
    .DESCRIPTION
    Step-ModuleVersionCalculated.ps1 - Profile a fresh revision of specified module for changes compared to prior semantic-version 'fingerprint'.
    
    ## relies on BuildHelpers module, and it's Set-BuildEnvironment profiling tool, and Step-ModuleVersion manifest .psd1-file revision-incrementing tool. 

    ## -Method: Default via 'Fingerprint': 
        
        'Fingerprint' assumes a prior pass of the Initialize-ModuleFingerpring function:
        
        ```powershell
        Initialize-ModuleFingerprint -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
        ```

        ... which creates & populates a 'fingerprint' file in the root of the module, summarizing the commands and parameters within the module. 

        When Step-ModuleVersionCalculated is run, with default Method:Fingerprint, 
        the prior fingerprint file contents are compared to the current module content, 
        and the choice between Major|Module|Patch revision step level is made on the following basis:
            - Major reflets breaking changes - removed commands and parameters that previously existed
            - Minor reflects enhancements - new commands and parameters that did not previously exist
            - Patch lesser modifications that neither add functions/commands or parameters, nor remove same. 

    ## Optional Method is via 'Percentage'

        'Percentage' profiles all files in the Module, for changes after the LastWriteDate after the existing .psd1 file. 
        Changes as a percentage of all of the files, are caldulated on the following basis:

            - Major, 50% or more changes to files 
            - Minor, 10 - 25% changes to files 
            - Patch, 10% or less % or more changes to files 
            Semantic Variable standard also supports Builds, and logic is in place in this 
            function (sub 5%), but BuildHelper:Step-ModuleVersion() does not currently 
            support Build level revisions.  
    
    .PARAMETER Path
    Path to root directory of the Module[-path 'C:\sc\PowerShell-Statistics\']
    .PARAMETER applyChange
    switch to apply the Version Update (execute step-moduleversion cmd)[-applyChange]
    .PARAMETER NoBuildInfo
    Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
    Fingerprint the specified module path, with whatif and verbose specified
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -NoBuildInfo ;
    Using option to exclude leveaging BuildHelper module (where it fails to properly process a given module, and 'hangs' with normal processing). 
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -NoBuildInfo -applyChange ;
    Demo -applyChange option to apply Step-ModuleVersion immediately.
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -Method Percentage -applyChange ;
    Demo use of the optional 'Percentage' -Method (vs default 'Fingerprint' basis). 
    .EXAMPLE
    PS> $newRevBump = Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo' ;
        Step-ModuleVersion -path 'C:\sc\Get-MediaInfo\MediaInfo.psd1' -By $newRevBump ;
    Analyze the specified module, calculate a revision BumpVersionType, and return the calculated value tp the pipeline
    Then run Step-ModuleVersion -By `$bumpVersionType to increment the ModuleVersion (independantly, rather than within this function using -ApplyChange)
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    #>
    #Requires -Version 3
    #Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    #Requires -RunasAdministrator    
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to root directory of the Module[-path 'C:\sc\PowerShell-Statistics\']")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path,
        [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Version level calculation basis (Fingerprint[default]|Percentage)[-Method Percentage]")]
        [ValidateSet("Fingerprint","Percentage")]
        [string]$Method='Fingerprint',
        [Parameter(HelpMessage="Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]")]
        [switch] $NoBuildInfo,
        [Parameter(HelpMessage="Switch to force-increment ModuleVersion by minimum step (Patch), regardless of calculated changes[-MinVersionIncrement]")]
        [switch] $MinVersionIncrement,
        [Parameter(HelpMessage="switch to apply the Version Update (execute step-moduleversion cmd)[-applyChange]")]
        [switch] $applyChange,
        [Parameter(HelpMessage="Suppress all but error-related outputs[-Silent]")]
        [switch] $Silent,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN { 
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;

        $sBnr="#*======v RUNNING :$($CmdletName):$($Path) v======" ; 
        $smsg = "$($sBnr)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        
        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        
        if($whatif -AND -not $applyChange){
            $smsg = "You have specified -whatif, but have not also specified -applyChange" ; 
            $smsg += "`nThere is no reason to use -whatif without -applyChange."  ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 

        $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'} ;

    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            $smsg = "profiling existing content..."
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $ModuleName = split-path $path -leaf ;
            $moddir = (gi -Path $path).FullName;
            #$moddirfiles = gci -path $moddir -recur ;
            $pltGCI=[ordered]@{path=$moddir.FullName ;recurse=$true ; ErrorAction='STOP'} ;
            $smsg = "gci w`n$(($pltGCI|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

            $moddirfiles = gci @pltGCI ;

            # prelocate .psm1 (BH doesn't locate the .psm1)
            if($psm1 = $moddirfiles|?{$_.name -eq "$ModuleName.psm1"} ){
                $smsg = "located `$psm1:$($psm1)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            } elseif($psm1 = $moddirfiles|?{$_.name -like "*.psm1"} ){
                $smsg = "fail-thru located `$psm1:$($psm1)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            } else {
                $smsg = "failed to locate a .psm1 module file!" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                throw $smsg ;
            } ; 
            if($psm1 -is [system.array]){
                $smsg = "`$psm1 resolved to multiple .psm1 files in the module tree!" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                throw $smsg ;
            } else {
                $psm1Basename = ((split-path $psm1.fullname -leaf).replace('.psm1','')) ; 
                if($ModuleName -ne $psm1Basename){
                    $smsg = "Module has non-standard root-dir name`n$($moddir.fullname)"
                    $smsg += "`ncorrecting `$ModuleName variable to use *actual* .psm1 basename:$($psm1Basename)" ; 
                    write-warning $smsg ; 
                    $ModuleName = $psm1Basename ; 
                } ; 
            } ;  
            
            if($NoBuildInfo){
                if($moddirfiles.name -contains "$ModuleName.psd1"){
                    $psd1 = $moddirfiles|?{$_.name -eq "$ModuleName.psd1"} ; 
                } else { 
                    throw "Unable to locate Manifest .psd1 file!" ; 
                } ; 
                if($psd1 = $moddirfiles|?{$_.name -eq "$ModuleName.psd1"} ){
                    $smsg = "located `$psd1:$($psd1)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } elseif($psd1 = $moddirfiles|?{$_.name -like "*.psd1"} ){
                    $smsg = "fail-thru located `$psd1:$($psd1)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } else {
                    $smsg = "failed to locate a .psd1 manifest file!" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    throw $smsg ;
                } ; 
                if($psd1 -is [system.array]){
                    $smsg = "`$psd1 resolved to multiple .psd1 files in the module tree!" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    throw $smsg ;
                } ; 

            } else { 
                # stock buildhelper e-varis
                $smsg = "(executing:Set-BuildEnvironment -Path $($moddir) -Force `n(use -NoBuildInfo if hangs))" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Set-BuildEnvironment -Path $moddir -Force ;
                # never outputs anything but the $env:BHPS* variables, on *success* (test their status)
                $smsg = "Processing $($ModuleName):`n$((get-item Env:BH*|out-string).trim())`n" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if(test-path $env:BHPSModuleManifest){
                    $psd1 = gci $env:BHPSModuleManifest ; 
                } else {
                    $smsg = "Unable to locate psd1:$($env:BHPSModuleManifest)" 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
            } ; 
            $pltXPsd1=[ordered]@{path=$psd1.FullName ; ErrorAction='STOP'} ; 
            $smsg = "Import-PowerShellDataFile w`n$(($pltXPsd1|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $PsdInfoPre = Import-PowerShellDataFile @pltXPsd1 ;
            $smsg = "test-ModuleManifest w`n$(($pltXPsd1|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $TestReport = test-modulemanifest @pltXPsd1 ;
            if($? ){ 
                $smsg= "(Test-ModuleManifest:PASSED)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } 
            
            switch ($Method) {

                'Fingerprint' {

                    $smsg = "Module:PSD1:calculating *FINGERPRINT* change Version Step" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    if($moddirfiles.name -contains "fingerprint"){
                        $oldfingerprint = Get-Content  ($moddirfiles|?{$_.name -eq "fingerprint"}).FullName ; 
                
                        if($psm1){
                            $pltXMO.Name = $psm1.fullname # load via full path to .psm1
                            $smsg = "import-module w`n$(($pltXMO|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            import-module @pltXMO ;

                            $commandList = Get-Command -Module $ModuleName
                            $pltXMO.Name = $psm1Basename ; # have to rmo using *basename*
                            $smsg = "remove-module w`n$(($pltXMO|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            remove-module @pltXMO ;

                            $smsg = "Calculating fingerprint"
                            # KM's core logic code:
                            $fingerprint = foreach ( $command in $commandList ){
                                $smsg = "(=cmd:$($command)...)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                foreach ( $parameter in $command.parameters.keys ){
                                    $smsg = "(---param:$($parameter)...)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                                    $command.parameters[$parameter].aliases | 
                                        Foreach-Object { '{0}:{1}' -f $command.name, $_}
                                };  
                            } ;   

                            $bumpVersionType = 'Patch' ; 
                            if($MinVersionIncrement){
                                $smsg = "-MinVersionIncrement override specified: incrementing by min .Build" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                #$Version.Build ++ ;
                                #$Version.Revision = 0 ; 
                                # drop through min patch rev above
                            } else { 
                                # KM's core logic code:
                                $smsg = "Detecting new features" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $fingerprint | Where {$_ -notin $oldFingerprint } | 
                                    ForEach-Object {$bumpVersionType = 'Minor'; "  $_"} ; 
                                $smsg = "Detecting breaking changes" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $oldFingerprint | Where {$_ -notin $fingerprint } | 
                                    ForEach-Object {$bumpVersionType = 'Major'; "  $_"} ; 
                            } ;

                        } else {
                            $smsg = "No module .psm1 file found in tree of `$path:`n$($moddir)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            throw $smsg ;
                        } ;
                    
                    } else {
                        $smsg =  "No fingerprint file found in `$path:`n$(join-path -path $moddir -child "$ModuleName.psm1")" ;
                        $smsg += "`nTo configure a fingerprint for this module, plese run:`n"
                        $smsg += "`nInitialize-ModuleFingerprint -path $($moddir) ;"
                        $smsg += "`n... and then re-run the Step-ModuleVersionCalculated cmdlet" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        throw $smsg ;
                    } ;  

                    if ( $fingerprint ){
                        $pltOFile=[ordered]@{Encoding='utf8' ;FilePath=(join-path -path $moddir -childpath 'fingerprint') ;whatif=$($whatif) ;} ; 
                        $smsg = "Writing fingerprint: Out-File w`n$(($pltOFile|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $fingerprint | out-file @pltOFile ; 
                    } else {
                        $smsg = "No funtional Module `$fingerprint generated for path specified`n$($Path)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ; 
                } 
                'Percentage' {
                    # implement's Martin Pugh's revision step code on percentage of files changed after psd1.LastWriteTime
                    $smsg = "Module:PSD1:calculating *PERCENTAGE* change Version Step" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    $LastChange = (Get-ChildItem $psd1.fullname).LastWriteTime ; 
                    $ChangedFiles = ($moddirfiles | Where LastWriteTime -gt $LastChange).Count ; 
                    $PercentChange = 100 - ((($moddirfiles.Count - $ChangedFiles) / $moddirfiles.Count) * 100) ; 
                    $smsg = "PercentChange:$($PercentChange)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    #$Version = ([version]$Psd1PriorData.ModuleVersion) | Select Major,Minor,Build,Revision ; 
                    # coerce Build & Revision:-1 to 0, handling; doesn't like it when rev is -1
                    #$Version = ([version]$Psd1PriorData.ModuleVersion) | select Major,Minor,Build,@{name='Revision';Expression={[System.Math]::Max($_.revision,0)} }
                    <#$Version = ([version]$Psd1PriorData.ModuleVersion) | select Major,Minor,
                        @{name='Build';Expression={[System.Math]::Max($_.Build,0)} },
                        @{name='Revision';Expression={[System.Math]::Max($_.revision,0)} }
                    $PriorVers =  $Version | Select Major,Minor,Build,Revision
                    #>
                    if($MinVersionIncrement){
                        write-host -foregroundcolor green "-MinVersionIncrement override specified: incrementing by min .Build" ; 
                        #$Version.Build ++ ;
                        #$Version.Revision = 0 ; 
                        $bumpVersionType = 'Patch' 
                    } else { 
                        If ($PercentChange -ge 50){
                            #$Version.Major ++ ; # MAJOR (breaking change)
                            #$Version.Minor = 0 ; 
                            #$Version.Build = 0 ; 
                            #$Version.Revision = 0 ; 
                            $bumpVersionType = 'Major';
                        }ElseIf ($PercentChange -ge 25){
                            #$Version.Minor ++ ; # .MINOR (new feature - backward compatible)
                            #$Version.Build = 0 ; 
                            #$Version.Revision = 0 ; 
                           $bumpVersionType = 'Minor' ; 
                        }ElseIf ($PercentChagne -ge 10){
                            #$Version.Build ++ ; # NORMALLY .PATCH (bug fix)
                            #$Version.Revision = 0 ; 
                            $bumpVersionType = 'Patch'
                        }ElseIf ($PercentChange -gt 0){
                            #$Version.Revision ++ ; # NORMALLY +BUILD (pre-release and build metadata) # doesn't look like buildhelper  does 4-digit Build variants
                            $bumpVersionType = 'Patch' 
                        } ; 
                    } ; 

                } ;
            } # switch-E

            if($TestReport -AND $applyChange ){ 
                $pltStepMV=[ordered]@{Path=$psd1.FullName ; By=$bumpVersionType ; ErrorAction='STOP';} ; 

                $smsg = "Step-ModuleVersion w`n$(($pltStepMV|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if(!$whatif){
                    # Step-ModuleVersion -Path $env:BHPSModuleManifest -By $bumpVersionType ; 
                    Step-ModuleVersion @pltStepMV ; 
                    $PsdInfo = Import-PowerShellDataFile -path $env:BHPSModuleManifest ;
                    $smsg = "----PsdVers incremented from $($PsdInfoPre.ModuleVersion) to $((Import-PowerShellDataFile -path $env:BHPSModuleManifest).ModuleVersion)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                } else {
                    $smsg = "(-whatif, skipping exec:`nStep-ModuleVersion -Path $($env:BHPSModuleManifest) -By $($bumpVersionType)) ;" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $PsdInfo.ModuleVersion | write-output ; 
                } ;
            } ; 
  
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #-=-record a STATUSWARN=-=-=-=-=-=-=
            $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
            if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
            if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
            #-=-=-=-=-=-=-=-=
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ; 
    } ;  # PROC-E
    END {
    
        if ( $bumpVersionType ){
            
            if(-not $applyChange){
                $hMsg =@"

$($Method) analysis recommends ModuleVersion Step:$($bumpVersionType). 

This can be implemented with the following command:

Step-ModuleVersion -Path $($psd1.fullname) -By $($bumpVersionType)

(the above will use the BuildHelpers module to update the revision stored in the Manifest .psd1 file for the module).

"@ ; 
            } else {
                $hmsg = @"
$($Method) analysis recommended ModuleVersion Step:$($bumpVersionType). 

which was applied via the BuildHelper:Step-ModulerVersion cmdlet (above)

"@ ; 
            }; 

            $smsg = "`n$($hmsg)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        } else {
            $smsg = "Unable to generate a 'bumpVersionType' for path specified`n$($Path)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
    
        if($PsdInfo -AND $applyChange ){ 
            $smsg = "(returning updated ManifestPsd1 Content to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $PsdInfo | write-output 
        } else {
            $smsg = "-applyChange *not* specified, returning 'bumpVersionType' specification to pipeline:" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$PsdInfo.ModuleVersion | write-output 
             $bumpVersionType | write-output  ; 
        } ;  ;

        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;  # END-E
}

#*------^ Step-ModuleVersionCalculated.ps1 ^------