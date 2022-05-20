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
    * 8:58 AM 5/20/2022 WIP, add: $MinVersionIncrementBump (coerce Min failthrough rev to Build, constant, rather than hard-coded in code) ; 
        address gcm bug where failing to return any but 3 old renamed funcs from verb-io.psm1: 
        add $ASTMatchThreshold (reps min percentage match gcm to sls -pattern parse of function lines in .psm1), along with a raft of new eval testing code. 
        tried running AST profiling to pull functions & aliases, but takes _3Mins_ to run. Simpler, and 90% effective to do an sls parse.
    * 2:29 PM 5/16/2022 add: backup-fileTDO of the fingerprintfile
    * 9:42 AM 1/18/2022 added test for recursed nested #requires -module [modname] 
        strings - this one's a brute to recover from, just like the version clash, both 
        hard-break build and require reverting installed rev of module to get past. 
        Everything works, bbuild, publish, install, except the trailing ipmo dies 
        *hard* ; updated $rgxRequreVersionLine prefix (\s|^) to suppress returns of double-#'d rem'd requires lines.
    * 2:09 PM 10/26/2021 requires vers code: only run if $PsFilesWVers populated ; shifted 'good' exit to within bumpvers test, and output $false otherwise ; updated mult #requires code to profile -version variants, and look for -gt 1; added verbose dump of Minor/Major changes in trailing outputs. 
    * 3:46 PM 10/25/2021 fingerprint code was dropping matches into pipeline, and blowing up returned bumprev string (ingested the outputs) ; added .psm1 test for multi '#requires -version' (crashes all ipmos) ; add verbose support into all the splats
    * 2:19 PM 10/16/2021 actually implemented the new -Silent param ; updated ModuleName locater; 
    * 6:11 PM 10/15/2021 rem'd # raa, replaced psd1/psm1-location code with Get-PSModuleFile(), which is a variant of BuildHelpers get-psModuleManifest. 
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
            
            Semantic versioning (aka SemVer), supports an optional pre-release tag and optional build meta tag (1.2.0-a.1)
            [Semantic Versioning 2.0.0 | Semantic Versioning - semver.org/](https://semver.org/)

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
    ##Requires -RunasAdministrator    
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to root directory of the Module[-path 'C:\sc\PowerShell-Statistics\']")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path,
        [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Version level calculation basis (Fingerprint[default]|Percentage)[-Method Percentage]")]
        [ValidateSet("Fingerprint","Percentage")]
        [string]$Method='Fingerprint',
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
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        
        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        
        if($whatif -AND -not $applyChange){
            $smsg = "You have specified -whatif, but have not also specified -applyChange" ; 
            $smsg += "`nThere is no reason to use -whatif without -applyChange."  ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            elseif(-not $Silent){ write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
        
        #$rgxRequreVersionLine = '#requires\s+-version\s' ;
        # add filter for BOL or \s lead, drop the ##-rem'd lines
        $rgxRequreVersionLine = '(\s|^)#requires\s+-version\s' ;
        # also should check for nested recursion - ensure the Module isn't in any #requires\s-module
        # '((\s)*)#Requires\s+-Modules\s+.*,((\s)*)verb-exo' ; # module name
        # $Path will be c:\sc\verb-exo ; split-path c:\sc\verb-exo -leaf gets you the modulename back
        $ModName = split-path -Path $path -leaf ; 
        $rgxRequireModNested = "(\s|^)#Requires\s+-Modules\s+.*,((\s)*)$($ModName)" ;  # added: either BOL or after a space
        $ASTMatchThreshold = .8 ; # gcm must be w/in 80% of AST functions count, or this forces a 'Build' revision, to patch bugs in get-command -module xxx, where it fails to return full func/alias list from the module
        # increment bump used with -MinVersionIncrementBump
        $MinVersionIncrementBump = 'Build'

    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            $smsg = "profiling existing content..."
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $Path = $moddir = (Resolve-Path $Path).Path ; 
            $moddirfiles = gci -path $path -recur 
            #-=-=-=-=-=-=-=-=
            if(-not (gcm Get-PSModuleFile -ea 0)){
                function Get-PSModuleFile {
                    [CmdletBinding()]
                    PARAM(
                        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']")]
                        [ValidateScript({Test-Path $_ -PathType 'Container'})]
                        [string]$Path = $PWD.Path,
                        [Parameter(HelpMessage="Specify Module file type: Module .psm1 file or Manifest .psd1 file (psd1|psm1 - defaults psd1)[-Extension .psm1]")]
                        [ValidateSet('.psd1','.psm1','both')]
                        [string] $Extension='.psd1'
                    ) ;

                    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
                    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
                    $sBnr="#*======v RUNNING :$($CmdletName):$($Extension):$($Path) v======" ; 
                    $smsg = "$($sBnr)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    if($Extension -eq 'Both'){
                        [array]$Exts = '.psd1','.psm1'
                        write-verbose "(-extension Both specified: Running both:$($Exts -join ','))" ; 
                    } else {
                        $Exts = $Extension ; 
                    } ; 
                    $Path = ( Resolve-Path $Path ).Path ; 
                    $CurrentFolder = Split-Path $Path -Leaf ;
                    $ExpectedPath = Join-Path -Path $Path -ChildPath $CurrentFolder ;
        
                    foreach($ext in $Exts){
                        $ExpectedFile = Join-Path -Path $ExpectedPath -ChildPath "$CurrentFolder$($ext)" ;
                        if(Test-Path $ExpectedFile){$ExpectedFile  } 
                        else {
                            # Look for properly organized modules (name\name.ps(d|m)1)
                            $ProjectPaths = Get-ChildItem $Path -Directory |
                                ForEach-Object {
                                    $ThisFolder = $_ ;
                                    write-verbose "checking:$($ThisFolder)" ; 
                                    $ExpectedFile = Join-Path -path $ThisFolder.FullName -child "$($ThisFolder.Name)$($ext)" ;
                                    If( Test-Path $ExpectedFile) {$ExpectedFile  } ;
                                } ;
                            if( @($ProjectPaths).Count -gt 1 ){
                                Write-Warning "Found more than one project path via subfolders with psd1 files" ;
                                $ProjectPaths  ;
                            } elseif( @($ProjectPaths).Count -eq 1 )  {$ProjectPaths  } 
                            elseif( Test-Path "$ExpectedPath$($ext)" ) {
                                write-verbose "`$ExpectedPath:$($ExpectedPath)" ; 
                                #PSD1 in root of project - ick, but happens.
                                "$ExpectedPath$($ext)"  ;
                            } elseif( Get-Item "$Path\S*rc*\*$($ext)" -OutVariable SourceFiles)  {
                                # PSD1 in Source or Src folder
                                If ( $SourceFiles.Count -gt 1 ) {
                                    Write-Warning "Found more than one project $($ext) file in the Source folder" ;
                                } ;
                                $SourceFiles.FullName ;
                            } else {
                                Write-Warning "Could not find a PowerShell module $($ext) file from $($Path)" ;
                            } ;
                        } ;
                    } ; 
                    $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                }
                ##-=-=-=-=-=-=-=-=
            }

            $psd1M = Get-PSModuleFile -path $Path -ext .psd1 -verbose:$($VerbosePreference -eq 'Continue');
            $psm1 = Get-PSModuleFile -path $Path -ext .psm1 -verbose:$($VerbosePreference -eq 'Continue' ); 
            if ((split-path (split-path $psd1m) -leaf) -eq (gci $psd1m).basename){
                $ModuleName = split-path -leaf (split-path $psd1m) 
            } else {throw "`$ModuleName:Unable to match psd1.Basename $((gci $psd1m).basename) to psd1.parentfolder.name $(split-path (split-path $psd1m) -leaf)" }  ;
        
            # check for incidental ipmo crasher: multiple #require -versions, pretest (everything to that point is fine, just won't ipmo, and catch returns zippo)
            # no, revise, it's multi-versions of -vers, not mult instances. Has to be a single version spec across entire .psm1 (and $moddir of source files)
            if($PsFilesWVers = gci $moddir -include *.ps*1 -recur | sls -Pattern $rgxRequreVersionLine){
                # only run if $PsFilesWVers populated
                $profilePsFilesVersions = $PsFilesWVers.line | %{$_.trim()} | group ;
                if($profilePsFilesVersions.count -gt 1){
                    # $PsFilesWVers| ft -auto file*,line*
                    $smsg =  "MULTIPLE #requires -version strings matched in:`n$($psm1)`n(not-permited, wrecks ipmo) - psm1 and constitutent .ps1 files:`n$(($PsFilesWVers| ft -auto file*,line*|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRet=Read-Host "Enter YYY to continue *anyway*. Anything else will exit" 
                    if ($bRet.ToUpper() -eq "YYY") {
                            Write-host "Moving on"
                    } else {
                            Throw $smsg ; 
                    } ;
                } 
            } ; 
            <#if ((get-content $psm1 | sls -Pattern $rgxRequreVersionLine | measure).count -gt 1){
                $MultReqVers = (get-content $pltXMO.name | sls -Pattern $rgxRequreVersionLine) ; 
                $smsg =  "MULTIPLE #requires -version strings in:`n$($psm1)`n(not-permited, wrecks ipmo)`n$(($multreqvers | ft -auto Pattern,LineNumber,Line|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                elseif(-not $Silent){ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Throw $smsg ; 
            } ; 
            #>
            # check for recursion call of the hosting module in subs: $rgxRequireModNested
            if($PsFilesWNestedMod = gci $moddir -include *.ps*1 -recur | sls -Pattern $rgxRequireModNested){
                # only run if $PsFilesWNestedMod populated, and unique single entry of matches, trimmed
                $profilePsFilesRecursive = $PsFilesWNestedMod.line | %{$_.trim()} | group ;
                if($profilePsFilesRecursive.count -gt 0){
                    # $PsFilesWNestedMod| ft -auto file*,line*
                    $smsg =  "RECURSIVE #requires strings matched in:"
                    $smsg += "`n$($psm1)`n(not-permited, wrecks ipmo) - psm1 and constitutent .ps1 files:"
                    $smsg += "`nEDIT OUT any #requires -Modules line spec'ing '$($ModName) !'"
                    $smsg += "`nOR THIS MODULE BUILD WILL CRASH AND REQUIRE REVISION ROLLBACK!" 
                    $smsg += "`n$(($PsFilesWNestedMod| ft -auto file*,line*|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRet=Read-Host "Enter YYY to continue *anyway*. Anything else will exit" 
                    if ($bRet.ToUpper() -eq "YYY") {
                            Write-host "Moving on"
                    } else {
                            Throw $smsg ; 
                    } ;
                } 
            } ; 


            $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'; Verbose = $($VerbosePreference -eq 'Continue') } ;
            $pltXpsd1M=[ordered]@{path=$psd1M ; ErrorAction='STOP'; Verbose = $($VerbosePreference -eq 'Continue') } ; 

            $smsg = "Import-PowerShellDataFile w`n$(($pltXpsd1M|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $PsdInfoPre = Import-PowerShellDataFile @pltXpsd1M ;
            $smsg = "test-ModuleManifest w`n$(($pltXpsd1M|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $TestReport = test-modulemanifest @pltXpsd1M ;
            if($? ){ 
                $smsg= "(Test-ModuleManifest:PASSED)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $ModuleName = $TestReport.Name ; 
            } 
            
            switch ($Method) {

                'Fingerprint' {

                    $smsg = "Module:psd1M:calculating *FINGERPRINT* change Version Step" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    #$fingerprintfile = get-childitem -path "$($ModDirPath)\fingerprint*" -ea 0 | select -expand fullname ; 
                    if($fingerprintfile = ($moddirfiles|?{$_.name -eq "fingerprint"}).FullName){
                        $oldfingerprint = Get-Content $fingerprintfile ; 
                
                        if($psm1){
                            $pltXMO.Name = $psm1 # ipmo via full path to .psm1
                            
                            $smsg = "import-module w`n$(($pltXMO|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            import-module @pltXMO ;

                            $commandList = Get-Command -Module $ModuleName # gcm doesn't support full path to module .psm1 
                            $rgxFuncDeclare = '(^|((\s)*))Function\s+[\w-_]+\s+((\(.*)*)\{' ;  # supports opt inline param syntax as well; and func names made from [A-Za-z0-9-_]chars
                            $rawfunccount = get-childitem -path $psm1 | select-string -pattern $rgxFuncDeclare |  measure | select -expand count  ; 
                            <# 8:52 AM 5/18/2022 issue:
                                get-command -module verb-io is only returning the 3 renamed funcs 
                                gcm invoke-com*

                                CommandType     Name                                               Version    Source                                                                                                                                                                                                      
                                -----------     ----                                               -------    ------                                                                                                                                                                                                      
                                Function        Invoke-CommandAs                                   2.2        Invoke-CommandAs                                                                                                                                                                                            
                                Cmdlet          Invoke-Command                                     3.0.0.0    Microsoft.PowerShell.Core                                                                                                                                                                                   
                                Cmdlet          Invoke-CommandInDesktopPackage                     2.0.0.0    Appx    

                                 detect and redir the build process into step:BUILD, as the above completely breaks the fingerprint-based step process
                                 Otherwise it under revs the build.
                            #>
                            # use Select-String regex parse to prxy count # of funcs that roughly should come back from gcm w/in $ASTMatchThreshold
                            if( ($commandList.count / $rawfunccount) -lt $ASTMatchThreshold ){
                                $smsg = "get-command failed to return a complete Func/Alias list from $($ModuleName) -lt AST $($ASTMatchThreshold * 100)% match:" ; 
                                $smsg += "`nAST profile (get-FunctionBlocks+get-AliasAssignsAST) returned:$($ASTCmds.count)"
                                $smsg += "`nFORCING STEP EVAL INTO 'PATCH' TO WORK AROUND BUG" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                $MinVersionIncrement = $true ; 
                            } else { 
                                $smsg = "get-command $($ModuleName) -gt AST $($ASTMatchThreshold * 100)% match:" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            } ;
                            <# AST based approach - dirt slow, adds 3min wait to the build process better to regex sls out the functions and use that as a guage ^
                            # -----------
                            #if(( ($commandList.count / $rawfunccount) -lt $ASTMatchThreshold ) -AND (get-command get-FunctionBlocks) -AND (get-command get-AliasAssignsAST)){
                                $smsg = "(ASTprofile: get-FunctionBlocks $($ModuleName)..." ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                #$ASTfuncs = get-FunctionBlocks $ModuleName ; 
                                $ASTcmds = @() ; 
                                $ASTProfile = get-codeprofileast -path 'C:\sc\verb-IO\verb-IO\verb-IO.psm1' -Functions -aliases -verbose:$($VerbosePreference -eq "Continue")  ;
                                $ASTCmds = $ASTProfile.Functions.name ; 
                                $ASTCmds += $ASTProfile.Aliases.extent.text ; 
                                $diffCount = $ASTCmds.count - $commandList.name.count ;
                                $diffPerc = $commandList.name.count / $ASTCmds.count ; ;
                                if($diffPerc -lt $ASTMatchThreshold ){
                                    $smsg = "get-command failed to return a complete Func/Alias list from $($ModuleName) -lt AST $($ASTMatchThreshold * 100)% match:" ; 
                                    $smsg += "`nAST profile (get-FunctionBlocks+get-AliasAssignsAST) returned:$($ASTCmds.count)"
                                    $smsg += "`nFORCING STEP EVAL INTO 'PATCH' TO WORK AROUND BUG" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    $MinVersionIncrement = $true ; 
                                } else { 
                                    $smsg = "get-command $($ModuleName) -gt AST $($ASTMatchThreshold * 100)% match:" ; 
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                } ;

                            } else { 
                                $smsg = "Unable to gcm get-FunctionBlocks & get-AliasAssignsAST!" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                throw $smsg ;
                            } ;
                            # -----------
                            #>

                            
                            $pltXMO.Name = $ModuleName; # have to rmo using *basename*
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

                            # step-ModuleVersion supports -By: "Major", "Minor", "Build","Patch"
                            # SemVers uses 3-digits, a prerelease tag and a build meta tag (only 3 are used in pkg builds etc)
                            $bumpVersionType = 'Patch' ; 
                            if($MinVersionIncrement){
                                $smsg = "-MinVersionIncrement override specified: incrementing by min .$($MinVersionIncrementBump)" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                #$Version.Build ++ ;
                                #$Version.Revision = 0 ; 
                                # drop through min patch rev above - no, it now uses $MinVersionIncrementBump
                            } else { 
                                # KM's core logic code:
                                $smsg = "Detecting new features" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                # yank out the pipeline drops (or accumulate them)
                                $NewChgs = $BreakChgs =@() ; 
                                $fingerprint | Where {$_ -notin $oldFingerprint } | 
                                    ForEach-Object {$bumpVersionType = 'Minor'; $NewChgs += "`n  $_"} ; 
                                $smsg = "Detecting breaking changes" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $oldFingerprint | Where {$_ -notin $fingerprint } | 
                                    ForEach-Object {$bumpVersionType = 'Major'; $BreakChgs += "`n  $_"} ; 
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

                        if($fingerprintfile){
                            write-verbose "(backup-FileTDO -path $($fingerprintfile))" ;
                            $fingerprintBU = backup-FileTDO -path $fingerprintfile -showdebug:$($showdebug) -whatif:$($whatif) ;
                            if(-not $FingerprintBU -AND -not $whatif){throw "backup-FileTDO -Source $($fingerprintfile)!" }
                        } else { 
                           write-verbose "(no fingerprint file to backup)" ;  
                        } ; 

                        $pltOFile=[ordered]@{Encoding='utf8' ;FilePath=(join-path -path $moddir -childpath 'fingerprint') ;whatif=$($whatif) ; Verbose = $($VerbosePreference -eq 'Continue') } ;
                        $smsg = "Writing fingerprint: Out-File w`n$(($pltOFile|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $fingerprint | out-file @pltOFile ; 
                    } else {
                        $smsg = "No funtional Module `$fingerprint generated for path specified`n$($Path)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ; 
                } 
                'Percentage' {
                    # implement's Martin Pugh's revision step code on percentage of files changed after psd1.LastWriteTime
                    $smsg = "Module:psd1M:calculating *PERCENTAGE* change Version Step" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    $LastChange = (Get-ChildItem $psd1M).LastWriteTime ; 
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
                        write-host -foregroundcolor green "-MinVersionIncrement override specified: incrementing by min:$($MinVersionIncrementBump)" ; 
                        #$Version.Build ++ ;
                        #$Version.Revision = 0 ; 
                        $bumpVersionType = $MinVersionIncrementBump  ; 
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
                $pltStepMV=[ordered]@{Path=$psd1M ; By=$bumpVersionType ; ErrorAction='STOP';} ; 

                $smsg = "Step-ModuleVersion w`n$(($pltStepMV|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if(!$whatif){
                    # Step-ModuleVersion -Path $env:BHPSModuleManifest -By $bumpVersionType ; 
                    Step-ModuleVersion @pltStepMV ; 
                    $PsdInfo = Import-PowerShellDataFile -path $env:BHPSModuleManifest ;
                    $smsg = "----PsdVers incremented from $($PsdInfoPre.ModuleVersion) to $((Import-PowerShellDataFile -path $env:BHPSModuleManifest).ModuleVersion)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                } else {
                    $smsg = "(-whatif, skipping exec:`nStep-ModuleVersion -Path $($env:BHPSModuleManifest) -By $($bumpVersionType)) ;" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
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

Step-ModuleVersion -Path $($psd1M) -By $($bumpVersionType)

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
            elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $smsg = "Minor/New-Feature Chgs:`n$(($NewChgs |out-string).trim())`n`nMajor/Removal/Breaking Chgs:`n$(($BreakChgs |out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

            if($PsdInfo -AND $applyChange ){ 
                $smsg = "(returning updated ManifestPsd1 Content to pipeline)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $PsdInfo | write-output 
            } else {
                $smsg = "-applyChange *not* specified, returning 'bumpVersionType' specification to pipeline:" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #$PsdInfo.ModuleVersion | write-output 
                 $bumpVersionType | write-output  ; 
            } ; 

        } else {
            $smsg = "Unable to generate a 'bumpVersionType' for path specified`n$($Path)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $false | write-output  ; 
        } ; 

        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        elseif(-not $Silent){ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;  # END-E
}

#*------^ Step-ModuleVersionCalculated.ps1 ^------