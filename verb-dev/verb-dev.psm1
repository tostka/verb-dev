﻿# verb-dev.psm1


<#
.SYNOPSIS
VERB-dev - Development PS Module-related generic functions
.NOTES
Version     : 1.4.54
Author      : Todd Kadrie
Website     :	https://www.toddomation.com
Twitter     :	@tostka
CreatedDate : 1/14/2020
FileName    : VERB-dev.psm1
License     : MIT
Copyright   : (c) 1/14/2020 Todd Kadrie
Github      : https://github.com/tostka
AddedCredit : REFERENCE
AddedWebsite:	REFERENCEURL
AddedTwitter:	@HANDLE / http://twitter.com/HANDLE
REVISIONS
* 3:27 PM 3/15/2020 load-Module: added $PsmNameTmp, $PsdNameTmp and shifted updating to a _TMP file of each, which at end, if error free, overwrites the current functional copy (correcting prior issue with corruption of existing copy, when there were processing errors). 
* 3:00 PM 2/24/2020 1.2.8, pulled #Requires RunAsAdministrator, convertto-module runs as UID, doesn't have it
* 1/14/2020 - 1.2.7, final mod build (updated content file vers to match latest psd1)
# * 10:33 AM 12/30/2019 Merge-Module():951,952 assert sorts into alpha order (make easier to find in the psm1) ; fixed/debugged monolithic build options, now works. Could use some code to autoupdate all .NOTES:Version fields, but that's for future. ;Added code to update against monolithic/non-dyn-incl psm1s. Parses CBH & meta blocks out & constructs a new psm1 from the content. ; dbgd merge-module.ps1 w/in process-NewModule.ps1, functional so far. ; parseHelp(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file ; ; profile-FileAST: updated CBH: added INPUTS & OUTPUTS, including hash properties returned ; Get-CommentBlocks:updated cbh and added .INPUTS/.OUTPUTS cbh entries, detailing the subcompontents of the hashtable returned
# * 12:03 PM 12/29/2019 added else wh on pswls entries
# * 1:54 PM 12/28/2019 added merge-module to verb-dev ; Merge-Module fixed $sBnrSStart/End typo
# * 5:22 PM 12/15/2019initial vers includes Get-CommentBlocks, parseHelp, profile-FileAST, build-VSCConfig, Merge-Module
.DESCRIPTION
VERB-dev - Development PS Module-related generic functions
.INPUTS
None
.OUTPUTS
None
.EXAMPLE
.EXAMPLE
.LINK
https://github.com/tostka/verb-dev
#>


$script:ModuleRoot = $PSScriptRoot ;
$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem $script:moduleroot\*.psd1).fullname).moduleversion ;

#*======v FUNCTIONS v======



#*------v build-VSCConfig.ps1 v------
function build-VSCConfig {
    <#
    .SYNOPSIS
    build-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2:58 PM 12/15/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:14 AM 12/30/2019 added CBH .INPUTS & .OUTPUTS, including specific material returned.
    * 5:51 PM 12/16/2019 added OneArgument param
    * 2:58 PM 12/15/2019 INIT
    .DESCRIPTION
    build-VSCConfig - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
    .PARAMETER  CommandLine
    CommandLine to be converted into a launch.json configuration
    .PARAMETER OneArgument
    Flag to specify all arguments should be in a single unparsed entry[-OneArgument]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Console dump & copy to clipboard, of model launch.json conversion of ISE Breakpoints xml file.
    .EXAMPLE
    $bRet = build-VSCConfig -CommandLine $updatedContent -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    if (!$bRet) {Continue } ;
    .LINK
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "CommandLine to be written to specified file [-CommandLine script.ps1 arguments]")]
        [ValidateNotNullOrEmpty()]$CommandLine,
        [Parameter(HelpMessage = "Flag to specify all arguments should be in a single unparsed entry[-OneArgument]")]
        [switch] $OneArgument = $true,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    
    #$verbosePreference = "Continue" # opts: Stop(&Error)|Inquire(&Prompt)|Continue(Display)|SilentlyContinue(Suppress);
    $Verbose = ($VerbosePreference -eq "Continue") ; 
    #$CommandLine = Read-Host "Enter Command to be Parsed" ;
    $parsedCmdLine = Split-CommandLine -CommandLine $CommandLine | Where-Object { $_.length -gt 1 }  ;
    $ttl = ($parsedCmdLine | Measure-Object).count ;

    $error.clear() ;
    TRY {
        # 1st elem is the script/exec name
        $jsonRequest = [ordered]@{
            type    = "PowerShell";
            request = "launch";
            name    = "PS $(split-path $parsedCmdLine[0] -Leaf)" ;
            script  = (resolve-path -path $parsedCmdLine[0]).path;
            args    = $() ;
            cwd     = "`${workspaceRoot}";
        } ;

        if ($ttl -gt 1) {
            if ($OneArgument) {
                $jsonRequest.args = $parsedCmdLine[1..$($ttl)] -join " " ;
            }
            else {
                # args are 2nd through last elem
                $jsonRequest.args = $parsedCmdLine[1..$($ttl)]
            } ;
        } ;
        if ($showDebug) {
            Write-HostOverride -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):ConvertTo-Json w`n$(($jsonRequest|out-string).trim())`nargs:`n$(($jsonRequest.args|out-string).trim())" ;
        } ;
        $cfg = $jsonRequest | convertto-json ;
    }
    CATCH {
        Write-Error "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        $false | Write-Output ;
        CONTINUE #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
    } ;
    $cfgTempFile = [System.IO.Path]::GetTempFileName().replace('.tmp', '.json') ;
    Set-FileContent -Text $cfg -Path $cfgTempFile -showDebug:$($showDebug) -whatIf:$($whatIf);
    write-verbose -verbose:$true "Generated launch.json config entry for input:`n w`n$(($cfg|out-string).trim())" ;
    write-verbose -verbose:$true "Generated launch.json config entry for input:`n w`n$((get-command $cfgTempFile |out-string).trim())" ;
    write-verbose -verbose:$true "(copied to clipboard)" ;
    $cfg | C:\WINDOWS\System32\clip.exe ;
    $true | write-output ;

}

#*------^ build-VSCConfig.ps1 ^------

#*------v check-PsLocalRepoRegistration.ps1 v------
function check-PsLocalRepoRegistration {
    <#
    .SYNOPSIS
    check-PsLocalRepoRegistration - Check for PSRepository for $localPSRepo, register if missing
    .NOTES
    Version     : 1.0.0
    Author: Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    CreatedDate : 2020-03-29
    FileName    : check-PsLocalRepoRegistration
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,Git,Repository
    REVISIONS
    * 7:00 PM 3/29/2020 init
    .DESCRIPTION
    check-PsLocalRepoRegistration - Check for PSRepository for $localPSRepo, register if missing
    .PARAMETER  User
    User security principal (defaults to current user)[-User `$SecPrinobj]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $bRet = check-PsLocalRepoRegistration -Repository $localPSRepo 
    Check registration on the repo defined by variable $localPSRepo
    .LINK
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Local Repository [-Repository repoName]")]
        $Repository = $localPSRepo,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf=$true
    ) ; 
    $verbose = ($VerbosePreference -eq 'Continue') ; 
    # on cold installs there *is* no repo, precheck
    if($Repository){
        if(!(Get-PSRepository -Name $Repository -ea 0)){
            $repo = @{
                Name = 'lyncRepo' ;
                SourceLocation = $null;
                PublishLocation = $null;
                InstallationPolicy = 'Trusted' ;
            } ;
            if($Repository = 'lyncRepo'){
                $RepoPath = "\\lynmsv10\lync_fs\scripts\sc" ;
                $repo.Name = 'lyncRepo' ; 
                $repo.SourceLocation = $RepoPath ; 
                $repo.PublishLocation = $RepoPath ;
            } elseif($Repository = "tinRepo") {
                #Name = 'tinRepo', Location = '\\SYNNAS\archs\archs\sc'; IsTrusted = 'True'; IsRegistered = 'True'.
                $RepoPath = '\\SYNNAS\archs\archs\sc' ;
                $repo.Name = 'tinRepo' ; 
                $repo.SourceLocation = $RepoPath ; 
                $repo.PublishLocation = $RepoPath ;
            } else { 
                $smsg = "UNRECOGNIZED `$Repository" ; 
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warning } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            }; 
            $smsg = "MISSING REPO REGISTRATION!`nRegister-PSRepository w`n$(($repo|out-string).trim())" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            if(!$whatif){
                $bReturn = Register-PSRepository @repo ;
                $bReturn | write-output ;             
            } else { 
                $smsg = "(whatif detected: skipping execution - Register-PSRepository lacks -whatif support)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            }
        } else {
            $smsg = "($Repository repository is already registered in this profile)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $true | write-output ;              
        } ;  
    } else {
        $smsg = "MISSING REPO REGISTRATION!`nNO RECOGNIZED `$Repository DEFINED!" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warning } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }; 
}

#*------^ check-PsLocalRepoRegistration.ps1 ^------

#*------v convert-CommandLine2VSCDebugJson.ps1 v------
function convert-CommandLine2VSCDebugJson {
    <#
    .SYNOPSIS
    convert-CommandLine2VSCDebugJson - Process a sample ISE debugging command line, and convert it to a VSC launch.json 'configurations' entry
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2:58 PM 12/15/2019
    FileName    :convert-CommandLine2VSCDebugJson.ps1
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    REVISIONS
    * 9:28 AM 8/3/2020 ren'd build-vscconfir -> convert-CommandLine2VSCDebugJson, and added alias:convert-cmdline2json, porting into verb-dev module ; refactored name & script tag resolution, and accomdates leading dot-source(.), invocation (&), and local dir (.\) 1-2 chars of cmdline ; coerced right side of args assignement into [array](required in launch.json spec)
    * 5:51 PM 12/16/2019 added OneArgument param
    * 2:58 PM 12/15/2019 INIT
    .DESCRIPTION
    convert-CommandLine2VSCDebugJson - Converts a typical 'ISE-style debugging-launch commandline', into a VSC  launch.json-style 'configurations' block. 
    launch.json is in the .vscode subdir of each open folder in VSC's explorer pane
    
    General Launch.json editing notes: (outside of the output of this script, where customization is needed to get VSC debugging to work):
    #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    # Vsc - Debugging Launch.json

    ## Overview 

    -There's one per local workspace, stored in:

    ```C:\sc\powershell\[script dir]\.vscode\launch.json```

    -You can debug a simple application even if you don't have a folder open in VS Code but it is not possible to manage launch configurations and setup advanced debugging. For that, you have to open a folder in your workspace.

    -For advanced debugging, you first have to open a folder and then set up your launch configuration file - `launch.json`. Click on the *Configure gear*  icon on the Debug view top bar and VS Code will generate a `launch.json` file under your workspace's `.vscode` folder. VS Code will try to automatically detect your debug environment, if unsuccessful you will have to choose your debug environment manually.

    -Use IntelliSense if your cursor is located inside the configurations array.

    -The extension handles params, not VSCode. Ext env is config'd via `launch.json` file. Process:

    1.  Click Debug pane icon [not-bug]
    2.  Debug view top bar: Click [gear] icon => Opens launch.json for the workspace's .json folder for editing

    1.  As with all .json's, all but the last line end with comma (`,`), and `//` is the rem command
    2.  Note backslashes have to be doubled:

    ```json
    // Command line arguments passed to the program.
    ```

    ## Debug Arg launch.json entry examples:

    -   **`args` entry:**

    JSON array of command-line arguments to pass to the program when it is launched. Example `["arg1", "arg2"]`. If you are escaping characters, you will need to double escape them. For example, `["{[\\\"arg1\\\](file:///%22arg1/)": true}"]` will send `{"arg1": true}` to your application.<br>
    Example:

    ```json
    "args": [ "-TargetMbxsCSV 'C:\\usr\\work\\incid\\311526-onprem-deliver.csv' -Senders 'Daniel.Breton@sightpathmedical.com' -ExternalSender -Subject 'Quick Review' -logonly:$true -deletecontent:$false -whatif:$true" ],
    ```

    -   **`cwd` entry**

    Sets the working directory of the application launched by the debugger.
    Example:

    ```json
    "cwd": "${workspaceFolder}"
    ```

    -   **`env` 'environment' entry**

    Environment variables to add to the environment for the program. 
    Example: (creates 'name' & 'value' evaris)
    ```json
    "env": "[ { "name": "squid", "value": "clam" } ]",
    ```

    >Also has also support for supplying input to Read-Host via the Debug Console input prompt.

    - Configure Environment Variable support in launch.json:

    1. Use the "configurations": [? "env":  ]section:<br>
    It's in "vari-name":"vari-value" format

    ```json
    "env": {"AWS_REGION":"us-east-1", "SLS_DEBUG":"*"},
    ```

    ## Launch.json Arg cmdline param passing examples

    -   **`args`** - arguments passed to the program to debug. This attribute is of type array and expects individual arguments as array elements.
    -   The rule to translate a command line to the "args" is simple: *every command line argument separated by whitespace needs to become a separate item of the "args" attribute.*
    -   **Exception to the rule above: when you need *key:value*  args:**

    ```text
    $ python main.py --verbose --name Test
    ```

    -   above is coded inside the launch.json args line as:

    ```json
    args:["--verbose","--name=Test"],  
    ```
        
    -   **Watson example shows another variant:**  
        
        ```json
        "program": "${workspaceFolder}/console.py" 
        "args": ["dev", "runserver", "--noreload=True"],
        ```
    
    - Other examples:
    ```json
    // 3 ways to spec the same switch/key-value: (all work)
    "args": ["-Verbose"],
    "args": ["-Verbose:$true"],
    "args": ["-Verbose:", "$true"],
    // separating across lines & array elems
    "args": [   "-arg1 value1",
                "-argname2 value2"],
    ```

    - **These reflect editing the existing empty entry:**

    ```json
    "args": [""],

    // can spread them out on lines too
    "args": [
    "--nolazy"
    ],

    // feed them all on one string (ala cmdline)
    "args": [ "-Param1 foo -Recurse" ],

    "args": ["-Count 55 -DelayMilliseconds 250"],

    // or feed them as an array of params comma-quoted

    // below,will be concatenated to a single string w space delim

    "args": [ "-Path", "C:\\Users\\Keith", "*.ps1", "-Recurse" ],

    // another example, long one:
    "args": [
    "-u",
    "tdd",
    "--compilerOptions",
    "--require",
    "ts-node/register",
    "--require",
    "jsdom-global/register",
    "--timeout",
    "999999",
    "--colors",
    "${file}"
    ],

    /// another with param values
    "args": [
    "${workspaceRoot}/tools/startTest.js",
    "--require", "ts-node/register",
    "--watch-extensions", "ts,tsx",
    "--require", "babel-register",
    "--watch-extensions", "js",
    "tests/**/*.spec.*"
    ],

    /// another
    "args": [  "-arg1 value1",
    "-argname2 value2"],

    //another
    "args": [
    "${command:SpecifyScriptArgs}"
    ],

    // $ python main.py --verbose --name Test
    args:["--verbose","--name=Test"],

    // spaces in parameters

    // need pass the args FIRST ARGUMENT and SECOND ARGUMENT as the first and second argument. But comes through as 4 arguments: 
    FIRST, ARGUMENT, SECOND, ARGUMENT

    // You need to include the quotes in the args strings and escape them:
    "args": ["\"FIRST ARGUMENT\"", "\"SECOND ARGUMENT\""]

    // linux gnome-terminal version
    "program": "/usr/bin/gnome-terminal",
    "args": ["-x", "/usr/bin/powershell", "-NoExit", "-f", "${file}"],
    ```

    Besides ${workspaceRoot} and ${file}, the following variables are available for use in launch.json:
    |variable|Notes|
    |--------|-----|
    |${workspaceRoot}|the path of the folder opened in Visual Studio Code|
    |${workspaceRootFolderName}|the name of the folder opened in Visual Studio Code without any solidus (/)|
    |${file}|the current opened file|
    |${relativeFile}|the current opened file relative to workspaceRoot|
    |${fileBasename}|the current opened file?s basename|
    |${fileBasenameNoExtension}|the current opened file?s basename with no file extension|
    |${fileDirname}|the current opened file?s dirname|
    |${fileExtname}|the current opened file?s extension|
    |${cwd}|the task runner?s current working directory on startup|
    |${env.USERPROFILE}|To reference env varis ; `env` must be all lowercase, and can't be `env[colon]`, must be `env[period]` *(vsc syntax, not powershell)*|
    #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    .PARAMETER  CommandLine
    CommandLine to be converted into a launch.json configuration
    .PARAMETER OneArgument
    Flag to specify all arguments should be in a single unparsed entry[-OneArgument]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $bRet = convert-CommandLine2VSCDebugJson -CommandLine $updatedContent -showdebug:$($showdebug) -whatif:$($whatif) ;
    if (!$bRet) {Continue } ;
    .LINK
    #>
    [CmdletBinding()]
    [Alias('convert-cmdline2json')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "CommandLine to be parsed into launch.json config syntax [-CommandLine script.ps1 arguments]")]
        [ValidateNotNullOrEmpty()]$CommandLine,
        [Parameter(HelpMessage = "Flag to specify all arguments should be in a single unparsed entry[-OneArgument]")]
        [switch] $OneArgument = $true
    ) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    # Get parameters this function was invoked with
    $PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
    $Verbose = ($VerbosePreference -eq 'Continue') ; 

    $parsedCmdLine = Split-CommandLine -CommandLine $CommandLine | Where-Object { $_.length -gt 1 }  ;
    $ttl = ($parsedCmdLine | Measure-Object).count ;
    
    # you *can* build the json object as a hash, you just need to type the args attrib as array @() e.g. args = @("-Count 42 -DelayMillseconds 2000") ;
    $jsonRequest = [ordered]@{
        type    = "PowerShell";
        request = "launch";
        name    = $null ;
        script  = $null 
        args    = $() ;
        cwd     = "`${workspaceRoot}";
    } ;
    if ($OneArgument) {write-verbose "(-OneArgument specified: Generating single-argument output)" } ; 

    $lastConsumeditem = 0 ; 
    $error.clear() ;
    TRY {
        # parse out the name & script values from the first couple of elements
        if($parsedCmdLine[0].length -eq 1 -AND ($parsedCmdLine[0] -match '(&|.)') ){
            # invocation/dot-source char, skip it
            #$1stIsPunc = $true ; 
            $jsonRequest.name = "PS $(split-path $parsedCmdLine[1] -leaf)" ;
            $jsonRequest.script  = (resolve-path -path $parsedCmdLine[1]).path ;
            $lastConsumeditem = 1 ; 
        }elseif( ($parsedCmdLine[0].substring(0,2) -eq '.\') -OR ($parsedCmdLine[0] -match '(\\|\/)') ){ 
            # relative path ref, or apparent path, resolve it
            $jsonRequest.name = "PS $(split-path $parsedCmdLine[0] -leaf)" ;
            $jsonRequest.script  = (resolve-path -path $parsedCmdLine[0]).path ;
        }elseif ($parsedCmdLine[0] -match '(.+?)(\.[^.]*$|$)'){
            # if it's a single word or word with ext, it may be a system pathed OS cmd, use it as it lies
            $jsonRequest.name =  "PS $($parsedCmdLine[0])" ;
            $jsonRequest.script  = $parsedCmdLine[0] ; 
        } else {
            # , use it as it lies
            $jsonRequest.name =  "PS $($parsedCmdLine[0])" ;
            $jsonRequest.script  = $parsedCmdLine[0] ; 
        } ; 
        $lastConsumeditem++ ; 
        if ($ttl -gt 1) {
            if ($OneArgument) {
                write-verbose -verbose:$true "(-OneArgument specified: Generating single-argument output)" ; 
                # isn't coming out an array, so coerce it on the data assignement - that works
                $jsonRequest.args = [array]($parsedCmdLine[$lastConsumeditem..$($ttl)] -join " ") ;
            }
            else {
                # args are from after 'lastConsumeditem' through last elem
                $jsonRequest.args = [array]($parsedCmdLine[$lastConsumeditem..$($ttl)]) ; 
            } ;
        } else { 
            write-verbose -verbose:$true "Only a single parsed item in CommandLine:`n$($CommandLine)" ; ;
        } ; 

        write-verbose "$((get-date).ToString('HH:mm:ss')):ConvertTo-Json w`n$(($jsonRequest|out-string).trim())`nargs:`n$(($jsonRequest.args|out-string).trim())" ;
        $cfg = $jsonRequest | convertto-json ;
    }
    CATCH {
        Write-Error "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        $false | Write-Output ;
        CONTINUE #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
    } ;
    <# thought was having formatting issues, so put through a tmp file at one point
    $cfgTempFile = [System.IO.Path]::GetTempFileName().replace('.tmp', '.json') ;
    Set-FileContent -Text $cfg -Path $cfgTempFile -showDebug:$($showDebug) -whatIf:$($whatIf);
    write-verbose -verbose:$true "Generated launch.json config entry for input:`n w`n$((get-command $cfgTempFile |out-string).trim())" ;
    #>
    write-verbose -verbose:$true "Generated launch.json config entry for input:`n w`n$(($cfg|out-string).trim())`n`n(copied to clipboard)" ;
    $cfg | C:\WINDOWS\System32\clip.exe ;
    $true | write-output ;
}

#*------^ convert-CommandLine2VSCDebugJson.ps1 ^------

