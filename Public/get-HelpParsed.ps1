#*------v get-HelpParsed.ps1 v------
function get-HelpParsed {
    <#
    .SYNOPSIS
    get-HelpParsed - Parse Script CBH with get-help -full, return System.Object with Helpparsed property PSCustomObject (as parsed by get-help); hasExistingCBH boolean, and NotesHash OrderedDictionary reflecting a fully parsed NOTES block into hashtable of key:value combos (as split on colon's per line)
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
    10:43 AM 10/2/2023 ren to std verb-noun, alias orig name parseHelp -> parse-Help; No use real verb -> get-HelpParsed;
    added incrementing names to non-unique NOTES block key names (duplicates of Author, Website, Twitter etc, become Author1, Website1, ...) 
    fliped the hash returned to [ordered] - important where you have duplicated blocks of author,website,twitter to ensure the assoicated tags are contiguous in the output, and reflect the order from the source CBH block.
    * 3:45 PM 4/14/2020 added pretest of $path extension, get-help only works with .ps1/.psm1 script files (misnamed temp files fail to parse)
    * 7:50 AM 1/29/2020 added Cmdletbinding
    * 9:11 AM 12/30/2019 get-HelpParsed(): added CBH .INPUTS & .OUTPUTS, specifying returns hash of get-help parsed output, and presence of CBH in the file
    * 10:03 PM 12/2/201919 INIT
    .DESCRIPTION
    get-HelpParsed - Parse Script CBH with get-help -full, return System.Object with Helpparsed property PSCustomObject (as parsed by get-help); hasExistingCBH boolean, and NotesHash OrderedDictionary reflecting a fully parsed NOTES block into hashtable of key:value combos (as split on colon's per line)

    Between get-HelpParsed/parse-Help and get-VersionInfo, both do largely the same thing, but this uses a more flexible get-help call syntax less likely to mis-parse CBH out of a given target. This variant has also been continuosly updated, get-VersionInfo has been static since 4/2020.
    
    The NotesHash hashtable returned is aimed parsing out and returning usable metadata from my personal system of populating the NOTES block with standardized colon-delimited metadata:
    Version     : 1.1.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 3:45 PM 11/16/2019
    FileName    :
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/verb-dev
    AddedCredit :
    AddedWebsite:
    AddedTwitter:
    (the tags above are not standard but I find them useful none the less, especitally where using this type of parsing to assemble and reuse canned settings with a given script or function).

    My trailing entry in the notes block is the REVISION tag, which reflects solely the stack of updates on the code (The line following the REVISIONS lines should be part of another CBH keyword block)
    Where a given key value in a notes block is non-unique, subsequent instances of the same key have an incrementing integer appended to render them unique, for inclusion in the hash.

    Note, if using temp files, you *can't* pull get-help on anything but script/module files, with the proper extension (.e.g if you've got temp's named .TMP, get-help won't parse them)

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
    * NotesHash
    * RevisionsText
    .EXAMPLE
    $bRet = get-HelpParsed -Path $oSrc.fullname -showdebug:$($showdebug) -verbose:$VerbosePreference -whatif:$($whatif) ;
    if($bRet.HelpParsed){
        $HelpParsed = $bRet.HelpParsed
    } ;
    if($bRet.hasExistingCBH){
        $hasExistingCBH = $bRet.hasExistingCBH
    } ;
    .EXAMPLE
    PS> $prpHP = @{name="alertSet";expression={$_.alertSet | out-string}},'Category','description', @{name="description";expression={$_.description | out-string}}, @{name="details";expression={$_.details | out-string}}, @{name="examples";expression={$_.examples | out-string}}, @{name="inputTypes";expression={$_.inputTypes | out-string}}, 'ModuleName','Name', @{name="parameters";expression={$_.parameters | out-string}}, @{name="returnValues";expression={$_.returnValues | out-string}}, 'Synopsis', @{name="syntax";expression={$_.syntax | out-string}} ;
    PS> $bRet | fl $prpHP ; 

    alertSet     :

                       Author: Todd Kadrie
                       Website:	http://tinstoys.blogspot.com
                       Twitter:	http://twitter.com/tostka
                       Additional Credits: [REFERENCE]
                       Website:	[URL]
                       Twitter:	[URL]
                       REVISIONS   :
                       # 1:54 PM 7/26/2023 updated 'jpg' thumbnail image seeking code to target both .jpg & .webp (YT has shifted to the latter on recent dl), driven by 
                        $rgxYTCoverExts constant;
                       fixed inaccur helpmessage/param for $inputobject; ren'd all $*jpg vari refs to $*thumb, to reflect the image files are thumbs of either .jpg or webp type, 
                       using postfilter match on extension rgx; updated CBH desc/synopsis for accuracy
                       ....
                   

    Category     : ExternalScript
    description  : 
                   move-ConvertedVidFiles.ps1 - Post youtube vid-conversion-toMp3 script that collects mp4|mkv|webm files, checks for matching mp3 files -gt 1MB, and mathing 
                   jpg|webp files, and 
                   then collects the vid & jpg|webp files and moves them to C:\vidtmp\_vids-done\ & C:\vidtmp\_jpgs-done\ respectively

    details      : 
                   NAME
                       C:\usr\work\ps\scripts\move-ConvertedVidFiles.ps1
                   
                   SYNOPSIS
                       move-ConvertedVidFiles.ps1 - Post vid-conversion-toMp3 script that collects mp4|mkv|webm files, checks for matching mp3 files -gt 1MB, and mathing 
                   jpg|webp thumbnail 
                       files, and then collects the vid & jpg|webp files and moves them to C:\vidtmp\_vids-done\ & C:\vidtmp\_jpgs-done\ respectively

    examples     : 
                   -------------------------- EXAMPLE 1 --------------------------
               
                   PS C:\>.\move-ConvertedVidFiles.ps1
               
                   Default settings running from current path

                   -------------------------- EXAMPLE 2 --------------------------
               
                   PS C:\>.\move-ConvertedVidFiles.ps1 -InputObject "C:\vidtmp\" -showdebug -whatif ;
               
                   Whatif & showdebug pass specifying a specific path to check.

    inputTypes   : 
                   Accepts piped input.

    ModuleName   : 
    Name         : C:\usr\work\ps\scripts\move-ConvertedVidFiles.ps1
    parameters   : 
                       -InputObject <Object>
                           Path to be checked for transcod to mp3 (and matching .jpg|webp)
                       
                           Required?                    false
                           Position?                    1
                           Default value                
                           Accept pipeline input?       true (ByValue, ByPropertyName)
                           Accept wildcard characters?  false
                       
                       -showDebug [<SwitchParameter>]
                           Parameter to display Debugging messages [-ShowDebug switch]
                       
                           Required?                    false
                           Position?                    named
                           Default value                False
                           Accept pipeline input?       false
                           Accept wildcard characters?  false
                       
                       -whatIf [<SwitchParameter>]
                       
                           Required?                    false
                           Position?                    named
                           Default value                False
                           Accept pipeline input?       false
                           Accept wildcard characters?  false
                       
                       <CommonParameters>
                           This cmdlet supports the common parameters: Verbose, Debug,
                           ErrorAction, ErrorVariable, WarningAction, WarningVariable,
                           OutBuffer, PipelineVariable, and OutVariable. For more information, see 
                           about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).

    returnValues : 
                   Returns an object with uptime data to the pipeline.

    Synopsis     : move-ConvertedVidFiles.ps1 - Post youtube vid-conversion-toMp3 script that collects mp4|mkv|webm files, checks for matching mp3 files -gt 1MB, and mathing 
                   jpg|webp thumbnail files, and then collects the vid & jpg|webp files and moves them to C:\vidtmp\_vids-done\ & C:\vidtmp\_jpgs-done\ respectively
    syntax       : 
                   C:\usr\work\ps\scripts\move-ConvertedVidFiles.ps1 [[-InputObject] <Object>] [-showDebug] [-whatIf] [<CommonParameters>]    

    Builds on first expl: Demos expressed properties that outline the default data returned pre-parsed by get-help. 
    .EXAMPLE
    PS> $bret.Noteshash

    Name                           Value                                                                                                                                              
    ----                           -----                                                                                                                                              
    Author                         Todd Kadrie                                                                                                                                        
    Website                        http://tinstoys.blogspot.com                                                                                                                       
    Twitter                        http://twitter.com/tostka                                                                                                                          
    Website1                       [URL]                                                                                                                                              
    Twitter1                       [URL]                                                                                                                                              
    LastRevision                   # 1:54 PM 7/26/2023 updated 'jpg' thumbnail image seeking code to target both .jpg & .webp (YT has shifted to the latter on recent dl), driven b...

    
    Also builds on first expl: Demo contents of the returned NotesHash ordered hashtable property of the return
    .EXAMPLE
    PS> $bret.RevisionsText

    # 1:54 PM 7/26/2023 updated 'jpg' thumbnail image seeking code to target both .jpg & .webp (YT has shifted to the latter on recent dl), driven by $rgxYTCoverExts constant;
    fixed inaccur helpmessage/param for $inputobject; ren'd all $*jpg vari refs to $*thumb, to reflect the image files are thumbs of either .jpg or webp type, 
    using postfilter match on extension rgx; updated CBH desc/synopsis for accuracy
    # 11:17 AM 7/21/2023 working fully; ...

    Also builds on first expl: Demo contents of the returned RevisionsText property.

    .LINK
    https://github.com/verb-dev
    #>
    # [ValidateScript({Test-Path $_})], [ValidateScript({Test-Path $_})]
    [CmdletBinding()]
    [Alias('parse-Help','parseHelp')]
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
    $notes = $null ; 
    if($host.version.major -lt 3){
        $notes = @{ } ;
    } else { 
        $notes = [ordered]@{ } ;
    } ; 

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
                    Continue ;
                    #break ; 
                    # no don't break, parse the entire stack, there's could be a range of keywords below REVISIONS
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
                        #if (!($notes.ContainsKey($name))) { $notes.Add($name, $value) } ;
                        # incremnent the keyname to continue adding additional same-keyed items
                        # ordered has .conains method, non ordered has containskey method
                        if($host.version.major -lt 3){
                            if (-not ($notes.ContainsKey($name))) { 
                                $notes.Add($name, $value) 
                            } else {
                                $incr = 1 ; 
                                $nameN = "$($name)$($incr)"
                                while ($notes.ContainsKey($nameN)) {
                                    $incr++ ; 
                                    write-verbose "incrementing hash key clash:$($incr)" ; 
                                } ; 
                                $notes.Add($nameN, $value) ; 
                            } ;
                        } else { 
                            if (-not ($notes.Contains($name))) { 
                                $notes.Add($name, $value) 
                            } else {
                                $incr = 1 ; 
                                $nameN = "$($name)$($incr)"
                                while ($notes.Contains($nameN)) {
                                    $incr++ ; 
                                    write-verbose "incrementing hash key clash:$($incr)" ; 
                                } ; 
                                $notes.Add($nameN, $value) ; 
                            } ;
                        } ; 
                    } ;
                } ;
            } ; 
        } ;
        $objReturn.NotesHash = $notes ;
        $objReturn.RevisionsText = $revText ; 
    } ; 

    $objReturn | Write-Output ;
}

#*------^ get-HelpParsed.ps1 ^------