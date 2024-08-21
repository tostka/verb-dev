# Uninstall-ModuleForce.ps1
#*------v Function Uninstall-ModuleForce v------
Function Uninstall-ModuleForce {
    <#
    .SYNOPSIS
    Uninstall-ModuleForce.ps1 - Uninstalls a module (via Uninstall-Module -force), and then searches through all PSModulePath directories, and deletes any unregistered copies as well.
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-10
    FileName    : Uninstall-ModuleForce.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Module,Management,Lifecycle
    REVISIONS
    # 4:06 PM 8/21/2024 #135:empty PSModulePath entry causes this to crash out, post filter only populated!
    * 12:33 PM 1/17/2024 added RunAA pretest, and folder perms seize code
    * 10:10 AM 5/17/2022 updated post test, also don't want it to abort/break, on any single failure.
    * 11:11 AM 5/10/2022 init, split out process-NewModule #773: $smsg= "Removing existing profile $($ModuleName) content..."  block, to have a single maintainable shared func
    .DESCRIPTION
    Uninstall-ModuleForce.ps1 - Uninstalls a module (via Uninstall-Module -force), and then searches through all PSModulePath directories, and deletes any unregistered copies as well.
    Note: *installed* mods have PSGetModuleInfo.xml files
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> $pltUMF=[ordered]@{ ModuleName = $ModuleName ; Verbose = $($VerbosePreference -eq 'Continue') ; whatif=$($whatif); } ;
    PS> $smsg= "Uninstall-ModuleForce w`n$(($pltUMF|out-string).trim())" ;
    PS> if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    PS> else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    PS> $bRet = Uninstall-ModuleForce @pltUMF ;
    PS> # check return for semi-colon-delimited specific error string
    PS> if($sRet){
    PS>     if([array]$sRet.split(';').trim() -contains 'uninstall-module:ERROR'){
    PS>         # or, work with raw ;-delim'd string: if($sret.indexof('uninstall-module:ERROR')){
    PS>         $smsg = "Uninstall-ModuleForce:uninstall-module:ERRO!"  ;
    PS>         write-warning $smsg ;
    PS>         throw $smsg ;
    PS>         # spec optional Break|Continue etc recovery cmd
    PS>     } ;
    PS> } else {
    PS>     $smsg = "(no `$sRet returned on call)" ;
    PS>     if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    PS>     else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    PS> } ; 
    Demo that displays running with a splat, and parsing the return'd PassStatus for Error entries in the array
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]")]
        [string[]] $ModuleName,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    )
    BEGIN {
        #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        write-verbose -verbose:$verbose "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
        $Verbose = ($VerbosePreference -eq 'Continue') ;

        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ;
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ;
            write-verbose "(non-pipeline - param - input)" ;
        } ;
        
        if(-not(get-variable -Name whoamiAll -ea 0)){$whoamiAll = (whoami /all)} ;
        if([bool](($whoamiAll |Where-Object{$_ -match 'BUILTIN\\Administrators'}) -AND ($whoamiAll |
            Where-Object{$_ -match 'S-1-16-12288'}))){} else { 
                throw "Must be RunAsAdmin!" ; 
                BREAK ;
            } ; 
    } ;  # BEGIN-E
    PROCESS {
        $Error.Clear() ;
        # - Pipeline support will iterate the entire PROCESS{} BLOCK, with the bound - $array -
        #   param, iterated as $array=[pipe element n] through the entire inbound stack.
        # $_ within PROCESS{}  is also the pipeline element (though it's safer to declare and foreach a bound $array param).

        # - foreach() below alternatively handles _named parameter_ calls: -array $objectArray
        # which, when a pipeline input is in use, means the foreach only iterates *once* per
        #   Process{} iteration (as process only brings in a single element of the pipe per pass)

        foreach($Mod in $ModuleName){
            if($PsGInstalled=Get-InstalledModule -name $($Mod) -AllVersions -ea 0 ){
                foreach($PsGMod in $PsGInstalled){
                    $sBnrS="`n#*------v Uninstall PSGet Mod:$($PsGMod.name):v$($PsGMod.version) v------" ;
                    $smsg= $sBnrS ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $pltRmv = [ordered]@{
                        Force=$true ;
                        Whatif=$($whatif) ;
                        Verbose = $($VerbosePreference -eq 'Continue') ;
                    } ;
                    $sMsg = "Uninstall-Script w`n$(($pltRmv|out-string).trim())" ;
                    if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;} ;
                    $error.clear() ;
                    TRY {
                        get-module $PsGMod.installedlocation -listavailable |uninstall-module @pltRmv
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";uninstall-module:ERROR";
                        $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Exit #Opts: STOP(debug)|EXIT(close)|Continue(move on in loop cycle)
                    } ;
                    $smsg="$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
            } else {
                $smsg="(No:Get-InstalledModule -name $($Mod))" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;
        

            # surviving conflicts locking install-module: need to check everywhere, loop the entire $env:psprofilepath list
            $smsg="(Processing `$env:PSModulePath paths, for surviving locked copies of $($Mod) to *manually* purge...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            #$modpaths = $env:PSModulePath.split(';') ;
            # 4:06 PM 8/21/2024 empty PSModulePath entry causes this to crash out, post filter only populated!
            $modpaths = $env:PSModulePath.split(';') |?{$_} ;
            foreach($modpath in $modpaths){
                $smsg= "Checking: $($Mod) below: $($modpath)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $searchPath = join-path -path $modpath -ChildPath "$($Mod)\*.*" ;
                # adding ownership seize before removal:
                if($mPath = get-item -path (join-path -path $modpath -ChildPath $Mod) -ea 0){
                    write-host "Seizing ownership:$($mPath.fullname)..." ;
                    takeown /F $mPath.fullname /A /R ;
                    icacls $mPath.fullname /reset ;
                    icacls $mPath.fullname /grant Administrators:'F' /inheritance:d /T ;
                } ; 
                # adding -GracefulFail to get past locked verb-dev cmdlets
                $bRet = remove-ItemRetry -Path $searchPath -Recurse -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail ;
                #if (-not$bRet) {throw "FAILURE" ; Break ; } ;
                if(-not $bRet -AND -not $whatif){throw "remove-ItemRetry -Path $($searchPath)!" } else {
                    $PassStatus += ";UPDATED:remove-ItemRetry ";
                }  ;
            } ;
        } ;  # loop-E

    } ;  # PROC-E
    END {
        #$stopResults = try {Stop-transcript -ErrorAction stop} catch {} ;
        #write-host $stopResults ;
        # the $PassStatus updates should have been global, but if not, return what we have and post-test for ";new-item:ERROR"; V ";new-item:UPDATED";
        $PassStatus | write-output ;
    } ;  # END-E
} ;
#*------^ END Function Uninstall-ModuleForce  ^------
