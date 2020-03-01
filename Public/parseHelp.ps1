#*------v Function parseHelp() v------
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
    AddedTwitter:#*------v Function parseHelp() v------
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
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:11 AM 12/30/2019 parseHelp(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file
    * 10:03 PM 12/2/201919 INIT
    .DESCRIPTION
    parseHelp - Parse Script and prepend new Comment-based-Help keyed to existing contents
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
        $smsg = "$(($helpparsed | select Category,Name,Synopsis, param*,alertset,details,examples |out-string).trim())" ;
        #$smsg = "CMDLET w`n$((|out-string).trim())" ;
        $smsg = "`$Path.FullName:$($Path.FullName)" ;
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


    }  ;
    $objReturn | Write-Output ;
} ; # #*------^ END Function parseHelp() ^------
    REVISIONS
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:11 AM 12/30/2019 parseHelp(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file
    * 10:03 PM 12/2/201919 INIT
    .DESCRIPTION
    parseHelp - Parse Script and prepend new Comment-based-Help keyed to existing contents
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
        $smsg = "$(($helpparsed | select Category,Name,Synopsis, param*,alertset,details,examples |out-string).trim())" ;
        #$smsg = "CMDLET w`n$((|out-string).trim())" ;
        $smsg = "`$Path.FullName:$($Path.FullName)" ;
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


    }  ;
    $objReturn | Write-Output ;
} ; # #*------^ END Function parseHelp() ^------