#*------v export-ISEBreakPoints.ps1 v------
function export-ISEBreakPoints {
    <#
    .SYNOPSIS
    export-ISEBreakPoints - Export all 'Line' ise breakpoints to XML file 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : export-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 12:56 PM 8/25/2020 fixed typo in 1.0.0 ; init, added to verb-dev module
    .DESCRIPTION
    export-ISEBreakPoints - Export all 'Line' ise breakpoints to XML file
    By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.
    .EXAMPLE
    export-ISEBreakPoints
    Export all 'line'-type breakpoints on the current open ISE tab, to a matching xml file
    .EXAMPLE
    export-ISEBreakPoints -Script c:\path-to\script.ps1
    Export all 'line'-type breakpoints from the specified script, to a matching xml file
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('eIseBp')]
    PARAM(
        [Parameter(HelpMessage="Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$PathDefault = 'c:\scripts',
        [Parameter(HelpMessage="(debugging):Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]")]
        #[ValidateScript({Test-Path $_})]
        [string]$Script
    ) ;
    BEGIN {} ;
    PROCESS {
        if ($psise){
            
            if($Script){
                if( ($tScript = (gci $Script).FullName) -AND ($psise.powershelltabs.files.fullpath -contains $tScript)){
                    write-host "-Script specified diverting target to:`n$($Script)" ; 
                    $tScript = $Script ; 
                    $xFname=$tScript.replace(".ps1","-ps1.xml").replace(".psm1","-psm1.xml").replace(".","-BP.") ;
                } else { 
                    throw "-Script specified is not a valid path!`n$($Script)`n(or is not currently open in ISE)" ; 
                } ; 
            } elseif($psise.CurrentFile.FullPath){
                $tScript = $psise.CurrentFile.FullPath ;
                # default to same loc, variant name of script in currenttab of ise
                #$xFname=$psise.CurrentFile.FullPath.replace(".ps1","-ps1.xml").replace(".psm1","-psm1.xml").replace(".","-BP.") ;
                $xFname=$tScript.replace(".ps1","-ps1.xml").replace(".psm1","-psm1.xml").replace(".","-BP.") ;
                $AllUsrsScripts = "$($env:ProgramFiles)\WindowsPowerShell\Scripts" ; 
                if( ( (split-path $xFname) -eq $AllUsrsScripts) -OR (-not(test-path (split-path $xFname))) ){
                    # if in the AllUsers profile, or the ISE script dir is invalid
                    if($tdir = get-item "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts"){
                        # if the CUser has a profile Scripts dir, use it                
                    } elseif($tdir = get-item $PathDefault){
                        # else if functional use the $pathdefault
                    } else {
                        throw "Unable to resolve a suitable destination for the current script`n$($tScript)" ; 
                        break ; 
                    } ; 
                    $smsg = "broken path, defaulting to: $($tdir.fullname)" ; 
                    #$xFname=(join-path -path "c:\scripts\" -childpath (split-path $psise.CurrentFile.FullPath -leaf)).replace(".ps1","-ps1.xml").replace(".psm1","-psm1.xml").replace(".","-BP.") ;
                    $xFname = $xFname.replace( (split-path $xFname), $tdir.fullname) ;
                } ;
            } else { throw "ISE has no current file open. Open a file before using this script" } ; 
        
        write-host "Creating BP file:$($xFname)" ;
        #$xBPs= get-psbreakpoint |?{$_.Script -eq $($psise.currentfile.fullpath) -AND ($_.line)} ;
        $xBPs= get-psbreakpoint |?{ ($_.Script -eq $tScript) -AND ($_.line)} ;
        $xBPs | Export-Clixml -Path $xFname ;
        write-host "$(($xBPs|measure).count) Breakpoints exported to $xFname`n$(($xBPs|sort line|ft -a Line,Script|out-string).trim())" ;
        } else {  write-warning "This script only functions within PS ISE, with a script file open for editing" };
    } # PROC-E
}

#*------^ export-ISEBreakPoints.ps1 ^------

#*------v Get-CommentBlocks.ps1 v------
function Get-CommentBlocks {
    <#
    .SYNOPSIS
    Get-CommentBlocks - Parse specified Path (or inbound Textcontent) for Comment-BasedHelp, and surrounding structures.
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 8:07 PM 11/18/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    * 3:49 PM 4/14/2020 minor change
    * 5:19 PM 4/11/2020 added Path variable, and ParameterSet/exlus support
    * 8:36 AM 12/30/2019 Get-CommentBlocks:updated cbh and added .INPUTS/.OUTPUTS cbh entries, detailing the subcompontents of the hashtable returned
    * 8:28 PM 11/17/2019 INIT
    .DESCRIPTION
    Get-CommentBlocks - Parse specified Path (or inbound Textcontent) for Comment-BasedHelp, and surrounding structures. Returns following parsed content: metaBlock (`<#PSScriptInfo..#`>), metaOpen (Line# of start of metaBlock), metaClose (Line# of end of metaBlock), cbhBlock (Comment-Based-Help block), cbhOpen (Line# of start of CBH), cbhClose (Line# of end of CBH), interText (Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line), metaCBlockIndex ( Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock), CbhCBlockIndex  (Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock)
    .PARAMETER  TextLines
    Raw source lines from the target script file (as gathered with get-content) [-TextLines TextArrayObj]
    .PARAMETER Path
    Path to a powershell ps1/psm1 file to be parsed for CBH [-Path c:\path-to\script.ps1]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Returns a hashtable containing the following parsed content/objects, from the Text specified:
    * metaBlock : `<#PSScriptInfo..#`> published script metadata block (added via New|Update-ScriptFileInfo, at top of file)
    * metaOpen : Line# of start of metaBlock
    * metaClose : Line# of end of metaBlock
    * cbhBlock : Comment-Based-Help block
    * cbhOpen : Line# of start of CBH
    * cbhClose : Line# of end of CBH
    * interText : Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line.
    * metaCBlockIndex : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock
    * CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock
    .EXAMPLE
    $rawSourceLines = get-content c:\path-to\script.ps*1  ;
    $oBlkComments = Get-CommentBlocks -TextLines $rawSourceLines -showdebug:$($showdebug) -whatif:$($whatif) ;
    $metaBlock = $oBlkComments.metaBlock ;
    if ($metaBlock) {
        $smsg = "Existing MetaData located and tagged" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
    } ;
    $cbhBlock = $oBlkComments.cbhBlock ;
    $preCBHBlock = $oBlkComments.interText ;
    .LINK
    #>
    #Requires -Version 3
    ##Requires -RunasAdministrator

    [CmdletBinding()]
    PARAM(
        [Parameter(ParameterSetName='Text',Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Raw source lines from the target script file (as gathered with get-content) [-TextLines TextArrayObj]")]
        [ValidateNotNullOrEmpty()]$TextLines,
        [Parameter(ParameterSetName='File',Position = 0, Mandatory = $True, HelpMessage = "Path to a powershell ps1/psm1 file to be parsed for CBH [-Path c:\path-to\script.ps1]")]
        [ValidateScript({Test-Path $_})]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $Verbose = ($VerbosePreference -eq "Continue") ;

    if($Path){
        $TextLines = get-content -path $path  ;
    } ;

    $AllBlkCommentCloses = $TextLines | Select-string -Pattern '\s*#>' | Select-Object -ExpandProperty LineNumber ;
    $AllBlkCommentOpens = $TextLines | Select-string -Pattern '\s*<#' | Select-Object  -ExpandProperty LineNumber ;

    $MetaStart = $TextLines | Select-string -Pattern '\<\#PSScriptInfo' | Select-Object -First 1 -ExpandProperty LineNumber ;

    # cycle the comment-block combos till you find the CBH comment block
    $metaBlock = $null ; $metaBlock = @() ;
    $cbhBlock = $null ; $cbhBlock = @() ;

    $rgxCBHKeywords = "\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK|COMPONENT|ROLE|FUNCTIONALITY|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE|EXTERNALHELP)"

    $Procd = 0 ;
    foreach ($Open in $AllBlkCommentOpens) {
        $tmpBlock = $TextLines[($Open - 1)..($AllBlkCommentCloses[$Procd] - 1)]

        if ($tmpBlock -match '\<\#PSScriptInfo') {
            $metaCBlockIndex = $Procd ;
            $metaOpen = $Open - 1 ;
            $metaClose = $AllBlkCommentCloses[$Procd] - 1
            $metaBlock = $tmpBlock ;
            if ($showDebug) {
                if ($metaOpen -AND $metaClose) {
                    $smsg = "Existing MetaData located and tagged" ;
                    #if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
                    write-verbose -verbose:$true  "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                } ;
            } ;
        }
        elseif ($tmpBlock -match $rgxCBHKeywords) {
            $CbhCBlockIndex = $Procd ;
            $CBHOpen = $Open - 1 ;
            $CBHClose = $AllBlkCommentCloses[$Procd] - 1 ;
            $cbhBlock = $tmpBlock ;
            if ($showDebug) {
                if ($metaOpen -AND $metaClose) {
                    $smsg = "Existing CBH metaBlock located and tagged" ;
                    #if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
                    write-verbose -verbose:$true  "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                } ;
            } ;
            break ;
        } ;
        $Procd++ ;
    };


    $InterText = $null ; $InterText = [ordered]@{ } ;
    if ($metaClose -AND $cbhOpen) {
        $InterText = $TextLines[($metaClose + 1)..($cbhOpen - 1 )] ;
    }
    else {
        write-verbose -verbose:$true  L"$((get-date).ToString('HH:mm:ss')):(doesn't appear to be an inter meta-CBH block)" ;
    } ;
    <#
    metaBlock : <#PSScriptInfo published script metadata block
    metaOpen : Line# of start of metaBlock
    metaClose : Line# of end of metaBlock
    cbhBlock : Comment-Based-Help block
    cbhOpen : Line# of start of CBH
    cbhClose : Line# of end of CBH
    interText : Block of text *between* any metaBlock metaClose, and any CBH cbhOpen.
    metaCBlockIndex : Of the collection of all block comments - `<#..#`> , the index of the one corresponding to the metaBlock
    CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> , the index of the one corresponding to the cbhBlock
    #>
    $objReturn = [ordered]@{
        metaBlock       = $metaBlock  ;
        metaOpen        = $metaOpen ;
        metaClose       = $metaClose ;
        cbhBlock        = $cbhBlock ;
        cbhOpen         = $cbhOpen ;
        cbhClose        = $cbhClose ;
        interText       = $InterText ;
        metaCBlockIndex = $metaCBlockIndex ;
        CbhCBlockIndex  = $CbhCBlockIndex ;
    } ;
    $objReturn | Write-Output

}

#*------^ Get-CommentBlocks.ps1 ^------

#*------v get-FunctionBlock.ps1 v------
function get-FunctionBlock {
    <#
    .SYNOPSIS
    get-FunctionBlock - Retrieve the specified $functionname function block from the specified $Parsefile.
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    # 10:07 AM 9/27/2019 ren'd GetFuncBlock -> get-FunctionBlock & tighted up, added named param expl
    3:19 PM 8/31/2016 - initial version, functional
    .DESCRIPTION
    .PARAMETER  ParseFile
    Script to be parsed [path-to\script.ps1]
    .PARAMETER  functionName
    Function name to be found and displayed from ParseFile
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    .EXAMPLE
    get-FunctionBlock C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 Add-EMSRemote ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using positional params
    .EXAMPLE
    get-FunctionBlock -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 -Func Add-EMSRemote ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    #Requires -Version 3
    Param(
        [Parameter(Position=0,MandaTory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        $ParseFile
        ,[Parameter(Position=1,MandaTory=$True,HelpMessage="Function name to be found and displayed from ParseFile")]
        $functionName
    )  ;


    # 2:07 PM 8/31/2016 alt code:
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($ParseFile,[ref]$null,[ref]$Null ) ;
    $funcsInFile = $AST.FindAll({$args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $true) ;
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    $matchfunc = $null ;
    foreach($func in $funcsInFile) {
        if($func.Name -eq $functionName) {
            $matchfunc = $func ;
            break ;
        } ;
    } ;
    if($matchfunc -eq $null){ return 0 } ;
    $matchfuncBody = $matchfunc.Body ;

    # dumping the last line# for the targeted funct to pipeline
    #return $matchfuncBody.Extent.EndLineNumber ;

    # 2:20 PM 8/31/2016 return the function with bracketing

    $sPre="$("=" * 50)`n#*------v Function $($matchfunc.name) from Script:$($ParseFile) v------" ;
    $sPost="#*------^ END Function $($matchfunc.name) from Script:$($ParseFile) ^------ ;`n$("=" * 50)" ;

    # here string seems to make it crap out, just append together
    $sOut = $null ;
    $sOut += "$($sPre)`nFunction $($matchfunc.name) " ;
    $sOut += "$($matchfunc.Body) $($sPost)" ;

    write-verbose -verbose:$true "Script:$($ParseFile): Matched Function:$($functionName) " ;
    $sOut | write-output ;

}

#*------^ get-FunctionBlock.ps1 ^------

#*------v get-FunctionBlocks.ps1 v------
function get-FunctionBlocks {
    <#
    .SYNOPSIS
    get-FunctionBlocks - All functions from the specified $Parsefile, output them directly to pipeline (capture on far end & parse/display)
    .NOTES
    Author: Todd Kadrie
    Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
    Website:	http://tinstoys.blogspot.com
    Twitter:	http://twitter.com/tostka
    REVISIONS   :
    # 5:55 PM 3/15/2020 fix corrupt ABC typo
    # 10:21 AM 9/27/2019 just pull the functions in a file and pipeline them, nothing more.
    .DESCRIPTION
    .PARAMETER  ParseFile
    Script to be parsed [path-to\script.ps1]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    None. Returns matched Function block to pipeline.
    get-FunctionBlocks -Parse C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    Pull/display the Add-EMSRemote function from the specified .ps1, using named params
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    $funcs |?{$_.name -eq 'get-lastwake'} | format-list name,body
    Pull ALL functions, and post-filter return for specific function, and dump the name & body to console.
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    ($funcs |?{$_.name -eq 'get-lastwake'}).Extent.text
    Pull ALL functions, and post-filter return for specific function, and dump the extent.text (body) to console.
    .EXAMPLE
    $funcs = get-FunctionBlocks C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
    foreach($func in $funcs){
      $sPre="$("=" * 50)`n#*------v Function $($func.name) from Script:$($ParseFile) v------" ;
      $sPost="#*------^ END Function $($func.name) from Script:$($ParseFile) ^------ ;`n$("=" * 50)" ;
      $sOut = $null ;
      $sOut += "$($sPre)`nFunction $($func.name) " ;
      $sOut += "$($func.Body) $($sPost)" ;
      write-host $sOut
    } ;
    Output a formatted block of Name & Bodies (approx the get-FunctionBlock())
    .LINK
    https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
    #>

    #Requires -Version 3
    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
        $ParseFile
    )  ;

    # 2:07 PM 8/31/2016 alt code:
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($ParseFile, [ref]$null, [ref]$Null ) ;
    $funcsInFile = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
    # this variant pulls commands v functions
    #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    foreach ($func in $funcsInFile) {
        $func | write-output ;
    } ;
}

#*------^ get-FunctionBlocks.ps1 ^------

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

#*------v get-ScriptProfileAST.ps1 v------
function get-ScriptProfileAST {
    <#
    .SYNOPSIS
    get-ScriptProfileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:56 PM 12/8/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    # 1:01 PM 5/27/2020 moved alias: profile-FileAST win func
    # 5:25 PM 2/29/2020 ren profile-FileASt -> get-ScriptProfileAST (aliased orig name)
    # * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:04 AM 12/30/2019 profile-FileAST: updated CBH: added .INPUTS & OUTPUTS, including hash properties returned
    * 3:56 PM 12/8/2019 INIT
    .DESCRIPTION
    profile-FileAST - Parse specified Script/Module using Language.FunctionDefinitionAst
    .PARAMETER  File
    Path to script/module file
    .PARAMETER Functions
    Flag to return Functions-only [-Functions]
    .PARAMETER Parameter
    Flag to return Parameter-only [-Functions]
    .PARAMETER Variables
    Flag to return Variables-only [-Variables]
    .PARAMETER Aliases
    Flag to return Aliases-only [-Aliases]
    .PARAMETER GenericCommands
    Flag to return GenericCommands-only [-GenericCommands]
    .PARAMETER All
    Flag to return All [-All]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable object containing:
    * Parameters : Details on all Parameters in the file
    * Functions : Details on all Functions in the file
    * VariableAssignments : Details on all Variables assigned in the file
    .EXAMPLE
    $ASTProfile = profile-FileAST -File c:\pathto\script.ps1 -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    Return the raw $ASTProfile object to the piepline (default behavior)
    .EXAMPLE
    $FunctionNames = (get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -Functions).functions.name ;
    Return the Functions within the specified script, and select the name properties of the functions object returned.
    .EXAMPLE
    $AliasAssignments = (get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -Aliases).Aliases.extent.text;
    Return the set/new-Alias commands from the specified script, selecting the full syntax of the command
    .EXAMPLE
    $WhatifLines = ((get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -GenericCommands).GenericCommands | ?{$_.extent -like '*whatif*' } | select -expand extent).text
    Return any GenericCommands from the specified script, that have whatif within the line
    .EXAMPLE
    $bRet = ((get-scriptprofileast -File c:\usr\work\exch\scripts\verb-dev.ps1 -All) ;
    $bRet.functions.name ;
    $bret.variables.extent.text
    $bret.aliases.extent.text

    Return ALL variant objects - Functions, Parameters, Variables, aliases, GenericCommands - from the specified script, and output the function names, variable names, and alias assignement commands
    .LINK
    #>
    [CmdletBinding()]
    [Alias('profile-FileAST')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-File path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$File,
        [Parameter(HelpMessage = "Flag to return Functions-only [-Functions]")]
        [switch] $Functions,
        [Parameter(HelpMessage = "Flag to return Parameters-only [-Functions]")]
        [switch] $Parameters,
        [Parameter(HelpMessage = "Flag to return Variables-only [-Variables]")]
        [switch] $Variables,
        [Parameter(HelpMessage = "Flag to return Aliases-only [-Aliases]")]
        [switch] $Aliases,
        [Parameter(HelpMessage = "Flag to return GenericCommands-only [-GenericCommands]")]
        [switch] $GenericCommands,
        [Parameter(HelpMessage = "Flag to return All [-All]")]
        [switch] $All,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN {
        $Verbose = ($VerbosePreference -eq "Continue") ;
        if ($File.GetType().FullName -ne 'System.IO.FileInfo') {
            $File = get-childitem -path $File ;
        } ;
    } ;
    PROCESS {
        $AST = [System.Management.Automation.Language.Parser]::ParseFile($File.fullname, [ref]$null, [ref]$Null ) ;

        $objReturn = [ordered]@{ } ;

        if ($Functions -OR $All) {
            $ASTFunctions = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
            $objReturn.add('Functions', $ASTFunctions) ;
        } ;
        if ($Parameters -OR $All) {
            $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;
            $objReturn.add('Parameters', $ASTParameters) ;
        } ;
        if ($Variables -OR $All) {
            $AstVariableAssignments = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) ;
            $objReturn.add('Variables', $AstVariableAssignments) ;
        } ;
        if ($($Aliases -OR $GenericCommands) -OR $All) {
            $ASTGenericCommands = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) ;
            if ($Aliases -OR $All) {
                $ASTAliasAssigns = ($ASTGenericCommands | ? { $_.extent.text -match '(set|new)-alias' }) ;
                $objReturn.add('Aliases', $ASTAliasAssigns) ;
            } ;
            if ($GenericCommands -OR $All) {
                $objReturn.add('GenericCommands', $ASTGenericCommands) ;
            } ;
        } ;
        $objReturn | Write-Output ;
    } ;
    END { } ;
} ; #*------^ END Function get-ScriptProfileAST ^------
if (!(get-alias -name "profile-FileAST" -ea 0 )) { Set-Alias -Name 'profile-FileAST' -Value 'get-ScriptProfileAST' ; }

#*------^ get-ScriptProfileAST.ps1 ^------

#*------v get-VersionInfo.ps1 v------
function get-VersionInfo {
    <#
    .SYNOPSIS
    get-VersionInfo.ps1 - get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).
    .NOTES
    Version     : 0.2.0
    Author      : Todd Kadrie
    Website     :	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    CreatedDate : 02/07/2019
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    AddedCredit : Based on code & concept by Alek Davis
    AddedWebsite:	https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    AddedTwitter:
    REVISIONS
    * 3:47 PM 4/14/2020 substantially shifted role to parseHelp(), which is less brittle and less likely to fail the critical get-help call that underlies the parsing. 
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:36 AM 12/30/2019 added CBH .INPUTS & OUTPUTS, including description of the hashtable of key/value pairs returned, for existing CBH .NOTES block
    * added explicit -path param to get-help
    * 8:39 PM 11/21/2019 added test for returned get-help
    * 8:27 AM 11/5/2019 Todd rework: Added Path param, parsed to REVISIONS: block, & return the top rev as LastRevision key in returned object.
    * 02/07/2019 Posted version
    .DESCRIPTION
    get-VersionInfo.ps1 - Extract comment-help .NOTES block into a hashtable, key-value split on colons, to provide portable metadata (for New/Update-ScriptFileInfo inputs).
    .PARAMETER  Path
    Path to target script (defaults to $PSCommandPath)
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .INPUTS
    None
    .OUTPUTS
    Returns a hashtable of key-value pairs for each of the entries in the .NOTES CBH block in a given file. 
    .EXAMPLE
    .\get-VersionInfo
    Default process from $PSCommandPath
    .EXAMPLE
    .\get-VersionInfo -Path .\path-to\script.ps1 -verbose:$VerbosePreference
    Explicit file via -Path
    .LINK
    https://stackoverflow.com/questions/38561009/where-is-the-standard-place-to-put-a-powershell-script-version-number
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to target script (defaults to `$PSCommandPath) [-Path -Path .\path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $Verbose = ($VerbosePreference -eq "Continue") ; 
    $notes = $null ; $notes = @{ } ;
    # Get the .NOTES section of the script header comment.
    # key difference from parseHelp is the get-help in that one, doesn't spec -path param, AT ALL, just the value: $HelpParsed = Get-Help -Full $Path.fullname, and it *works* on the same file that won't with below
    if (!$Path) {
        $Help = Get-Help -Full -path $PSCommandPath
    }
    else { $Help = Get-Help -Full -path $Path } ;
    if($Help){
        $notesLines = ($Help.alertSet.alert.Text -split '\r?\n').Trim() ;
        foreach ($line in $notesLines) {
            if (!$line) { continue } ;
            $name = $null ; $value = $null ;
            if ($line -eq 'REVISIONS') { $bRevBlock = $true ; Continue } ;
            if ($bRevBlock) {
                $notes.Add("LastRevision", "$line") ;
                break ;
            } ;
            if ($line.Contains(':')) {
                $nameValue = $null ;
                $nameValue = @() ;
                # Split line by the first colon (:) character.
                $nameValue = ($line -split ':', 2).Trim() ;
                $name = $nameValue[0] ;
                if ($name) {
                    $value = $nameValue[1] ;
                    if ($value) { $value = $value.Trim() } ;
                    if (!($notes.ContainsKey($name))) { $notes.Add($name, $value) } ;
                } ;
            } ;
        } ;
        $notes | write-output ;
    } else {
        $false | write-output ;
    } ;
}

#*------^ get-VersionInfo.ps1 ^------

#*------v import-ISEBreakPoints.ps1 v------
function import-ISEBreakPoints {
    <#
    .SYNOPSIS
    import-ISEBreakPoints - Import the 'Line' ise breakpoints previously cached to an XML file
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : import-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:43 AM 8/26/2020 fixed typo $ibp[0]->$ibps[0]
    * 1:45 PM 8/25/2020 fix bug in import code ; init, added to verb-dev module
    .DESCRIPTION
    import-ISEBreakPoints - Import the 'Line' ise breakpoints previously cached to an XML file
    By default, attempts to save to the same directory as the script, but if the directory specified doesn't exist, it redirects the save to the c:\scripts dir.
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .EXAMPLE
    import-ISEBreakPoints
    Import all 'line'-type breakpoints into the current open ISE tab, from matching xml file
    .EXAMPLE
    Import-ISEBreakPoints -Script c:\path-to\script.ps1
    Import all 'line'-type breakpoints into the specified script, from matching xml file
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('iIseBp')]

    #[ValidateScript({Test-Path $_})]
    PARAM(
        [Parameter(HelpMessage="Default Path for Import (when `$Script directory is unavailable)[-PathDefault c:\path-to\]")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$PathDefault = 'c:\scripts',
        [Parameter(HelpMessage="(debugging):Path to target Script file (defaults to Current ISE Tab fullpath)[-Script c:\path-to\file.ext]")]
        [string]$Script
    ) ;
    BEGIN {} ;
    PROCESS {
        # for debugging, -Script permits targeting another script *not* being currently debugged
        if ($psise){
            if($Script){
                if( ($tScript = (gci $Script).fullname) -AND ($psise.powershelltabs.files.fullpath -contains $tScript)){
                    write-host "-Script specified diverting target to:`n$($Script)" ;
                    $iFname = "$($Script.replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ;
                } else {
                    throw "-Script specified is not a valid path!`n$($Script)`n(or is not currently open in ISE)" ;
                } ;
            } elseif($psise.CurrentFile.FullPath){
                $tScript = $psise.CurrentFile.FullPath
                # array of paths to be preferred (in order)
                # - script's current path (with either -[ext]-BP or -BP suffix)
                #
                $tfiles = "$($tScript.replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))",
                    # ^current path name variant 1
                    "$($tScript.replace('ps1','xml').replace('.','-BP.'))",
                    # ^current path name variant 2
                    "$((join-path -path "$([Environment]::GetFolderPath('MyDocuments'))\WindowsPowershell\Scripts" -childpath (split-path $tScript -leaf)).replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ,
                    # ^CU scripts dir
                    "$((join-path -path $PathDefault -childpath (split-path $tScript -leaf)).replace('.ps1','-ps1.xml').replace('.psm1','-psm1.xml').replace('.','-BP.'))" ;
                    # ^ PathDefault dir
                foreach($tf in $tfiles){if($iFname = gci $tf -ea 0 | select -exp fullname ){break } } ;
            } else { throw "ISE has no current file open. Open a file before using this script" } ;

            if($iFname){
                write-host "*Importing BP file:$($iFname) and setting specified BP's for open file`n$($tScript)" ;
                # clear all existing bps
                if($eBP=Get-PSBreakpoint |?{$_.line -AND $_.Script -eq $tScript}){$eBP | remove-PsBreakpoint } ;

                # set bps in found .xml file
                $iBPs = Import-Clixml -path $iFname ;

                <# fundemental issue importing cross-machines, the xml stores the full path to the script at runtime
                    $iBP.script
                C:\Users\UID\Documents\WindowsPowerShell\Scripts\maintain-AzTenantGuests.ps1
                    $tscript
                C:\usr\work\o365\scripts\maintain-AzTenantGuests.ps1
                #>
                # so if they mismatch, we need to patch over the script used in the set-psbreakpoint command
                if(  ( (split-path $iBPs[0].script) -ne (split-path $tscript) ) -AND ($psise.powershelltabs.files.fullpath -contains $tScript) ) {
                    write-verbose "Target script is pathed to different location than .XML exported`n(patching BPs to accomodate)" ; 
                    $setPs1 = $tScript ; 
                } else {
                    # use script on 1st bp in xml
                    $setPs1 = $iBPs[0].Script ; 
                }; 

                #$iBPs | %{set-PSBreakpoint -script $_.script -line $_.line } | out-null ;
                foreach($iBP in $iBPs){
                    $null = set-PSBreakpoint -script $setPs1 -line $iBP.line ;
                } ; 
                write-host "$(($iBP|measure).count) Breakpoints imported and set as per $($iFname)`n$(($iBPs|sort line|ft -a Line,Script|out-string).trim())" ;
             } else { "Missing .xml BP file for open file $($tScript)" } ;
        } else {  write-warning 'This script only functions within PS ISE, with a script file open for editing' };
    } # PROC-E
}

#*------^ import-ISEBreakPoints.ps1 ^------

#*------v import-ISEConsoleColors.ps1 v------
Function import-ISEConsoleColors {
    <#
    .SYNOPSIS
    import-ISEConsoleColors - Import stored $psise.options from a "`$(split-path $profile)\IseColors-XXX.csv" file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-03-17
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Copyright   : 
    Github      : https://github.com/tostka
    Tags        : Powershell,ExchangeOnline,Exchange,RemotePowershell,Connection,MFA
    REVISIONS   :
    * 7:29 AM 3/17/2021 init
    .DESCRIPTION
    import-ISEConsoleColors - Import stored $psise.options from a "`$(split-path $profile)\IseColors-XXX.csv" file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    import-ISEConsoleColors;
    .LINK
    https://github.com/tostka/verb-IO
    #>
    
    [CmdletBinding()]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
        switch($host.name){
            "Windows PowerShell ISE Host" {
                ##$psISE.Options.RestoreDefaultTokenColors()
                <#$sFileTag=Read-Host "Enter 'Name' for saved color scheme" ;
                $ofile = "$(split-path $profile)\IseColors-$($sFileTag).csv" ; 
                write-host -fore green "Saving current Colors & Fonts to file: $($ofile)" ; 
                $psise.options | Select ConsolePane*,Font* | Export-CSV "$($ofile)" ;
                #>
                #$ifile = "$(split-path $profile)\IseColorsDefault.csv" ; 
                get-childitem  "$(split-path $profile)\IseColors*.csv" | out-gridview -Title "Pick IseColors-XXX.csv file of Font/Color settings to be imported into ISE:" -passthru | foreach-object {
                    $ifile = $_.fullname ; 
                    if(test-path $ifile){
                        (import-csv $ifile ).psobject.properties | foreach { $psise.options.$($_.name) = $_.Value} ; 
                    } else { 
                        throw "Missing $($ifile), skipping import-ISEConsoleColors.ps1`nCan be created via:`n`$psise.options | Select ConsolePane*,Font* | Export-CSV '`$(split-path $profile)\IseColorsDefault.csv'"
                    } ;
                } ;
            } 
            "ConsoleHost" {
                #[console]::ResetColor()  # reset console colorscheme to default
                throw "This command is intended to import ISE settings (`$psie.options object). PS `$host is not supported" ; 
            }
            default {
                write-warning "Unrecognized `$Host.name:$($Host.name), skipping $($MyInvocation.MyCommand.Name)" ; 
            } ; 
        } ; 
    }

#*------^ import-ISEConsoleColors.ps1 ^------

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
    * 8:47 AM 10/15/2021 rem'd # raa, convert-tomodule etc run as UID, and I have this loading in profile...
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
    ##Requires -RunasAdministrator
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

#*------v Merge-Module.ps1 v------
function Merge-Module {
    <#
    .SYNOPSIS
    Merge-Module.ps1 - Merge function .ps1 files into a monolisthic module.psm1 module file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2019-12-10
    FileName    : Merge-Module.ps1
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit : Przemyslaw Klys
    AddedWebsite: https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/
    Tags        : Powershell,Module,Development
    AddedTwitter:
    REVISIONS
    * 11:25 AM 9/21/2021 added code to remove obsolete gens of .nupkgs & build log files (calls to new verb-io:remove-UnneededFileVariants()); CBH:added Tags; fixed missing CmdletBinding (which breaks functional verbose); added brcketing Banr (easier to tell where breaks occur)
    * 12:15 PM 4/21/2021 expanded select-string aliases
    * 11:42 AM 6/30/2020 fixed Public\_CommonCode.ps1, -ea 0 when not present
    * 1:13 PM 6/29/2020 add support for .Public\_CommonCode.ps1 - module-spanning code that should follow the Function block in the .psm1
    * 3:27 PM 3/15/2020 load-Module: added $PsmNameTmp, $PsdNameTmp and shifted updating to a _TMP file of each, which at end, if error free, overwrites the current functional copy (correcting prior issue with corruption of existing copy, when there were processing errors).
    * failing to load verb-io content, added a forceload if get-fileencoding isn't present, added new PassStatus tests and passed back in output, also now does the build in a .psm1_TMP file, to avoid damaging last functional copy
    * 12:42 PM 3/3/2020 fixed missing trailing sbnr (Internal)
    * 10:36 AM 3/3/2020 added pre-check & echo when unable to locate the psd1 FunctionsToExport value
    * 1:58 PM 3/2/2020 as Set-ModuleFunction isn't properly setting *all* exported, go back to collecting and updating the psm1 & psd1 *both* via regx
    * 9:12 AM 2/29/2020 shift export-modulemember/FooterBlock to bottom, added FUNCTIONS delimiter lines
    * 9:17 AM 2/27/2020 added new -NoAliasExport param, and added the missing
    * 3:44 PM 2/26/2020 Merge-Module: added -LogSpec param (feed it the object returned by a Start-Log() pass).
    * 11:27 AM Merge-Module 2/24/2020 suppress block dumps to console, unless -showdebug or -verbose in use
    * 7:24 AM 1/3/2020 #936: trimmed errant trailing ;- byproduct of fix-encoding pass
    * 10:33 AM 12/30/2019 Merge-Module():951,952 assert sorts into alpha order (make easier to find in the psm1)
    * 10:20 AM 12/30/2019 Merge-Module(): fixed/debugged monolithic build options, now works. Could use some code to autoupdate all .NOTES:Version fields, but that's for future.
    * 8:59 AM 12/30/2019 Merge-Module(): Added code to update against monolithic/non-dyn-incl psm1s. Parses CBH & meta blocks out & constructs a new psm1 from the content.
    * 9:51 AM 12/28/2019 Merge-Module fixed $sBnrSStart/End typo
    * 1:23 PM 12/27/2019 pulled regex sig replace with simple start/end detect and throw error (was leaving dangling curlies in psm1)
    * 12:11 PM 12/27/2019 swapped write-error in catch blocks with write-warning - we seems to be failing to exec the bal of the catch
    * 7:46 AM 12/27/2019 Merge-Module(): added included file demarc comments to improve merged file visual parsing, accumulating $PrivateFunctions now as well, explicit echos
    * 8:51 AM 12/20/2019 removed plural from ModuleSourcePaths -> ModuleSourcePath (matches all the calls etc)
    *8:50 PM 12/18/2019 sorted hard-coded verb-aad typo
    2:54 PM 12/11/2019 rewrote, added backup of psm1, parsing out the stock dyn-include code from the orig psm1, leverages fault-tolerant set-fileContent(), switched sourcepaths to array type, and looped, detecting public/internal by path and prepping for the export list.
    * 2018/11/06 Przemyslaw Klys posted version
    .DESCRIPTION
    Merge-Module.ps1 - Merge function .ps1 files into a monolisthic module.psm1 module file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER  ModuleSourcePath
    Directory containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]
    .PARAMETER ModuleDestinationPath
    Final monolithic module .psm1 file name to be populated [-ModuleDestinationPath c:\path-to\module\module.psm1]
    .PARAMETER NoAliasExport
    Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable object containing: Status[$true/$false], PsmNameBU [the name of the backup of the original psm1 file]
    .EXAMPLE
    .\merge-Module.ps1 -ModuleName verb-AAD -ModuleSourcePath C:\sc\verb-AAD\Public -ModuleDestinationPath C:\sc\verb-AAD\verb-AAD -showdebug -whatif ;
    Command line process
    .EXAMPLE
    $pltmergeModule=[ordered]@{
        ModuleName="verb-AAD" ;
        ModuleSourcePath="C:\sc\verb-AAD\Public","C:\sc\verb-AAD\Internal" ;
        ModuleDestinationPath="C:\sc\verb-AAD\verb-AAD" ;
        showdebug=$true ;
        whatif=$($whatif);
    } ;
    Merge-Module @pltmergeModule ;
    Splatted example (from process-NewModule.ps1)
    .LINK
    https://www.toddomation.com
    #>
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]")]
        [string] $ModuleName,
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]")]
        [array] $ModuleSourcePath,
        [Parameter(Mandatory = $True, HelpMessage = "Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]")]
        [string] $ModuleDestinationPath,
        [Parameter(Mandatory = $False, HelpMessage = "Logging spec object (output from start-log())[-LogSpec `$LogSpec]")]
        $LogSpec,
        [Parameter(HelpMessage = "Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]")]
        [switch] $NoAliasExport,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    # Get parameters this function was invoked with
    #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
    $verbose = ($VerbosePreference -eq "Continue") ;
    
    $sBnr="#*======v $(${CmdletName}): v======" ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    

    $rgxSigStart='#\sSIG\s#\sBegin\ssignature\sblock' ;
    $rgxSigEnd='#\sSIG\s#\sEnd\ssignature\sblock' ;

    $PassStatus = $null ;
    $PassStatus = @() ;

    $tModCmdlet = "Get-FileEncoding" ;
    if(!(test-path function:$tModCmdlet)){
         write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet";
         $tModFile = "verb-IO.ps1" ; $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ; if (Test-Path $sLoad) {     Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ; . $sLoad ; if ($showdebug) { Write-Verbose -verbose "Post $sLoad" }; } else {     $sLoad = (join-path -path $backInclDir -childpath $tModFile) ; if (Test-Path $sLoad) {         Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ; . $sLoad ; if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };     }     else { Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ; exit; } ; } ;
    } ;

    if($logspec){
        $logging=$logspec.logging ;
        $logfile=$logspec.logfile ;
        $transcript=$logspec.transcript ;
    } ;

    if ($ModuleDestinationPath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
        $ModuleDestinationPath = get-item -path $ModuleDestinationPath ;
    } ;

    $ModuleRootPath = split-path $ModuleDestinationPath -Parent ;

    $ttl = ($ModuleSourcePath | Measure-Object).count ;
    $iProcd = 0 ;

    $ExportFunctions = @() ;
    $PrivateFunctions = @() ;

    $PsmName="$ModuleDestinationPath\$ModuleName.psm1" ;
    $PsdName="$ModuleDestinationPath\$ModuleName.psd1" ;
    $PsmNameTmp="$ModuleDestinationPath\$ModuleName.psm1_TMP" ;
    $PsdNameTmp="$ModuleDestinationPath\$ModuleName.psd1_TMP" ;


    # backup existing & purge the dyn-include block
    if(test-path -path $PsmName){
        $rawSourceLines = get-content -path $PsmName  ;
        $SrcLineTtl = ($rawSourceLines | Measure-Object).count ;
        $PsmNameBU = backup-File -path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$PsmNameBU) {throw "FAILURE" } ;

        # the above produces 'C:\sc\verb-Auth\verb-Auth\verb-auth.psm1_20210609-1544PM' files from the prior .psm1
        # make it purge all but the last 2 backups above, dated prior to today.
        #$PsmName = 'C:\sc\verb-Auth\verb-Auth\verb-Auth.psm1'
        $pltRGens =[ordered]@{
            Path = (split-path $PsmName) ;
            Include =(split-path $PsmName -leaf).replace('.psm1','.psm1_*') ;
            Pattern = '\.ps(m|d)1_\d{8}-\d{3,4}(A|P)M$' ;
            FilterOn = 'CreationTime' ;
            Keep = 2 ;
            KeepToday = $true ;
            verbose=$true ;
            whatif=$($whatif) ;
        } ; 
        write-host -foregroundcolor green "DEADWOOD REMOVAL:remove-UnneededFileVariants w`n$(($pltRGens|out-string).trim())" ; 
        remove-UnneededFileVariants @pltRGens ;

        # this script *appends* to the existing .psm1 file.
        # which by default includes a dynamic include block:
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        # stock dyanmic export of collected functions
        #$rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        # updated version of dyn end, that also explicitly exports -alias *
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s-Alias\s\*\s;\s'
        $dynIncludeOpen = (select-string -Path  $PsmName -Pattern $rgxPurgeblockStart).linenumber ;
        $dynIncludeClose = (select-string -Path  $PsmName -Pattern $rgxPurgeBlockEnd).linenumber ;
        if(!$dynIncludeOpen){$dynIncludeClose = 0 } ;
        $updatedContent = @() ; $DropContent=@() ;

        if($dynIncludeOpen -AND $dynIncludeClose){
            # dyn psm1
            $smsg= "(dyn-include psm1 detected - purging content...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $updatedContent = $rawSourceLines[0..($dynIncludeOpen-2)] ;
            $updatedContent += $rawSourceLines[($dynIncludeClose)..$Srclinettl] ;
            $DropContent = $rawsourcelines[$dynIncludeOpen..$dynIncludeClose] ;
            if($showdebug){
                $smsg= "`$DropContent:`n$($DropContent|out-string)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;
        } else {
            # monolithic psm1?
            $smsg= "(NON-dyn psm1 detected - purging existing non-CBH content...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            # parse out the CBH and just start from that:
            $oBlkComments = Get-CommentBlocks -TextLines $rawSourceLines -showdebug:$($showdebug) -whatif:$($whatif) ;
            <# returned props
            * metaBlock : `<#PSScriptInfo..#`> published script metadata block (added via New|Update-ScriptFileInfo, at top of file)
            * metaOpen : Line# of start of metaBlock
            * metaClose : Line# of end of metaBlock
            * cbhBlock : Comment-Based-Help block
            * cbhOpen : Line# of start of CBH
            * cbhClose : Line# of end of CBH
            * interText : Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line.
            * metaCBlockIndex : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock
            * CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock
            #>
            <# so we want a stack of
            # [psm1name]

            [metaBlock]
            [interText]
            [cbhBlock]
            [PostCBHBlock]
            [space]
            [optional PostCBHBlock2]
            [space]
            ...and then add the includes to the file
            #>

            # doing a herestring assigned to $updatedContent *unwraps* everything!
            # do them in separately
            #"$($oBlkComments.metaBlock)`n$($oBlkComments.interText)`n$($oBlkComments.cbhBlock)" | Add-Content @pltAdd ;
            $updatedContent += "# $(split-path -path $PsmName -leaf)`n"
            if($oBlkComments.metaBlock){$updatedContent += $oBlkComments.metaBlock  |out-string ; } ;
            if($oBlkComments.interText ){$updatedContent += $oBlkComments.interText  |out-string ; } ;
            $updatedContent += $oBlkComments.cbhBlock |out-string ;

            # Post CBH always add the helper/alias-export command (functions are covered in the psd1 manifest, dyn's have in the template)
            $PostCBHBlock=@"

`$script:ModuleRoot = `$PSScriptRoot ;
`$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem `$script:moduleroot\*.psd1).fullname).moduleversion ;

#*======v FUNCTIONS v======

"@ ;
            $updatedContent += $PostCBHBlock |out-string ;

        } ;  # if-E dyn/monolithic source psm1


        if($updatedContent){
            $bRet = Set-FileContent -Text $updatedContent -Path $PsmNameTmp -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$bRet) {throw "FAILURE" } else {
                $PassStatus += ";UPDATED:Set-FileContent ";
            }  ;
        } else {
            $PassStatus += ";ERROR:Set-FileContent";
            $smsg= "NO PARSEABLE METADATA/CBH CONTENT IN EXISTING FILE, TO BUILD UPDATED PSM1 FROM!`n$($PsmName)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ;
                PsmNameBU = $PsmNameBU ;
                PassStatus = $PassStatus ;
            } ;
            $ReportObj | write-output ;
            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
        } ;
    } ;

    # DEFAULT - DIRS CREATION - git doesn't reproduce empty dirs, create if empty (avoids errors later)
    # exempt the .git & .vscode dirs, we don't publish those to modules dir
    $DefaultModDirs = "Public","Internal","Classes","Tests","Docs","Docs\Cab","Docs\en-US","Docs\Markdown" ;
    foreach($Dir in $DefaultModDirs){
        $tPath = join-path -path $ModuleRootPath -ChildPath $Dir ;
        if(!(test-path -path $tPath)){
            $pltDir = [ordered]@{
                path     = $tPath ;
                ItemType = "Directory" ;
                ErrorAction="Stop" ;
                whatif   = $($whatif) ;
            } ;
            $smsg = "Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $error.clear() ;
            $bRetry=$false ;
            TRY {
                new-item @pltDir | out-null ;
                $PassStatus += ";new-item:UPDATED";
            } CATCH {
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";new-item:ERROR";
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" }
                $bRetry=$true ;
            } ;
            if($bRetry){
                $pltDir.add('force',$true) ;
                $smsg = "Retry:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $error.clear() ;
                TRY {
                    new-item @pltDir | out-null ;
                    $PassStatus += ";new-item:UPDATED";
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";new-item:ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRetry=$false ;
                    EXIT #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                } ;
            } ;
        } ;
    } ;  # loop-E

    # $MODULESOURCEPATH - DIRS CREATION
    foreach ($ModuleSource in $ModuleSourcePath) {
        $iProcd++ ;
        if ($ModuleSource.GetType().FullName -ne 'System.IO.DirectoryInfo') {
            # git doesn't reproduce empty dirs, create if empty
            if(!(test-path -path $ModuleSource)){
                 $pltDir = [ordered]@{
                    path     = $ModuleSource ;
                    ItemType = "Directory" ;
                    ErrorAction="Stop" ;
                    whatif   = $($whatif) ;
                } ;
                $smsg = "Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $bRetry=$false ;
                $error.clear() ;
                TRY {
                    new-item @pltDir | out-null ;
                    $PassStatus += ";new-item:UPDATED";
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $bRetry=$true ;
                    $PassStatus += ";new-item:ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                if($bRetry){
                    $pltDir.add('force',$true) ;
                    $smsg = "RETRY:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $error.clear() ;
                    TRY {
                        new-item @pltDir | out-null ;
                        $PassStatus += ";new-item:UPDATED";
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";new-item:ERROR";
                        $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $bRetry=$false
                        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                    } ;
                } ;
            } ;
            $ModuleSource = get-item -path $ModuleSource ;
        } ;

        # Process components below $ModuleSource
        $sBnrS = "`n#*------v ($($iProcd)/$($ttl)):$($ModuleSource) v------" ;
        $smsg = "$($sBnrS)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $error.clear() ;
        TRY {
            [array]$ComponentScripts = $null ; [array]$ComponentModules = $null ;
            if($ModuleSource.count){
                # excl -Exclude _CommonCode.ps1 (gets added to .psm1 at end of all processing)
                $ComponentScripts = Get-ChildItem -Path $ModuleSource\*.ps1 -Exclude _CommonCode.ps1 -Recurse -ErrorAction SilentlyContinue | Sort-Object name  ;
                $ComponentModules = Get-ChildItem -Path $ModuleSource\*.psm1 -Recurse -ErrorAction SilentlyContinue | Sort-Object name;
            } ;
            $pltAdd = @{
                Path=$PsmNameTmp ;
                whatif=$whatif;
            } ;
            foreach ($ScriptFile in $ComponentScripts) {
                $smsg= "Processing:$($ScriptFile)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $ParsedContent = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$null) ;
                # detect and throw up on sigs
                if($ParsedContent| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($scriptfile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    exit
                } ;

                # above is literally the entire AST, unfiltered. Should be ALL parsed entities.
                # add demarc comments - this is AST parsed, so it prob doesn't include delimiters
                $sBnrSStart = "`n#*------v $($ScriptFile.name) v------" ;
                $sBnrSEnd = "$($sBnrSStart.replace('-v','-^').replace('v-','^-'))" ;
                "$($sBnrSStart)`n$($ParsedContent.EndBlock.Extent.Text)`n$($sBnrSEnd)" | Add-Content @pltAdd ;

                $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$Null ) ;
                $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;

                # public & functions = public ; private & internal = private - flip output to -showdebug or -verbose, only
                if($ModuleSource -match '(Public|Functions)'){
                    $smsg= "$($ScriptFile.name):PUB FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if($showDebug) {
                        if ($logging -AND ($showDebug -OR $verbose)) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $ExportFunctions += $ASTFunctions.name ;
                } elseif($ModuleSource -match '(Private|Internal)'){
                    $smsg= "$($ScriptFile.name):PRIV FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if($showDebug) {
                        if ($logging -AND ($showDebug -OR $verbose)) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $PrivateFunctions += $ASTFunctions.name ;
                } ;
            } ; # loop-E

            # Process Modules below project
            foreach ($ModFile in $ComponentModules) {
                $smsg= "Adding:$($ModFile)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $Content = Get-Content $ModFile ;

                if($Content| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                    if($showDebug) {
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    exit ;
                } ;
                $Content | Add-Content @pltAdd ;
                $PassStatus += ";Add-Content:UPDATED";
                # by contrast, this is NON-AST parsed - it's appending the entire raw file content. Shouldn't need delimiters - they'd already be in source .psm1
            } ;

        } CATCH {
            $ErrorTrapped = $Error[0] ;
            $PassStatus += ";ComponentLoop:ERROR";
            $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ;
                PsmNameBU = $PsmNameBU ;
                PassStatus = $PassStatus ;
            } ;
            $ReportObj | write-output ;
            #Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            Continue ;
        } ;

        $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;


    } ; # loop-E

    # add support for Public\_CommonCode.ps1 (module-spanning code that trails the functions block in the .psm1)
    if($PublicPath = $ModuleSourcePath |Where-Object{$_ -match 'Public'}){
        if($ModFile = Get-ChildItem -Path $PublicPath\_CommonCode.ps1 -ea 0 ){
            $smsg= "Adding:$($ModFile)..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            "#*======v _CommonCode v======" | Add-Content @pltAdd ;
            $Content = Get-Content $ModFile ;
            if($Content| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                if($showDebug) {
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                exit ;
            } ;
            $Content | Add-Content @pltAdd ;
            "#*======^ END _CommonCode ^======" | Add-Content @pltAdd ;
            $PassStatus += ";Add-Content:UPDATED";
        } else {
            write-verbose "(no Public\_CommonCode.ps1)" ;
        } ;
    } ;

    # append the Export-ModuleMember -Function $publicFunctions  (psd1 functionstoexport is functional instead),
    $smsg= "(Updating Psm1 Export-ModuleMember -Function to reflect Public modules)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;
    # Collect & set explicitly in the psm1, the psd1 Set-ModuleFunctoin buildhelper isn't doing the full set, only above.
    # stick the Alias * in there too, force it as the psd1 spec's simply override the explicits in the psm1

    #"`nExport-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *" | Add-Content @pltAdd ;

    # tack in footerblock to the merged psm1 (primarily export-modulemember -alias * ; can also be any function-trailing content you want in the psm1)
    $FooterBlock=@"

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *

"@ ;

    if(-not($NoAliasExport)){
        $smsg= "Adding:FooterBlock..." ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #$updatedContent += $FooterBlock |out-string ;
        $pltAdd = @{
            Path=$PsmNameTmp ;
            whatif=$whatif;
        } ;
        $FooterBlock | Add-Content @pltAdd ;
        $PassStatus += ";Add-Content:UPDATED";
    } else {
        $smsg= "NoAliasExport specified:Skipping FooterBlock add" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        "#*======^ END FUNCTIONS ^======" | Add-Content @pltAdd ;
        $PassStatus += ";Add-Content:UPDATED";
    } ;


    # update the manifest too: # should be forced array: FunctionsToExport = @('build-VSCConfig','Get-CommentBlocks','get-VersionInfo','Merge-Module','parseHelp')
    $smsg = "Updating the Psd1 FunctionsToExport to match" ;
    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    $rgxFuncs2Export = 'FunctionsToExport((\s)*)=((\s)*).*' ;
    $tf = $PsdName ;
    # switch back to manual local updates
    if($psd1ExpMatch = Get-ChildItem $tf | select-string -Pattern $rgxFuncs2Export ){
        $enc=$null ; $enc=get-FileEncoding -path $tf ;
        if($enc -eq 'ASCII') {
            $enc = 'UTF8' ;
            $smsg = "(ASCI encoding detected, converting to UTF8)" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
        } ; # force damaged/ascii to UTF8
        $pltSetCon=[ordered]@{ Path=$PsdNameTmp ; whatif=$($whatif) ;  } ;
        if($enc){$pltSetCon.add('encoding',$enc) } ;
        (Get-Content $tf) | Foreach-Object {
            $_ -replace $rgxFuncs2Export , ("FunctionsToExport = " + "@('" + $($ExportFunctions -join "','") + "')")
        } | Set-Content @pltSetCon ;
        $PassStatus += ";Set-Content:UPDATED";
    } else {
        $smsg = "UNABLE TO Regex out $($rgxFuncs2Export) from $($tf)`nFunctionsToExport CAN'T BE UPDATED!" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } ;

    #if($PassStatus.tolower().contains('error')){ # not properly matching, switch to select-string regex, the appends are line per append, multiline seems to break contains.
    if($PassStatus.tolower() | select-string '.*error.*'){
        $smsg = "ERRORS LOGGED, ABORTING UPDATE OF ORIGINAL .PSM1!:`n$($pltCpy.Destination)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } elseif(!$whatif) {
        if(test-path $PsmNameTmp){
            $pltCpy = @{
                Path=$PsmNameTmp ;
                Destination=$PsmName ;
                whatif=$whatif;
                ErrorAction="STOP" ;
            } ;
            $smsg = "Processing error free: Overwriting temp .psm1 with temp copy`ncopy-item w`n$(($pltCpy|out-string).trim())" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $error.clear() ;
            TRY {
                copy-Item @pltCpy ;
                $PassStatus += ";copy-Item:UPDATED";
            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $PassStatus += ";copy-Item:ERROR";
                Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            } ;
        } else {
            $smsg = "UNABLE TO LOCATE temp .psm1!:`n$($pltCpy.path)" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $PassStatus += ";test-path $PsmNameTmp:ERROR";
        } ;
        # $PsdNameTmp/$PsdName
        if(test-path $PsdNameTmp){
            $pltCpy = @{
                Path=$PsdNameTmp ;
                Destination=$PsdName ;
                whatif=$whatif;
                ErrorAction="STOP" ;
            } ;
            $smsg = "Processing error free: Overwriting temp .psd1 with temp copy`ncopy-item w`n$(($pltCpy|out-string).trim())" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $error.clear() ;
            TRY {
                copy-Item @pltCpy ;
                $PassStatus += ";copy-Item:UPDATE";
            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $PassStatus += ";copy-Item:ERROR";
                Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            } ;
        } else {
            $smsg = "UNABLE TO LOCATE temp .psm1!:`n$($pltCpy.path)" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $PassStatus += ";test-path $PsdNameTmp:ERROR";
        } ;
    } else {
        $smsg = "(whatif:skipping updates)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    };
    $ReportObj=[ordered]@{
        Status=$true ;
        PsmNameBU = $PsmNameBU ;
        PassStatus = $PassStatus ;
    } ;
    if($PassStatus.tolower() | select-string '.*error.*'){
        $ReportObj.Status=$false ;
    } ;
    $ReportObj | write-output ;
    
    $smsg = $sBnr.replace('=v','=^').replace('v=','^=') ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
}

#*------^ Merge-Module.ps1 ^------

#*------v Merge-ModulePs1.ps1 v------
function Merge-ModulePs1 {
    <#
    .SYNOPSIS
    Merge-ModulePs1.ps1 - Merge function .ps1 files into a monolisthic uwes\[module].ps1 backload file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2019-12-10
    FileName    : Merge-ModulePs1.ps1
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit : Przemyslaw Klys
    AddedWebsite: https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/
    AddedTwitter:
    REVISIONS
    * 12:18 PM 4/21/2021 expanded select-string aliases
    * 10:50 AM 9/25/2020 debugged, looks functional, resulting .ps1 will dot-source load wo issues ; port over from merg-module.ps1 -> merge-moduleps1.ps1
    * 11:42 AM 6/30/2020 fixed Public\_CommonCode.ps1, -ea 0 when not present
    * 1:13 PM 6/29/2020 add support for .Public\_CommonCode.ps1 - module-spanning code that should follow the Function block in the .psm1
    * 3:27 PM 3/15/2020 load-Module: added $PsmNameTmp, $PsdNameTmp and shifted updating to a _TMP file of each, which at end, if error free, overwrites the current functional copy (correcting prior issue with corruption of existing copy, when there were processing errors).
    * failing to load verb-io content, added a forceload if get-fileencoding isn't present, added new PassStatus tests and passed back in output, also now does the build in a .psm1_TMP file, to avoid damaging last functional copy
    * 12:42 PM 3/3/2020 fixed missing trailing sbnr (Internal)
    * 10:36 AM 3/3/2020 added pre-check & echo when unable to locate the psd1 FunctionsToExport value
    * 1:58 PM 3/2/2020 as Set-ModuleFunction isn't properly setting *all* exported, go back to collecting and updating the psm1 & psd1 *both* via regx
    * 9:12 AM 2/29/2020 shift export-modulemember/FooterBlock to bottom, added FUNCTIONS delimiter lines
    * 9:17 AM 2/27/2020 added new -NoAliasExport param, and added the missing
    * 3:44 PM 2/26/2020 Merge-ModulePs1: added -LogSpec param (feed it the object returned by a Start-Log() pass).
    * 11:27 AM Merge-ModulePs1 2/24/2020 suppress block dumps to console, unless -showdebug or -verbose in use
    * 7:24 AM 1/3/2020 #936: trimmed errant trailing ;- byproduct of fix-encoding pass
    * 10:33 AM 12/30/2019 Merge-ModulePs1():951,952 assert sorts into alpha order (make easier to find in the psm1)
    * 10:20 AM 12/30/2019 Merge-ModulePs1(): fixed/debugged monolithic build options, now works. Could use some code to autoupdate all .NOTES:Version fields, but that's for future.
    * 8:59 AM 12/30/2019 Merge-ModulePs1(): Added code to update against monolithic/non-dyn-incl psm1s. Parses CBH & meta blocks out & constructs a new psm1 from the content.
    * 9:51 AM 12/28/2019 Merge-ModulePs1 fixed $sBnrSStart/End typo
    * 1:23 PM 12/27/2019 pulled regex sig replace with simple start/end detect and throw error (was leaving dangling curlies in psm1)
    * 12:11 PM 12/27/2019 swapped write-error in catch blocks with write-warning - we seems to be failing to exec the bal of the catch
    * 7:46 AM 12/27/2019 Merge-ModulePs1(): added included file demarc comments to improve merged file visual parsing, accumulating $PrivateFunctions now as well, explicit echos
    * 8:51 AM 12/20/2019 removed plural from ModuleSourcePaths -> ModuleSourcePath (matches all the calls etc)
    *8:50 PM 12/18/2019 sorted hard-coded verb-aad typo
    2:54 PM 12/11/2019 rewrote, added backup of psm1, parsing out the stock dyn-include code from the orig psm1, leverages fault-tolerant set-fileContent(), switched sourcepaths to array type, and looped, detecting public/internal by path and prepping for the export list.
    * 2018/11/06 Przemyslaw Klys posted version
    .DESCRIPTION
    Merge-ModulePs1.ps1 - Merge function .ps1 files into a monolisthic uwes\[module].ps1 backload file, returns a hash with status:$true/$false, and PsmNameBU:The name of a backup of the original .psm1 file (for restoring on failures)
    Essentially once a module is validated functional, migrate the updated component functions into the uwes\[module].ps1 backload file
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER  ModuleSourcePath
    Directory containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]
    .PARAMETER ModuleDestinationPs1File
    Final monolithic module .psm1 file name to be populated [-ModuleDestinationPs1File c:\path-to\module\module.psm1]
    .PARAMETER NoAliasExport
    Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable object containing: Status[$true/$false], PsmNameBU [the name of the backup of the original psm1 file]
    .EXAMPLE
    cls ; Merge-ModulePs1 -ModuleName verb-AAD -ModuleSourcePath C:\sc\verb-AAD\Public -ModuleDestinationPs1File c:\usr\work\exch\scripts\verb-AAD.ps1 -showdebug -whatif ;
    Command line process
    .LINK
    https://www.toddomation.com
    #>
    param (
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.ps1 file)[-ModuleName verb-XXX]")]
        [string] $ModuleName,
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePath c:\path-to\module\Public]")]
        [array] $ModuleSourcePath,
        [Parameter(Mandatory = $True, HelpMessage = "Full path to the final [modle].ps1 file should be constructed [-ModuleDestinationPs1File c:\path-to\scripts\module.ps1]")]
        [string] $ModuleDestinationPs1File,
        [Parameter(Mandatory = $False, HelpMessage = "Logging spec object (output from start-log())[-LogSpec `$LogSpec]")]
        $LogSpec,
        [Parameter(HelpMessage = "Flag that skips auto-inclusion of 'Export-ModuleMember -Alias * ' in merged file [-NoAliasExport]")]
        [switch] $NoAliasExport,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $verbose = ($VerbosePreference -eq "Continue") ;

    $rgxSigStart='#\sSIG\s#\sBegin\ssignature\sblock' ;
    $rgxSigEnd='#\sSIG\s#\sEnd\ssignature\sblock' ;

    $PassStatus = $null ;
    $PassStatus = @() ;

    $tModCmdlet = "Get-FileEncoding" ;
    if(!(test-path function:$tModCmdlet)){
         write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet";
         $tModFile = "verb-IO.ps1" ; $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ; if (Test-Path $sLoad) {     Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ; . $sLoad ; if ($showdebug) { Write-Verbose -verbose "Post $sLoad" }; } else {     $sLoad = (join-path -path $backInclDir -childpath $tModFile) ; if (Test-Path $sLoad) {         Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ; . $sLoad ; if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };     }     else { Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ; exit; } ; } ;
    } ;

    if($logspec){
        $logging=$logspec.logging ;
        $logfile=$logspec.logfile ;
        $transcript=$logspec.transcript ;
    } ;

    # expects an existing target file (may want to rem this test out)
    if ($ModuleDestinationPs1File.GetType().FullName -ne 'System.IO.FileInfo') {
        $ModuleDestinationPs1File = get-childitem -path $ModuleDestinationPs1File ;
    } ;

    $ModuleRootPath = split-path $ModuleDestinationPs1File -Parent ;

    $ttl = ($ModuleSourcePath | Measure-Object).count ;
    $iProcd = 0 ;

    $ExportFunctions = @() ;
    $PrivateFunctions = @() ;

    <#$PsmName="$ModuleDestinationPath\$ModuleName.psm1" ;
    $PsdName="$ModuleDestinationPath\$ModuleName.psd1" ;
    $PsmNameTmp="$ModuleDestinationPath\$ModuleName.psm1_TMP" ;
    $PsdNameTmp="$ModuleDestinationPath\$ModuleName.psd1_TMP" ;
    #>
    $ModuleDestinationPs1FileTmp = $ModuleDestinationPs1File.replace('.ps1','.ps1_TMP') ;

    # backup existing & purge the dyn-include block
    if(test-path -path $ModuleDestinationPs1File){
        $rawSourceLines = get-content -path $ModuleDestinationPs1File  ;
        $SrcLineTtl = ($rawSourceLines | Measure-Object).count ;
        $ModuleDestinationPs1FileBU = backup-File -path $ModuleDestinationPs1File -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$ModuleDestinationPs1FileBU) {throw "FAILURE" } ;

        # this script *appends* to the existing .ps1 file.
        # which by default includes a dynamic include block:
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        #$rgxPurgeblockStart = "#\*======v\sFUNCTIONS\sv======"
        # stock dyanmic export of collected functions
        #$rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        # updated version of dyn end, that also explicitly exports -alias *
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s-Alias\s\*\s;\s'
        #$rgxPurgeBlockEnd  = "#\*======\^\sEND\sFUNCTIONS\s\^======" ;
        $dynIncludeOpen = (Select-object -Path  $ModuleDestinationPs1File -Pattern $rgxPurgeblockStart).linenumber ;
        if($dynIncludeOpen -is [system.array]){
            $dynIncludeOpen = $dynIncludeOpen[-1] ;
        } ;
        $dynIncludeClose = (Select-object -Path  $ModuleDestinationPs1File -Pattern $rgxPurgeBlockEnd).linenumber ;
        if($dynIncludeClose -is [system.array]){
            $dynIncludeClose = $dynIncludeClose[-1] ;
        } ;
        if(!$dynIncludeOpen){$dynIncludeClose = 0 } ;
        $updatedContent = @() ; $DropContent=@() ;

        # 11:31 AM 9/25/2020 this shouldn't be done dyn, it should be monolithic
        if($dynIncludeOpen -AND $dynIncludeClose){
            # dyn psm1
            $smsg= "(dyn-include psm1 detected - purging content...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $updatedContent = $rawSourceLines[0..($dynIncludeOpen-2)] ;
            $updatedContent += $rawSourceLines[($dynIncludeClose)..$Srclinettl] ;
            $DropContent = $rawsourcelines[$dynIncludeOpen..$dynIncludeClose] ;
            if($showdebug){
                $smsg= "`$DropContent:`n$($DropContent|out-string)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;
        } else {
            # monolithic psm1?
            $smsg= "(NON-dyn psm1 detected - purging existing non-CBH content...)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            # parse out the CBH and just start from that:
            $oBlkComments = Get-CommentBlocks -TextLines $rawSourceLines -showdebug:$($showdebug) -whatif:$($whatif) ;
            <# returned props
            * metaBlock : `<#PSScriptInfo..#`> published script metadata block (added via New|Update-ScriptFileInfo, at top of file)
            * metaOpen : Line# of start of metaBlock
            * metaClose : Line# of end of metaBlock
            * cbhBlock : Comment-Based-Help block
            * cbhOpen : Line# of start of CBH
            * cbhClose : Line# of end of CBH
            * interText : Block of text *between* any metaBlock metaClose line, and any CBH cbhOpen line.
            * metaCBlockIndex : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the metaBlock
            * CbhCBlockIndex  : Of the collection of all block comments - `<#..#`> - the index of the one corresponding to the cbhBlock
            #>
            <# so we want a stack of
            # [psm1name]

            [metaBlock]
            [interText]
            [cbhBlock]
            [PostCBHBlock]
            [space]
            [optional PostCBHBlock2]
            [space]
            ...and then add the includes to the file
            #>

            # doing a herestring assigned to $updatedContent *unwraps* everything!
            # do them in separately
            #"$($oBlkComments.metaBlock)`n$($oBlkComments.interText)`n$($oBlkComments.cbhBlock)" | Add-Content @pltAdd ;
            $updatedContent += "# $(split-path -path $ModuleDestinationPs1File -leaf)`n"
            if($oBlkComments.metaBlock){$updatedContent += $oBlkComments.metaBlock  |out-string ; } ;
            if($oBlkComments.interText ){$updatedContent += $oBlkComments.interText  |out-string ; } ;
            $updatedContent += $oBlkComments.cbhBlock |out-string ;

            # Post CBH always add the helper/alias-export command (functions are covered in the psd1 manifest, dyn's have in the template)
            <# .psm1 block
            $PostCBHBlock=@"

`$script:ModuleRoot = `$PSScriptRoot ;
`$script:ModuleVersion = (Import-PowerShellDataFile -Path (get-childitem `$script:moduleroot\*.psd1).fullname).moduleversion ;

