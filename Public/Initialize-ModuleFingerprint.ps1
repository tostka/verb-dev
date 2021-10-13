#*------v Initialize-ModuleFingerprint.ps1 v------
function Initialize-ModuleFingerprint {
    <#
    .SYNOPSIS
    Initialize-ModuleFingerprint.ps1 - Profile a specified module and summarize commands into a semantic-version 'fingerprint'.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-09
    FileName    : 
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : Kevin Marquette
    AddedWebsite: https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    AddedTwitter: 
    REVISIONS
    * 12:36 PM 10/13/2021 added else block to catch mods with inconsistent names between root dir, and .psm1 file, (or even .psm1 location); upgraded catchblock to curr std; added splats and verbose echos for debugging outlier processing errors
    * 7:41 PM 10/11/2021 cleaned up rem'd requires
    * 9:08 PM 10/9/2021 init version
    .DESCRIPTION
    Initialize-ModuleFingerprint.ps1 - Profile a specified module and summarize commands into a semantic-version 'fingerprint'.
    Rounded out the sample logic KM posted on the above site, along with matching processing function: Step-ModuleVersionCalculated
    .PARAMETER Path
    Path to .psm1-hosting directory of the Module[-path 'C:\sc\PowerShell-Statistics\Statistics' ]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    .EXAMPLE
    PS> Initialize-ModuleFingerprint -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
    Fingerprint the specified module path, with whatif and verbose specified
    .EXAMPLE
    $whatif = $true ;
    foreach($mod in $mods){
        if(test-path "$($mod)\fingerprint"){write-host -fore green "---`nPRESENT:$($mod)\fingerprint`n```" }
        else {Initialize-ModuleFingerprint -path $mod -whatif:$($whatif) -verbose} ;
    } ;
    Sample code to process list of module root directory paths and initialize fingerprints in the dirs currently lacking the files.
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    #>
    #Requires -Version 3
    #Requires -RunasAdministrator
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("(lyn|bcc|spb|adl)ms6(4|5)(0|1).(china|global)\.ad\.toro\.com")][ValidateSet("USEA","GBMK","AUSYD")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)][ValidateCount(1,3)]
    [CmdletBinding()]
    ###[Alias('Alias','Alias2')]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to .psd1-hosting directory of the Module[-path 'C:\sc\PowerShell-Statistics\Statistics' ]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN { 
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;

        $sBnr="#*======v RUNNING :$($CmdletName):$($Path) v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;

        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            write-host "profiling existing content..."

            if( ($path -like 'BounShell') -OR ($path -like 'VERB-transcript')){
                write-verbose "GOTCHA!" ;
            } ; 

            $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'} ;
            $modname = split-path $path -leaf ;
            $moddir = gi -Path $path;

            $pltGCI=[ordered]@{path=$moddir.FullName ;recurse=$true ; ErrorAction='STOP'} ;
            write-verbose "gci w`n$(($pltGCI|out-string).trim())" ; 
            $moddirfiles = gci @pltGCI ;
            # Accomodate modules in non-standard name schemes: Statistics.psm1 root folder isn't named 'Statistics', it's named: 'PowerShell-Statistics', 
            # failthrough & recheck for *any* .psm1 in the $moddirfiles and (ensure it's not an array)
            if($psm1 = $moddirfiles|?{$_.name -eq "$modname.psm1"} ){
                write-verbose "located `$psm1:$($psm1)" ; 
            } elseif($psm1 = $moddirfiles|?{$_.name -like "*.psm1"} ){
                write-verbose "fail-thru located `$psm1:$($psm1)" ; 
            } ; 
            if($psm1){
                if($psm1 -is [system.array]){
                    throw "`$psm1 resolved to multiple .psm1 files in the module tree!" ; 
                } ; 
                # regardless of root dir name, the .psm1 name *is* the name of the module, use it for ipmo/rmo's
                $psm1Basename = ((split-path $psm1.fullname -leaf).replace('.psm1','')) ; 
                if($modname -ne $psm1Basename){
                    $smsg = "Module has non-standard root-dir name`n$($moddir.fullname)"
                    $smsg += "`ncorrecting `$modname variable to use *actual* .psm1 basename:$($psm1Basename)" ; 
                    write-warning $smsg ; 
                    $modname = $psm1Basename ; 
                } ; 
                $pltXMO.Name = $psm1.fullname # load via full path to .psm1
                write-verbose "import-module w`n$(($pltXMO|out-string).trim())" ; 
                import-module @pltXMO ;
                $commandList = Get-Command -Module $modname ;
                $pltXMO.Name = $psm1Basename ; # have to rmo using *basename*
                write-verbose "remove-module w`n$(($pltXMO|out-string).trim())" ; 
                remove-module @pltXMO ;

                write-host  'Calculating fingerprint...'
                # KM's core logic code:
                $fingerprint = foreach ( $command in $commandList ){
                    write-verbose "(=cmd:$($command)...)" ;
                    foreach ( $parameter in $command.parameters.keys ){
                        write-verbose "(---param:$($parameter)...)" ;
                        '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                        $command.parameters[$parameter].aliases | 
                            Foreach-Object { '{0}:{1}' -f $command.name, $_}
                    };  
                } ;   

            } else {
                throw "No module .psm1 file found in `$path:`n$(join-path -path $moddir.fullname -child "$modname.psm1")" ;
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
            $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ; 
    } ;  # PROC-E
    END {
        if ( $fingerprint ){
            $pltOFile=[ordered]@{Encoding='utf8' ;FilePath=(join-path -path $moddir.fullname -childpath 'fingerprint') ;whatif=$($whatif) ;} ; 
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Out-File w`n$(($pltOFile|out-string).trim())" ; 
            $fingerprint | out-file @pltOFile ; 
        } else {
            write-warning "$((get-date).ToString('HH:mm:ss')):No funtional Module `$fingerprint generated for path specified`n$($Path)" ; 
        } ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    } ;  # END-E
}

#*------^ Initialize-ModuleFingerprint.ps1 ^------