#*------v Get-PSModuleFile.ps1 v------
function Get-PSModuleFile {
    <#
    .SYNOPSIS
    Get-PSModuleFile.ps1 - Locate a module's manifest .psd1 file, given the root path of the moodule (direct lift from BuildHelpers:Get-PSModuleManifest, but I want a sep copy wo BH as a dependancy)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-15
    FileName    : Get-PSModuleFile.ps1
    License     : MIT License 
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell
    AddedCredit :  RamblingCookieMonster (Warren Frame)
    AddedWebsite: https://github.com/RamblingCookieMonster
    AddedTwitter: @pscookiemonster
    AddedWebsite: https://github.com/RamblingCookieMonster/BuildHelpers
    REVISIONS
    * 11:38 AM 10/15/2021 init version, added support for locating both .psd1 & .psm1, a new -Extension param to drive the choice, and a 'both' optional extension spec to retrieve both file type paths.
    * 1/1/2019 BuildHelpers most recent rev of the get-PsModuleManifest function.
    .DESCRIPTION
    Get-PSModuleFile.ps1 - Locate a module's Manifest (.psd1) or Module (.psm1) file, given the root path of the moodule (direct lift from BuildHelpers:Get-PSModuleManifest, but extended to do either psd1 or psm1)
    Get the PowerShell key psd1|psm1 for a project ;
        Evaluates based on the following scenarios: ;
            * Subfolder with the same name as the current folder with a psd1|psm1 file in it ;
            * Subfolder with a <subfolder-name>.psd1|psm1 file in it ;
            * Current folder with a <currentfolder-name>.psd1|psm1 file in it ;
            + Subfolder called "Source" or "src" (not case-sensitive) with a psd1|psm1 file in it ;
        Note: This does not handle paths in the format Folder\ModuleName\Version\ ;
    .PARAMETER Path
    Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    $psd1M = Get-PSModuleFile -path c:\sc\someproj\
    Retrieve the defualt .psd1 Manifest from the specified project, and assign the fullpath to the $psd1M variable
    .EXAMPLE
    Get-PSModuleFile -path c:\sc\someproj\ -extension 'psm1'
    Use the -Extension 'Both' option to find and return the path to the .psm1 Module file for the specified project, 
    .EXAMPLE
    $modulefiles = Get-PSModuleFile -path c:\sc\someproj\ -extension both
    Use the -Extension 'Both' option to find and return the paths of both the .psd1 Manifest and the .psm1 Module for the specified project, and assign the fullpath to the $modulefiles variable
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/RamblingCookieMonster/BuildHelpers
    #>
    #Requires -Version 3
    ##Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    ##Requires -RunasAdministrator    
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path = $PWD.Path,
        [Parameter(HelpMessage="Specify Module file type: Module .psm1 file or Manifest .psd1 file (psd1|psm1 - defaults psd1)[-Extension .psm1]")]
        [ValidateSet('.psd1','.psm1','both')]
        [string] $Extension='.psd1'
    ) ;
    
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
        $sBnr="#*======v RUNNING :$($CmdletName):$($Extension):$($Path) v======" ; 
        $smsg = "$($sBnr)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        if($Extension -eq 'Both'){
            [array]$Exts = '.psd1','.psm1'
            write-verbose "(-extension Both specified: Running both:$($Exts -join ','))" ; 
        } else {
            $Exts = $Extension ; 
        } ; 
        $Path = ( Resolve-Path $Path ).Path ; 
        $CurrentFolder = Split-Path $Path -Leaf ;
        $ExpectedPath = Join-Path -Path $Path -ChildPath $CurrentFolder ;
        
        foreach($ext in $Exts){
            $ExpectedFile = Join-Path -Path $ExpectedPath -ChildPath "$CurrentFolder$($ext)" ;
            if(Test-Path $ExpectedFile){$ExpectedFile  } 
            else {
                # Look for properly organized modules (name\name.ps(d|m)1)
                $ProjectPaths = Get-ChildItem $Path -Directory |
                    ForEach-Object {
                        $ThisFolder = $_ ;
                        write-verbose "checking:$($ThisFolder)" ; 
                        $ExpectedFile = Join-Path -path $ThisFolder.FullName -child "$($ThisFolder.Name)$($ext)" ;
                        If( Test-Path $ExpectedFile) {$ExpectedFile  } ;
                    } ;
                if( @($ProjectPaths).Count -gt 1 ){
                    Write-Warning "Found more than one project path via subfolders with psd1 files" ;
                    $ProjectPaths  ;
                } elseif( @($ProjectPaths).Count -eq 1 )  {$ProjectPaths  } 
                elseif( Test-Path "$ExpectedPath$($ext)" ) {
                    write-verbose "`$ExpectedPath:$($ExpectedPath)" ; 
                    #PSD1 in root of project - ick, but happens.
                    "$ExpectedPath$($ext)"  ;
                } elseif( Get-Item "$Path\S*rc*\*$($ext)" -OutVariable SourceFiles)  {
                    # PSD1 in Source or Src folder
                    If ( $SourceFiles.Count -gt 1 ) {
                        Write-Warning "Found more than one project $($ext) file in the Source folder" ;
                    } ;
                    $SourceFiles.FullName ;
                } else {
                    Write-Warning "Could not find a PowerShell module $($ext) file from $($Path)" ;
                } ;
            } ;
        } ; 
        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
}

#*------^ Get-PSModuleFile.ps1 ^------