#*======v FUNCTIONS v======

"@ ;
#>
            # ps1 block
            $PostCBHBlock=@"

#*======v FUNCTIONS v======

"@ ;

            $updatedContent += $PostCBHBlock |out-string ;

        } ;  # if-E dyn/monolithic source psm1


        if($updatedContent){
            $bRet = Set-FileContent -Text $updatedContent -Path $ModuleDestinationPs1FileTmp -showdebug:$($showdebug) -whatif:$($whatif) ;
            if (!$bRet) {throw "FAILURE" } else {
                $PassStatus += ";UPDATED:Set-FileContent ";
            }  ;
        } else {
            $PassStatus += ";ERROR:Set-FileContent";
            $smsg= "NO PARSEABLE METADATA/CBH CONTENT IN EXISTING FILE, TO BUILD UPDATED PSM1 FROM!`n$($ModuleDestinationPs1File)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ;
                PsmNameBU = $ModuleDestinationPs1FileBU ;
                PassStatus = $PassStatus ;
            } ;
            $ReportObj | write-output ;
            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
        } ;
    } ;

    # don't need this on monolithic .ps1 backload file
    # DEFAULT - DIRS CREATION - git doesn't reproduce empty dirs, create if empty (avoids errors later)
    # exempt the .git & .vscode dirs, we don't publish those to modules dir
    $DefaultModDirs = "Public","Internal","Classes","Tests","Docs","Docs\Cab","Docs\en-US","Docs\Markdown" ;
    foreach($Dir in $DefaultModDirs){
        $tPath = join-path -path $ModuleRootPath -ChildPath $Dir ;
        if(!(test-path -path $tPath)){
            $pltDir = [ordered]@{
                path     = $tPath ;
                ItemType = "Directory" ;
                ErrorAction="Stop" ;
                whatif   = $($whatif) ;
            } ;
            $smsg = "Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $error.clear() ;
            $bRetry=$false ;
            TRY {
                new-item @pltDir | out-null ;
                $PassStatus += ";new-item:UPDATED";
            } CATCH {
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";new-item:ERROR";
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" }
                $bRetry=$true ;
            } ;
            if($bRetry){
                $pltDir.add('force',$true) ;
                $smsg = "Retry:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $error.clear() ;
                TRY {
                    new-item @pltDir | out-null ;
                    $PassStatus += ";new-item:UPDATED";
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";new-item:ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRetry=$false ;
                    EXIT #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                } ;
            } ;
        } ;
    } ;  # loop-E

    # $MODULESOURCEPATH - DIRS CREATION
    foreach ($ModuleSource in $ModuleSourcePath) {
        $iProcd++ ;
        if ($ModuleSource.GetType().FullName -ne 'System.IO.DirectoryInfo') {
            <#
            # git doesn't reproduce empty dirs, create if empty
            if(!(test-path -path $ModuleSource)){
                 $pltDir = [ordered]@{
                    path     = $ModuleSource ;
                    ItemType = "Directory" ;
                    ErrorAction="Stop" ;
                    whatif   = $($whatif) ;
                } ;
                $smsg = "Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $bRetry=$false ;
                $error.clear() ;
                TRY {
                    new-item @pltDir | out-null ;
                    $PassStatus += ";new-item:UPDATED";
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $bRetry=$true ;
                    $PassStatus += ";new-item:ERROR";
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                if($bRetry){
                    $pltDir.add('force',$true) ;
                    $smsg = "RETRY:FORCE:Creating missing dir:new-Item w`n$(($pltDir|out-string).trim())" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $error.clear() ;
                    TRY {
                        new-item @pltDir | out-null ;
                        $PassStatus += ";new-item:UPDATED";
                    } CATCH {
                        $ErrorTrapped = $Error[0] ;
                        $PassStatus += ";new-item:ERROR";
                        $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $bRetry=$false
                        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
                    } ;
                } ;
            } ;
            #>
            $ModuleSource = get-item -path $ModuleSource ;
        } ;

        # Process components below $ModuleSource
        $sBnrS = "`n#*------v ($($iProcd)/$($ttl)):$($ModuleSource) v------" ;
        $smsg = "$($sBnrS)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $error.clear() ;
        TRY {
            [array]$ComponentScripts = $null ; [array]$ComponentModules = $null ;
            if($ModuleSource.count){
                # excl -Exclude _CommonCode.ps1 (gets added to .ps1 at end of all processing)
                $ComponentScripts = Get-ChildItem -Path $ModuleSource\*.ps1 -Exclude _CommonCode.ps1 -Recurse -ErrorAction SilentlyContinue | Sort-Object name  ;
                $ComponentModules = Get-ChildItem -Path $ModuleSource\*.ps1 -Recurse -ErrorAction SilentlyContinue | Sort-Object name;
            } ;
            $pltAdd = @{
                Path=$ModuleDestinationPs1FileTmp ;
                whatif=$whatif;
            } ;
            foreach ($ScriptFile in $ComponentScripts) {
                $smsg= "Processing:$($ScriptFile)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $ParsedContent = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$null) ;
                # detect and throw up on sigs
                if($ParsedContent| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($scriptfile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    exit
                } ;

                # above is literally the entire AST, unfiltered. Should be ALL parsed entities.
                # add demarc comments - this is AST parsed, so it prob doesn't include delimiters
                $sBnrSStart = "`n#*------v $($ScriptFile.name) v------" ;
                $sBnrSEnd = "$($sBnrSStart.replace('-v','-^').replace('v-','^-'))" ;
                "$($sBnrSStart)`n$($ParsedContent.EndBlock.Extent.Text)`n$($sBnrSEnd)" | Add-Content @pltAdd ;

                $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$Null ) ;
                $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;

                # public & functions = public ; private & internal = private - flip output to -showdebug or -verbose, only
                if($ModuleSource -match '(Public|Functions)'){
                    $smsg= "$($ScriptFile.name):PUB FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if($showDebug) {
                        if ($logging -AND ($showDebug -OR $verbose)) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $ExportFunctions += $ASTFunctions.name ;
                } elseif($ModuleSource -match '(Private|Internal)'){
                    $smsg= "$($ScriptFile.name):PRIV FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if($showDebug) {
                        if ($logging -AND ($showDebug -OR $verbose)) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    $PrivateFunctions += $ASTFunctions.name ;
                } ;
            } ; # loop-E

            # Process Modules below project
            foreach ($ModFile in $ComponentModules) {
                $smsg= "Adding:$($ModFile)..." ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                $Content = Get-Content $ModFile ;

                if($Content| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                    $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                    if($showDebug) {
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ;
                    exit ;
                } ;
                $Content | Add-Content @pltAdd ;
                $PassStatus += ";Add-Content:UPDATED";
                # by contrast, this is NON-AST parsed - it's appending the entire raw file content. Shouldn't need delimiters - they'd already be in source .ps1
            } ;

        } CATCH {
            $ErrorTrapped = $Error[0] ;
            $PassStatus += ";ComponentLoop:ERROR";
            $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$false | write-output ;
            $ReportObj=[ordered]@{
                Status=$false ;
                PsmNameBU = $ModuleDestinationPs1FileBU ;
                PassStatus = $PassStatus ;
            } ;
            $ReportObj | write-output ;
            #Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            Continue ;
        } ;

        $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;


    } ; # loop-E

    # add support for Public\_CommonCode.ps1 (module-spanning code that trails the functions block in the .ps1)
    if($PublicPath = $ModuleSourcePath |Where-Object{$_ -match 'Public'}){
        if($ModFile = Get-ChildItem -Path $PublicPath\_CommonCode.ps1 -ea 0 ){
            $smsg= "Adding:$($ModFile)..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            "#*======v _CommonCode v======" | Add-Content @pltAdd ;
            $Content = Get-Content $ModFile ;
            if($Content| Where-Object{$_ -match $rgxSigStart -OR $_ -match $rgxSigEnd} ){
                $smsg= "*WARNING*:SUBFILE`n$($ModFile.fullname)`nHAS AUTHENTICODE SIGNATURE MARKERS PRESENT!`nREVIEW THE FILE AND REMOVE ANY EVIDENCE OF SIGNING!" ;
                if($showDebug) {
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
                exit ;
            } ;
            $Content | Add-Content @pltAdd ;
            "#*======^ END _CommonCode ^======" | Add-Content @pltAdd ;
            $PassStatus += ";Add-Content:UPDATED";
        } else {
            write-verbose "(no Public\_CommonCode.ps1)" ;
        } ;
    } ;

    <# psm1 code
    # append the Export-ModuleMember -Function $publicFunctions  (psd1 functionstoexport is functional instead),
    $smsg= "(Updating Psm1 Export-ModuleMember -Function to reflect Public modules)" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;
    # Collect & set explicitly in the psm1, the psd1 Set-ModuleFunctoin buildhelper isn't doing the full set, only above.
    # stick the Alias * in there too, force it as the psd1 spec's simply override the explicits in the psm1

    #"`nExport-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *" | Add-Content @pltAdd ;
    #>

    # tack in footerblock to the merged psm1 (primarily export-modulemember -alias * ; can also be any function-trailing content you want in the psm1)
    <# psm1 block
    $FooterBlock=@"

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function $(($ExportFunctions) -join ',') -Alias *

"@ ;
#>
    # ps1 block
    $FooterBlock=@"

#*======^ END FUNCTIONS ^======

"@ ;

    if(-not($NoAliasExport)){
        $smsg= "Adding:FooterBlock..." ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #$updatedContent += $FooterBlock |out-string ;
        $pltAdd = @{
            Path=$ModuleDestinationPs1FileTmp ;
            whatif=$whatif;
        } ;
        $FooterBlock | Add-Content @pltAdd ;
        $PassStatus += ";Add-Content:UPDATED";
    } else {
        $smsg= "NoAliasExport specified:Skipping FooterBlock add" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        "#*======^ END FUNCTIONS ^======" | Add-Content @pltAdd ;
        $PassStatus += ";Add-Content:UPDATED";
    } ;


    <# psm1/psd1 block
    # update the manifest too: # should be forced array: FunctionsToExport = @('build-VSCConfig','Get-CommentBlocks','get-VersionInfo','Merge-ModulePs1','parseHelp')
    $smsg = "Updating the Psd1 FunctionsToExport to match" ;
    if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    $rgxFuncs2Export = 'FunctionsToExport((\s)*)=((\s)*).*' ;
    $tf = $PsdName ;
    # switch back to manual local updates
    if($psd1ExpMatch = gci $tf |select-string -Pattern $rgxFuncs2Export ){
        $enc=$null ; $enc=get-FileEncoding -path $tf ;
        if($enc -eq 'ASCII') {
            $enc = 'UTF8' ;
            $smsg = "(ASCI encoding detected, converting to UTF8)" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
        } ; # force damaged/ascii to UTF8
        $pltSetCon=[ordered]@{ Path=$PsdNameTmp ; whatif=$($whatif) ;  } ;
        if($enc){$pltSetCon.add('encoding',$enc) } ;
        (Get-Content $tf) | Foreach-Object {
            $_ -replace $rgxFuncs2Export , ("FunctionsToExport = " + "@('" + $($ExportFunctions -join "','") + "')")
        } | Set-Content @pltSetCon ;
        $PassStatus += ";Set-Content:UPDATED";
    } else {
        $smsg = "UNABLE TO Regex out $($rgxFuncs2Export) from $($tf)`nFunctionsToExport CAN'T BE UPDATED!" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } ;
    #>

    if($PassStatus.tolower() | select-string '.*error.*'){
        $smsg = "ERRORS LOGGED, ABORTING UPDATE OF ORIGINAL .ps1!:`n$($pltCpy.Destination)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
        else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    } elseif(!$whatif) {
        if(test-path $ModuleDestinationPs1FileTmp){
            $pltCpy = @{
                Path=$ModuleDestinationPs1FileTmp ;
                Destination=$ModuleDestinationPs1File ;
                whatif=$whatif;
                ErrorAction="STOP" ;
            } ;
            $smsg = "Processing error free: Overwriting temp .ps1 with temp copy`ncopy-item w`n$(($pltCpy|out-string).trim())" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $error.clear() ;
            TRY {
                copy-Item @pltCpy ;
                $PassStatus += ";copy-Item:UPDATED";
            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $PassStatus += ";copy-Item:ERROR";
                Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            } ;
        } else {
            $smsg = "UNABLE TO LOCATE temp .ps1!:`n$($pltCpy.path)" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $PassStatus += ";test-path $ModuleDestinationPs1FileTmp:ERROR";
        } ;

        <# psm1/psd1 block
        # $PsdNameTmp/$PsdName
        if(test-path $PsdNameTmp){
            $pltCpy = @{
                Path=$PsdNameTmp ;
                Destination=$PsdName ;
                whatif=$whatif;
                ErrorAction="STOP" ;
            } ;
            $smsg = "Processing error free: Overwriting temp .psd1 with temp copy`ncopy-item w`n$(($pltCpy|out-string).trim())" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $error.clear() ;
            TRY {
                copy-Item @pltCpy ;
                $PassStatus += ";copy-Item:UPDATE";
            } CATCH {
                Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                $PassStatus += ";copy-Item:ERROR";
                Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            } ;
        } else {
            $smsg = "UNABLE TO LOCATE temp .ps1!:`n$($pltCpy.path)" ;
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
            else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
            $PassStatus += ";test-path $PsdNameTmp:ERROR";
        } ;
        #>

    } else {
        $smsg = "(whatif:skipping updates)" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR} #Error|Warn|Debug
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ;
    };
    $ReportObj=[ordered]@{
        Status=$true ;
        PsmNameBU = $ModuleDestinationPs1FileBU ;
        PassStatus = $PassStatus ;
    } ;
    if($PassStatus.tolower() | select-string '.*error.*'){
        $ReportObj.Status=$false ;
    } ;
    $ReportObj | write-output ;
}

#*------^ Merge-ModulePs1.ps1 ^------

#*------v new-CBH.ps1 v------
function new-CBH {
    <#
    .SYNOPSIS
    new-CBH - Parse Script and prepend new Comment-based-Help keyed to existing contents
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:45 PM 11/16/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,Development,Scripts
    REVISIONS
    * 11:38 AM 4/14/2020 flipped filename from fullname to name
    * 4:42 PM 4/9/2020 ren NewCBH-> new-CBH shift into verb-Dev.psm1
    * 9:12 PM 11/25/2019 new-CBH: added dummy parameter name fields - drop them and you get no CBH function
    * 6:47 PM 11/24/2019 new-CBH: got revision of through a full pass of adding a new CBH addition to a non-compliant file.
    * 3:48 PM 11/16/2019 INIT
    .DESCRIPTION
    new-CBH - Parse Script and prepend new Comment-based-Help keyed to existing contents
    .PARAMETER  Path
    Path to script
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $updatedContent = new-CBH -Path $oSrc.fullname -showdebug:$($showdebug) -whatif:$($whatif) ;
    .LINK
    #>
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-Path path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    if ($Path.GetType().FullName -ne 'System.IO.FileInfo') {
        $Path = get-childitem -path $Path ;
    } ;

    $sQot = [char]34 ; $sQotS = [char]39 ;
    $NewCBH = $null ; $NewCBH = @() ;

    $smsg = "Opening a copy for reference" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug

    $editor = "notepad2.exe" ;
    $editorArgs = "$($path.fullname)" ;
    Invoke-Command -ScriptBlock { & $editor $editorArgs } ;
    write-host "`a" ;
    write-host "`a" ;
    write-host "`a" ;

    $sSynopsis = Read-Host "Enter Script SYNOPSIS text"

    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path.fullname, [ref]$null, [ref]$Null ) ;

    # parameters declared in the AST PARAM() Block
    $ASTParameters = $ast.ParamBlock.Parameters.Name.variablepath.userpath ;

    $DefaultHelpTop = @"
#VERB-NOUN.ps1

<#
.SYNOPSIS
VERB-NOUN.ps1 - $($sSynopsis)
.NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     : https://www.toddomation.com
Twitter     : @tostka / http://twitter.com/tostka
CreatedDate : $(get-date -format yyyy-MM-dd)
FileName    : $($Path.name)
License     : MIT License
Copyright   : (c)  $(get-date -format yyyy) Todd Kadrie. All rights reserved.
Github      : https://github.com/tostka
Tags        : Powershell
AddedCredit : REFERENCE
AddedWebsite:	URL
AddedTwitter:	URL
REVISIONS
* $(get-date -format 'HH:mm tt MM/dd/yyyy') Added default CBH
.DESCRIPTION
VERB-NOUN.ps1 - $($sSynopsis)
"@ ;

    $DefaultHelpBottom=@"
.PARAMETER ShowDebug
Parameter to display Debugging messages [-ShowDebug switch]
.PARAMETER Whatif
Parameter to run a Test no-change pass [-Whatif switch]
.EXAMPLE
.\VERB-NOUN.ps1
.EXAMPLE
.\VERB-NOUN.ps1
.LINK
#>
"@ ;

    $DefaultHelpBottom = @"
.PARAMETER ShowDebug
Parameter to display Debugging messages [-ShowDebug switch]
.PARAMETER Whatif
Parameter to run a Test no-change pass [-Whatif switch]
.EXAMPLE
.\VERB-NOUN.ps1
.EXAMPLE
.\VERB-NOUN.ps1
.LINK
#>
"@ ;


    $NewCBH += $DefaultHelpTop ;
    $rgxStr = 'HelpMessage=' + $sQot + "(.*)" + $sQot ;

    if (($ASTParameters | measure).count -eq 0) {
        $NewCBH += ".PARAMETER PARAMETERNAME`nPARAMETERNAMEDESCRIPTION" ;
        <# do NOT create undefined parameters - sticking a .parameter in wo a
        parametername, will BREAK get-help CBH function#>
    }
    else {
        foreach ($param in $ASTParameters) {
            $NewCBH += ".PARAMETER`t$($param.variablepath.userpath)`n$($param.variablepath.userpath)DESCRIPTION`n" ;
        } ;
    } ;

    $NewCBH += $DefaultHelpBottom ;
    $NewCBH = $NewCBH -replace ('VERB-NOUN', $Path.name.replace('.ps1', '') ) ;
    <# 7:30 PM 11/24/2019 WATCHOUT FOR *FAKE* CBH "KEYWORDS", CBH will BREAK, if it sees fake keywords.
    The keyword names are case-insensitive, but they must be spelled exactly as specified.
    The dot and the keyword name cannot be separated by even one space.
    None of the keywords are required* in comment-based help, but you can't add or
    change keywords, even it you really want a new one (such as .FILENAME, which
    would be a really good idea). If you use .NOTE (instead of .NOTES) or .EXAMPLES
    (instead of .EXAMPLE), Get-Help doesn't display any of it.
    GUESS WHAT, IF A LINE BEGINS WITH .Net, YOU GUESSED IT! CBH interprets it as a FAKE KEYWORD!
    and BREAKS all cbh retrieval by the get-help command on the file!
    #>
    $rgxFakeCBHKeywords = '^\s*\.[A-Z]+\w*\s*'
    $rgxCBHKeywords = "\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK|COMPONENT|ROLE|FUNCTIONALITY|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE|EXTERNALHELP)"

    [array]$FakeKeywordLines = $null ;
    if( $NewCBH |?{($_ -match $rgxFakeCBHKeywords) -AND ($_ -notmatch $rgxCBHKeyword?)}){
        $smsg= "" ;
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):NOTE!:NEW CBH BLOCK INCLUDES A *FAKE* CBH KEYWORD LINE(S)!`n$(([array]$FakeKeywordLines |out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug
        $CBH = $CBH | ForEach-Object {
            if (($_ -match $rgxFakeCBHKeywords) -AND ($_ -notmatch $rgxCBHKeywords)) {
                $_ -replace '\.(?=[A-Za-z]+)','dot' ;
            } else {
                $_
            } ;
        } ;
    } ;
    $NewCBH | write-output ;

}

#*------^ new-CBH.ps1 ^------

#*------v New-GitHubGist.ps1 v------
Function New-GitHubGist {
    <#
    .SYNOPSIS
    New-GitHubGist.ps1 - Create GitHub Gist from passed param or file contents
    .NOTES
    Author: Jeffery Hicks
    Website:	https://jdhitsolutions.com/blog/powershell/5410/creating-a-github-gist-with-powershell/
    Twitter:	@tostka, http://twitter.com/tostka
    Additional Credits: REFERENCE
    Website:	URL
    Twitter:	URL
    REVISIONS   :
    * 1/26/17 - posted version
    .DESCRIPTION
    .PARAMETER Name
    What is the name for your gist?
    PARAMETER Path
    Path to file of content to be converted
    PARAMETER Content,
    Content to be converted
    PARAMETER Description,
    Description for new Gist
    PARAMETER UserToken
    Github Access Token
    PARAMETER Private
    Switch parameter that specifies creation of a Private Gist
    PARAMETER Passthru
    Passes the new Gist through into pipeline, as a new object
    .EXAMPLE
    New-GitHubGist -Name "BoxPrompt.ps1" -Description "a fancy PowerShell prompt function" -Path S:\boxprompt.ps1
    .LINK
    https://jdhitsolutions.com/blog/powershell/5410/creating-a-github-gist-with-powershell/
    #>

    [cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = "Content")]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "What is the name for your gist?", ValueFromPipelineByPropertyName)]
        [ValidateNotNullorEmpty()]
        [string]$Name,
        [Parameter(ParameterSetName = "path", Mandatory, ValueFromPipelineByPropertyName)]
        [ValidateNotNullorEmpty()]
        [Alias("pspath")]
        [string]$Path,
        [Parameter(ParameterSetName = "Content", Mandatory)]
        [ValidateNotNullorEmpty()]
        [string[]]$Content,
        [string]$Description,
        [Alias("token")]
        [ValidateNotNullorEmpty()]
        [string]$UserToken = $gitToken,
        [switch]$Private,
        [switch]$Passthru
    )

    Begin {
        Write-Verbose "[BEGIN  ] Starting: $($MyInvocation.Mycommand)"

        #create the header
        $head = @{
            Authorization = 'Basic ' + $UserToken
        }
        #define API uri
        $base = "https://api.github.com"

    } #begin

    Process {
        #display PSBoundparameters formatted nicely for Verbose output
        [string]$pb = ($PSBoundParameters | Format-Table -AutoSize | Out-String).TrimEnd()
        Write-Verbose "[PROCESS] PSBoundparameters: `n$($pb.split("`n").Foreach({"$("`t"*2)$_"}) | Out-String) `n"

        #json section names must be lowercase
        #format content as a string

        switch ($pscmdlet.ParameterSetName) {
            "path" {
                $gistContent = Get-Content -Path $Path | Out-String
            }
            "content" {
                $gistContent = $Content | Out-String
            }
        } #close Switch

        $data = @{
            files       = @{$Name = @{content = $gistContent } }
            description = $Description
            public      = (-Not ($Private -as [boolean]))
        } | Convertto-Json

        Write-Verbose ($data | out-string)
        Write-Verbose "[PROCESS] Posting to $base/gists"

        If ($pscmdlet.ShouldProcess("$name [$description]")) {

            #parameters to splat to Invoke-Restmethod
            $invokeParams = @{
                Method      = 'Post'
                Uri         = "$base/gists"
                Headers     = $head
                Body        = $data
                ContentType = 'application/json'
            }

            $r = Invoke-Restmethod @invokeParams

            if ($Passthru) {
                Write-Verbose "[PROCESS] Writing a result to the pipeline"
                $r | Select @{Name = "Url"; Expression = { $_.html_url } },
                Description, Public,
                @{Name = "Created"; Expression = { $_.created_at -as [datetime] } }
            }
        } #should process

    } #process

    End {
        Write-Verbose "[END    ] Ending: $($MyInvocation.Mycommand)"
    } #end

}

#*------^ New-GitHubGist.ps1 ^------

#*------v parseHelp.ps1 v------
function parseHelp {
    <#
    .SYNOPSIS
    parseHelp - Parse Script CBH with get-help -full, return parseHelp obj & $hasExistingCBH boolean
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:45 PM 11/16/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    REVISIONS
    * 3:45 PM 4/14/2020 added pretest of $path extension, get-help only works with .ps1/.psm1 script files (misnamed temp files fail to parse)
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:11 AM 12/30/2019 parseHelp(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file
    * 10:03 PM 12/2/201919 INIT
    .DESCRIPTION
    parseHelp - Parse Script and prepend new Comment-based-Help keyed to existing contents
    Note, if using temp files, you *can't* pull get-help on anything but script/module files, with the proper extension
    .PARAMETER  Path
    Path to script
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None
    .OUTPUTS
    Outputs a hashtable with following content/objects:
    * HelpParsed : Raw object output of a get-help -full [path] against the specified $Path
    * hasExistingCBH : Boolean indicating if a functional CBH was detected
    .EXAMPLE
    $bRet = parseHelp -Path $oSrc.fullname -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    if($bRet.parseHelp){
        $parseHelp = $bRet.parseHelp
    } ;
    if($bRet.hasExistingCBH){
        $hasExistingCBH = $bRet.hasExistingCBH
    } ;
    .LINK
    #>
    # [ValidateScript({Test-Path $_})], [ValidateScript({Test-Path $_})]
    [CmdletBinding()]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Path to script[-Path path-to\script.ps1]")]
        [ValidateScript( { Test-Path $_ })]$Path,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    $Verbose = ($VerbosePreference -eq "Continue") ; 
    if ($Path.GetType().FullName -ne 'System.IO.FileInfo') {
        $Path = get-childitem -path $Path ;
    } ;
    # Collect existing HelpParsed
    $error.clear() ;
    if($Path.Extension -notmatch '\.PS((M)*)1'){
        $smsg = "Specified -Path is *INVALID* for processing with Get-Help`nMust specify a file with valid .PS1/.PSM1 extensions.`nEXITING" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-error -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        Exit ; 
    } ; 
    TRY {
        $HelpParsed = Get-Help -Full $Path.fullname
    }
    CATCH {
        Write-Error "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Continue #Opts: STOP(debug)|EXIT(close)|Continue(move on in loop cycle)
    } ;

    $objReturn = [ordered]@{
        HelpParsed     = $HelpParsed  ;
        hasExistingCBH = $false ;
        NotesHash = $null ; 
        RevisionsText = $null ; 
    } ;

    <# CBH keywords to use to detect CBH blocks
        SYNOPSIS
        DESCRIPTION
        PARAMETER
        EXAMPLE
        INPUTS
        OUTPUTS
        NOTES
        LINK
        COMPONENT
        ROLE
        FUNCTIONALITY
        FORWARDHELPTARGETNAME
        FORWARDHELPCATEGORY
        REMOTEHELPRUNSPACE
        EXTERNALHELP
    #>
    $rgxCBHKeywords = "\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|INPUTS|OUTPUTS|NOTES|LINK|COMPONENT|ROLE|FUNCTIONALITY|FORWARDHELPTARGETNAME|FORWARDHELPCATEGORY|REMOTEHELPRUNSPACE|EXTERNALHELP)"

    # 4) determine if target already has CBH:
    if ($showDebug) {
        $smsg = "`$Path.FullName:$($Path.FullName):`n$(($helpparsed | select Category,Name,Synopsis, param*,alertset,details,examples |out-string).trim())" ;
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    } ;


    if ( ( ($HelpParsed.Category -eq 'ExternalScript') -AND ($HelpParsed.Name -eq $Path.Name) ) ) {
        <# weird, helpparsed.synopsis is 3 lines long (has word wraps), although the first looks like the $Path.name, it still doesn't match
            pull Synopsis out - it's always populated but matching it is a PITA
            -AND ($HelpParsed.Synopsis -ne $Path.FullName)
        #>
        if ( -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND -not($HelpParsed.examples) -AND ($HelpParsed.Synopsis -ne $Path.FullName ) ) {
            #  non-cbh/non-meta script
            <# completey non-cbh/non-meta script get-help -fulls as:
                #-=-=-=-=-=-=-=-=
                Name          : get-NonUserMbxsByOU.ps1
                Category      : ExternalScript
                Synopsis      : get-NonUserMbxsByOU.ps1
                Component     :
                Role          :
                Functionality :
                ModuleName    :
                Length        : 26
                #-=-=-=-=-=-=-=-=
            #>
            $objReturn.hasExistingCBH = $false ;
        }
        else {
            # partially configured CBH, at least one of the above are populated
            $objReturn.hasExistingCBH = $true ;
        } ;

    }
    elseif ( ( ($HelpParsed.Category -eq 'ExternalScript') -AND ($HelpParsed.Name -eq $Path.FullName) ) ) {
        if ( ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.examples) -OR ($HelpParsed.Synopsis -ne $Path.FullName ) ) {
            <# weird, helpparsed.synopsis is 3 lines long (has word wraps), although the first looks like the $Path.name, it still doesn't match
            pull Synopsis out - it's always populated but matching it is a PITA
            -AND ($HelpParsed.Synopsis -ne $Path.FullName)
            #>
            <#
            # script with cbh, no meta get-help -fulls as:
                #-=-=-=-=-=-=-=-=
                examples      : @{example=System.Management.Automation.PSObject[]}
                alertSet      : @{alert=System.Management.Automation.PSObject[]}
                parameters    :
                details       : @{name=C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1; description=System.Management.Automation.PSObject[]}
                description   : {@{Text=get-NonUserMbxsByOU.ps1 - Get non-user mailboxes by OU}}
                relatedLinks  : @{navigationLink=@{linkText=}}
                syntax        : @{syntaxItem=@{name=C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1}}
                xmlns:maml    : http://schemas.microsoft.com/maml/2004/10
                xmlns:command : http://schemas.microsoft.com/maml/dev/command/2004/10
                xmlns:dev     : http://schemas.microsoft.com/maml/dev/2004/10
                Name          : C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1
                Category      : ExternalScript
                Synopsis      : get-NonUserMbxsByOU.ps1 - Get non-user mailboxes by OU
                Component     :
                Role          :
                Functionality :
                ModuleName    :
                #-=-=-=-=-=-=-=-=
        #>
            $objReturn.hasExistingCBH = $true ;
        }
        else {
            throw "Error: This script has an undefined mixture of CBH values!"
        } ;
        <# # script with cbh & meta get-help -fulls as:
            #-=-=-=-=-=-=-=-=
            examples      : @{example=System.Management.Automation.PSObject[]}
            relatedLinks  : @{navigationLink=@{linkText=}}
            details       : @{name=C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1; description=System.Management.Automation.PSObject[]}
            description   : {@{Text=get-NonUserMbxsByOU.ps1 - Get non-user mailboxes by OU}}
            parameters    :
            syntax        : @{syntaxItem=@{name=C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1}}
            xmlns:maml    : http://schemas.microsoft.com/maml/2004/10
            xmlns:command : http://schemas.microsoft.com/maml/dev/command/2004/10
            xmlns:dev     : http://schemas.microsoft.com/maml/dev/2004/10
            Name          : C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1
            Category      : ExternalScript
            Synopsis      : get-NonUserMbxsByOU.ps1 - Get non-user mailboxes by OU
                            Version     : 1.0.1
                            Author      : Todd Kadrie
                            Website     : https://www.toddomation.com
                            Twitter     : @tostka / http://twitter.com/tostka
                            CreatedDate : 2019-11-25
                            FileName    : C:\usr\work\exch\scripts\get-NonUserMbxsByOU.ps1
                            License     : MIT License
                            Copyright   : (c)  2019 Todd Kadrie. All rights reserved.
                            Github      : https://github.com/tostka
                            AddedCredit : REFERENCE
                            AddedWebsite:	URL
                            AddedTwitter:	URL
                            REVISIONS
                            * 21:53 PM 11/25/2019 Added default CBH
            Component     :
            Role          :
            Functionality :
            ModuleName    :
    #>

        <# interesting point, even with NO CBH, get-help returns content (nuts)

        An non-CBH script will return at minimum:
        #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        $HelpParsed
        Move-MultMbxsToExo.ps1


        #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        $HelpParsed.Synopsis
        Move-MultMbxsToExo.ps1


        #-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
        which rgx escape reveals as:
        #-=-=-=-=-=-=-=-=
        [regex]::Escape($($HelpParsed.Synopsis))
        Move-MultMbxsToExo\.ps1\ \r\n
        #-=-=-=-=-=-=-=-=
        But attempts to build a regex to match the above haven't been successful
        So, we go to explicitly testing the highpoints to fail a non-CBH:
        ($HelpParsed.Category -eq 'ExternalScript') -AND ($HelpParsed.Name -eq $Path.Name) -AND (!$HelpParsed.parameters) -AND (!($HelpParsed.alertSet)) -AND (!($HelpParsed.details)) -AND (!($HelpParsed.examples))
    #>


    } elseif ($HelpParsed.Name -eq 'default') {
        # failed to properly parse CBH
        $objReturn.helpparsed = $null ; 
        $objReturn.hasExistingCBH = $false ;
        $objReturn.NotesHash = $null ; 
    } ;  

    # 12:24 PM 4/13/2020 splice in the get-VersionInfo notes processing code
    $notes = $null ; $notes = @{ } ;
    $notesLines = $null ; $notesLineCount = $null ;
    $revText = $null ; $CurrLine = 0 ; 
    $rgxNoteMeta = '^((\s)*)\w{3,}((\s*)*)\:((\s*)*)*.*' ; 
    if ( ($notesLines = $HelpParsed.alertSet.alert.Text -split '\r?\n').Trim() ) {
        $notesLineCount = ($notesLines | measure).count ;
        foreach ($line in $notesLines) {
            $CurrLine++ ; 
            if (!$line) { continue } ;
            if($line -match $rgxNoteMeta ){
                $name = $null ; $value = $null ;
                if ($line -match '(?i:REVISIONS((\s*)*)((\:)*))') { 
                    # at this point, from here down should be rev data
                    $revText = $notesLines[$($CurrLine)..$($notesLineCount)] ;  
                    $notes.Add("LastRevision", $notesLines[$currLine]) ;
                    #Continue ;
                    break ; 
                } ;
                if ($line.Contains(':')) {
                    $nameValue = $null ;
                    $nameValue = @() ;
                    # Split line by the first colon (:) character.
                    $nameValue = ($line -split ':', 2).Trim() ;
                    $name = $nameValue[0] ;
                    if ($name) {
                        $value = $nameValue[1] ;
                        if ($value) { $value = $value.Trim() } ;
                        if (!($notes.ContainsKey($name))) { $notes.Add($name, $value) } ;
                    } ;
                } ;
            } ; 
        } ;
        $objReturn.NotesHash = $notes ;
        $objReturn.RevisionsText = $revText ; 
    } ; 

    $objReturn | Write-Output ;
}

#*------^ parseHelp.ps1 ^------

#*------v process-NewModule.ps1 v------
function process-NewModule {
    <#
    .SYNOPSIS
    process-NewModule - post-module conversion or component update: sign, publish to repo, and install back script
    .NOTES
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2020-02-24
    FileName    : process-NewModule.ps1
    License     : MIT License
    Copyright   : (c) 2021 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Module,Build,Development
    REVISIONS
    * 1:17 PM 10/12/2021 revised post publish code, find-module was returning an array (bombming nupkg gci), so sort on version and take highest single.
    * 3:43 PM 10/7/2021 revised .nupkg caching code to use the returned (find-module).version string to find the repo .nupkg file, for caching (works around behavior where 4-digit semvars, with 4th digit(rev) 0, get only a 3-digit version string in the .nupkg file name)
    * 3:43 PM 9/27/2021 spliced in updated start-log pre-proc code ; fixed $Repo escape in update herestring block
    * 2:14 PM 9/21/2021 functionalized & added to verb-dev ; updated $FinalReport to leverage varis, simpler to port install cmds between mods; added #requires (left in loadmod support against dependancy breaks); cleaned up rems
    * 11:25 AM 9/21/2021 added code to remove obsolete gens of .nupkgs & build log files (calls to new verb-io:remove-UnneededFileVariants()); 
    * 12:40 PM 6/2/2021 example used verb-trans, swapped in verb-logging
    * 12:07 PM 4/21/2021 expanded ss aliases
    * 10:17 AM 3/16/2021 added -ea 0 to the install BP output, suppress remove-module error when not already loaded
    * 10:35 AM 6/29/2020 added new -NoBuildInfo param, to skip reliance on BuildHelpers module (get/Set-BuildEnvironment hang when run at join-object module)
    * 1:19 PM 4/10/2020 swapped in 7psmodhybrid mods
    * 3:38 PM 4/7/2020 added Remove-Module to the trailing demo install command - pulls down the upgraded mod from the session (otherwise, old & new remain in session); added AllUser demo trailing code too, less likely to misupgrade jumpbox
    * 9:21 AM 4/1/2020 added -RunTest to trigger pester test exec, also wrapped test-modulemanifest in try/catch to capture fails (a broken psd1 isn't going to work on install), fail immed exits processing, also added detection of invalid test script guids and force match to psd1
    * 8:44 AM 3/17/2020 added new rebuild-module.ps1 to excludes on install/publish
    * 10:11 AM 3/16/2020 swapped verb-IO to mod code, added AllowClobber to the demo reinstall end text
    * 3:46 PM 3/15/2020 reworked module copy process - went back to original 'copy all w isolated exclusions' and dropped the attempt at -include control of final extensions. Did a post-copy purge of undesired file types instead.
    * 9:59 AM 3/9/2020 fixed bug in module copy process, needed to sort dirs first, to ensure they pre-exist before files are attempted (supresses error)
    * 4:32 PM 3/7/2020 revised the module copy process to only target common module components by type (instead of all but .git & .vscode)
    * 7:05 PM 3/3/2020 added code to detect and echo psd1 guid match, updated export modules code, added buffering of proc log
    * 8:39 AM 3/2/2020 still trying to get things to smoothly fail through missing installed mod, to dev .psm1, and finally into uwes copy of the mod, to ensure the commands are mounted, under any circ, working, still not happy when updating a module that the script itself is dependant on. Updated Final Report to sort other machine update sample
    * 7:31 AM 3/2/2020 spliced over Set-ModuleFunction FunctionsToExport maint code from converTo-Module.ps1
    * 4:03 PM 3/1/2020 excluded module load block from verbose output
    * 4:32 PM 2/27/2020: ammended test import-module force (hard reload curr version) & verbose output ; added trailing FinalReport with post install guidence & testing 
    * 7:21 PM 2/26/2020 sorted a typo/dupe in the nupkg copy echo ; updated psm1 version code, fixd bug, replic'd it to the convert script. shifted FunctionsToExport into buildhelpers mod (added #requires), added -DisableNameChecking to mod imports
    * 6:30 PM 2/25/2020 added code to update the guid from the psd1 into the pester test scrpit
    * 2:00 PM 2/24/2020 added material re: uninstall in description/example
    * 4:00 PM 2/18/2020 added new descriptive -Tag $ModuleName  spec to the start-Log call
    * 7:36 PM 1/15/2020 added code to create 'Package' subdir, and copy in post-publish .nupkg file (easier to buffer into other repos, than publish-module) had to splice in broken installed module backfill for verb-dev 
    * 7:58 PM 1/14/2020 converted dev-verb call into #requires Module call ; #459 flipped to using .net to pull the mydocs specfolder out of the OS (in case of fut redir) ; ren parm (to match convertto-module.ps1): DemoRepo -> Repository, added manual removal of old version from all $env:psmodulepath entries, shifted $psd1vers code to always, and used it with the install-module -requiredversion, to work around the cmds lack of auto-priority, if it finds multiples, it doesn't install latest, just throws up. (could have used -minrev too and it *should* have done this, or any later). Ran full publish & validate on verb-dev (work)
    * 10:49 AM 1/13/2020 updated echos for Republish/non-republish output (enum specific steps each will cover), was throwing deep acc error on copy to local prof for md file, added retry, which 2x's and fails past it. Doesn't seem mpactful, the md wasn't even one id' pop'd, just a defaupt template file
    * 7:35 AM 12/30/2019 got through a full pass to import-module on verb-dev. *appears* functional
    * 12:03 PM 12/29/2019 added else wh on pswls entries
    * 1:53 PM 12/28/2019 shifted to verb-* loads for all local functions, added pre-publish check for existing conflicting verison. Still throwing exec code in sig block
    * 12:28 PM 12/27/2019 subbed write-warning for write-error throughout
    * 1:38 PM 12/26/2019 #251 filter public|internal|classes include subdirs - don't sign them (if including/dyn-including causes 'Executable script code found in signature block.' errors ; 12/26/2019 flipped #399 from Error to Info in write-log, ran a full clean pass on verb-dev. ; ADD #342 -AllowClobber, to permit install command overlap (otherwise it aborts the install-module attempt), updated SID test to leverage regx
    * 9:29 AM 12/20/2019 fixed quote/dbl-quote issue in the profile copy code (was suppressing vari expansion)
    * 7:05 PM 12/19/2019 subbed in write-log support ; init, ran through Republish pass on verb-AAD
    .DESCRIPTION
    process-NewModule - post-module conversion or component update: sign, publish to repo, and install back script
    Preqeq Installs: 
    Install-Module BuildHelpers -scope currentuser # buildhelpers metadata handling https://github.com/RamblingCookieMonster/BuildHelpers
    * To uninstall all but latest:
    #-=-=-=-=-=-=-=-=
    $modules = Get-Module -ListAvailable AzureRm* | Select-Object -ExpandProperty Name -Unique ; 
    foreach ($module in $modules) {$Latest = Get-InstalledModule $module; Get-InstalledModule $module -AllVersions | ? {$_.Version -ne $Latest.Version} | Uninstall-Module ;} ; 
    #-=-=-=-=-=-=-=-=
    .PARAMETER  ModuleName
    ModuleName[-ModuleName verb-AAD]
    .PARAMETER  ModDirPath
    ModDirPath[-ModDirPath C:\sc\verb-ADMS]
    .PARAMETER  Repository
    Target local Repo[-Repository lyncRepo
    .PARAMETER Merge
    Flag that indicates Module should be Merged into a monoolithic .psm1 [-Merge]
    .PARAMETER RunTest
    Flag that indicates Pester test script should be run, at end of processing [-RunTest]
    .PARAMETER NoBuildInfo
    Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Republish
    Flag that indicates Module should be republished into local Repo (skips Merge-Module & Sign-file steps) [-Republish]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    processbulk-NewModule.ps1 -mod verb-text,verb-io -verbose
    Example using the separate processbulk-NewModule.ps1 pre-procesesor to feed an array of mods through bulk processing, uses BuildEnvironment Step-ModuleVersion to increment the psd1 version, and specs -merge & -RunTest processing
    .EXAMPLE
    process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo  -Merge -showdebug -whatif ;
    Full Merge Build/Rebuild from components & Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo  -showdebug -whatif ;
    Non-Merge pass: Re-sign specified module & Publish/Install/Test specified module, with debug messages, and whatif pass.
    .EXAMPLE
    # pre-remove installed module
    # re-increment the psd1 file ModuleVersion (unique new val req'd to publish)
    process-NewModule.ps1 -ModuleName "verb-AAD" -ModDirPath "C:\sc\verb-AAD" -Repository $localPSRepo -Merge -Republish -showdebug -whatif ;
    Merge & Republish pass: Only Publish/Install/Test specified module, with debug messages, and whatif pass.
    .LINK
    #>

    ##Requires -Version 3 # rem'd already in module
    ##Requires -Module verb-dev # added to verb-dev (recursive if present)
    #Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    [CmdletBinding()]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="ModuleName[-ModuleName verb-AAD]")]
        [ValidateNotNullOrEmpty()]$ModuleName,
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="ModDirPath[-ModDirPath C:\sc\verb-ADMS]")]
        [ValidateNotNullOrEmpty()]$ModDirPath,
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Target local Repo[-Repository lyncRepo]")]
        [ValidateNotNullOrEmpty()]$Repository,
        [Parameter(HelpMessage="Flag that indicates Module should be Merged into a monoolithic .psm1 [-Merge]")]
        [switch] $Merge,
        [Parameter(HelpMessage="Flag that indicates Module should be republished into local Repo (skips Merge-Module & Sign-file steps) [-Republish]")]
        [switch] $Republish,
        [Parameter(HelpMessage="Flag that indicates Pester test script should be run, at end of processing [-RunTest]")]
        [switch] $RunTest,
        [Parameter(HelpMessage="Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]")]
        [switch] $NoBuildInfo,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
    ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;
    # Get parameters this function was invoked with
    #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
    $verbose = ($VerbosePreference -eq "Continue") ; 

    if ($psISE){
            $ScriptDir = Split-Path -Path $psISE.CurrentFile.FullPath ;
            $ScriptBaseName = split-path -leaf $psise.currentfile.fullpath ;
            $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($psise.currentfile.fullpath) ;
            $PSScriptRoot = $ScriptDir ;
            if($PSScriptRoot -ne $ScriptDir){ write-warning "UNABLE TO UPDATE BLANK `$PSScriptRoot TO CURRENT `$ScriptDir!"} ;
            $PSCommandPath = $psise.currentfile.fullpath ;
            if($PSCommandPath -ne $psise.currentfile.fullpath){ write-warning "UNABLE TO UPDATE BLANK `$PSCommandPath TO CURRENT `$psise.currentfile.fullpath!"} ;
    } else {
        if($host.version.major -lt 3){
            $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent ;
            $PSCommandPath = $myInvocation.ScriptName ;
            $ScriptBaseName = (Split-Path -Leaf ((&{$myInvocation}).ScriptName))  ;
            $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName) ;
        } elseif($PSScriptRoot) {
            $ScriptDir = $PSScriptRoot ;
            if($PSCommandPath){
                $ScriptBaseName = split-path -leaf $PSCommandPath ;
                $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($PSCommandPath) ;
            } else {
                $PSCommandPath = $myInvocation.ScriptName ;
                $ScriptBaseName = (Split-Path -Leaf ((&{$myInvocation}).ScriptName))  ;
                $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName) ;
            } ;
        } else {
            if($MyInvocation.MyCommand.Path) {
                $PSCommandPath = $myInvocation.ScriptName ;
                $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent ;
                $ScriptBaseName = (Split-Path -Leaf ((&{$myInvocation}).ScriptName))  ;
                $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($MyInvocation.InvocationName) ;
            } else {throw "UNABLE TO POPULATE SCRIPT PATH, EVEN `$MyInvocation IS BLANK!" } ;
        } ;
    } ;
    if($showDebug){write-verbose -verbose:$true "`$ScriptDir:$($ScriptDir)`n`$ScriptBaseName:$($ScriptBaseName)`n`$ScriptNameNoExt:$($ScriptNameNoExt)`n`$PSScriptRoot:$($PSScriptRoot)`n`$PSCommandPath:$($PSCommandPath)" ; } ;


    $DomainWork = $tormeta.legacydomain ;
    #$ProgInterval= 500 ; # write-progress wait interval in ms

    $backInclDir = "c:\usr\work\exch\scripts\" ;
    $Retries = 4 ;
    $RetrySleep = 5 ;

    #*======v FUNCTIONS v======

    # suppress VerbosePreference:Continue, if set, during mod loads (VERY NOISEY)
    if($VerbosePreference -eq "Continue"){
        $VerbosePrefPrior = $VerbosePreference ;
        $VerbosePreference = "SilentlyContinue" ;
        $verbose = ($VerbosePreference -eq "Continue") ;
    } ; 

    $PassStatus = $null ;
    $PassStatus = @() ;


    # strings are: "[tModName];[tModFile];tModCmdlet"
    $tMods = @() ;
    #$tMods+="verb-Auth;C:\sc\verb-Auth\verb-Auth\verb-Auth.psm1;get-password" ;
    $tMods+="verb-logging;C:\sc\verb-logging\verb-logging\verb-logging.psm1;write-log";
    $tMods+="verb-IO;C:\sc\verb-IO\verb-IO\verb-IO.psm1;Add-PSTitleBar" ;
    $tMods+="verb-Mods;C:\sc\verb-Mods\verb-Mods\verb-Mods.psm1;check-ReqMods" ;
    $tMods+="verb-Text;C:\sc\verb-Text\verb-Text\verb-Text.psm1;Remove-StringDiacritic" ;
    #$tMods+="verb-Desktop;C:\sc\verb-Desktop\verb-Desktop\verb-Desktop.psm1;Speak-words" ;
    #$tMods+="verb-dev;C:\sc\verb-dev\verb-dev\verb-dev.psm1;Get-CommentBlocks" ;
    #$tMods+="verb-Text;C:\sc\verb-Text\verb-Text\verb-Text.psm1;Remove-StringDiacritic" ;
    #$tMods+="verb-Automation.ps1;C:\sc\verb-Automation.ps1\verb-Automation.ps1\verb-Automation.ps1.psm1;Retry-Command" ;
    #$tMods+="verb-AAD;C:\sc\verb-AAD\verb-AAD\verb-AAD.psm1;Build-AADSignErrorsHash";
    #$tMods+="verb-ADMS;C:\sc\verb-ADMS\verb-ADMS\verb-ADMS.psm1;load-ADMS";
    #$tMods+="verb-Ex2010;C:\sc\verb-Ex2010\verb-Ex2010\verb-Ex2010.psm1;Connect-Ex2010";
    #$tMods+="verb-EXO;C:\sc\verb-EXO\verb-EXO\verb-EXO.psm1;Connect-Exo";
    #$tMods+="verb-L13;C:\sc\verb-L13\verb-L13\verb-L13.psm1;Connect-L13";
    #$tMods+="verb-Network;C:\sc\verb-Network\verb-Network\verb-Network.psm1;Send-EmailNotif";
    #$tMods+="verb-Teams;C:\sc\verb-Teams\verb-Teams\verb-Teams.psm1;Connect-Teams";
    #$tMods+="verb-SOL;C:\sc\verb-SOL\verb-SOL\verb-SOL.psm1;Connect-SOL" ;
    #$tMods+="verb-Azure;C:\sc\verb-Azure\verb-Azure\verb-Azure.psm1;get-AADBearToken" ;
    foreach($tMod in $tMods){
        $tModName = $tMod.split(';')[0] ;
        $tModFile = $tMod.split(';')[1] ;
        $tModCmdlet = $tMod.split(';')[2] ;
        $smsg = "( processing `$tModName:$($tModName)`t`$tModFile:$($tModFile)`t`$tModCmdlet:$($tModCmdlet) )" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        if($tModName -eq 'verb-Network' -OR $tModName -eq 'verb-Azure'){
            write-host "GOTCHA!" ;
        } ;
        $lVers = get-module -name $tModName -ListAvailable -ea 0 ;
        if($lVers){
            $lVers=($lVers | sort version)[-1];
            try {
                import-module -name $tModName -RequiredVersion $lVers.Version.tostring() -force -DisableNameChecking
            }   catch {
                 write-warning "*BROKEN INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;import-module -name $tModDFile -force -DisableNameChecking
            } ;
        } elseif (test-path $tModFile) {
            write-warning "*NO* INSTALLED MODULE*:$($tModName)`nBACK-LOADING DCOPY@ $($tModDFile)" ;
            try {import-module -name $tModDFile -force -DisableNameChecking}
            catch {
                write-error "*FAILED* TO LOAD MODULE*:$($tModName) VIA $(tModFile) !" ;
                $tModFile = "$($tModName).ps1" ;
                $sLoad = (join-path -path $LocalInclDir -childpath $tModFile) ;
                if (Test-Path $sLoad) {
                    Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;
                    . $sLoad ;
                    if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };
                } else {
                    $sLoad = (join-path -path $backInclDir -childpath $tModFile) ;
                    if (Test-Path $sLoad) {
                        Write-Verbose -verbose ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;
                        . $sLoad ;
                        if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };
                    } else {
                        Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;
                        exit;
                    } ;
                } ;
            } ;
        } ;
        if(!(test-path function:$tModCmdlet)){
            write-warning -verbose:$true  "UNABLE TO VALIDATE PRESENCE OF $tModCmdlet`nfailing through to `$backInclDir .ps1 version" ;
            $sLoad = (join-path -path $backInclDir -childpath "$($tModName).ps1") ;
            if (Test-Path $sLoad) {
                Write-Verbose -verbose:$true ((Get-Date).ToString("HH:mm:ss") + "LOADING:" + $sLoad) ;
                . $sLoad ;
                if ($showdebug) { Write-Verbose -verbose "Post $sLoad" };
                if(!(test-path function:$tModCmdlet)){
                    write-warning "$((get-date).ToString('HH:mm:ss')):FAILED TO CONFIRM `$tModCmdlet:$($tModCmdlet) FOR $($tModName)" ;
                } else { 
                    write-verbose -verbose:$true  "(confirmed $tModName loaded: $tModCmdlet present)"
                } 
            } else {
                Write-Warning ((Get-Date).ToString("HH:mm:ss") + ":MISSING:" + $sLoad + " EXITING...") ;
                exit;
            } ;
        } else {
            write-verbose -verbose:$true  "(confirmed $tModName loaded: $tModCmdlet present)"
        } ;
    } ;  # loop-E
    #*------^ END MOD LOADS ^------

    # reenable VerbosePreference:Continue, if set, during mod loads 
    if($VerbosePrefPrior -eq "Continue"){
        $VerbosePreference = $VerbosePrefPrior ;
        $verbose = ($VerbosePreference -eq "Continue") ;
    } ; 

    #*======^ END FUNCTIONS ^======


    #*======v SUB MAIN v======

    # Clear error variable
    $Error.Clear() ;

    # ensure running SID *not* UID
    if("$env:userdomain\$env:username" -match $rgxAcctWAdmn){
        # proper SID acct (shouldn't be exec'd SID)
    } elseif("$env:userdomain\$env:username" -match $rgxAcctWUID){
        write-warning "$((get-date).ToString('HH:mm:ss')):RUNNING AS *UID* - $($env:userdomain)\$($env:username) - MUST BE RUN *SID*! EXITING!" ;
        EXIT ; 
    } ; 


    if($Merge -AND $Republish){
        write-host -foregroundcolor RED "$((get-date).ToString('HH:mm:ss')):*WARNING!*:-Merge *AND* -Republish specified! Please use one or the other, but *not* BOTH!" ; 
        Exit ; 
    } ; 

    if($env:USERDOMAIN -EQ $DomainWork){
        if("$($env:USERDOMAIN)\$($env:USERNAME)" -notmatch $rgxAcctWAdmn ){
            write-host -foregroundcolor RED "$((get-date).ToString('HH:mm:ss')):*WARNING*! THIS SCRIPT MUST BE RUN AS SID AT WORK`nREQUIRES *ADMIN* REPO PUBLISHING PERMS, `nWHICH UID LACKS ($($env:USERDOMAIN)\$($env:USERNAME))" ; 
            #popd ; 
            EXIT ; 
        } ; 
    } ; 

    [array]$reqMods = $null ; # force array, otherwise single first makes it a [string]
    $reqMods += "Test-TranscriptionSupported;Test-Transcribing;Stop-TranscriptLog;Start-IseTranscript;Start-TranscriptLog;get-ArchivePath;Archive-Log;Start-TranscriptLog;Write-Log;Start-Log".split(";") ;
    $reqMods+="Get-CommentBlocks;parseHelp;get-ScriptProfileAST;build-VSCConfig;Merge-Module;get-VersionInfo".split(";") ; 
    # verb-IO reqMods
    $reqMods+="Set-FileContent;backup-File;Set-FileContent;backup-File;remove-ItemRetry".split(";") ; 
    $reqMods = $reqMods | Select-Object -Unique ;

    if ( !(check-ReqMods $reqMods) ) { write-error "$((get-date).ToString("yyyyMMdd HH:mm:ss")):Missing function. EXITING." ; throw "FAILURE" ; }  ;

    # 2:32 PM 9/27/2021 updated start-log code
    if(!(get-variable LogPathDrives -ea 0)){$LogPathDrives = 'd','c' };
    foreach($budrv in $LogPathDrives){if(test-path -path "$($budrv):\scripts" -ea 0 ){break} } ;
    if(!(get-variable rgxPSAllUsersScope -ea 0)){
        $rgxPSAllUsersScope="^$([regex]::escape([environment]::getfolderpath('ProgramFiles')))\\((Windows)*)PowerShell\\(Scripts|Modules)\\.*\.(ps(((d|m))*)1|dll)$" ;
    } ;
    if(!(get-variable rgxPSCurrUserScope -ea 0)){
        $rgxPSCurrUserScope="^$([regex]::escape([Environment]::GetFolderPath('MyDocuments')))\\((Windows)*)PowerShell\\(Scripts|Modules)\\.*\.(ps((d|m)*)1|dll)$" ;
    } ;
    $pltSL=[ordered]@{Path=$null ;NoTimeStamp=$false ;Tag=$null ;showdebug=$($showdebug) ; Verbose=$($VerbosePreference -eq 'Continue') ; whatif=$($whatif) ;} ;
    $pltSL.Tag = $ModuleName ; 
    if($script:PSCommandPath){
        if(($script:PSCommandPath -match $rgxPSAllUsersScope) -OR ($script:PSCommandPath -match $rgxPSCurrUserScope)){
            $bDivertLog = $true ; 
            switch -regex ($script:PSCommandPath){
                $rgxPSAllUsersScope{$smsg = "AllUsers"} 
                $rgxPSCurrUserScope{$smsg = "CurrentUser"}
            } ;
            $smsg += " context script/module, divert logging into [$budrv]:\scripts" 
            write-verbose $smsg  ;
            if($bDivertLog){
                if((split-path $script:PSCommandPath -leaf) -ne $cmdletname){
                    # function in a module/script installed to allusers|cu - defer name to Cmdlet/Function name
                    $pltSL.Path = (join-path -Path "$($budrv):\scripts" -ChildPath "$($cmdletname).ps1") ;
                } else {
                    # installed allusers|CU script, use the hosting script name
                    $pltSL.Path = (join-path -Path "$($budrv):\scripts" -ChildPath (split-path $script:PSCommandPath -leaf)) ;
                }
            } ;
        } else {
            $pltSL.Path = $script:PSCommandPath ;
        } ;
    } else {
        if(($MyInvocation.MyCommand.Definition -match $rgxPSAllUsersScope) -OR ($MyInvocation.MyCommand.Definition -match $rgxPSCurrUserScope) ){
             $pltSL.Path = (join-path -Path "$($budrv):\scripts" -ChildPath (split-path $script:PSCommandPath -leaf)) ;
        } else {
            $pltSL.Path = $MyInvocation.MyCommand.Definition ;
        } ;
    } ;
    write-verbose "start-Log w`n$(($pltSL|out-string).trim())" ; 
    $logspec = start-Log @pltSL ;
    $error.clear() ;
    TRY {
        if($logspec){
            $logging=$logspec.logging ;
            $logfile=$logspec.logfile ;
            $transcript=$logspec.transcript ;
            $stopResults = try {Stop-transcript -ErrorAction stop} catch {} ;
            start-Transcript -path $transcript ;
        } else {throw "Unable to configure logging!" } ;
    } CATCH {
        $ErrTrapd=$Error[0] ;
        $smsg = "Failed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: $($ErrTrapd)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;
    <# prior code
    $logspec = start-Log -Path ($MyInvocation.MyCommand.Definition) -Tag $ModuleName -showdebug:$($showdebug) -whatif:$($whatif) ;
    if($logspec){
        $logging=$logspec.logging ;
        $logfile=$logspec.logfile ;
        $transcript=$logspec.transcript ;
    } else {throw "Unable to configure logging!" } ;
    #>
    $sBnr="#*======v $($ScriptBaseName):$($ModuleName) v======" ; 
    $smsg= "$($sBnr)" ;  
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    $ModPsmName = "$($ModuleName).psm1" ;
    # C:\sc\verb-AAD\verb-AAD\verb-AAD.psd1
    $ModPsdPath = (gci "$($ModDirPath)\$($ModuleName)\$($ModuleName).psd1").FullName
    $PublicDirPath = "$($ModDirPath)\Public" ;
    $InternalDirPath = "$($ModDirPath)\Internal" ;
    # "C:\sc\verb-AAD" ; C:\sc\verb-AAD\Tests\verb-AAD.tests.ps1
    $TestScriptPath = "$($ModDirPath)\Tests\$($ModuleName).tests.ps1" ;
    $rgxSignFiles='\.(CAT|MSI|JAR,OCX|PS1|PSM1|PSD1|PS1XML|PSC1|MSP|CMD|BAT|VBS)$' ; 
    $rgxIncludeDirs='\\(Public|Internal|Classes)\\' ;

    $editor = "notepad2.exe" ;

    $error.clear() ;

    if($NoBuildInfo){
        # 9:34 AM 6/29/2020 for some reason, on join-object mod, Set-BuildEnvironment is going into the abyss, running git.exe log --format=%B -n 1
        # so use psd1version and manually increment, skipping BuildHelper mod use entirely
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(-NoBuildInfo specified:Skipping use of buggy BuildHelpers module)" ; 
        TRY {
            #$ModPsdPath = (gci "$($modroot)\$($ModuleName)\$($ModuleName).psd1").FullName
            # $ModPsdPath
            $psd1Profile = Test-ModuleManifest -path $ModPsdPath  ; 
            # check for failure of last command
            if($? ){ 
                $smsg= "(Test-ModuleManifest:PASSED)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } 
        } CATCH {
            $PassStatus += ";ERROR"; 
            write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            Exit ;
        } ;
        $psd1Vers = $psd1Profile.Version.tostring() ; 
    } else { 
        # stock buildhelper e-varis - I don't even see it in *use*
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):(executing:Get-BuildEnvironment -Path $($ModDirPath) `n(use -NoBuildInfo if hangs))" ; 
        $BuildVariable = Get-BuildVariable -path $ModDirPath 
    } ; 
    <# 	Get-Item ENV:BH* ; 
        returned as an object when run above:
        #-=-=-=-=-=-=-=-=
        BuildSystem   : Unknown
        ProjectPath   : C:\sc\verb-AAD
        BranchName    : master
        CommitMessage : 3a372b0324af6761bcd7aa492a89ee87ef34ef45
        CommitHash    :
        BuildNumber   : 0
        #-=-=-=-=-=-=-=-=
        Evaris config'd if run on cmdline: 
	    Name                           Value
	    ----                           -----
	    BHProjectName                  verb-AAD
	    BHModulePath                   C:\sc\verb-AAD\verb-AAD
	    BHPSModulePath                 C:\sc\verb-AAD\verb-AAD
	    BHProjectPath                  C:\sc\verb-AAD
	    BHBuildOutput                  C:\sc\verb-AAD\BuildOutput
	    BHPSModuleManifest             C:\sc\verb-AAD\verb-AAD\verb-AAD.psd1
	    BHBuildSystem                  Unknown
	    BHCommitMessage                3a372b0324af6761bcd7aa492a89ee87ef34ef45
	    BHBranchName                   master
	    BHBuildNumber                  0
    #>

    if(!$Republish){
        $sHS=@"
NON-Republish pass detected:
$(if($Merge){'MERGE parm specified as well:`n-Merge Public|Internal|Classes include subdirs module content into updated .psm1'} else {'(no -merge specified)'})
-Sign updated files. 
-Uninstall/Remove existing profile module
-Copy new module to profile
-Confirm: Get-Module -ListAvailable
-Check/Update existing Psd1 Version
-Publish-Module
-Remove existing installed profile module
-Test Install-Module
-Test Import-Module
"@ ; 
        $smsg= $sHS;  ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    
        if($Merge){
            $smsg= "-Merge specified..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $pltmergeModule=[ordered]@{
              ModuleName=$($ModuleName) ;
              ModuleSourcePath="$($PublicDirPath)","$($InternalDirPath)" ;
              ModuleDestinationPath="$($ModDirPath)\$($ModuleName)" ;
              LogSpec = $logspec ; 
              NoAliasExport=$($NoAliasExport) ; 
              ErrorAction="Stop" ; 
              showdebug=$($showdebug);
              whatif=$($whatif);
            } ;
            $smsg= "Merge-Module w`n$(($pltmergeModule|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            TRY {
                $ReportObj = Merge-Module @pltmergeModule ;
            } CATCH {
                $PassStatus += ";ERROR"; 
                write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                Exit ;
            } ;
            <#  $ReportObj=[ordered]@{
                    Status=$true ; 
                    PsmNameBU = $PsmNameBU ; 
                    PassStatus = $PassStatus ;
                } ; 
            #>
            $PsmNameBu=$ReportObj.PsmNameBU ; 
            if($ReportObj.Status){
            
            } else {
                $smsg= "Merge-Module failure.`nPassStatus:$($reportobj.PassStatus)" ;  
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if($PsmNameBu){
                    $smsg= "Reverting PSM1 from backup:" ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $error.clear() ;
                    TRY {
                        $bRet = revert-File -Source $PsmNameBu -Destination "$($ModDirPath)\$($ModuleName)\$($ModuleName).psm1" -showdebug:$($showdebug) -whatif:$($whatif)
                    } CATCH {
                        $PassStatus += ";ERROR"; 
                        Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
                    } ; 
                } else { 
                    $smsg= "(no backup .psm1 to revert from)" ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
            } ; 
        } ;

    } else {
        $sHS=@"
*REPUBLISH* param detected, performing solely *republish* steps:`
-Uninstall-Module/Remove any existing profile module
-Copy new module to profile
-Confirm: Get-Module -ListAvailable
-Check/Update existing Psd1 Version
-Publish-Module
-Remove existing installed profile module
-Test Install-Module
-Test Import-Module
"@ ; 
        $smsg= $sHS;  ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ; # non-republish block above

    $error.clear() ;
    TRY {
        # $ModPsdPath
        $psd1Profile = Test-ModuleManifest -path $ModPsdPath  ; 
        # check for failure of last command
        if($? ){ 
            $smsg= "(Test-ModuleManifest:PASSED)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } 
    } CATCH {
        $PassStatus += ";ERROR"; 
        write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
        Exit ;
    } ;

    $psd1Vers = $psd1Profile.Version.tostring() ; 
    $psd1guid = $psd1Profile.Guid.tostring() ; 
    if(test-path $TestScriptPath){
        # update the pester test script with guid: C:\sc\verb-AAD\Tests ; C:\sc\verb-AAD\Tests\verb-AAD.tests.ps1
        $smsg= "Checking sync of Psd1 module guid to the Pester Test Script: $($TestScriptPath)" ; ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        $rgxTestScriptNOGuid = "Please\sPaste\shere\syour\smodule\sGuid\s-\sTest-ModuleManifest\s'<ModulePath>'\s\|\sSelect-Object\s-ExpandProperty\sGuid"
        #$rgxTestScriptGuid = '\.Guid((\s)*)\|((\s)*)Should((\s)*)-Be((\s)*)"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}"'
        # cap grp
        $rgxTestScriptGuid = '\.Guid((\s)*)\|((\s)*)Should((\s)*)-Be((\s)*)"([0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12})"'
        $rgxGuid = "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}" ; 
        # also maintain encoding (set-content defaults ascii)
        $tf = $TestScriptPath; 
        $enc=$null ; $enc=get-FileEncoding -path $tf ;
        if($enc -eq 'ASCII') { 
            $enc = 'UTF8' ; 
            $smsg = "(ASCI encoding detected, converting to UTF8)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ; # force damaged/ascii to UTF8
        $pltSetCon=[ordered]@{ Path=$tf ; whatif=$($whatif) ;  } ;
        if($enc){$pltSetCon.add('encoding',$enc) } ;
        if($psd1ExpMatch = gci $tf |select-string -Pattern $rgxTestScriptNOGuid ){
            (Get-Content $tf) | Foreach-Object {
                $_ -replace $rgxTestScriptNOGuid, "$($psd1guid)"
            } | Set-Content @pltSetCon ; 
        } elseif($psd1ExpMatch = gci $tf |select-string -Pattern $rgxTestScriptGuid ){
            $testGuid = $psd1ExpMatch.matches[0].Groups[9].value.tostring() ;  ; 
            if($testGuid -eq $psd1guid){
                $smsg = "(Guid  already updated to match)" ; 
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INFO } #Error|Warn|Debug 
                else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            } else { 
                $smsg = "In:$($tf)`nGuid present:($testGuid)`n*does not* properly match:$($psd1guid)`nFORCING MATCHING UPDATE!" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-WARNING "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;  
                # generic guid replace: $_ -replace $rgxGuid, "$($psd1guid)"
                (Get-Content $tf) | Foreach-Object {
                    $_ -replace $testGuid, "$($psd1guid)"
                } | Set-Content @pltSetCon ; 
            } ; 
        } else { 
            $smsg = "UNABLE TO Regex out...`n$($rgxTestScriptNOGuid)`n...from $($tf)`nTestScript hasn't been UPDATED!" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
        } ; 

    } else { 
        $smsg = "Unable to locate `$TestScriptPath:$($TestScriptPath)" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level INfo } #Error|Warn|Debug 
        else{ write-verbose -verbose:$true "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
    } ; 

    # sync Psd Version to psm1
    # regex approach - necc for psm1 version updates (lacks a ps cmdlet to parse)
    $rgxPsM1Version='Version((\s*)*):((\s*)*)(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?' ; 
    $ModPsmPath = $ModPsdPath.replace('.psd1','.psm1')
    $psm1Profile = gci $ModPsmPath |select-string -Pattern $rgxPsM1Version ; 
    $psm1Vers = $psm1Profile.matches[0].captures.groups[0].value.split(':')[1].trim() ; 
    if($psm1Vers -ne $psd1Vers){
        $smsg = "Psd1<>Psm1 version mis-match ($($psd1Vers)<>$($Psm1Vers)):`nUpdating $($ModPsmPath) to *match*`n$($ModPsdPath)" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

        $tf = $ModPsmPath; 
        $enc=$null ; $enc=get-FileEncoding -path $tf ;
        if($enc -eq 'ASCII') { 
            $enc = 'UTF8' ; 
            $smsg = "(ASCI encoding detected, converting to UTF8)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ; # force damaged/ascii to UTF8
        $pltSetCon=[ordered]@{ Path=$tf ; whatif=$($whatif) ;  } ;
        if($enc){$pltSetCon.add('encoding',$enc) } ;
        (Get-Content $tf) | Foreach-Object {
            $_ -replace $psm1Profile.matches[0].captures.groups[0].value.tostring(), "Version     : $($psd1Vers)"
        } | Set-Content @pltSetCon ; 
    } else { 
        $smsg = "(Psd1:Psm1 versions match)" ; 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
    } ; 

    # Update the psd1 FunctionsToExport : (moved to merge-module, after the export-modulemember code)


    $smsg= "Signing appropriate files..." ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    #$files = Get-ChildItem "$($ModDirPath)\*" -recur |Where-Object{$_.extension -match $rgxSignFiles} ;
    # 1:38 PM 12/26/2019#251 filter public|internal|classes include subdirs - don't sign them (if including/dyn-including causes 'Executable script code found in signature block.' errors
    $files = Get-ChildItem "$($ModDirPath)\*" -recur |Where-Object{$_.extension -match $rgxSignFiles} | ?{$_.fullname -notmatch $rgxIncludeDirs} ; 
    if($files){
        $pltSignFile=[ordered]@{
            file=$files.fullname ;
            ErrorAction="Stop" ; 
            showdebug=$($showdebug);
            whatif=$($whatif);
        } ;
        $smsg= "Sign-file w`n$(($pltSignFile|out-string).trim())" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        TRY {
            sign-file @pltSignFile ;
        } CATCH {
            $PassStatus += ";ERROR"; 
            write-warning  "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            Exit ;
        } ;
    } else {
        $smsg= "(no matching signable files)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;

    $smsg= "Removing existing profile $($ModuleName) content..." ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    
    if($PsGInstalled=Get-InstalledModule -name $($ModuleName) -AllVersions -ea 0 ){
        foreach($PsGMod in $PsGInstalled){
            $sBnrS="`n#*------v Uninstall PSGet Mod:$($PsGMod.name):v$($PsGMod.version) v------" ; 
            $smsg= $sBnrS ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $pltRmv = [ordered]@{
                force=$true ; 
                whatif=$($whatif) ; 
            } ; 
            $error.clear() ;
            TRY { 
                if($showDebug){
                    $sMsg = "Uninstall-Script w`n$(($pltRmv|out-string).trim())" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
                get-module $PsGMod.installedlocation -listavailable |uninstall-module @pltRmv
            } CATCH { 
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";ERROR"; 
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #Exit #Opts: STOP(debug)|EXIT(close)|Continue(move on in loop cycle) 
            } ;   
            $smsg="$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
    } ; 
    <# installed mods have PSGetModuleInfo.xml files
    #>

    # 12:20 PM 1/14/2020 #438: surviving conflicts locking install-module: need to check everywhere, loop the entire $env:psprofilepath list
    $modpaths = $env:PSModulePath.split(';') ; 
    foreach($modpath in $modpaths){
        #"==$($modpath):"
        $smsg= "Checking: $($ModuleName) below: $($modpath)..." ;    
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #$bRet = remove-ItemRetry -Path "$($env:userprofile)\Documents\WindowsPowerShell\Modules\$($ModuleName)\*.*" -Recurse -showdebug:$($showdebug) -whatif:$($whatif) ;
        $searchPath = join-path -path $modpath -ChildPath "$($ModuleName)\*.*" ; 
        # 2:25 PM 4/21/2021 adding -GracefulFail to get past locked verb-dev cmdlets
        $bRet = remove-ItemRetry -Path $searchPath -Recurse -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail ;
        if (!$bRet) {throw "FAILURE" ; EXIT ; } ;
    } ; 


    $smsg= "Copying module to profile (net of .git & .vscode dirs, and backed up content)..." ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    $ModExtIncl='*.cab','*.cat','*.cmd','*.config','*.cscfg','*.csdef','*.css','*.dll','*.dylib','*.gif','*.html','*.ico','*.jpg','*.js','*.json','*.map','*.Materialize','*.MaterialUI','*.md','*.pdb','*.php','*.png','*.ps1','*.ps1xml','*.psd1','*.psm1','*.rcs','*.reg','*.snippet','*.so','*.txt','*.vscode','*.wixproj','*.wxi','*.xaml','*.xml','*.yml','*.zip' ; 
    $rgxModExtIncl='\.(cab|cat|cmd|config|cscfg|csdef|css|dll|dylib|gif|html|ico|jpg|js|json|map|Materialize|MaterialUI|md|pdb|php|png|ps1|ps1xml|psd1|psm1|rcs|reg|snippet|so|txt|vscode|wixproj|wxi|xaml|xml|yml|zip)' ; 
    $from="$($ModDirPath)" ; 
    $to = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\$($ModuleName)" ;
    $exclude = @('main.js','rebuild-module.ps1') ; $excludeMatch = @('.git','.vscode') ;

    [regex] $excludeMatchRegEx = '(?i)' + (($excludeMatch |ForEach-Object {[regex]::escape($_)}) -join "|") + '' ;
    # below is original copy-all gci
    $pltGci=[ordered]@{Path=$from ;Recurse=$true ;Exclude=$exclude; ErrorAction="Stop" ; } ;
    # explicitly only go after the common module component, by type, via -include - 
    #issue is -include causes it to collect only leaf files, doesn't include dir 
    #creation, and if no pre-exist on the dir, causes a hard error on copy attempt. 
    #$pltGci=[ordered]@{Path=$from ;Recurse=$true ;Exclude=$exclude; include =$ModExtIncl ; ErrorAction="Stop" ; } ;
    # 2:34 PM 3/15/2020 reset to copy all, and then post-purge non-$ModExtIncl

    # use a retry
    $Exit = 0 ;
    Do {
        Try {
            # below is original copy-all gci
            #Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} | Copy-Item -Destination {  if ($_.PSIsContainer) { Join-Path $to $_.Parent.FullName.Substring($from.length) }   else { Join-Path $to $_.FullName.Substring($from.length) }    } -Force -Exclude $exclude -whatif:$($whatif) ;
            # two stage it anyway
            $srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx} ; 
            $srcFiles | Copy-Item -Destination {
                    if ($_.PSIsContainer) {
                        Join-Path $to $_.Parent.FullName.Substring($from.length) 
                    }   else {
                        Join-Path $to $_.FullName.Substring($from.length) 
                    }    
                } -Force -Exclude $exclude -whatif:$($whatif) ;
            <# leaf copies fail hard, when gci -include, due to returns being solely leaf files, no dirs, so the dirs don't get pre-created, and cause 'not found' copy fails
            # 2-stage and pull out non-target ext's
            $srcFiles = Get-ChildItem @pltGci | Where-Object { $excludeMatch -eq $null -or $_.FullName.Replace($from, '') -notmatch $excludeMatchRegEx}
            # need the dirs before the files, to ensure they're pre-created (avoids errors)
            $srcFiles = $srcFiles | sort PSIsContainer,Parent -desc 
            $srcFiles | Copy-Item -Destination {  if ($_.PSIsContainer) { Join-Path $to $_.Parent.FullName.Substring($from.length) }   else { Join-Path $to $_.FullName.Substring($from.length) }    } -Force -Exclude $exclude -whatif:$($whatif) ;
            #>
            $Exit = $Retries ;
        } Catch {
            $ErrorTrapped=$Error[0] ;
            $PassStatus += ";ERROR"; 
            Start-Sleep -Seconds $RetrySleep ;
            # reconnect-exo/reconnect-ex2010
            $Exit ++ ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg= "Failed to exec cmd because: $($Error[0])" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $smsg= "Try #: $($Exit)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            If ($Exit -eq $Retries) {
                $smsg= "Unable to exec cmd!" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Exit ; 
            } ;
        }  ;
    } Until ($Exit -eq $Retries) ; 

    # if we've run a copy all, we need to loop back and pull the items that *arent* ext -match $rgxModExtIncl
    # $to = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\Modules\$($ModuleName)" ;
    $bannedFiles = get-childitem -path $to -recurse |?{$_.extension -notmatch $rgxModExtIncl -AND !$_.PSIsContainer} ; 
    # Remove-Item -Path -Filter -Include -Exclude -Recurse -Force -Credential -WhatIf
    $pltRItm = [ordered]@{
        path=$bannedFiles.fullname ; 
        whatif=$($whatif) ;
    } ; 
    if($bannedFiles){
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Creating Remove-Item w `n$(($pltRItm|out-string).trim())" ; 
        $error.clear() ;
        TRY {
            Remove-Item @pltRItm ;
        } CATCH {
            Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            $PassStatus += ";ERROR"; 
            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
        } ; 
    } ; 


    if(!$whatif){
        if($localMod=Get-Module -ListAvailable -Name $($ModPsmName.replace('.psm1',''))){

            <# 9:59 AM 12/28/2019 check for an existing repo pkg that will conflict with the version of the local copy
            $localMod.version : 1.2.0
            $trepo.PublishLocation
            \\REPOSERVER\lync_fs\scripts\sc
            $tRepo.ScriptPublishLocation
            \\REPOSERVER\lync_fs\scripts\sc

            gci "$($tRepo.ScriptPublishLocation)\verb-dev.1.2.0.nupkg"
                Directory: \\REPOSERVER\lync_fs\scripts\sc
            Mode                LastWriteTime         Length Name
            ----                -------------         ------ ----
            -a----       12/28/2019   9:27 AM         121100 verb-dev.1.2.0.nupkg
            #>
            # profile $localPsRepo
            $smsg= "(Profiling Repo: get-PSRepository -name $($localPSRepo)...)" ;  
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            TRY {
                $tRepo = get-PSRepository -name $localPSRepo 
            } CATCH {
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";ERROR"; 
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Exit ;
            } ;

            if($tRepo){
                $rgxPsd1Version="ModuleVersion\s=\s'\d*\.\d*\.\d*((\.\d*)*)'" ; 
                # 12:47 PM 1/14/2020 move the psdv1Vers detect code to always - need it for installs, as install-module doesn't prioritize, just throws up.
                <# regx
                $psd1Profile = gci $ModPsdPath |select-string -Pattern $rgxPsd1Version ; 
                $psd1Vers = $psd1Profile.matches.captures.groups[0].value.split('=').replace("'","")[1].trim() ; 
                #$psd1Vers = $psd1Vers.split('=').replace("'","")[1].trim() ; 
                #>
                # another way to pull version & guid is with get-module command, -name [path-to.psd1]
                # moved $psd1Vers & $psd1guid upstream , need the material *before* signing files
                if($tExistingPkg=gci "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($localMod.version).nupkg" -ea 0){
                    # pull the source psd1 ModuleVersion line
                    #(gci C:\sc\verb-dev\verb-dev\verb-dev.psd1 |select-string -Pattern $rgxPsd1Version).matches.captures.groups[0].value ; 
                    # "$($ModDirPath)\$($ModuleName)"
                    # if localvers being publ matches the $tExistingPkg version, twig
                    #if($psd1Vers.split('=').replace("'","")[1].trim() -eq $localmod.Version.tostring().trim()){
                    if($psd1Vers -eq $localmod.Version.tostring().trim()){

                        $blkMsg=@"

CONFLICTING EXISTING PUBLISHED VERSION FOUND!:
$($tExistingPkg.fullname)!
"@ ; 
                        $smsg= $blkMsg ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $smsg= "**DO YOU WANT TO *PRE-PURGE* THE ABOVE FILE,`nTO PERMIT PUBLICATION OF THE UPDATE?" ;  
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN }  #Error|Warn|Debug 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $bRet=Read-Host "Enter YYY to continue. Anything else will exit" 
                        if ($bRet.ToUpper() -eq "YYY") {
                            $bRet = remove-ItemRetry -Path $tExistingPkg.fullname -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail  ;
                            if (!$bRet) {throw "FAILURE" ; EXIT ; } ;
                        } else {
                            $blkMsg=@"
"Alternatively, you need to specify a *new* .psd1 file version...
    -- currently: $($psd1Vers) --
...in the source psd1:
$($ModPsdPath)

And then re-run process-NewModule. 
* NOW EXITING * 
"@ ; 
                            $smsg= $blkMsg ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            $smsg = "Opening a copy of Psd1:`n$($ModPsdPath)`nfor editing" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                            #$editor = "notepad2.exe" ;
                            $editorArgs = "$($ModPsdPath)" ;
                            Invoke-Command -ScriptBlock { & $editor $editorArgs } ;
                            Exit ; 
                        } ;

                    } ; 

                } ; 
            } ; 

            # added required version, to permit mult versions pre-reinstall
            $pltPublishModule=[ordered]@{
                Name=$($ModuleName) ;
                Repository=$($Repository) ;
                RequiredVersion=$($psd1Vers) ; 
                Verbose=$true ;
                ErrorAction="Stop" ; 
                whatif=$($whatif);
            } ;
            $smsg= "`nPublish-Module w`n$(($pltPublishModule|out-string).trim())" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            TRY {
                Publish-Module @pltPublishModule ;
            } CATCH {
                $ErrorTrapped = $Error[0] ;
                $PassStatus += ";ERROR"; 
                $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if($ErrorTrapped.Exception.Message -match 'The\sversion\smust\sexceed\sthe\scurrent\sversion'){
                    $smsg= "NOTE: If the psdVers ($($psd1Vers)) *is* > prior rev ($($localmod)) (e.g. publish-Module has bad SemanticVersion code),`nbump the rev a minor level`nStep-ModuleVersion -Path $($ModPsdPath) -by minor" ;        
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ; 
                Exit ;
            } ;

            $smsg= "Waiting for:find-module -name $($ModuleName) -Repository $Repository ..." ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $1F=$false ;Do {if($1F){Sleep -s 5} ;  write-host "." -NoNewLine ; $1F=$true ; } Until ($tMod = find-module -name $($ModuleName) -Repository $Repository -EA 0) ;

            if($tMod){
                # issue with $tMod is it can come back with multiple versions. Sort Version take last
                if($tMod -is [system.array]){
                    $smsg = "find-module returned Array, taking highest Version..." ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $tMod = ($tMod | sort version)[-1] ; 
                } ; 
                TRY {
                    $tfiles = Get-ChildItem -Recurse -Path "$($env:userprofile)\Documents\WindowsPowerShell\Modules\$($ModuleName)\*.*" |Where-Object{ ! $_.PSIsContainer } ; 
                    #$tfiles | remove-item @pltRemoveItem ; 
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";ERROR"; 
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $bRetry=$true ;
                } ;

                $bRet = remove-ItemRetry -Path $tFiles -Recurse -showdebug:$($showdebug) -whatif:$($whatif) -GracefulFail ;
                if (!$bRet) {throw "FAILURE" ; EXIT ; } ;

                # ADD -AllowClobber, to permit install command overlap (otherwise it aborts the install-module attempt)
                # add RequiredVersion to fix: Unable to install, multiple modules matched 'VERB-dev'. Please specify an exact -Name and -RequiredVersion.
                $pltInstallModule=[ordered]@{
                    Name=$($ModuleName) ;
                    Repository=$($Repository) ;
                    RequiredVersion=$($psd1Vers) ; 
                    scope="CurrentUser" ;
                    force=$true ;
                    AllowClobber=$true ; 
                    ErrorAction="Stop" ; 
                    whatif=$($whatif) ;
                } ;
                $smsg= "Install-Module w`n$(($pltInstallModule|out-string).trim())" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                TRY {
                    Install-Module @pltInstallModule;
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";ERROR"; 
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Exit ;
                } ;

                # test import-module with ea, force (hard reload curr version) & verbose output
                $pltImportMod=[ordered]@{
                    Name=$pltInstallModule.Name ; 
                    ErrorAction="Stop" ; 
                    force = $true ; 
                    verbose = $true ; 
                } ; 
                $smsg= "Testing Module:Import-Module w`n$(($pltImportMod|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                TRY {
                    Import-Module @pltImportMod ; 
                
                } CATCH {
                    $ErrorTrapped = $Error[0] ;
                    $PassStatus += ";ERROR"; 
                    $smsg= "Failed processing $($ErrorTrapped.Exception.ItemName). `nError Message: $($ErrorTrapped.Exception.Message)`nError Details: $($ErrorTrapped)" ;        
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error } #Error|Warn
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Exit ;
                } ;

                # finally, lets grab the .nukpg that was created on the repo, and cached it in the sc dir (for direct copying to stock other repos, home etc)
                #if($tNewPkg = gci "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($psd1Vers).nupkg" -ea 0){
                # revise: use $tMod.version instead of $psd1Vers
                # when publishing 4-digit n.n.n.n semvers, if revision (4th digit) is 0, the .nupkg gets only a 3-digit semvar string in the filename. 
                # The returned $tMod.version reflects the string actually used in the .nupkg, and is what you use to find the .nupkg for caching, from the repo.
                $smsg = "Retrieving matching Repo .nupkg file:`ngci $($tRepo.ScriptPublishLocation)\$($ModuleName).$($tMod.version).nupkgl.." ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                if($tNewPkg = gci "$($tRepo.ScriptPublishLocation)\$($ModuleName).$($tMod.version).nupkg" -ea 0){
                    $smsg= "Proper updated .nupkg file found:$($tNewPkg.name), copying to local Pkg directory." ;  
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $pkgdir = join-path -path $ModDirPath -childpath "Package" ; 
                    $pltNItm = [ordered]@{
                        path=$pkgdir ;
                        type="directory" ;
                        whatif=$($whatif) ;
                    } ; 
                    $pltCItm = [ordered]@{
                        path=$tNewPkg.fullname ;
                        destination=$pkgdir ;
                        whatif=$($whatif) ;
                    } ; 
                    if(!(test-path -path $pkgdir -ea 0)){
                        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Creating missing dir:New-Item w `n$(($pltNItm|out-string).trim())" ; 
                        $error.clear() ;
                        TRY {
                            New-Item @pltNItm ;
                        } CATCH {
                            Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                            $PassStatus += ";ERROR"; 
                            Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
                        } ; 
                    } ; 
                    write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):Copy-Item w`n$(($pltCItm|out-string).trim())" ; 
                    $error.clear() ;
                    TRY {
                        copy-Item @pltCItm ;
                    } CATCH {
                        Write-Warning "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
                        $PassStatus += ";ERROR"; 
                        Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ; 
                    } ; 

                } else { 
                    # no nupkg file found to cache locally
                } ; 

                # cleanout old pkg files prior to today and 2 gens old
                $pltRGens =[ordered]@{
                    Path = $pltCItm.destination ;
                    #Include =(($tNewPkg.split('.') | ?{$_ -notmatch '[0-9]+'} ) -join '*.') ;
                    Include = (( (split-path $tNewPkg.fullname -leaf).split('.') | ?{$_ -notmatch '[0-9]+'}) -join '*.') ;
                    Pattern = $null ; #'verb-\w*\.ps(m|d)1_\d{8}-\d{3,4}(A|P)M' ;
                    FilterOn = 'CreationTime' ;
                    Keep = 2 ;
                    KeepToday = $true ;
                    verbose=$true ;
                    whatif=$($whatif) ;
                } ; 
                $smsg = "remove-UnneededFileVariants w`n$(($pltRGens|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                remove-UnneededFileVariants @pltRGens ; # fr verb-IO

                # RUNTEST
                if($RunTest -AND (test-path $TestScriptPath)){
                    $smsg = "`-RunTest specified: Running Pester Test script:`n$($TestScriptPath)`n" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

                    # suppress VerbosePreference:Continue, if set, during mod loads (VERY NOISEY)
                    if($VerbosePreference -eq "Continue"){
                        $VerbosePrefPrior = $VerbosePreference ;
                        $VerbosePreference = "SilentlyContinue" ;
                        $verbose = ($VerbosePreference -eq "Continue") ;
                    } ; 
                
                    $sBnrS="`n#*------v RUNNING $($TestScriptPath): v------`n" ; 
                    write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS)" ;
                    pushd ; 
                    cd $ModDirPath ; 
                    $pltRunTest = [ordered]@{
                        Command=".\Tests\$(split-path $TestScriptPath -leaf)" ;verbose=$($verbosepreference -eq 'Continue') ; 
                    } ; 
                    #invoke-expression @pltRunTest; 
                    .(".\Tests\$(split-path $TestScriptPath -leaf)")
                    popd ; 
                    write-host -foregroundcolor white "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;

                    # reenable VerbosePreference:Continue, if set, during mod loads 
                    if($VerbosePrefPrior -eq "Continue"){
                        $VerbosePreference = $VerbosePrefPrior ;
                        $verbose = ($VerbosePreference -eq "Continue") ;
                    } ; 

                } ; 

                # POST REPORT
                $FinalReport=@"

