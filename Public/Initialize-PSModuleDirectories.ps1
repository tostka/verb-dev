# Initialize-PSModuleDirectories.ps1
#*------v Function Initialize-PSModuleDirectories v------
Function Initialize-PSModuleDirectories {
    <#
    .SYNOPSIS
    Initialize-PSModuleDirectories.ps1 - Initialize PS Module Directories
    .NOTES
    Version     : 3.4.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-04-26
    FileName    : Initialize-PSModuleDirectories.ps1
    License     : (None Asserted)
    Copyright   : (None Asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell, development, Module
    AddedCredit : Jeff Hicks
    AddedWebsite: https://www.powershellgallery.com/packages/ISEScriptingGeek/3.4.1
    AddedTwitter: 
    REVISIONS
    * 12:23 PM 8/7/2024 removed erroneous [ValidateScript( {Test-Path $_})] from $DefaultModDirs param
    * 12:18 PM 10/12/2023 correct .\Resources -> Resource that's in use 
    * 11:21 AM 10/3/2023 added LICENSES & LIBS & RESOURCES to DefaultModDirs
   * 9:35 AM 5/9/2022 init, split out from merge/unmerge-module, have a single maintainable func, rather than trying to sync the variants
    .DESCRIPTION
    Initialize-PSModuleDirectories.ps1 - Initialize PS Module Directories
    DEFAULT - DIRS CREATION - git doesn't reproduce empty dirs, create if empty (avoids errors later)
    exempt the .git & .vscode dirs, we don't publish those to modules dir
    .PARAMETER ModuleSourcePath
    Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]
    ModuleDestinationPath
    Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]
    DefaultModDirs
    Array of new module subdirectory names to be created
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $pltInitPsMDirs=[ordered]@{
        ModuleSourcePath=$ModuleSourcePath ;
        ModuleDestinationPath=$ModuleDestinationPath ;
        ErrorAction="Stop" ;
        whatif=$($whatif);
    } ;
    $smsg= "Initialize-PSModuleDirectories w`n$(($pltInitPsMDirs|out-string).trim())" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    TRY {
        $sRet = Initialize-PSModuleDirectories @pltInitPsMDirs ;
        if(sRet.split(';') -contains "new-item:ERROR"){
            $smsg = "Initialize-PSModuleDirectories:new-item:ERROR!"  ;
            write-warning $smsg ; 
            throw $smsg ;
        } ; 
    } CATCH {
        $PassStatus += ";ERROR";
        write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Exit ;
    } ;
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]")]
            [array] $ModuleSourcePath,
            [Parameter(Mandatory = $True, HelpMessage = "Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]")]
        [string] $ModuleDestinationPath,
        [Parameter(HelpMessage = "Array of new module subdirectory names to be created")]
            [string[]]$DefaultModDirs = @('Public','Internal','Classes','Libs','Tests','Licenses','Resource','Docs','Docs\Cab','Docs\en-US','Docs\Markdown'),
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    )
    BEGIN { 
        #region CONSTANTS-AND-ENVIRO #*======v CONSTANTS-AND-ENVIRO v======
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        write-verbose  "`$PSBoundParameters:`n$(($PSBoundParameters|out-string).trim())" ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 

    } ;  # BEGIN-E
    PROCESS {
        $Error.Clear() ; 
        # call func with $PSBoundParameters and an extra (includes Verbose)
        #call-somefunc @PSBoundParameters -anotherParam
        
        # - Pipeline support will iterate the entire PROCESS{} BLOCK, with the bound - $array - 
        #   param, iterated as $array=[pipe element n] through the entire inbound stack. 
        # $_ within PROCESS{}  is also the pipeline element (though it's safer to declare and foreach a bound $array param).
        
        # - foreach() below alternatively handles _named parameter_ calls: -array $objectArray
        # which, when a pipeline input is in use, means the foreach only iterates *once* per 
        #   Process{} iteration (as process only brings in a single element of the pipe per pass) 
        
        foreach($Dir in $DefaultModDirs){
            
            # put your real processing in here, and assume everything that needs to happen per loop pass is within this section.
            # that way every pipeline or named variable param item passed will be processed through. 
            $tPath = join-path -path $ModuleRootPath -ChildPath $Dir ;
            if(-not (test-path -path $tPath)){
                $pltDir = [ordered]@{
                    path     = $tPath ;
                    ItemType = "Directory" ;
                    ErrorAction="Stop" ;
                    whatif   = $($whatif) ;
                } ;
                $smsg = "Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $error.clear() ;
                $bRetry=$false ;
                TRY {
                    new-item @pltDir | out-null ;
                    $PassStatus += ";new-item:UPDATED";
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";new-item:ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" }
                    $bRetry=$true ;
                } ;
                if($bRetry){
                    $pltDir.add('force',$true) ;
                    $smsg = "Retry:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $error.clear() ;
                    TRY {
                        new-item @pltDir | out-null ;
                        $PassStatus += ";new-item:UPDATED";
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";new-item:ERROR";
                        $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $bRetry=$false ;
                        EXIT #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                    } ;
                } ;
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
#*------^ END Function Initialize-PSModuleDirectories  ^------
