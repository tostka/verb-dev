#*------v get-ProjectNameTDO.ps1 v------
function get-ProjectNameTDO {
    <#
    .SYNOPSIS
    get-ProjectNameTDO.ps1 - Get the name for this project (lifted from BuildHelpers module, and renamed to avoid collisions
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-15
    FileName    : get-ProjectNameTDO.ps1
    License     : MIT License 
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell
    AddedCredit :  RamblingCookieMonster (Warren Frame)
    AddedWebsite: https://github.com/RamblingCookieMonster
    AddedTwitter: @pscookiemonster
    AddedWebsite: https://github.com/RamblingCookieMonster/BuildHelpers
    REVISIONS
    * 11:51 AM 10/16/2021 init version, minor CBH mods, put into OTB format. 
    * 1/1/2019 BuildHelpers most recent rev of the get-PsModuleManifest function.
    .DESCRIPTION
    Get the name for this project

        Evaluates based on the following scenarios:
            * Subfolder with the same name as the current folder
            * Subfolder with a <subfolder-name>.psd1 file in it
            * Current folder with a <currentfolder-name>.psd1 file in it
            + Subfolder called "Source" or "src" (not case-sensitive) with a psd1 file in it

        If no suitable project name is discovered, the function will return
        the name of the root folder as the project name.
        
         We assume you are in the project root, for several of the fallback options
         
         [How to Write a PowerShell Module Manifest - PowerShell | Microsoft Docs - docs.microsoft.com/](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest?view=powershell-7.1)
         "You link a manifest file to a module by naming the manifest the same as the module, and storing the manifest in the module's root directory."
         
         [Understanding a Windows PowerShell Module - PowerShell | Microsoft Docs - docs.microsoft.com/](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/understanding-a-windows-powershell-module?view=powershell-7.1)
          "A module is a set of related Windows PowerShell functionalities, grouped together as a convenient unit (usually saved in a single directory)."
          "Regardless, the path of the folder is referred to as the base of the module (ModuleBase), and the name of the script, binary, or manifest module file (.psm1) should be the same as the module folder name, with the following exceptions:..."
          
    .FUNCTIONALITY
    CI/CD
    .PARAMETER Path
    Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']
    .EXAMPLE
    $ModuleName = get-ProjectNameTDO -path c:\sc\someproj\
    Retrieve the Name from the specified project, and assign it to the $ModuleName variable
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/RamblingCookieMonster/BuildHelpers
    .LINK
    Get-BuildVariable
    .LINK
    Set-BuildEnvironment
    .LINK
    about_BuildHelpers
    #>
    ##Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    ##Requires -RunasAdministrator    
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to project root. Defaults to the current working path [-path 'C:\sc\PowerShell-Statistics\']")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path = $PWD.Path,
        [validatescript({
            if(-not (Get-Command $_ -ErrorAction SilentlyContinue))
            {
                throw "Could not find command at GitPath [$_]"
            }
            $true
        })]
        $GitPath = 'git'
    ) ;
    
    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    $sBnr="#*======v RUNNING :$($CmdletName):$($Extension):$($Path) v======" ; 
    $smsg = "$($sBnr)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    if(!$PSboundParameters.ContainsKey('GitPath')) {
        $GitPath = (Get-Command $GitPath -ErrorAction SilentlyContinue)[0].Path ; 
    } ; 

    $WeCanGit = ( (Test-Path $( Join-Path $Path .git )) -and (Get-Command $GitPath -ErrorAction SilentlyContinue) ) ; 

    $Path = ( Resolve-Path $Path ).Path ; 
    $CurrentFolder = Split-Path $Path -Leaf   ; 
    $ExpectedPath = Join-Path -Path $Path -ChildPath $CurrentFolder ; 
    if(Test-Path $ExpectedPath) { $result = $CurrentFolder }
    else{
        # Look for properly organized modules
        $ProjectPaths = Get-ChildItem $Path -Directory |
            Where-Object {
                Test-Path $(Join-Path $_.FullName "$($_.name).psd1")  
            } |
                Select-Object -ExpandProperty Fullname ; 

        if( @($ProjectPaths).Count -gt 1 ){
            Write-Warning "Found more than one project path via subfolders with psd1 files" ; 
            $result = Split-Path $ProjectPaths -Leaf ; 
        } elseif( @($ProjectPaths).Count -eq 1 ){
            $result = Split-Path $ProjectPaths -Leaf ; 
        } elseif( Get-Item "$Path\S*rc*\*.psd1" -OutVariable SourceManifests){
            # PSD1 in Source or Src folder
            If ( $SourceManifests.Count -gt 1 ){
                Write-Warning "Found more than one project manifest in the Source folder" ; 
            } ; 
            $result = $SourceManifests.BaseName
        } elseif( Test-Path "$ExpectedPath.psd1" ) {
            #PSD1 in root of project - ick, but happens.
            $result = $CurrentFolder ; 
        } elseif ( $PSDs = Get-ChildItem -Path $Path "*.psd1" ){
            #PSD1 in root of project but name doesn't match
            #very ick or just an icky time in Azure Pipelines
            if ($PSDs.count -gt 1) {
                Write-Warning "Found more than one project manifest in the root folder" ; 
            } ; 
            $result = $PSDs.BaseName ; 
        } elseif ( $WeCanGit ) {
            #Last ditch, are you in Azure Pipelines or another CI that checks into a folder unrelated to the project?
            #let's try some git
            $result = (Invoke-Git -Path $Path -GitPath $GitPath -Arguments "remote get-url origin").Split('/')[-1] -replace "\.git","" ; 
        } else {
            Write-Warning "Could not find a project from $($Path); defaulting to project root for name" ; 
            $result = Split-Path $Path -Leaf ; 
        } ; 
    } ; 

    if ($env:APPVEYOR_PROJECT_NAME -and $env:APPVEYOR_JOB_ID -and ($result -like $env:APPVEYOR_PROJECT_NAME)) {
        $env:APPVEYOR_PROJECT_NAME ; 
    } else {
        $result ; 
    } ; 
        
    $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
} ; 

#*------^ get-ProjectNameTDO.ps1 ^------