---------------------------------------------------------------------------------
Processing completed: $($ModuleName) :: $($ModDirPath)
- Script is currently installed (from PsRep:$($localRepo) with scope:CurrentUser, under $($env:userdomain)\$($env:username) profile

- To update other scopes/accounts on same machine, or install on other machines:
    1. Uninstall current module copies:

        Uninstall-Module -Name $($ModuleName)) -AllVersion -whatif ; 
                        
    2. Install the current version (or higher) from the Repo:$($Repository):

        install-Module -name $($ModuleName) -Repository $($Repository) -MinimumVersion $($psd1Vers) -scope currentuser -whatif ; 

    3. Reimport the module with -force, to ensure the current installed verison is loaded:
                        
        import-Module -name $($ModuleName) -force -verbose ;

#-=-Stacked list: Unwrap to create a 1-liner for the above: CURRENTUSER =-=-=-=-=-=-=
`$whatif=`$false ; `$tMod = '$($ModuleName)' ; `$tVer = '$($psd1Vers)' ;  `$tScop = 'CurrentUser' ;
TRY {
Remove-Module -Name `$tmod -ea 0 ;
Uninstall-Module -Name `$tmod -AllVersion -whatif:`$(`$whatif) ;
install-Module -name `$tmod -Repository '$($Repository)' -MinimumVersion `$tVer -scope `$tScop -AllowClobber -whatif:`$(`$whatif) ;
import-Module -name `$tmod -force -verbose ;
} CATCH {
Write-Warning "Failed processing `$(`$_.Exception.ItemName). `nError Message: `$(`$_.Exception.Message)`nError Details: `$(`$_)" ; Break ;
} ;
#-=-=-=-=-=-=-=-=
#-=-Stacked list: Unwrap to create a 1-liner for the above: ALLUSERS =-=-=-=-=-=-=
`$whatif=`$false ; `$tMod = '$($ModuleName)' ; `$tVer = '$($psd1Vers)' ;  `$tScop = 'AllUsers' ;
TRY {
Remove-Module -Name `$tmod -ea 0 ;
Uninstall-Module -Name `$tmod -AllVersion -whatif:`$(`$whatif) ;
install-Module -name `$tmod -Repository '$($Repository)' -MinimumVersion `$tVer -scope `$tScop -AllowClobber -whatif:`$(`$whatif) ;
import-Module -name `$tmod -force -verbose ;
} CATCH {
Write-Warning "Failed processing `$(`$_.Exception.ItemName). `nError Message: `$(`$_.Exception.Message)`nError Details: `$(`$_)" ; Break ;
} ;
#-=-=-=-=-=-=-=-=

- You may also want to run the configured Pester Tests of the new script: 
                        
        . $($ModDirPath)\Tests\$($ModuleName).tests.ps1

Full Processing Details can be found in:
                
$($logfile) 

---------------------------------------------------------------------------------

"@ ; 
                $smsg = $FinalReport ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

            } else {
                $sMsg = "FAILED:Get-Module -ListAvailable -Name $($ModPsmName.replace('.psm1',''))"
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } ;

        } else {
              $sMsg="FAILED:Get-Module -ListAvailable -Name $($ModPsmName.replace('.psm1',''))"
              if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Error }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ;
    } else { 
        $smsg= "(-whatif: Skipping balance)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ; 

    $smsg = "`n(Processing log can be found at:$(join-path -path $ModDirPath -childpath $logfile))" ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
    # copy the conversion log into the dev dir $ModDirPath
    if ($logging) {
        copy-item -path $logfile -dest $ModDirPath -whatif:$($whatif) ;
    } ;

    # this is where we should maintain accumulated old logs, post log close
    # $logfile =  'C:\sc\verb-Auth\process-NewModule-verb-auth-LOG-BATCH-EXEC-20210917-1504PM-log.txt'

    $pltRGens =[ordered]@{
        Path = $ModDirPath ;
        Include =(((split-path $logfile -leaf) -split '-LOG-BATCH-')[0],'-LOG-BATCH-','*','-log.txt' -join '') ;
        Pattern = $null ; #'verb-\w*\.ps(m|d)1_\d{8}-\d{3,4}(A|P)M' ;
        FilterOn = 'CreationTime' ;
        Keep = 2 ;
        KeepToday = $true ;
        verbose=$true ;
        whatif=$($whatif) ;
    } ; 
    $smsg= "remove-UnneededFileVariants w`n$(($pltRGens|out-string).trim())" ; 
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    remove-UnneededFileVariants @pltRGens ;

    $smsg= "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn
    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

    #*======^ END SUB MAIN ^======
}

