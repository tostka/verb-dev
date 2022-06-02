#*------v get-ModuleRevisedCommands.ps1 v------
function get-ModuleRevisedCommands {
    <#
    .SYNOPSIS
    get-ModuleRevisedCommands - Dynamically located any revised module 'Public' source .ps1, as identified as (LastWriteTime -gt RequiredVersion.pkg.LastWriteTime), and return array of fullname paths to .ps1's for ipmo during revision debugging.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : get-ModuleRevisedCommands
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:33 AM 6/2/2022 as ipmo w/in a module doesn't export the results to the 
        environement, post-exec, ren import-ModuleRevised -> get-ModuleRevisedCommands, 
        and hard-code export list as sole function; set catch to continue; added 
        -ReturnList for external ipmo;  flipped pipeline array detect to test name 
        count, and not isArray (it's hard typed array, so it's always array)
    * 12:11 PM 5/25/2022 init
    .DESCRIPTION
    get-ModuleRevisedCommands - Dynamically located any revised module 'Public' source .ps1, as identified as (LastWriteTime -gt RequiredVersion.pkg.LastWriteTime), and return array of fullname paths to .ps1's for ipmo during revision debugging.
    Quick, 'reload my current efforts for testing', that isolates most recent revised .\Public folder .ps1's, for the specified module, and returns an array, to be ipmo -force -verbose, for debugging. 
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

    Notes: 
        - Supports specifying name as a semicolon-delimted string: "[moduleName];[requiredversion]", to pass an array of name/requiredversion combos for processing. 
        - ipmo -fo -verb 'C:\sc\verb-dev\public\get-ModuleRevisedCommands.ps1' ; 
    
        - In general this seems to work more effectively run with single-modules and -RequiredVersion, rather than feeding an array through with a common -ExplicitTime. 

    .PARAMETER Name
    Module Name to have revised Public source directory import-module'd. Optionally can specify as semicolon-delimited hybrid value: -Name [ModuleName];[RequiredVersion] [-Name verb-io]
    .PARAMETER RequiredVersion
    Required module .pkg file version to be used as filter date  for determining 'revised' public cmdlets[-RequiredVersion '2.0.3']
    .PARAMETER ExplicitTime
    Explicit timestamp to be used for 'Revised' Public .ps1 cmdlet filtering[-ExplicitTime (get-date).adddays(-14)]
    .EXAMPLE
    PS> get-ModuleRevisedCommands -Name verb-io -RequiredVersion '2.0.3' -verbose
    Retrieve any Public cmdlet .ps1 for the source directory of verb-io, dated after the locally stored nupkg file for Version 2.0.3
    .EXAMPLE
    PS> get-ModuleRevisedCommands -Name verb-io -ExplicitTime (get-date).adddays(-14) -verbose
    Retrieve any Public cmdlet .ps1 for the source directory of verb-io, dated in the last 14 days (as specified via -ExplicitTime parameter).
    .EXAMPLE
    PS> get-ModuleRevisedCommands -Name 'verb-io','verb-dev' -ExplicitTime (get-date).adddays(-14) -verbose ;
    Retrieve both verb-io and verb-dev, against revisions -ExplicitTime'd 14days prior.
    .EXAMPLE
    PS> [array]$lmod = get-ModuleRevisedCommands -Name verb-dev -verbose -RequiredVersion 1.5.9 -ReturnList ;
    PS> $lmod += get-ModuleRevisedCommands -Name verb-io -verbose -RequiredVersion 2.0.0 -ReturnList;
    PS> ipmo -fo -verb $lmod ;    
    Demo use of external ipmo of resulting list.
    .EXAMPLE
    PS> $lmod= get-ModuleRevisedCommands -Name "verb-dev;1.5.9","verb-io;2.0.0" ; 
    PS> ipmo -fo -verb $lmod ;    
    Demo use of semicolon-delimited -Name with both ModuleName and RequiredVersion, in an array, with external ipmo of resulting list.
    .LINK
    https://github.com/tostka/verb-dev
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding(DefaultParameterSetName='Version')]
    [Alias('gmorc')]
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
        if( $RequiredVersion -AND (($Name|measure).count -gt 1)){
            $smsg = "An array of -Name (modules) values was specified"
            $smsg += "`nalong with a -RequiredVersion specification:"
            $smsg += "`nThis command can use a generic ExplicitTime filter across multiple modules,"
            $smsg += "`nbut *cannot* use a single -RequiredVersion across multiple modules!"
            $smsg += "`nPlease rerun the command, specifying either a *non-Array* for -Name, or a generic -ExplicitTime to filter target command revisions"
            $smsg += "`nOr use the -Name `"[modulename];[requiredversion]`" parameter option to specify per-module requiredversion values"
            $smsg += "`n(which also supports running an array of the Name combos)."
            write-warning $smsg ; 
            throw $smsg ; 
            Break ; 
        } ; 
    }
    PROCESS {
        foreach ($item in $Name){
            $sBnrS="`n#*------v PROCESSING : $($item) v------" ; 
            write-host -foregroundcolor green $sBnrS ;

            if($item.contains(';')){
                if($RequiredVersion){
                    $smsg = "-RequiredVersion specified, while using semicolon-delimited Name;RequiredVersion spec."
                    $smsg += "`nuse one or the other, but not *both*" ; 
                    write-warning $smsg ; 
                    throw $smsg ; 
                    Break ;
                } else { 
                    write-verbose "(semicolon-delimited -Name value found: splitting on semicolon and assuming pattern:[`$Name];[`$RequiredVersion]" ; 
                    $ModuleName,$tRequiredVersion = $item.split(';')
                } ; 
            } else {
                $ModuleName = $item ; 
                $tRequiredVersion = $RequiredVersion
            } ; ; 
            $error.clear() ;
            TRY{
                [string]$ModRoot = gi c:\sc\$ModuleName ;
                [string[]]$revisedcommands = @() ; 
                $smsg = "(filtering:`n`$ModRoot:$($ModRoot)" ; 
                if($tRequiredVersion){
                    $smsg += "`nOn RequiredVersion:$($tRequiredVersion)" ; 
                    [system.io.fileinfo]$targetPkg = (Resolve-Path "$modroot\Package\*$($tRequiredVersion.ToString()).nupkg").path ;
                    $cutDate = $targetPkg.lastwritetime ; 
                    $smsg += "`nwith effective CutDate:$($cutDate))" ; 
                } elseif($ExplicitTime){
                    $cutDate = $ExplicitTime ; 
                    $smsg += "`nwith ExplicitTime CutDate:$($cutDate))" ; 
                } else {
                    write-warning "Neither -RequiredVersion nor -ExplicitTime specified: Please specify one or the other)" ; 
                    Break ; 
                }; 
                write-verbose $smsg ; 
                $revisedcommands = (gci $ModRoot\public\*.ps1 | ? LastWriteTime -gt  $cutDate).fullname ; 
                if($Internal){
                    $revisedcommands += (gci $ModRoot\Internal\*.ps1 | ? LastWriteTime -gt  $cutDate).fullname ; 
                } 
                $smsg = "$(($revisedcommands|measure).count) matching commands returned)" ; 
                write-verbose $smsg ;

            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ; 
            if ($revisedcommands){
                write-verbose "(returning `$revisedcommands to pipeline)" ; 
                $revisedcommands | write-output ; 
            } else {  
                $smsg = "No Revised $($ModuleName): cmdlets detected (post $((get-date $cutDate.lastwritetime -format 'yyyyMMdd-HHmmtt')))" 
                write-host $smsg ;
                $false | write-output ; 
            };
            write-host -foregroundcolor green $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ;  # loop-E $items in $NaME
    } # PROC-E
    END{
        write-host -foregroundcolor green $sBnr.replace('=v','=^').replace('v=','^=') ; 
    } ;
}
#*------^ get-ModuleRevisedCommands.ps1 ^------