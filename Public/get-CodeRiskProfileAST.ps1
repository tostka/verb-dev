# get-CodeRiskProfileAST.ps1
#*------v Function get-CodeRiskProfileAST v------
Function get-CodeRiskProfileAST {
    <#
    .SYNOPSIS
    get-CodeRiskProfileAST.ps1 - Analyze a script/function/module (ps1|psm1) and prepare a report showing what commands it would run, necessary parameters, and anything that might pose a danger. Outputs/displays an ABOUT_[filebasename].help.txt file. 
    .NOTES
    Version     : 3.4.1
    Author      : Jeff Hicks
    Website     : https://www.powershellgallery.com/packages/ISEScriptingGeek/3.4.1
    Twitter     : 
    CreatedDate : 2022-04-26
    FileName    : get-CodeRiskProfileAST.ps1
    License     : 
    Copyright   : 
    Github      : 
    Tags        : Powershell,Parser,Risk
    REVISIONS
    * 12:58 PM 4/28/2022 ren'd get-ASTCodeRiskProfile.ps1 -> get-CodeRiskProfileAST.ps1 (matches other verb-dev functions in niche)
    * 3:59 PM 4/26/2022 ren'd get-ASTProfile() (JH's original func name) & get-ASTScriptProfile.ps1 -> get-ASTCodeRiskProfile ; fixed output wrap issues (added `n to a few of the here string leads, to ensure proper line wraps occured). ;  spliced over jdhitsolutions' latest rev of get-ASTCodeRiskProfile() (reverts -Reportpath param back to orig -FilePath); move it into verb-dev
    * Jun 24, 2019 jdhitsolutions from v3.4.1 of ISEScriptingGeek module
    * 8:26 AM 2/27/2020 added CBH, renamed FilePath to ReportDir, expanded param defs a little. 
    * 2019, posted vers 3.4.1
    .DESCRIPTION
    get-CodeRiskProfileAST.ps1 - Analyze a script/function/module (ps1|psm1) and prepare a report showing what commands it would run, necessary parameters, and anything that might pose a danger. Outputs/displays an ABOUT_[filebasename].help.txt file.  
    Based on Jeff Hicks' get-ASTProfile() script. 
    .PARAMETER  Path
    Enter the path of a PowerShell script
    .PARAMETER  FilePath
    Report output directory
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    PS> get-CodeRiskProfileAST -Path 'C:\sc\verb-AAD\verb-AAD\verb-AAD.psm1' -FilePath 'C:\sc\verb-AAD\'
    .LINK
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Position = 0, HelpMessage = "Enter the path of a PowerShell script")]
        [ValidateScript( {Test-Path $_})][ValidatePattern( "\.(ps1|psm1|txt)$")]
        [string]$Path = $(Read-Host "Enter the filename and path to a PowerShell script"),
        [Parameter(HelpMessage = "Report output directory")]
        [ValidateScript( {Test-Path $_})][Alias("fp", "out")]
        [string]$FilePath = "$env:userprofile\Documents\WindowsPowerShell"
    )

    Write-Verbose "Starting $($myinvocation.MyCommand)"

    #region setup profiling
    #need to resolve full path and convert it
    $Path = (Resolve-Path -Path $Path).Path | Convert-Path
    Write-Verbose "Analyzing $Path"

    Write-Verbose "Parsing File for AST"
    New-Variable astTokens -force
    New-Variable astErr -force

    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr)

    #endregion

    #region generate AST data

    #include PowerShell version information
    Write-Verbose "PSVersionTable"
    Write-Verbose ($PSversionTable | Out-String)

    if ($ast.ScriptRequirements) {
        $requirements = ($ast.ScriptRequirements | Out-String).Trim()
    }
    else {
        $requirements = "-->None detected`n"
    }

    if ($ast.ParamBlock.Parameters ) {
        write-verbose "Parameters detected"
        $foundParams = $(($ast.ParamBlock.Parameters |
                    Select-Object Name, DefaultValue, StaticType, Attributes |
                    Format-List | Out-String).Trim()
        )
    }
    else {
        $foundParams = "-->None detected. Parameters for nested commands not tested.`n"
    }


    #define the report text
    $report = @"