#*------^ process-NewModule.ps1 ^------

#*------v restore-ISEConsoleColors.ps1 v------
Function restore-ISEConsoleColors {
    <#
    .SYNOPSIS
    restore-ISEConsoleColors - Restore default $psise.options from "`$(split-path $profile)\IseColorsDefault.csv" file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-03-17
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Copyright   : 
    Github      : https://github.com/tostka
    Tags        : Powershell,ExchangeOnline,Exchange,RemotePowershell,Connection,MFA
    REVISIONS   :
    * 7:29 AM 3/17/2021 init
    .DESCRIPTION
    restore-ISEConsoleColors - Restore default $psise.options from "`$(split-path $profile)\IseColorsDefault.csv" file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    restore-ISEConsoleColors;
    .LINK
    https://github.com/tostka/verb-IO
    #>
    
    [CmdletBinding()]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
        switch($host.name){
            "Windows PowerShell ISE Host" {
                ##$psISE.Options.RestoreDefaultTokenColors()
                <#$sFileTag=Read-Host "Enter 'Name' for saved color scheme" ;
                $ofile = "$(split-path $profile)\IseColors-$($sFileTag).csv" ; 
                write-host -fore green "Saving current Colors & Fonts to file: $($ofile)" ; 
                $psise.options | Select ConsolePane*,Font* | Export-CSV "$($ofile)" ;
                #>
                $ifile = "$(split-path $profile)\IseColorsDefault.csv" ; 
                if(test-path $ifile){
                    (import-csv $ifile ).psobject.properties | foreach { $psise.options.$($_.name) = $_.Value} ; 
                } else { 
                    throw "Missing $($ifile), skipping restore-ISEConsoleColors.ps1`nCan be created via:`n`$psise.options | Select ConsolePane*,Font* | Export-CSV '`$(split-path $profile)\IseColorsDefault.csv'"
                } ;
            } 
            "ConsoleHost" {
                #[console]::ResetColor()  # reset console colorscheme to default
                throw "This command is intended to backup ISE (`$psie.options object). PS `$host is not supported" ; 
            }
            default {
                write-warning "Unrecognized `$Host.name:$($Host.name), skipping $($MyInvocation.MyCommand.Name)" ; 
            } ; 
        } ; 
    }

