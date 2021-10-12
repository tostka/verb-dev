#Initialize-ModuleFingerprint.ps1

#*------v Function Initialize-ModuleFingerprint  v------
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
    * 7:41 PM 10/11/2021 cleaned up rem'd requires
    * 9:08 PM 10/9/2021 init version
    .DESCRIPTION
    Initialize-ModuleFingerprint.ps1 - Profile a specified module and summarize commands into a semantic-version 'fingerprint'.
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

        $sBnr="#*======v RUNNING :$($CmdletName) v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;

        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            write-host "profiling existing content..."

            $modname = split-path $path -leaf ;
            $moddir = gi -Path $path;
            $moddirfiles = gci -path $moddir.FullName -recur ;
            #write-verbose "Module:PSM1:confirm/validate existing" ; 
            if($moddirfiles.name -contains "$modname.psm1"){
                $psm1 = $moddirfiles|?{$_.name -eq "$modname.psm1"} ; 
                import-module -force $psm1.fullname -ErrorAction STOP ;

                $commandList = Get-Command -Module $modname
                #Remove-Module $modname
                remove-module -force ((split-path $psm1.fullname -leaf).replace('.psm1','')) ; 

                write-host  'Calculating fingerprint'
                $fingerprint = foreach ( $command in $commandList ){
                    foreach ( $parameter in $command.parameters.keys ){
                        '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                        $command.parameters[$parameter].aliases | 
                            Foreach-Object { '{0}:{1}' -f $command.name, $_}
                    };  # loop-E  parameters
                } ;  # loop-E commands     

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
} ; 
#*------^ END Function Initialize-ModuleFingerprint ^------