#*------v import-ModuleRevised.ps1 v------
function import-ModuleRevised {
    <#
    .SYNOPSIS
    import-ModuleRevised - Dynamically load any revised module 'Public' source .ps1, as identified as (LastWriteTime -gt RequiredVersion.pkg.LastWriteTime)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : import-ModuleRevised
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 12:11 PM 5/25/2022 init
    .DESCRIPTION
    import-ModuleRevised - Dynamically load any revised module 'Public' source .ps1, as identified as (LastWriteTime -gt RequiredVersion.pkg.LastWriteTime)
    Quick, 'reload my current efforts for testing' import-module wrapper, that isolates most recent revised .\Public folder .ps1's, for the specified module, and ipmo -force -verbose imports them, for debugging. 
    Assumes that module source files are in following tree structure (example for the Verb-IO module):

    ```text
    C:\SC\VERB-IO
    ├───Internal
    │       [Internal 'non'-exported cmdlet files].ps1 
    ├───Package
    │       verb-io.2.0.3.nupkg # RequiredRevision nupkg file location and name-structure
    ├───Public
    │       [Public exported cmdlet files].ps1
    └───verb-IO
        │   verb-IO.psd1 # module Manifest psd1
        │   verb-IO.psm1 # module .psm1 file
    ```
    .PARAMETER Name
    Module Name to have revised Public source directory import-module'd[-PARAM SAMPLEINPUT]
    PARAMETER RequiredVersion
    Required module .pkg file version to be used as filter date  for determining 'revised' public cmdlets[-RequiredVersion '2.0.3']
    PARAMETER ExplicitTime
    Explicit timestamp to be used for 'Revised' Public .ps1 cmdlet filtering[-ExplicitTime (get-date).adddays(-14)]
    .EXAMPLE
    PS> import-ModuleRevised -Name verb-io -RequiredVersion '2.0.3' -verbose
    Manually ipmo any Public cmdlet .ps1 for the source directory of verb-io, dated after the locally stored nupkg file for Version 2.0.3
    .EXAMPLE
    PS> import-ModuleRevised -Name verb-io -ExplicitTime (get-date).adddays(-14) -verbose
    Manually ipmo any Public cmdlet .ps1 for the source directory of verb-io, dated in the last 14 days (as specified via -ExplicitTime parameter).
    .EXAMPLE
    PS> import-ModuleRevised -Name 'verb-io','verb-dev' -ExplicitTime (get-date).adddays(-14) -verbose ;
    Ipmo both verb-io and verb-dev, against revisions -ExplicitTime'd 14days prior.
    .LINK
    https://github.com/tostka/verb-dev
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding(DefaultParameterSetName='Version')]
    #[Alias('iIseBpAll')]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Module Name to have revised Public source directory import-module'd[-PARAM SAMPLEINPUT]")]
        [ValidateNotNullOrEmpty()]
        #[Alias('ALIAS1', 'ALIAS2')]
        [string[]]$Name,
        [Parameter(ParameterSetName='Version',HelpMessage="Required module .pkg file version to be used as filter date  for determining 'revised' public cmdlets[-RequiredVersion '2.0.3']")]
        [version] $RequiredVersion,
        [Parameter(ParameterSetName='Date',HelpMessage="Explicit timestamp to be used for 'Revised' Public .ps1 cmdlet filtering[-ExplicitTime (get-date).adddays(-14)]")]
        [datetime] $ExplicitTime,
        [Parameter(HelpMessage="Switch to load Internal commands (along with 'Public' commands)[-whatIf]")]
        [switch] $Internal
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;

        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 
        if( $RequiredVersion -AND ($Name -is [system.array])){
            $smsg = "An array of -Name (modules) values was specified"
            $smsg += "`nalong with a -RequiredVersion specification:"
            $smsg += "`nThis command can use a generic ExplicitTime filter across multiple modules,"
            $smsg += "`nbut *cannot* use a single -RequiredVersion across multiple modules!"
            $smsg += "`nPlease rerun the command, specifying either a *non-Array* for -Name, or a generic -ExplicitTime to filter target command revisions"
            write-warning $smsg ; 
            throw $smsg ; 
            Break ; 
        } ; 
    }
    PROCESS {
        foreach ($item in $Name){
            $sBnrS="`n#*------v PROCESSING : $($item) v------" ; 
            write-host -foregroundcolor green $sBnrS ;

            $error.clear() ;
            TRY{
                [string]$ModRoot = gi c:\sc\$item ;
                [string[]]$revisedcommands = @() ; 
                if($RequiredVersion){
                    [system.io.fileinfo]$targetPkg = (Resolve-Path "$modroot\Package\*$($RequiredVersion.ToString()).nupkg").path ;
                    $cutDate = $targetPkg.lastwritetime ; 
                } elseif($ExplicitTime){
                    $cutDate = $ExplicitTime ; 
                } else {
                    write-warning "Neither -RequiredVersion nor -ExplicitTime specified: Please specify one or the other)" ; 
                    Break ; 
                }; 
                $revisedcommands = (gci $ModRoot\public\*.ps1 | ? LastWriteTime -gt  $cutDate).fullname ; 
                if($Internal){
                    $revisedcommands += (gci $ModRoot\Internal\*.ps1 | ? LastWriteTime -gt  $cutDate).fullname ; 
                } 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ; 
            if ($revisedcommands){
                write-host "ipmo -force -verbose '$(($revisedcommands -join "', '"|out-string).trim())'" ; 
                TRY{
                    # always verbose: we're debugging new revs on the fly
                    import-module -force -verbose $revisedcommands ; 
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$($smsg)" } ;
                    Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                } ; 
            } else {  
                $smsg = "No Revised $($item): cmdlets detected (post $((get-date $cutDate.lastwritetime -format 'yyyyMMdd-HHmmtt')))" 
                write-host $smsg ;
            };
            write-host -foregroundcolor green $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ;  # loop-E $items in $NaME
    } # PROC-E
    END{
        write-host -foregroundcolor green $sBnr.replace('=v','=^').replace('v=','^=') ; 
    } ;
}
#*------^ import-ModuleRevised.ps1 ^------