#*------^ restore-ISEConsoleColors.ps1 ^------

#*------v save-ISEConsoleColors.ps1 v------
Function save-ISEConsoleColors {
    <#
    .SYNOPSIS
    save-ISEConsoleColors - Save $psise.options | Select ConsolePane*,Font* to prompted csv file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2021-03-17
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Copyright   : 
    Github      : https://github.com/tostka
    Tags        : Powershell,ExchangeOnline,Exchange,RemotePowershell,Connection,MFA
    REVISIONS   :
    * 1:25 PM 3/5/2021 init ; added support for both ISE & powershell console
    .DESCRIPTION
    save-ISEConsoleColors - Save $psise.options | Select ConsolePane*,Font* to prompted csv file
    .INPUTS
    None. Does not accepted piped input.
    .OUTPUTS
    None. Returns no objects or output.
    .EXAMPLE
    save-ISEConsoleColors;
    .LINK
    https://github.com/tostka/verb-IO
    #>
    [CmdletBinding()]
    #[Alias('dxo')]
    Param() 
    $verbose = ($VerbosePreference -eq "Continue") ; 
        switch($host.name){
            "Windows PowerShell ISE Host" {
                ##$psISE.Options.RestoreDefaultTokenColors()
                $sFileTag=Read-Host "Enter 'Name' for saved color scheme" ;
                $ofile = "$(split-path $profile)\IseColors-$($sFileTag).csv" ; 
                write-host -fore green "Saving current Colors & Fonts to file: $($ofile)" ; 
                $psise.options | Select ConsolePane*,Font* | Export-CSV "$($ofile)" ;
            } 
            "ConsoleHost" {
                #[console]::ResetColor()  # reset console colorscheme to default
                throw "This command is intended to backup ISE (`$psie.options object). PS `$host is not supported" ; 
            }
            default {
                write-warning "Unrecognized `$Host.name:$($Host.name), skipping save-ISEConsoleColors" ; 
            } ; 
        } ; 
    }

