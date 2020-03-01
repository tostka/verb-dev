#*------v Function build-VSCConfig() v------
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

}; #*------^ END Function build-VscConfig ^------