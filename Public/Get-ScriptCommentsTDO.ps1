# Get-ScriptCommentsTDO

Function Get-ScriptCommentsTDO {
    <#
    .SYNOPSIS
    Get-ScriptCommentsTDO - Parse Comments from specified .ps1 file
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : Get-ScriptCommentsTDO
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
    Get-ScriptCommentsTDO - Parse Comments from specified .ps1 file
    .PARAMETER  PARAMNAME
    .PARAMETER  PARAMNAME2
    .PARAMETER Ticket
    Ticket number[-ticket 123456]
    .PARAMETER Path
    Path [-path c:\path-to\]
    .PARAMETER File
    File [-file c:\path-to\file.ext]
    .PARAMETER TargetMailboxes
    HelpMessage="Mailbox email addresses(array)[-Targetmailboxes]
    .PARAMETER ResultSize
    Integer maximum number of results to request (for shortened debugging passes)
    .PARAMETER Credential
    Use specific Credentials (defaults to Tenant-defined SvcAccount)[-Credentials [credential object]]
    .PARAMETER AdminAccount
    Use specific Admin account (defaults to Tenant-defined o365_SIDUpn)[-Credentials [credential object]]
    .PARAMETER UserRole
    Credential User Role spec (SID|CSID|UID|B2BI|CSVC|ESVC|LSVC|ESvcCBA|CSvcCBA|SIDCBA)[-UserRole @('SIDCBA','SID','CSVC')]
    .PARAMETER useEXOv2
    Use EXOv2 (ExchangeOnlineManagement) over basic auth legacy connection [-useEXOv2]
    .PARAMETER Silent
    Switch to specify suppression of all but warn/error echos.(unimplemented, here for cross-compat)
    .PARAMETER MGPermissionsScope
    Optional Array of MG Permission Names(avoids manual discovery against configured cmdlets)[-MGPermissionsScope @('Domain.Read.All','Domain.ReadWrite.All','Directory.Read.All') ]
    .PARAMETER useExOPVers
    String array to indicate target OnPrem Exchange Server version to target with connections, if an array, will be assumed to reflect a span of versions to include, connections will aways be to a random server of the latest version specified (Ex2000|Ex2003|Ex2007|Ex2010|Ex2000|Ex2003|Ex2007|Ex2010|Ex2016|Ex2019), used with verb-Ex2010\get-ADExchangeServerTDO() dyn location via ActiveDirectory.[-useExOPVers @('Ex2010','Ex2016')]")]
    .PARAMETER Force
    Force (Confirm-override switch, overrides ShouldProcess testing, executes somewhat like legacy -whatif:`$false)[-force]
    .PARAMETER PassThru
    Returns an object to pipeline. By default, this cmdlet does not generate any pipeline output.[-PassThru]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .INPUTS
    None. Does not accepted piped input.(.NET types, can add description)
    .OUTPUTS
    None. Returns no objects or output (.NET types)
    System.Boolean
    .EXAMPLE
    PS> .\Get-ScriptCommentsTDO -whatif -verbose
    EXSAMPLEOUTPUT
    Run with whatif & verbose
    .LINK
    https://github.com/tostka/verb-XXX
    .LINK
    https://github.com/tostka/powershellbb/
    #>
    [CmdletBinding()]
    [Alias('Get-ScriptComments')]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = 'Enter the path of a PS1 file',
            ValueFromPipeline, ValueFromPipelineByPropertyName)]
            [Alias('PSPath', 'Name')]
            [ValidateScript( { Test-Path $_ })]
            [ValidatePattern('\.ps(1|m1)$')]
            [String]$Path
    )
    Begin {
        #Begin scriptblock
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        #initialization commands
        #explicitly define some AST variables
        #New-Variable $AstTokens -Force # throws:New-Variable : Cannot bind argument to parameter 'Name' because it is null.
        New-Variable AstTokens -Force
        New-Variable astErr -Force
    } #close begin
    Process {        
        #Process scriptblock
        #convert each path to a nice filesystem path
        $Path = Convert-Path -Path $Path
        $sBnrS="`n#*------v AST-PARSED COMMENTS : $($Path) v------" ; 
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnrS)" ;
        Write-Verbose -Message "Parsing $Path"
        #Parse the file
        $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$AstTokens, [ref]$astErr)
        #filter tokens for comments and display text
        $AstTokens.where( { $_.kind -eq 'comment' }) |
        Select-Object -ExpandProperty Text
        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
    } #close process
    End {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    } #close end
} #close function