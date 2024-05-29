#*------v copy-ISETabFileToLocal.ps1 v------
function copy-ISETabFileToLocal {
    <#
    .SYNOPSIS
    copy-ISETabFileToLocal - Copy the currently open ISE tab file, to local machine (RDP remote only), prompting for local path. The filename copied is either the intact local name, or, if -stripFunc is used, the filename with any _func substring removed. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-05-22
    FileName    : copy-ISETabFileToLocal
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging,backup
    REVISIONS
    * 2:15 PM 5/29/2024 add: c:\sc dev repo dest test, prompt for optional -nofunc use (avoid mistakes copying into repo with _func.ps1 source name intact)
    * 1:22 PM 5/22/2024init
    .DESCRIPTION
    copy-ISETabFileToLocal - Copy the currently open ISE tab file, to local machine (RDP remote only), prompting for local path. The filename copied is either the intact local name, or, if -stripFunc is used, the filename with any _func substring removed. 
    This also checks for a matching exported breakpoint file (name matches target script .ps1, with trailing name ...-ps1-BP.xml), and prompts to also move that file along with the .ps1. 

    .PARAMETER Path
    Path to source file (defaults to `$psise.CurrentFile.FullPath)[-Path 'D:\scripts\copy-ISETabFileToLocal_func.ps1']
    .PARAMETER LocalDestination
    Localized destination directory path[-path c:\pathto\]
    .PARAMETER noFunc
    Switch to remove any '_func' substring from the original file name, while copying (used for copying to final module .\Public directory for publishing[-noFunc]
    .PARAMETER whatIf
    Whatif switch [-whatIf]
    .EXAMPLE
    PS> copy-ISETabFileToLocal -verbose -whatif
    Copy the current tab file to prompted local destination, whatif, with verbose output
    .EXAMPLE
    PS> copy-ISETabFileToLocal -verbose -localdest C:\sc\verb-dev\public\ -noFunc -whatif
    Copy the current tab file to explicit specified -LocalDesetination, replacing any _func substring from filename, with whatif, with verbose output
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('cpIseFileLocal')]
    PARAM(
        [Parameter(Mandatory = $false,Position=0,HelpMessage="Path to source file (defaults to `$psise.CurrentFile.FullPath)[-Path 'D:\scripts\copy-ISETabFileToLocal_func.ps1']")]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            #[string]
            [system.io.fileinfo]$Path=$psise.CurrentFile.FullPath,
        [Parameter(Mandatory = $true,Position = 1,HelpMessage = 'Localized destination directory path[-path c:\pathto\]')]
            #[Alias('PsPath')]
            #[ValidateScript({Test-Path $_ -PathType 'Container'})]
            [ValidateScript({
                if([uri]$_ |?{ $_.IsUNC}){
                    throw "UNC Path specified: Please specify a 'localized' path!" ; 
                }elseif([uri]$_ |?{$_.AbsolutePath -AND $_.LocalPath -AND $_.IsFile -AND -not $_.IsUNC}){
                    $true ;
                }else{
                    throw "Invalid path!" ; 
                }
            })]
            #[System.IO.DirectoryInfo]
            [string]$LocalDestination,
        [Parameter(HelpMessage="Switch to remove any '_func' substring from the original file name, while copying (used for copying to final module .\Public directory for publishing[-noFunc])")]
            [switch]$noFunc,
        [Parameter(HelpMessage="Whatif switch [-whatIf]")]
            [switch] $whatIf
    ) ;
    BEGIN {
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $verbose = $($VerbosePreference -eq "Continue")
        $sBnr="#*======v $($CmdletName): v======" ;
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr)" ;
        $moveBP = $false ; 
    }
    PROCESS {
        if ($psise){
            if($env:SESSIONNAME  -match 'RDP-Tcp#\d+'){
                TRY{
                    if($path){
                        [system.io.fileinfo[]]$source = @($path) ; 
                        if(-not $noFunc -AND $LocalDestination -match '^C:\\sc\\'){
                            $smsg = "Note: Copying to `$LocalDestination prefixed with C:\sc\ (dev repo)" ; 
                            $smsg += "`nWITHOUT specifying -NoFunc!" ; 
                            $smsg += "`nDO YOU WANT TO USE -NOFUNC (suppress _func.ps1 on copy)?" ; 
                            write-warning $smsg ; 
                            $bRet=Read-Host "Enter YYY to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "YYY") {
                                $smsg = "(specifying -NoFunc)" ; 
                                write-host -foregroundcolor green $smsg  ;
                                $noFunc = $true ; 
                            } else {
                                $smsg = "(*skip* copying -BP.xml file)" ; 
                                write-host -foregroundcolor yellow $smsg  ;
                            } ; 
                        } ; 
                        if($LocalDestination.substring(0,1) -ne 'c'){
                            $Destination = $LocalDestination.replace(':','$') ; 
                            $Destination = (join-path -path "\\$($mybox[0])\" -childpath $Destination) ; 
                        }else{
                            $Destination = $LocalDestination.replace(':','') ; 
                            $Destination = (join-path -path "\\tsclient\" -childpath $Destination) ; 
                        } ; 
                        write-verbose "resolved `$Destination:$($Destination)" ; 
                        if(-not (test-path -path $Destination)){
                            $smsg = "Missing/invalid converted `$Destination:"
                            $smsg += "`n$($Destination)" ; 
                            write-warning $smsg ; 
                            throw $smsg ; 
                            break ; 
                        } ;
                        # check for matching local ps1-BP.xml file to also copy
                        if($bpp = get-childitem -path ($path.fullname.replace('.ps1','-ps1-BP.xml')) -ea 0){
                            $smsg = "Matching Breakpoint export file found:`n$(($bpp |out-string).trim())" ; 
                            $smsg += "`nDo you want to move this file with the .ps1?" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Prompt } 
                            else{ write-host -foregroundcolor YELLOW "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $bRet=Read-Host "Enter Y to continue. Anything else will exit"  ; 
                            if ($bRet.ToUpper() -eq "Y") {
                                $smsg = "(copying -BP.xml file)" ; 
                                write-host -foregroundcolor green $smsg  ;
                                $moveBP = $true ; 
                                $source += @($bpp)
                            } else {
                                $smsg = "(*skip* copying -BP.xml file)" ; 
                                write-host -foregroundcolor yellow $smsg  ;
                            } ; 
                        } ; 
                        $pltCI=[ordered]@{
                            path = $null ; 
                            destination = $null ; 
                            erroraction = 'STOP' ;
                            verbose = $true ; 
                            whatif = $($whatif) ;
                        } ;
                        foreach($src in $source){
                            $pltCI.path = $src.fullname ; 
                            if($noFunc){
                                $pltCI.destination = (join-path -path $Destination -childpath $src.name.replace('_func','') -EA stop)
                            } else { 
                                $pltCI.destination = (join-path -path $Destination -childpath $_.name  -EA stop); 
                            } ; 
                            $smsg = "copy-item w`n$(($pltCI|out-string).trim())" ; 
                            write-host -foregroundcolor green $smsg  ;
                            copy-item @pltCI ; 
                        } ; 
                    } else { 
                        throw "NO POPULATED `$psise.CurrentFile.FullPath!`n(PSISE-only, with a target file tab selected)" ; 
                    } ; 
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                    write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                } ;             
            } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
        } else {  write-warning "This script only functions within an RDP remote session (non-local)" };
    } # PROC-E
    END{
        write-verbose  "$((get-date).ToString('HH:mm:ss')):$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    }
}; 
#*------^ copy-ISETabFileToLocal.ps1 ^------
