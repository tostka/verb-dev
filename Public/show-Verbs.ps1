# show-Verbs.ps1 

# #*------v show-Verbs.ps1 v------
Function show-Verbs {
    <#
    .SYNOPSIS
    show-Verbs.ps1 - Display standard Verbs grouped into Categories
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2021-01-20
    FileName    : show-Verbs.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    AddedCredit : arsscriptum
    AddedWebsite: https://github.com/arsscriptum/PowerShell.Module.Core/blob/master/src/Miscellaneous.ps1
    AddedTwitter: 
    REVISION
    * 8:48 AM 5/18/2026 corrected CBH syn & desc; revised demo's added echos
    * 4:35 PM 7/20/2022 init; cached & subbed out redundant calls to get-verb; ; explict write-out v return ; fixed fails on single object counts; added pipeline support; 
        flipped DarkRed outputs to foreground/background combos (visibility on any given bg color)
    * 5/13/22 arsscriptum's posted copy (found in google search)
    .DESCRIPTION
    show-Verbs.ps1 - Display standard Verbs grouped into Categories
    If -verb is used, only the specified verb's info and group/category is output.
    .PARAMETER Verb
    Verb string to be tested[-verb report]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    Boolean
    .EXAMPLE
    PS> 'New' | show-Verbs ;
    
      Found 1 verbs
      Verb Group
      ---- -----
      New  Common

    Show the info on the new standard verb
    .EXAMPLE
    PS> show-verbs ; 
    
        Verbs in category Common (34) :
        Add       Clear     Close     Copy     Enter    Exit     Find     Format   Get      Hide     Join     Lock     Move     New      Open
        Optimize  Pop       Push      Redo     Remove   Rename   Reset    Resize   Search   Select   Set      Show     Skip     Split    Step
        Switch    Undo      Unlock    Watch
        Verbs in category Data (24) :
        Backup       Checkpoint   Compare      Compress     Convert      ConvertFrom  ConvertTo   Dismount    Edit        Expand      Export
        Group        Import       Initialize   Limit        Merge        Mount        Out         Publish     Restore     Save        Sync
        Unpublish    Update
        Verbs in category Lifecycle (20) :
        Approve     Assert      Complete    Confirm     Deny        Disable     Enable     Install    Invoke     Register   Request    Restart
        Resume      Start       Stop        Submit      Suspend     Uninstall   Unregister Wait
        Verbs in category Diagnostic (7) :
        Debug    Measure  Ping    Repair  Resolve Test    Trace
        Verbs in category Communications (6) :
        Connect     Disconnect  Read        Receive     Send        Write
        Verbs in category Security (6) :
        Block      Grant      Protect    Revoke     Unblock    Unprotect
        Verbs in category Other (1) :
        Use    

    Output formatted display of all standard verbs (as per get-verb)
    .EXAMPLE
    PS> 'show','new','delete','invoke' | show-verbs -verbose  ; 
    
        Verb   Group
        ----   -----
        Show   Common
        New    Common
        Invoke Lifecycle    

    Show specs on an array of verbs with verbose output and pipeline input
    .EXAMPLE
    gcm -mod verb-io | ? commandType -eq 'Function' | select -expand verb -unique | show-Verbs -verbo
    Collect all unique verbs for functions in the verb-io module, and test against MS verb standard with verbose output
    .LINK
    https://github.com/tostka/verb-IO
    #>
    [CmdletBinding()]
    #[Alias('test-verb')]
    #[OutputType([boolean])]
    PARAM(
        [Parameter(Mandatory=$false,ValueFromPipeline = $true,HelpMessage="Verb string to be tested[-verb report]") ]
        [Alias('Name' ,'v', 'n','like', 'match')]
        [String[]]$Verb
    )   
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        $verbs = (get-verb) ; 
        $Groups = ($verbs | Select Group -Unique).Group ; 
    } ;
    PROCESS {
        foreach($item in $verb){
            write-verbose "(checking: $($item))" ; 
            #if ($PSBoundParameters.ContainsKey('Verb')) {
            $Formatted = ($verbs | where Verb -match $item| sort -Property Verb)
            if($Formatted){
                $FormattedCount = $Formatted |  measure | select -expand count ;
                Write-Host "Found $FormattedCount verbs`n" -f Black -b Gray -n ; 
                $Formatted | write-output ;  
            }else{
                Write-Host "No verb found`n" -f DarkGray -b White; 
            } ; 
            return ; 
        } ; 
        $Groups.ForEach({
                $g = $_
                $VerbsCount = $verbs | where group -eq $g |  measure | select -expand count ; 
                $Formatted = (($verbs | where Group -match $g | sort -Property Verb | Format-Wide  -Autosize | Out-String).trim()) ; 
                Write-Host "Verbs in category " -f Black -b Gray -n ; 
                Write-Host "$g ($VerbsCount) : " -f Yellow -b Gray  -n ; 
                Write-Host "`n$Formatted" -f DarkYellow -b Black ; 
            })
    } ;  # PROC-E
    END {} ; # END-E
}
#*------^ show-Verbs.ps1 ^------
