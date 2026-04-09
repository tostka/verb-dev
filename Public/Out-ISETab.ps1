# Out-ISETab.ps1

Function Out-ISETab {
    <#
    .SYNOPSIS
    Out-ISETab.ps1 - Runs specified input (pipeline) into a Tab in ISE (new tab, default, -currenttab if specified)
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Out-ISETab.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-XXX
    Tags        : Powershell
    AddedCredit : jdhitsolutions
    AddedWebsite: https://github.com/jdhitsolutions/ISEScriptingGeek/
    AddedTwitter: URL
    REVISIONS
    * 10:13 AM 4/9/2026 init
    * Jul 3, 2023 jdh posted vers
    .DESCRIPTION
    Out-ISETab.ps1 - Runs specified input (pipeline) into a Tab in ISE (new tab, default, -currenttab if specified)
    .INPUTS
    object[]
    Accepts pipeline input
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    .EXAMPLE
    PS> gc d:\scripts\out-iseTab_func.ps1 | Out-ISETab
    Demo pipeline content from a script file, creates a new tab in current ISE and populates the tab with the inbound content        
    .EXAMPLE
    PS> gc d:\scripts\out-iseTab_func.ps1 | Out-ISETab -currentfile
    Demo above but recycles the current open tab/file as the destination
    .LINK
    https://github.com/tostka/verb-dev
    .LINK
    https://github.com/jdhitsolutions/ISEScriptingGeek/
    #>
    [CmdletBinding()]
    [alias('tab')]
    Param (
        [Parameter(Position = 0, Mandatory, ValueFromPipeline)]
            [object[]]$InputObject,
            [Switch]$UseCurrentFile
    )
    Begin {
        if ($psISE) {
            Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
            if ($UseCurrentFile) {
                Write-Verbose 'Using current file'
                $tab = $psISE.CurrentFile
            }
            else {
                #create a new file
                Write-Verbose 'Creating a new tab'
                $tab = $psISE.CurrentPowerShellTab.Files.Add()
            }
        } else {
            Write-Warning 'This function requires the Windows PowerShell ISE.'
            return ; 
        }
        $data = @()
    }
    Process {
        #add each piped object
        $data += $InputObject
    } #process
    End {
        #send the data to the ISE tab
        $tab.Editor.InsertText(($data | Out-String))
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
} #end function