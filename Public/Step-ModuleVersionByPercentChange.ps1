#Step-ModuleVersionByPercentChange.ps1

#*------v Function Step-ModuleVersionByPercentChange  v------
function Step-ModuleVersionByPercentChange {
    <#
    .SYNOPSIS
    Step-ModuleVersionByPercentChange.ps1 - Profile a fresh revision of specified module for changes compared to percentage file changes after the .psd1 Manifest file's current date.
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
    AddedCredit : Martin Pugh (revision code on file change percent)
    AddedWebsite: www.thesurlyadmin.com
    AddedTwitter: @thesurlyadm1n
    REVISIONS
    * 10:28 PM 10/9/2021 init version
    .DESCRIPTION
    Step-ModuleVersionByPercentChange.ps1 - Profile a fresh revision of specified module for changes compared to percentage file changes after the .psd1 Manifest file's current date.
    .PARAMETER Path
    Path to .psm1-hosting directory of the Module[-path 'C:\sc\PowerShell-Statistics\Statistics' ]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> Step-ModuleVersionByPercentChange -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
    Fingerprint the specified module path, with whatif and verbose specified
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    #>
    ##Requires -Version 2.0
    #Requires -Version 3
    ##requires -PSEdition Desktop
    ##requires -PSEdition Core
    ##Requires -PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
    ##Requires -Modules ActiveDirectory, AzureAD, MSOnline, ExchangeOnlineManagement, verb-AAD, verb-ADMS, verb-Auth, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Network, verb-Text
    ##Requires -Modules ActiveDirectory, AzureAD, MSOnline, ExchangeOnlineManagement, MicrosoftTeams, SkypeOnlineConnector, Lync,  verb-AAD, verb-ADMS, verb-Auth, verb-Azure, VERB-CCMS, verb-Desktop, verb-dev, verb-Ex2010, verb-EXO, verb-IO, verb-logging, verb-Mods, verb-Network, verb-L13, verb-SOL, verb-Teams, verb-Text, verb-logging
    #Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
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
        
        # stock buildhelper e-varis - I don't even see it in *use*
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(executing:Get-BuildEnvironment -Path $($ModDirPath) `n(use -NoBuildInfo if hangs))" ; 
        $BuildVariable = Get-BuildVariable -path $Path 
    
    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            write-host "profiling existing content..."

            $modname = split-path $path -leaf ;
            $moddir = gi -Path $path;
            $moddirfiles = gci -path $moddir.FullName -recur ;

            if($moddirfiles.name -contains "$modname.psd1"){
                $psd1 = $moddirfiles|?{$_.name -eq "$modname.psd1"} ; 
            } else { 
                throw "Unable to locate Manifest .psd1 file!" ; 
            } ; 

            $propsTstModMani = 'ModuleType','Version','Name','ExportedCommands'
           
            if([boolean]$hasPSD1 = (test-path $psd1.fullname)){
                $psd1Profile = Test-ModuleManifest -Path $psd1.fullname -ErrorAction STOP ;
                if($? ){ 
                    $smsg= "(existing:Test-ModuleManifest:PASSED)`n$(($psd1Profile|ft -a $propsTstModMani|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug 
                    else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
            } else { 
                throw "Unable to Test-Path $($psd1)!"
            } ; 

            write-verbose "Load existing Manifest,`n& profile changes since it's file LastWriteTime`n(to determine Version increments)" ; 
            <# .psd1 content: (common, non-rem'd)
                $data = Import-PowerShellDataFile -path 'C:\sc\PowerShell-Statistics\Statistics\Statistics.psd1' ;
                $data ; 
                     Name                           Value
                    ----                           -----
                    Copyright                      (c) 2017 Nicholas Dille. All rights reserved.
                    PrivateData                    {PSData}
                    Description                    Statistical analysis of data in the console window. For example this module can generate a histogram (Get...
                    CompanyName
                    PowerShellVersion              5.0
                    FunctionsToExport              {New-RangeString, Get-ExampleTimeSeries, Add-Bar, ConvertFrom-PerformanceCounter...}
                    Author                         Nicholas Dille
                    GUID                           d5add589-39c5-4f5a-a200-ba8258085bc9
                    RootModule                     Statistics.psm1
                    VariablesToExport
                    AliasesToExport                {ab, cfpc, cfpt, edt...}
                    ModuleVersion                  1.2.0
                    FormatsToProcess               {HistogramBucket.Format.ps1xml, HistogramBar.Format.ps1xml}
                    CmdletsToExport

                $data.privatedata.psdata
                    Name                           Value
                    ----                           -----
                    LicenseUri                     https://github.com/nicholasdille/PowerShell-Statistics/blob/master/LICENSE
                    Tags                           {Math, Mathematics, Statistics, Histogram}
                    ProjectUri                     https://github.com/nicholasdille/PowerShell-Statistics
                    ReleaseNotes                   https://github.com/nicholasdille/PowerShell-Statistics/releases
            #>
            if($hasPSD1){
               

                # switch to update-modulemanfiest, where existing, instead. 
                $LastChange = (Get-ChildItem $psd1.fullname).LastWriteTime ; 
                $ChangedFiles = ($moddirfiles | Where LastWriteTime -gt $LastChange).Count ; 
                $PercentChange = 100 - ((($moddirfiles.Count - $ChangedFiles) / $moddirfiles.Count) * 100) ; 
                write-verbose "PercentChange:$($PercentChange)" ; 
                #$Version = ([version]$Psd1PriorData.ModuleVersion) | Select Major,Minor,Build,Revision ; 
                # coerce Build & Revision:-1 to 0, handling; doesn't like it when rev is -1
                #$Version = ([version]$Psd1PriorData.ModuleVersion) | select Major,Minor,Build,@{name='Revision';Expression={[System.Math]::Max($_.revision,0)} }
                $Version = ([version]$Psd1PriorData.ModuleVersion) | select Major,Minor,
                    @{name='Build';Expression={[System.Math]::Max($_.Build,0)} },
                    @{name='Revision';Expression={[System.Math]::Max($_.revision,0)} }
                $PriorVers =  $Version | Select Major,Minor,Build,Revision

                <# fingerprint switching
                $bumpVersionType = 'Patch' ; 
                write-host 'Detecting new features' ; 
                $fingerprint | Where {$_ -notin $oldFingerprint } | 
                    ForEach-Object {$bumpVersionType = 'Minor'; "  $_"} ; 
                write-host 'Detecting breaking changes' ; 
                $oldFingerprint | Where {$_ -notin $fingerprint } | 
                    ForEach-Object {$bumpVersionType = 'Major'; "  $_"} ; 
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
                #$pltVerbManifest.ModuleVersion = "$($Version.Major,$Version.Minor,$Version.Build,$Version.Revision -join '.')"
                #"$($Version.Major).$($Version.Minor).$($Version.Build).$($Version.Revision)" ; 
                #$priorVstring = "$($PriorVers.Major,$PriorVers.Minor,$PriorVers.Build,$PriorVers.Revision -join '.')"
                #"$($PriorVers.Major).$($PriorVers.Minor).$($PriorVers.Build).$($PriorVers.Revision)" ;
                #write-verbose "Incremented Revision:$($priorVstring)=>$($pltVerbManifest.ModuleVersion.tostring())" ; 
                <# can also pull the rev out via:
                    $psd1Profile = Test-ModuleManifest -path $ModPsdPath  ; 
                    $psd1Vers = $psd1Profile.Version.tostring() ; 
                #>
                <# alt buildhelpers use
                write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(executing:Get-BuildEnvironment -Path $($ModDirPath) `n(use -NoBuildInfo if hangs))" ; 
                $BuildVariable = Get-BuildVariable -path $ModDirPath 
                $buildvariable ; 
                    BuildSystem   : Unknown
                    ProjectPath   : C:\sc\PowerShell-Statistics\
                    BranchName    : master
                    CommitMessage : updated cbh to reflect conversion from .md to CBH help (to get get-help to function properly).
                                    * 4:03 PM 7/20/2021 all mod cmdlets: converted external .md-based docs into CBH (wasn't displaying get-help for cmds when published & installed)
                    CommitHash    : b40abe5df960ec3c8e41e4bf85185e399245185e
                    BuildNumber   : 0
                Step-ModuleVersion -Path $($ModPsdPath) -by minor
                #>

            } else { 
   
                throw "Unable to locate a .psd1 file for module!" ; 
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
    
        if ( $bumpVersionType){
            
            $hMsg =@"

Percent Change analysis since PSD1 lastwritetime recommends ModuleVersion Step:$($bumpVersionType). 

This can be implemented with the following command:

Step-ModuleVersion -Path $($psd1.fullname) -By $($bumpVersionType)

(the above will use the BuildHelpers module to update the revision stored in the Manifest .psd1 file for the module).
"@ ; 
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):`n$($hmsg)" ; 


        } else {
            throw " Unable to generate a bumpVersionType for path specified`n$($Path)" ; 
        } ; 
    
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    } ;  # END-E
} ; 
#*------^ END Function Step-ModuleVersionByPercentChange ^------