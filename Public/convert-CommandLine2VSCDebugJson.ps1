﻿#*------v convert-CommandLine2VSCDebugJson.ps1 v------
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

    1. Use the "configurations": [� "env":  ]section:<br>
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
    |${fileBasename}|the current opened file�s basename|
    |${fileBasenameNoExtension}|the current opened file�s basename with no file extension|
    |${fileDirname}|the current opened file�s dirname|
    |${fileExtname}|the current opened file�s extension|
    |${cwd}|the task runner�s current working directory on startup|
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