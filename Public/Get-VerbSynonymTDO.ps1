# Get-VerbSynonymTDO.ps1 

# #*------v Get-VerbSynonymTDO.ps1 v------
Function Get-VerbSynonymTDO {
    <#
    .SYNOPSIS
    Get-VerbSynonymTDO.ps1 - The Get-VerbSynonymTDO advanced function returns the synonyms for a verb. 
    .NOTES
    Version     : 1.4.5
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-12-12
    FileName    : Get-VerbSynonymTDO.ps1
    License     : MIT License
    Copyright   : (c) 2023 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    AddedCredit : Tommy Maynard
    AddedWebsite: http://tommymaynard.com
    AddedTwitter: @thetommymaynard / http://twitter.com/thetommymaynard
    REVISION
    * 8:23 AM 12/13/2024 add: Alias 'Get-VerbSyn'
    * 11:55 AM 12/10/2024 add: Alias to output (queried via my verb-dev\get-VerbAliasTDO()) add: pretest input Verb, for ApprovedVerb status and pre-echo it into the outputs ; add -AllowMultiWord, otherwise, it now auto-skips multiword returned Synonyms ; 
        looked at adding theaurus.com support, by splicing over code from kpatnayakuni's get-synonym.ps1, but found it doesn't parse properly anymore (html revisions in theaurus.com output) ; 
        replaced TMs key ('fkS0rTuZ62Duag0bYgwn') with my own (simply requires a google logon, to obtain a free key).
    * 4:24 PM 12/09/2024 added full pipeline support, and looping to handle multiple verbs; updated CBH, removed script wrapper & script registration block; 
        renamed Get-TMVerbSynonym -> Get-VerbSynonymTDO(), added to verb-dev (could treat as a text movule, verb-text, but it does ps-approved verb testing, which doesn't apply to raw text.
    * 3:00 PM 7/20/2022 init
    * 06/09/2016 TM posted v1.4 cites: [1.3], 01/04/2017 [1.4] 
    TM's prior release notes below:
    Version 1.4
        - Changed -- to $null for properties that do not have a value.
        - Removed redundant Get-Verb execution, when checking if a synonym is approved (uses OutVariable and temporary variable).
        - Renamed $Approved to $ApprovedVerb due to introducing the Approved switch parameter.
        - Added Approved switch parameter to only return approved synonyms without Where-Object filtering.
        - Added hardcoded position parameter attribute to the Verb parameter.
        - Added verb supplied by user to output object; renamed Verb property used for synonym to Synonym. This creates a list by default; however, it will allow for the Verb parameter taking multiple verbs... version 1.5 perhaps.
        - Rewrote help where necessary to indicate changes.
        - Added *another* If statement, to ensure an object isn't created if the Verb and Synonym are the same: Get synonyms won't return Get; Start synonyms won't return Start.     
    Version 1.3
        - Modified code to handle logic outside of the object creation time.
        - Added Group property: Indicates name of the verb's group when verb is approved.
        - Changed Approved string property of Yes and No, to $true and $false.
        - Rewrote help where necessary to indicate changes.
    Version 1.2
        - Skipped 1.1
        - Included my key for http://thesaurus.altervista.org. This keeps from needing to register for a key.
        - Decreased number of spaces in help. Other help changes due to not needing to register for a key.
        - As API key is included, modified code to
    .DESCRIPTION
    The Get-VerbSynonymTDO advanced function returns the synonyms for a verb, and indicates if they are approved verbs using Get-Verb. Additionally, if the verb is approved, it will indicate the group. This advanced function relies on the thesaurus at altervista.org.
    
    Note: What it detects as 'Approved' will depend on the rev of Powershell run under (as it uses get-verb to detect ApprovedVerbs):
     - new verbs added to ps6 - Deploy(dp) & Build (bd) - will only detect if run under Ps6+

    This is a tweaked variant of Tommy Maynard's Get-TMVerbSynonym: I'd fork his source, if he had it _github/bitbucket; Unfortunately he only posts revs to PSGallery (which isn't a git-able source revision system). So we "manually fork". 
    
    This leverages the http://thesaurus.altervista.org/thesaurus/ Thesaurus API to pull synonyms for the intput vert, and then cycles each against get-verb to qualify Approved status on each option. 
    Benefit, over get-Verb is that it autoresolves your conceptual verb, against related approved verb options. 
    
    Automatically drops multi-word synonyms (unless -AllowMultiWords used), as they aren't permitted ApprovedVerbs in Powershell. 
    
    .PARAMETER Verb
    String array of verbs for which the function will find synonyms.[-verb 'Report','publish']
    .PARAMETER Key 
    This parameter requires an API key parameter value to use this function. Versions 1.2 and greater include an API key, so there's no need to register for one. 
    .PARAMETER Approved 
    This switch parameter ensures that the results are only approved verbs. 
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.PSCustomObject
    .EXAMPLE
    PS> PS > Get-VerbSynonymTDO -Verb Launch | Format-Table -AutoSize
 
        Verb Synonym Group Approved Notes
        ---- ------- ----- -------- -----
        Launch Abolish False Antonym
        Launch Begin False
        Launch Commence False
        Launch Displace False
        Launch Establish False
        Launch Found False
        Launch Get Common True
        Launch Get Down False
        Launch Impel False
        Launch Move Common True
        Launch Open Common True
        Launch Open Up False
        Launch Plunge False
        Launch Propel False
        Launch Set About False
        Launch Set In Motion False
        Launch Set Out False
        Launch Set Up False
        Launch Smooth False
        Launch Smoothen False
        Launch Start Lifecycle True
        Launch Start Out False
     
    This example returns all the synonyms for the verb "launch." 
    .EXAMPLE
    PS> Get-VerbSynonymTDO -Verb write,trace -verbose -Approved | ft -a 
    Run multiple verbs through, return only ApprovedVerbs
    .EXAMPLE
    PS > Get-VerbSynonymTDO -Verb Launch -Approved | Format-Table -AutoSize
 
        Verb Synonym Group Approved Notes
        ---- ------- ----- -------- -----
        Launch Get Common True
        Launch Move Common True
        Launch Open Common True
        Launch Start Lifecycle True
 
    This example returns only the synonyms for the verb "Launch" that are approved verbs. If there were no approved verbs, this example would return no results.
    .EXAMPLE
    PS> Get-VerbSynonymTDO -Verb car | Format-Table -Autosize
    
        WARNING: The word "Car" may not have any verb synonyms.
 
    This example attempts to return synonyms for the word car. Since car cannot be used as a verb, it returns a warning message. This function only works when the word supplied can be used as a verb.
 
.EXAMPLE
    PS> Get-VerbSynonymTDO -Verb exit | Sort-Object Approved -Descending | Format-Table -AutoSize
 
        Verb Synonym Group Approved Notes
        ---- ------- ----- -------- -----
        Exit Move Common True
        Exit Enter Common True Antonym
        Exit Be Born False Antonym
        Exit Pop Off False
        Exit Play False
        Exit Perish False
        Exit Pass Away False
        Exit Pass False
        Exit Leave False
        Exit Kick The Bucket False
        Exit Go Out False
        Exit Go False
        Exit Give-Up The Ghost False
        Exit Get Out False
        Exit Expire False
        Exit Drop Dead False
        Exit Die Out False Related Term
        Exit Die Off False Related Term
        Exit Die Down False Related Term
        Exit Die False
        Exit Decease False
        Exit Croak False
        Exit Conk False
        Exit Choke False
        Exit Change State False
        Exit Cash In One's Chips False
        Exit Buy The Farm False
        Exit Snuff It False
        Exit Turn False
 
    This example returns synonyms for the verb "exit," and sorts the verbs by those that are approved. At the time of writing, this example only returned two approved verbs: Move and Enter. Enter is actually an antonym, and is indicated as such in the Notes property.
     
    .LINK
    https://gist.github.com/tommymaynard/76a219efa9ff51f3c90064f04fa1b662/revisions
    https://tommymaynard.com/get-tmverbsynonym-1-4-2017/
    https://www.powershellgallery.com/packages/Get-TMVerbSynonym/1.4/Content/Get-TMVerbSynonym.ps1
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('Get-VerbSynonym','Get-TMVerbSynonym','Get-VerbSyn')]
    #[OutputType([boolean])]
    PARAM (
        [Parameter(Mandatory = $true,Position=0,ValueFromPipeline=$true,HelpMessage="String array of verbs for which the function will find synonyms.[-verb 'Report','publish']")]
            [string[]]$Verb,
        [Parameter(,HelpMessage="This parameter requires an API key parameter value to use this function. Versions 1.2 and greater include an API key, so there's no need to register for one. [-Key aaa0aaaa62aaaa0aaaaa")]
            [string]$Key = 'kVW9sY6X4zpY01aciPne',
        [Parameter(,HelpMessage="This switch parameter ensures that the results are only approved verbs. [-Approved]")]
            [switch]$Approved,
        [Parameter(,HelpMessage="This switch parameter permits multi-word synonyms (overrides default; are unsupported by Powershell). [-AllowMultiWord]")]
            [switch]$AllowMultiWord
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        # check if using Pipeline input or explicit params:
        if ($rPSCmdlet.MyInvocation.ExpectingInput) {
            $smsg = "Data received from pipeline input: '$($InputObject)'" ;
            if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } else {
            # doesn't actually return an obj in the echo
            #$smsg = "Data received from parameter input: '$($InputObject)'" ;
            #if($verbose){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            #else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
        } ;
          
    } ;
    PROCESS {
        #region PROCESS ; #*------v PROCESS v------
        $Error.Clear() ; 
        $ttl = $verb |  measure | select -expand count ; 
        $prcd = 0 ; 
        #region PIPELINE_PROCESSINGLOOP ; #*------v PIPELINE_PROCESSINGLOOP v------
        foreach($item in $verb) {
            $prcd++ ; 
            $smsg = $sBnrS="`n#*------v PROCESSING ($($prcd)/$($ttl)) : $($item) v------" ; 
            write-verbose $smsg ; 
            
            # Modify case: Capitalize first letter.
            $item = (Get-Culture).TextInfo.ToTitleCase($item) ; 
            # Obtain thesaurus information on verb.
            
            write-verbose "Pretest if the specified Verbs is already a known ApprovedVerb"
            If (Get-Verb -Verb $item -OutVariable TempVerbCheck) {
                $ApprovedVerb = $true ; 
                $Group = $TempVerbCheck.Group ; 
                Remove-Variable -Name TempVerbCheck ; 
                write-host -foregroundcolor green "Note: specified verb:$($item) is *already* an Approved Verb for Powershell" ; 
                [pscustomobject]@{
                    Verb = $item ; 
                    Synonym = '(self)' ; 
                    Group = $Group ; 
                    Approved = $ApprovedVerb ; 
                    Notes = $Notes ; 
                    Alias = (get-VerbAliasTDO -Verb $item -ea Continue) ;
                } | write-output ; 
            } ; 

            TRY {
                Write-Verbose -Message "Downloading thesaurus.altervista.org synonyms for $item." ; 
                [xml]$Data = (Invoke-WebRequest -Uri "http://thesaurus.altervista.org/thesaurus/v1?word=$item&language=en_US&key=$Key&output=xml" -Verbose:$false).Content ; 
            } CATCH [System.Net.WebException] {
                Write-Warning -Message "Unable to find any synonyms for $item. Please check your spelling." ; 
            } CATCH {
                Write-Warning -Message 'Unhandled error condition in PROCESS Block.' ; 
            } ;    
                
            # Check supplied verb against thesaurus.
            Write-Verbose -Message "Checking for synonoms for $item."
            If ($Data) {
                Write-Verbose -Message 'Attempting to parse synonyms list.' ; 
                
                TRY {
                    $Synonyms = ($Data.response.list | Where-Object -Property Category -eq '(verb)' | 
                        Select-Object -ExpandProperty Synonyms).Split('|') | 
                            Select-Object -Unique | Sort-Object ; 
                } CATCH [System.Management.Automation.RuntimeException] {
                    Write-Warning -Message "The word ""$item"" may not have any verb synonyms." ; 
                } CATCH {
                    Write-Warning -Message 'Unhandled error condition in Process Block.' ; 
                } ; 
                TRY {
                
                    Write-Verbose -Message 'Building results.' ; 
                    Foreach ($Synonym in $Synonyms) {
                        $Synonym = (Get-Culture).TextInfo.ToTitleCase($Synonym) ; 
                        <#
                        if($Synonym -match 'Trace|Write'){
                            write-host 'gotcha!' ;
                        }
                        #>                        
                        # Clear paraenthesis: (Antonym) and (Related Term) --> Antonym and Related Term.
                        # Write to Notes variable.
                        if ($Synonym -match '\(*\)') {
                            $Notes = $Synonym.Split('(')[-1].Replace(')','') ; 
                            $Synonym = ($Synonym.Split('(')[0]).Trim() ; 
                        } Else {
                            $Notes = $null ; 
                        } ; 
                        if (-not $AllowMultiWord -AND $Synonym -match '\s'){
                            write-verbose "skipping multi-word synonym:$($Synonym)" ; 
                            Continue ; 
                        }
                        # Determine if verb is approved.
                        If (Get-Verb -Verb $Synonym -OutVariable TempVerbCheck) {
                            $ApprovedVerb = $true ; 
                            $Group = $TempVerbCheck.Group ; 
                            Remove-Variable -Name TempVerbCheck ; 
                        } Else {
                            $ApprovedVerb = $false ; 
                            $Group = $null ; 
                        } ; 

                        # Build Objects.
                        If ($item -ne $Synonym) {
                            If ($Approved) {
                                If ($ApprovedVerb -eq $true) {
                                    [pscustomobject]@{
                                        Verb = $item ; 
                                        Synonym = $Synonym ; 
                                        Group = $Group ; 
                                        Approved = $ApprovedVerb ; 
                                        Notes = $Notes ; 
                                        Alias = if($ApprovedVserb){(get-VerbAliasTDO -Verb $Synonym -ea Continue)}else{$null} ;
                                    } | write-output ; 
                                } ; 
                            } Else {
                                [pscustomobject]@{
                                    Verb = $item ; 
                                    Synonym = $Synonym ; 
                                    Group = $Group ; 
                                    Approved = $ApprovedVerb ; 
                                    Notes = $Notes ; 
                                    Alias = if($ApprovedVerb){(get-VerbAliasTDO -Verb $Synonym -ea Continue)}else{$null} ;
                                } | write-output ; 
                            }  ; 
                        }  ;  # if-E ($item -ne $Synonym).
                    } ; # loop-E
                } CATCH [System.Management.Automation.RuntimeException] {
                    Write-Warning -Message "The word ""$item"" may not have any verb synonyms." ; 
                } CATCH {
                    Write-Warning -Message 'Unhandled error condition in Process Block.' ; 
                } ; 
            } ;
            write-verbose  $sBnrS.replace('-v','-^').replace('v-','^-') ;
        } ;  # loop-E
        #endregion PIPELINE_PROCESSINGLOOP ; #*------^ END PIPELINE_PROCESSINGLOOP ^------
    } ;  # PROC-E
    END {} ; # END-E
} ; 
#*------^ Get-VerbSynonymTDO.ps1 ^------