#*------^ save-ISEConsoleColors.ps1 ^------

#*------v shift-ISEBreakPoints.ps1 v------
function shift-ISEBreakPoints {
    <#
    .SYNOPSIS
    shift-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified
    .NOTES
    Version     : 1.0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2020-08-25
    FileName    : shift-ISEBreakPoints
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 10:49 AM 8/25/2020 init, added to verb-dev module
    .DESCRIPTION
    shift-ISEBreakPoints - Offset current ISE tab's existing breakpoints by lines specified
    .PARAMETER PathDefault
    Default Path for export (when `$Script directory is unavailable)[-PathDefault c:\path-to\]
    .EXAMPLE
    shift-ISEBreakPoints -lines -4
    Shift all existing PSBreakpoints UP 4 lines
    .EXAMPLE
    shift-ISEBreakPoints -lines 5
    Shift all existing PSBreakpoints DOWN 5 lines
    .LINK
    Github      : https://github.com/tostka
    #>
    [CmdletBinding()]
    [Alias('sIseBp')]
    PARAM(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter lines +/- to shift breakpoints on current script[-lines -3]")]
        [int]$lines
    ) ;
    BEGIN {} ;
    PROCESS {
        if ($psise -AND $psise.CurrentFile.FullPath){
            
            $eBPs = get-psbreakpoint -Script $psise.CurrentFile.fullpath ; 
            # older, mandetory param prompts instead
            #$lines=Read-Host "Enter lines +/- to shift breakpoints on current script:($($psise.CurrentFile.displayname))" ;
            foreach($eBP in $eBPs){
              remove-psbreakpoint -id $eBP.id ; 
              set-PSBreakpoint -script $eBP.script -line ($eBP.line + $lines) ; 
            } ; 
            
        } else {  write-warning 'This script only functions within PS ISE, with a script file open for editing' };

     } # PROC-E
}

#*------^ shift-ISEBreakPoints.ps1 ^------

#*------v split-CommandLine.ps1 v------
function Split-CommandLine {
    <#
    .SYNOPSIS
    Split-CommandLine - Parse command-line arguments using Win32 API CommandLineToArgvW function.
    .NOTES
    Version     : 1.6.2
    Author      : beatcracker
    Website     :	http://beatcracker.wordpress.com
    Twitter     :	@beatcracker / http://twitter.com/beatcracker
    CreatedDate : 2014-11-22
    FileName    : Split-CommandLine
    License     :
    Copyright   :
    Github      : https://github.com/beatcracker
    AddedCredit : Todd Kadrie
    AddedWebsite:	http://www.toddomation.com
    AddedTwitter:	@tostka / http://twitter.com/tostka
    REVISIONS
    * 8:21 AM 8/3/2020 shifted into verb-dev module
    * 1:17 PM 12/14/2019 TSK:Split-CommandLine():  minor reformatting & commenting
    * 11/22/2014 posted version
    .DESCRIPTION
    This is the Cmdlet version of the code from the article http://edgylogic.com/blog/powershell-and-external-commands-done-right. It can parse command-line arguments using Win32 API function CommandLineToArgvW .
    .PARAMETER  CommandLine
    This parameter is optional.
    A string representing the command-line to parse. If not specified, the command-line of the current PowerShell host is used.
    .EXAMPLE
    Split-CommandLine
    Description
    -----------
    Get the command-line of the current PowerShell host, parse it and return arguments.
    .EXAMPLE
    Split-CommandLine -CommandLine '"c:\windows\notepad.exe" test.txt'
    Description
    -----------
    Parse user-specified command-line and return arguments.
    .EXAMPLE
    '"c:\windows\notepad.exe" test.txt',  '%SystemRoot%\system32\svchost.exe -k LocalServiceNetworkRestricted' | Split-CommandLine
    Description
    -----------
    Parse user-specified command-line from pipeline input and return arguments.
    .EXAMPLE
    Get-WmiObject Win32_Process -Filter "Name='notepad.exe'" | Split-CommandLine
    Description
    -----------
    Parse user-specified command-line from property name of the pipeline object and return arguments.
    .LINK
    https://github.com/beatcracker/Powershell-Misc/blob/master/Split-CommandLine
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandLine
    ) ;
    Begin {
        $Kernel32Definition = @'
            [DllImport("kernel32")]
            public static extern IntPtr GetCommandLineW();
            [DllImport("kernel32")]
            public static extern IntPtr LocalFree(IntPtr hMem);
'@ ;
        $Kernel32 = Add-Type -MemberDefinition $Kernel32Definition -Name 'Kernel32' -Namespace 'Win32' -PassThru ;
        $Shell32Definition = @'
            [DllImport("shell32.dll", SetLastError = true)]
            public static extern IntPtr CommandLineToArgvW(
                [MarshalAs(UnmanagedType.LPWStr)] string lpCmdLine,
                out int pNumArgs);
'@ ;
        $Shell32 = Add-Type -MemberDefinition $Shell32Definition -Name 'Shell32' -Namespace 'Win32' -PassThru ;
        if (!$CommandLine) {
            $CommandLine = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Kernel32::GetCommandLineW());
        } ;
    } ;

    Process {
        $ParsedArgCount = 0 ;
        $ParsedArgsPtr = $Shell32::CommandLineToArgvW($CommandLine, [ref]$ParsedArgCount) ;

        Try {
            $ParsedArgs = @();

            0..$ParsedArgCount | ForEach-Object {
                $ParsedArgs += [System.Runtime.InteropServices.Marshal]::PtrToStringUni(
                    [System.Runtime.InteropServices.Marshal]::ReadIntPtr($ParsedArgsPtr, $_ * [IntPtr]::Size)
                )
            }
        }
        Finally {
            $Kernel32::LocalFree($ParsedArgsPtr) | Out-Null
        } ;

        $ret = @() ;

        # -lt to skip the last item, which is a NULL ptr
        for ($i = 0; $i -lt $ParsedArgCount; $i += 1) {
            $ret += $ParsedArgs[$i]
        } ;

        return $ret ;
    } ;
}

#*------^ split-CommandLine.ps1 ^------

#*------v Step-ModuleVersionCalculated.ps1 v------
function Step-ModuleVersionCalculated {
    <#
    .SYNOPSIS
    Step-ModuleVersionCalculated.ps1 - Increment a fresh revision of specified module via profiled changes compared to prior semantic-version 'fingerprint' (or Percentage change).
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-10-09
    FileName    : 
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell
    AddedCredit : Kevin Marquette
    AddedWebsite: https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    AddedTwitter: 
    AddedCredit : Martin Pugh (revision code on file change percent)
    AddedWebsite: www.thesurlyadmin.com
    AddedTwitter: @thesurlyadm1n
    REVISIONS
    * 8:47 AM 10/15/2021 rem'd # raa, convert-tomodule etc run as UID, and I have this loading in profile...
    * 2:51 PM 10/13/2021 subbed pswls's for wv's ; added else block to catch mods with inconsistent names between root dir, and .psm1 file, (or even .psm1 location); added path to sBnr
    * 3:55 PM 10/10/2021 added output of final psd1 info on applychange ; recoded to use buildhelper; added -applyChange to exec step-moduleversion, and -NoBuildInfo to bypass reliance on BuildHelpers mod (where acting up for a module). 
    * 9:08 PM 10/9/2021 init version
    .DESCRIPTION
    Step-ModuleVersionCalculated.ps1 - Profile a fresh revision of specified module for changes compared to prior semantic-version 'fingerprint'.
    
    ## relies on BuildHelpers module, and it's Set-BuildEnvironment profiling tool, and Step-ModuleVersion manifest .psd1-file revision-incrementing tool. 

    ## -Method: Default via 'Fingerprint': 
        
        'Fingerprint' assumes a prior pass of the Initialize-ModuleFingerpring function:
        
        ```powershell
        Initialize-ModuleFingerprint -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
        ```

        ... which creates & populates a 'fingerprint' file in the root of the module, summarizing the commands and parameters within the module. 

        When Step-ModuleVersionCalculated is run, with default Method:Fingerprint, 
        the prior fingerprint file contents are compared to the current module content, 
        and the choice between Major|Module|Patch revision step level is made on the following basis:
            - Major reflets breaking changes - removed commands and parameters that previously existed
            - Minor reflects enhancements - new commands and parameters that did not previously exist
            - Patch lesser modifications that neither add functions/commands or parameters, nor remove same. 

    ## Optional Method is via 'Percentage'

        'Percentage' profiles all files in the Module, for changes after the LastWriteDate after the existing .psd1 file. 
        Changes as a percentage of all of the files, are caldulated on the following basis:

            - Major, 50% or more changes to files 
            - Minor, 10 - 25% changes to files 
            - Patch, 10% or less % or more changes to files 
            Semantic Variable standard also supports Builds, and logic is in place in this 
            function (sub 5%), but BuildHelper:Step-ModuleVersion() does not currently 
            support Build level revisions.  
    
    .PARAMETER Path
    Path to root directory of the Module[-path 'C:\sc\PowerShell-Statistics\']
    .PARAMETER applyChange
    switch to apply the Version Update (execute step-moduleversion cmd)[-applyChange]
    .PARAMETER NoBuildInfo
    Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo' -whatif -verbose ;
    Fingerprint the specified module path, with whatif and verbose specified
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -NoBuildInfo ;
    Using option to exclude leveaging BuildHelper module (where it fails to properly process a given module, and 'hangs' with normal processing). 
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -NoBuildInfo -applyChange ;
    Demo -applyChange option to apply Step-ModuleVersion immediately.
    .EXAMPLE
    PS> Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo'  -verbose -Method Percentage -applyChange ;
    Demo use of the optional 'Percentage' -Method (vs default 'Fingerprint' basis). 
    .EXAMPLE
    PS> $newRevBump = Step-ModuleVersionCalculated -path 'C:\sc\Get-MediaInfo' ;
        Step-ModuleVersion -path 'C:\sc\Get-MediaInfo\MediaInfo.psd1' -By $newRevBump ;
    Analyze the specified module, calculate a revision BumpVersionType, and return the calculated value tp the pipeline
    Then run Step-ModuleVersion -By `$bumpVersionType to increment the ModuleVersion (independantly, rather than within this function using -ApplyChange)
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://powershellexplained.com/2017-10-14-Powershell-module-semantic-version/
    #>
    #Requires -Version 3
    #Requires -Modules BuildHelpers,verb-IO, verb-logging, verb-Mods, verb-Text
    ##Requires -RunasAdministrator    
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Path to root directory of the Module[-path 'C:\sc\PowerShell-Statistics\']")]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [string]$Path,
        [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Version level calculation basis (Fingerprint[default]|Percentage)[-Method Percentage]")]
        [ValidateSet("Fingerprint","Percentage")]
        [string]$Method='Fingerprint',
        [Parameter(HelpMessage="Skip BuildInfo use (workaround for hangs in that module)[-NoBuildInfo]")]
        [switch] $NoBuildInfo,
        [Parameter(HelpMessage="Switch to force-increment ModuleVersion by minimum step (Patch), regardless of calculated changes[-MinVersionIncrement]")]
        [switch] $MinVersionIncrement,
        [Parameter(HelpMessage="switch to apply the Version Update (execute step-moduleversion cmd)[-applyChange]")]
        [switch] $applyChange,
        [Parameter(HelpMessage="Suppress all but error-related outputs[-Silent]")]
        [switch] $Silent,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;
    BEGIN { 
        # function self-name (equiv to script's: $MyInvocation.MyCommand.Path) ;
        ${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name ;

        $sBnr="#*======v RUNNING :$($CmdletName):$($Path) v======" ; 
        $smsg = "$($sBnr)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        
        # Get parameters this function was invoked with
        #$PSParameters = New-Object -TypeName PSObject -Property $PSBoundParameters ;
        $Verbose = ($VerbosePreference -eq 'Continue') ; 
        
        if($whatif -AND -not $applyChange){
            $smsg = "You have specified -whatif, but have not also specified -applyChange" ; 
            $smsg += "`nThere is no reason to use -whatif without -applyChange."  ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor yellow "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 

        $pltXMO=@{Name=$null ; force=$true ; ErrorAction='STOP'} ;

    } ;  # BEGIN-E
    PROCESS {
        $error.clear() ;
        TRY {
            $smsg = "profiling existing content..."
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

            $ModuleName = split-path $path -leaf ;
            $moddir = (gi -Path $path).FullName;
            #$moddirfiles = gci -path $moddir -recur ;
            $pltGCI=[ordered]@{path=$moddir.FullName ;recurse=$true ; ErrorAction='STOP'} ;
            $smsg = "gci w`n$(($pltGCI|out-string).trim())" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 

            $moddirfiles = gci @pltGCI ;

            # prelocate .psm1 (BH doesn't locate the .psm1)
            if($psm1 = $moddirfiles|?{$_.name -eq "$ModuleName.psm1"} ){
                $smsg = "located `$psm1:$($psm1)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            } elseif($psm1 = $moddirfiles|?{$_.name -like "*.psm1"} ){
                $smsg = "fail-thru located `$psm1:$($psm1)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            } else {
                $smsg = "failed to locate a .psm1 module file!" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                throw $smsg ;
            } ; 
            if($psm1 -is [system.array]){
                $smsg = "`$psm1 resolved to multiple .psm1 files in the module tree!" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                throw $smsg ;
            } else {
                $psm1Basename = ((split-path $psm1.fullname -leaf).replace('.psm1','')) ; 
                if($ModuleName -ne $psm1Basename){
                    $smsg = "Module has non-standard root-dir name`n$($moddir.fullname)"
                    $smsg += "`ncorrecting `$ModuleName variable to use *actual* .psm1 basename:$($psm1Basename)" ; 
                    write-warning $smsg ; 
                    $ModuleName = $psm1Basename ; 
                } ; 
            } ;  
            
            if($NoBuildInfo){
                if($moddirfiles.name -contains "$ModuleName.psd1"){
                    $psd1 = $moddirfiles|?{$_.name -eq "$ModuleName.psd1"} ; 
                } else { 
                    throw "Unable to locate Manifest .psd1 file!" ; 
                } ; 
                if($psd1 = $moddirfiles|?{$_.name -eq "$ModuleName.psd1"} ){
                    $smsg = "located `$psd1:$($psd1)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } elseif($psd1 = $moddirfiles|?{$_.name -like "*.psd1"} ){
                    $smsg = "fail-thru located `$psd1:$($psd1)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                } else {
                    $smsg = "failed to locate a .psd1 manifest file!" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    throw $smsg ;
                } ; 
                if($psd1 -is [system.array]){
                    $smsg = "`$psd1 resolved to multiple .psd1 files in the module tree!" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    throw $smsg ;
                } ; 

            } else { 
                # stock buildhelper e-varis
                $smsg = "(executing:Set-BuildEnvironment -Path $($moddir) -Force `n(use -NoBuildInfo if hangs))" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Set-BuildEnvironment -Path $moddir -Force ;
                # never outputs anything but the $env:BHPS* variables, on *success* (test their status)
                $smsg = "Processing $($ModuleName):`n$((get-item Env:BH*|out-string).trim())`n" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if(test-path $env:BHPSModuleManifest){
                    $psd1 = gci $env:BHPSModuleManifest ; 
                } else {
                    $smsg = "Unable to locate psd1:$($env:BHPSModuleManifest)" 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                } ;
            } ; 
            $pltXPsd1=[ordered]@{path=$psd1.FullName ; ErrorAction='STOP'} ; 
            $smsg = "Import-PowerShellDataFile w`n$(($pltXPsd1|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $PsdInfoPre = Import-PowerShellDataFile @pltXPsd1 ;
            $smsg = "test-ModuleManifest w`n$(($pltXPsd1|out-string).trim())" ;                         
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            $TestReport = test-modulemanifest @pltXPsd1 ;
            if($? ){ 
                $smsg= "(Test-ModuleManifest:PASSED)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info }  #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            } 
            
            switch ($Method) {

                'Fingerprint' {

                    $smsg = "Module:PSD1:calculating *FINGERPRINT* change Version Step" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    if($moddirfiles.name -contains "fingerprint"){
                        $oldfingerprint = Get-Content  ($moddirfiles|?{$_.name -eq "fingerprint"}).FullName ; 
                
                        if($psm1){
                            $pltXMO.Name = $psm1.fullname # load via full path to .psm1
                            $smsg = "import-module w`n$(($pltXMO|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            import-module @pltXMO ;

                            $commandList = Get-Command -Module $ModuleName
                            $pltXMO.Name = $psm1Basename ; # have to rmo using *basename*
                            $smsg = "remove-module w`n$(($pltXMO|out-string).trim())" ; 
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                            remove-module @pltXMO ;

                            $smsg = "Calculating fingerprint"
                            # KM's core logic code:
                            $fingerprint = foreach ( $command in $commandList ){
                                $smsg = "(=cmd:$($command)...)" ;
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                foreach ( $parameter in $command.parameters.keys ){
                                    $smsg = "(---param:$($parameter)...)" ;
                                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                                    '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                                    $command.parameters[$parameter].aliases | 
                                        Foreach-Object { '{0}:{1}' -f $command.name, $_}
                                };  
                            } ;   

                            $bumpVersionType = 'Patch' ; 
                            if($MinVersionIncrement){
                                $smsg = "-MinVersionIncrement override specified: incrementing by min .Build" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                #$Version.Build ++ ;
                                #$Version.Revision = 0 ; 
                                # drop through min patch rev above
                            } else { 
                                # KM's core logic code:
                                $smsg = "Detecting new features" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $fingerprint | Where {$_ -notin $oldFingerprint } | 
                                    ForEach-Object {$bumpVersionType = 'Minor'; "  $_"} ; 
                                $smsg = "Detecting breaking changes" ; 
                                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                                $oldFingerprint | Where {$_ -notin $fingerprint } | 
                                    ForEach-Object {$bumpVersionType = 'Major'; "  $_"} ; 
                            } ;

                        } else {
                            $smsg = "No module .psm1 file found in tree of `$path:`n$($moddir)" ;
                            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                            throw $smsg ;
                        } ;
                    
                    } else {
                        $smsg =  "No fingerprint file found in `$path:`n$(join-path -path $moddir -child "$ModuleName.psm1")" ;
                        $smsg += "`nTo configure a fingerprint for this module, plese run:`n"
                        $smsg += "`nInitialize-ModuleFingerprint -path $($moddir) ;"
                        $smsg += "`n... and then re-run the Step-ModuleVersionCalculated cmdlet" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Warn } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        throw $smsg ;
                    } ;  

                    if ( $fingerprint ){
                        $pltOFile=[ordered]@{Encoding='utf8' ;FilePath=(join-path -path $moddir -childpath 'fingerprint') ;whatif=$($whatif) ;} ; 
                        $smsg = "Writing fingerprint: Out-File w`n$(($pltOFile|out-string).trim())" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        $fingerprint | out-file @pltOFile ; 
                    } else {
                        $smsg = "No funtional Module `$fingerprint generated for path specified`n$($Path)" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
                        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    } ; 
                } 
                'Percentage' {
                    # implement's Martin Pugh's revision step code on percentage of files changed after psd1.LastWriteTime
                    $smsg = "Module:PSD1:calculating *PERCENTAGE* change Version Step" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                    $LastChange = (Get-ChildItem $psd1.fullname).LastWriteTime ; 
                    $ChangedFiles = ($moddirfiles | Where LastWriteTime -gt $LastChange).Count ; 
                    $PercentChange = 100 - ((($moddirfiles.Count - $ChangedFiles) / $moddirfiles.Count) * 100) ; 
                    $smsg = "PercentChange:$($PercentChange)" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
                    #$Version = ([version]$Psd1PriorData.ModuleVersion) | Select Major,Minor,Build,Revision ; 
                    # coerce Build & Revision:-1 to 0, handling; doesn't like it when rev is -1
                    #$Version = ([version]$Psd1PriorData.ModuleVersion) | select Major,Minor,Build,@{name='Revision';Expression={[System.Math]::Max($_.revision,0)} }
                    <#$Version = ([version]$Psd1PriorData.ModuleVersion) | select Major,Minor,
                        @{name='Build';Expression={[System.Math]::Max($_.Build,0)} },
                        @{name='Revision';Expression={[System.Math]::Max($_.revision,0)} }
                    $PriorVers =  $Version | Select Major,Minor,Build,Revision
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

                } ;
            } # switch-E

            if($TestReport -AND $applyChange ){ 
                $pltStepMV=[ordered]@{Path=$psd1.FullName ; By=$bumpVersionType ; ErrorAction='STOP';} ; 

                $smsg = "Step-ModuleVersion w`n$(($pltStepMV|out-string).trim())" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if(!$whatif){
                    # Step-ModuleVersion -Path $env:BHPSModuleManifest -By $bumpVersionType ; 
                    Step-ModuleVersion @pltStepMV ; 
                    $PsdInfo = Import-PowerShellDataFile -path $env:BHPSModuleManifest ;
                    $smsg = "----PsdVers incremented from $($PsdInfoPre.ModuleVersion) to $((Import-PowerShellDataFile -path $env:BHPSModuleManifest).ModuleVersion)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

                } else {
                    $smsg = "(-whatif, skipping exec:`nStep-ModuleVersion -Path $($env:BHPSModuleManifest) -By $($bumpVersionType)) ;" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    $PsdInfo.ModuleVersion | write-output ; 
                } ;
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
    
        if ( $bumpVersionType ){
            
            if(-not $applyChange){
                $hMsg =@"

$($Method) analysis recommends ModuleVersion Step:$($bumpVersionType). 

This can be implemented with the following command:

Step-ModuleVersion -Path $($psd1.fullname) -By $($bumpVersionType)

(the above will use the BuildHelpers module to update the revision stored in the Manifest .psd1 file for the module).

"@ ; 
            } else {
                $hmsg = @"
$($Method) analysis recommended ModuleVersion Step:$($bumpVersionType). 

which was applied via the BuildHelper:Step-ModulerVersion cmdlet (above)

"@ ; 
            }; 

            $smsg = "`n$($hmsg)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;

        } else {
            $smsg = "Unable to generate a 'bumpVersionType' for path specified`n$($Path)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warn } #Error|Warn|Debug 
            else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        } ; 
    
        if($PsdInfo -AND $applyChange ){ 
            $smsg = "(returning updated ManifestPsd1 Content to pipeline)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            $PsdInfo | write-output 
        } else {
            $smsg = "-applyChange *not* specified, returning 'bumpVersionType' specification to pipeline:" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #$PsdInfo.ModuleVersion | write-output 
             $bumpVersionType | write-output  ; 
        } ;  ;

        $smsg = "$($sBnr.replace('=v','=^').replace('v=','^='))" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
    } ;  # END-E
}

#*------^ Step-ModuleVersionCalculated.ps1 ^------

#*======^ END FUNCTIONS ^======

Export-ModuleMember -Function build-VSCConfig,check-PsLocalRepoRegistration,convert-CommandLine2VSCDebugJson,export-ISEBreakPoints,Get-CommentBlocks,get-FunctionBlock,get-FunctionBlocks,Get-PSModuleFile,get-ScriptProfileAST,get-VersionInfo,import-ISEBreakPoints,import-ISEConsoleColors,Initialize-ModuleFingerprint,Merge-Module,Merge-ModulePs1,new-CBH,New-GitHubGist,parseHelp,process-NewModule,restore-ISEConsoleColors,save-ISEConsoleColors,shift-ISEBreakPoints,Split-CommandLine,Step-ModuleVersionCalculated -Alias *


# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqVPouzsd0eVsLCcoiU+rTrpm
# 7J+gggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDEyMjkxNzA3MzNaFw0zOTEyMzEyMzU5NTlaMBUxEzARBgNVBAMTClRvZGRT
# ZWxmSUkwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALqRVt7uNweTkZZ+16QG
# a+NnFYNRPPa8Bnm071ohGe27jNWKPVUbDfd0OY2sqCBQCEFVb5pqcIECRRnlhN5H
# +EEJmm2x9AU0uS7IHxHeUo8fkW4vm49adkat5gAoOZOwbuNntBOAJy9LCyNs4F1I
# KKphP3TyDwe8XqsEVwB2m9FPAgMBAAGjdjB0MBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MF0GA1UdAQRWMFSAEL95r+Rh65kgqZl+tgchMuKhLjAsMSowKAYDVQQDEyFQb3dl
# clNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3SCEGwiXbeZNci7Rxiz/r43gVsw
# CQYFKw4DAh0FAAOBgQB6ECSnXHUs7/bCr6Z556K6IDJNWsccjcV89fHA/zKMX0w0
# 6NefCtxas/QHUA9mS87HRHLzKjFqweA3BnQ5lr5mPDlho8U90Nvtpj58G9I5SPUg
# CspNr5jEHOL5EdJFBIv3zI2jQ8TPbFGC0Cz72+4oYzSxWpftNX41MmEsZkMaADGC
# AWAwggFcAgEBMEAwLDEqMCgGA1UEAxMhUG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZp
# Y2F0ZSBSb290AhBaydK0VS5IhU1Hy6E1KUTpMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSwrEy0
# E5GQmh3E1in1QHaSOGa1PzANBgkqhkiG9w0BAQEFAASBgCsHEvh/EEaI0fh9x8ix
# CT3VJ6wjqTeJ56yTEHEZZRxpKFfvXCDqyDvtmqzWTohII9d2u6wTKdpa4Kz3OyuQ
# 8wHKuAPTunk54Um3ekAJZX0pRaub5wCHaMsjZghOTfHIkjp4jfSUwbMxNe+v/1N8
# Shm/eVizvromMhl+eCM4DyPH
# SIG # End signature block
