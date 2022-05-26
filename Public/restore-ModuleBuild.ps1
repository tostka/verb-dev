#*------v restore-ModuleBuild.ps1 v------
function restore-ModuleBuild {
    <#
    .SYNOPSIS
    restore-ModuleBuild - Restore fingerprint, Manifest (.psd1) & Module (.psm1) files from deep (c:\scBlind\[modulename]) backup, as specified by inbound .xml file or array of files
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-11
    FileName    : restore-ModuleBuild
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 10:12 AM 5/26/2022 init; got through full debugged pass.
    .DESCRIPTION
    restore-ModuleBuild - Restore fingerprint, Manifest (.psd1) & Module (.psm1) files from deep (c:\scBlind\[modulename]) backup, as specified by inbound .xml file or array of files

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
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .OUTPUT
    System.Object[] array reflecting full path to exch backed up module build file
    .EXAMPLE
    PS> $bRet = restore-modulebuild -path 'C:\scblind\verb-io\bufiles-20220525-1528PM.xml' -verbose -whatif 
    Restage the specified .xml of backup files, from deep extra-git backup loc, to git repo source dir, and then leverage restore-fileTDO to restore production filename to the files. 
    .EXAMPLE
    PS> $bRet = restore-modulebuild -path 'C:\scblind\verb-io\fingerprint._20220525-1527PM','C:\scblind\verb-io\verb-IO\verb-IO.psm1_20220525-1527PM','C:\scblind\verb-io\verb-IO\verb-IO.psd1_20220525-1527PM' -verbose -whatif 
    Restage an array of backed up files, from deep extra-git backup loc, to git repo source dir, and then leverage restore-fileTDO to restore production filename to the files. 
    .LINK
    https://github.com/tostka/verb-dev
    #>
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding()]
    #[Alias('iIseBpAll')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Path to .xml backup file, or leaf backed up files to be restored[-Path C:\scblind\verb-io\bufiles-20220525-1528PM.xml]")]
        [ValidateScript( { Test-Path $_ })]
        [system.io.fileinfo[]]$Path,
        [Parameter(HelpMessage="Destination for restores (defaults below c:\scp\)[-backupRoot c:\path-to\source-root\]")]
        [system.io.fileinfo]$scRoot = 'C:\sc', 
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;

        $templateFiles= 'fingerprint','MOD.psm1','MOD.psd1' ; 
        #$backupRoot = 'C:\scblind'

        TRY{
            [string]$ModuleName = (split-path $Path[0].fullname).split('\')[-1] ; 
            [system.io.fileinfo]$modroot = "$($scroot.fullname)\$($modulename)" ; 
            [system.io.fileinfo]$BuRoot = (split-path $Path[0].fullname).split('\')[0..2] -join '\'
        } CATCH {
            $ErrTrapd=$Error[0] ;
            $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$($smsg)" } ;
            Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
        } ;
        if( (($Path|  measure).count -eq 1) -AND $Path.extension -eq '.xml'){
            write-host '.xml file detected: Attempting to retrieve and restore backup files defined within' ; 
            $pltXXML=[ordered]@{Path = $path ;verbose=$verbose ;erroraction = 'STOP'} ; 
            write-host "ixml w`n$(($pltXXML |out-string).trim())" ; 
            TRY{
                $xfiles = import-clixml @pltXXML ; 
                <#[string]$ModuleName = (split-path $Path).split('\')[-1] ; 
                [system.io.fileinfo]$modroot = "$($scroot.fullname)\$($modulename)" ; 
                [system.io.fileinfo]$BuRoot = (split-path $Path).split('\')[0..2] -join '\'
                #>
                # .replace('C:\sc',$backupRoot)
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;
        } else {
            $xfiles = $path.fullname ; 
            
        } ; 
        $smsg = "`$ModuleName:$($ModuleName)" ; 
        $smsg += "`n`$modroot:$($modroot)" ; 
        $smsg += "`n`$BuRoot:$($BuRoot)" ; 
        write-verbose $smsg ;
        $smsg = "`$xfiles:`n$(($xfiles|out-string).trim())" ; 
        write-verbose $smsg ;
        #[string]$ModRoot = gi c:\sc\$item ;
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 

        $oReport = @() ; 
    }
    PROCESS {
        foreach ($item in $xfiles){
            $sBnrS="`n#*------v PROCESSING: $($item) v------" ; 
            write-host -foregroundcolor green $sBnrS ;

            $error.clear() ;
            TRY{
                [system.io.fileinfo]$sfile = (resolve-path $item -ErrorAction 'STOP' -verbose:$($verbose) ).path ; 
                $pltCI=[ordered]@{
                    path=$sfile.fullname ;
                    Destination=$sfile.tostring().replace($buroot,$modroot) ;
                    ErrorAction='STOP' ;
                    verbose=$($verbose);
                    whatif=$($whatif) ;
                } ; 
                $smsg = "Staging Deep Backup back to git repo directory:copy-item w`n$(($pltCI|out-string).trim())" ; 
                write-host $smsg ;
                copy-item @pltCI ; 

                $pltRF=[ordered]@{
                    Source = $pltCI.Destination
                    #Destination=$sfile.tostring().replace($buroot,$modroot) ;
                    ErrorAction='STOP' ;
                    verbose=$($verbose);
                    whatif=$($whatif) ;
                } ; 
                $smsg = "restore-FileTDO w`n$(($pltRF|out-string).trim())" ; 
                write-host $smsg ;
                if(-not $whatif){
                    $bRet = restore-FileTDO @pltRF ;
                    if (!$bRet -and -not $whatif) {throw "FAILURE" } else {
                        $oReport += $bRet ; 
                    } ; 
                } else { 
                    write-host "(-whatif: skipping restore-fileTDO)" ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ;

            write-host -foregroundcolor green $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ;  # loop-E $items in $item
    } # PROC-E
    END{
        if(-not $whatif){
            $smsg = "(returning `$oReport restored filenames to pipeline:`n$(($oReport|out-string).trim()))" ; 
            write-verbose $smsg ;
        } ; 
        $oReport | write-output ; 
        write-host -foregroundcolor green $sBnr.replace('=v','=^').replace('v=','^=') ; 
    } ;
}
#*------^ restore-ModuleBuild.ps1 ^------