#*------v backup-ModuleBuild.ps1 v------
function backup-ModuleBuild {
    <#
    .SYNOPSIS
    backup-ModuleBuild - Backup current Module source fingerprint, Manifest (.psd1) & Module (.psm1) files to deep (c:\scBlind\[modulename]) backup, then creates a summary bufiles-yyyyMMdd-HHmmtt.xml file for the backup, in the deep backup directory.
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2022-05-25
    FileName    : backup-ModuleBuild
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 10:35 AM 5/26/2022 minor cleanup
    * 12:11 PM 5/25/2022 init
    .DESCRIPTION
    backup-ModuleBuild - Backup current Module source fingerprint, Manifest (.psd1) & Module (.psm1) files to deep (c:\scBlind\[modulename]) backup, then creates a summary bufiles-yyyyMMdd-HHmmtt.xml file for the backup, in the deep backup directory.

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
    .PARAMETER backupRoot
    Destination for extra-git backup files (generally mirrors dir structure of current module, defaults below c:\scBackup)[-backupRoot c:\path-to\backupdir\]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .OUTPUT
    System.Object[] array reflecting full path to exch backed up module build file
    .EXAMPLE
    PS> backup-ModuleBuild -Name verb-io -verbose -whatif 
    Backup the verb-io module's current build with verbose output, and whatif pass
    .LINK
    https://github.com/tostka/verb-dev
    #> 
    # VALIDATORS: [ValidateNotNull()][ValidateNotNullOrEmpty()][ValidateLength(24,25)][ValidateLength(5)][ValidatePattern("some\sregex\sexpr")][ValidateSet("US","GB","AU")][ValidateScript({Test-Path $_ -PathType 'Container'})][ValidateScript({Test-Path $_})][ValidateRange(21,65)]#positiveInt:[ValidateRange(0,[int]::MaxValue)]#negativeInt:[ValidateRange([int]::MinValue,0)][ValidateCount(1,3)]
    [CmdletBinding()]
    #[Alias('iIseBpAll')]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Module Name to have revised Public source directory import-module'd[-PARAM SAMPLEINPUT]")]
        [ValidateNotNullOrEmpty()]
        #[Alias('ALIAS1', 'ALIAS2')]
        [string[]]$Name,
        [Parameter(HelpMessage="Destination for extra-git backup files (generally mirrors dir structure of current module, defaults below c:\scBackup)[-backupRoot c:\path-to\backupdir\]")]
        $backupRoot = 'C:\scblind', 
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue") ;
        $sBnr="#*======v $($CmdletName): v======" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;

        # files to be targeted for backup (MOD gets replaced with the module name)
        $templateFiles= 'fingerprint','MOD.psm1','MOD.psd1' ; 

        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 
    }
    PROCESS {
        foreach ($item in $Name){
            $sBnrS="`n#*------v PROCESSING : $($item) v------" ; 
            write-host -foregroundcolor green $sBnrS ;

            $error.clear() ;
            TRY{
                $tmodfiles = gci "c:\sc\$item\*" -Recurse ; # collect all files in the module, then post-filter targets out.
                $targetFiles = $templateFiles|foreach-object{$tmodfiles |where name -eq $_.replace('MOD',$item)} | select -expand fullname ; 
                [system.io.fileinfo[]]$bupath = "$backupRoot\$item" ; 
                if($targetFiles){
                    $pltBUF=[ordered]@{Path = $targetFiles ;verbose=$verbose ;whatif = $($whatif); erroraction = 'STOP'} ; 
                    write-host "backup-fileTDO  w`n$(($pltBUF |out-string).trim())" ; 
                    if($bufiles = backup-fileTDO @pltBUF){
                        $xfiles = @() ;         
                        foreach($sfile in $bufiles){
                            $pltCI=[ordered]@{Path = $sfile ; destination = $sfile.replace('C:\sc',$backupRoot) ; verbose=$verbose ;whatif = $($whatif); erroraction = 'STOP'} ; 
                            if(-not (Test-path (split-path $pltCI.destination))){
                                write-host "(creating missing dest:$(split-path $pltCI.destination)" ; 
                                mkdir (split-path $pltCI.destination) -WhatIf:$($whatif) -erroraction 'STOP'; 
                            } ; 
                            write-host "copy-item w`n$(($pltCI |out-string).trim())" ; 
                            if(-not $whatif){
                                copy-item @pltCI ; 
                                $xfiles += $pltCI.destination ;    
                            } else {
                                write-host "(-whatif, skipping balance)" ; 
                            } ;       
                        } ; 
                        $ofile = "$bupath\bufiles-$(get-date -format 'yyyyMMdd-HHmmtt').xml" ; 
                        $pltXXML=[ordered]@{Path = $ofile ;verbose=$verbose ;whatif = $($whatif); erroraction = 'STOP'} ; 
                        write-host "Creating XML record of module backup:`nxxml w`n$(($pltXXML |out-string).trim())" ; 
                        $xfiles | xxml @pltXXML ; 
                        $xfiles | write-output ; 
                    } ; 
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
        write-host -foregroundcolor green $sBnr.replace('=v','=^').replace('v=','^=') ; 
    } ;
}
#*------^ backup-ModuleBuild.ps1 ^------