This is an analysis of a PowerShell script or module. Analysis will most likely NOT be 100% thorough.
"@

    Write-Verbose "Getting requirements and parameters"
    $report += @"
`nREQUIREMENTS
$requirements
PARAMETERS
$foundparams
"@

    Write-Verbose "Getting all command elements"

    $commands = @()
    $unresolved = @()

    $genericCommands = $astTokens |
        Where-Object {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'generic'}

    $aliases = $astTokens |
        Where-Object {$_.tokenflags -eq 'commandname' -AND $_.kind -eq 'identifier'}

    Write-Verbose "Parsing commands"
    foreach ($command in $genericCommands) {
        Try {
            $commands += Get-Command -Name $command.text -ErrorAction Stop
        }
        Catch {
            $unresolved += $command.Text
        }
    }

    foreach ($command in $aliases) {
        Try {
            $commands += Get-Command -Name $command.text -erroraction Stop |
                ForEach-Object {
                #get the resolved command
                Get-Command -Name $_.Definition
            }
        }
        Catch {
            $unresolved += $command.Text
        }
    }

    Write-Verbose "All commands"
    $report += @"
ALL COMMANDS
All possible PowerShell commands. This list may not be complete or even correct.
$(($Commands | Sort -Unique | Format-Table -autosize | Out-String).Trim())
"@

    Write-Verbose "Unresolved commands"
    if ($unresolved) {
        $unresolvedText = $Unresolved | Sort-Object -Unique | Format-Table -autosize | Out-String
    }
    else {
        $unresolvedText = "-->None detected`n"
    }

    $report += @"
`nUNRESOLVED
These commands may be called from nested commands or unknown modules.
$unresolvedtext
"@

    Write-Verbose "Potentially dangerous commands"
    #identify dangerous commands
    $danger = "Remove", "Stop", "Disconnect", "Suspend", "Block",
    "Disable", "Deny", "Unpublish", "Dismount", "Reset", "Resize",
    "Rename", "Redo", "Lock", "Hide", "Clear"

    $danger = $commands | Where-Object {$danger -contains $_.verb} | Sort-Object Name | Get-Unique

    if ($danger) {
        $dangercommands = $($danger | Format-Table -AutoSize | Out-String).Trim()
    }
    else {
        $dangercommands = "-->None detected`n"
    }

    #get type names, some of which may come from parameters
    Write-Verbose "Typenames"

    $typetokens = $asttokens | Where-Object {$_.tokenflags -eq 'TypeName'}
    if ($typetokens ) {
        $foundTypes = $typetokens |
            Sort-Object @{expression = {$_.text.toupper()}} -unique |
            Select-Object -ExpandProperty Text | ForEach-Object { "[$_]"} | Out-String
    }
    else {
        $foundTypes = "-->None detected`n"
    }

    $report += @"
TYPENAMES
These are identified .NET type names that might be used as accelerators.
$foundTypes
"@

    $report += @"
WARNING
These are potentially dangerous commands.
$dangercommands
"@

    #endregion

    Write-Verbose "Display results"
    #region create and display the result

    #create a help topic file using the script basename
    $basename = (Get-Item $Path).basename
    #stored in the Documents folder
    $reportFile = Join-Path -Path $FilePath -ChildPath "ABOUT_$basename.help.txt"

    Write-Verbose "Saving report to $reportFile"
    #insert the Topic line so help recognizes it
    @"
TOPIC
about $basename profile
"@ |Out-File -FilePath $reportFile -Encoding ascii

    #create the report
    @"
SHORT DESCRIPTION
Script Profile report for: $Path
"@ | Out-File -FilePath $reportFile -Encoding ascii -Append

    @"
LONG DESCRIPTION
$report
"@  | Out-File -FilePath $reportFile -Encoding ascii -Append

    #view the report with Notepad

    Notepad $reportFile

    #endregion

    Write-Verbose "Profiling complete."
} ; 
#*------^ END Function get-CodeRiskProfileAST  ^------
