# find-NounAliasesTDO.ps1 

# #*------v find-NounAliasesTDO.ps1 v------
Function find-NounAliasesTDO {
    <#
    .SYNOPSIS
    find-NounAliasesTDO.ps1 - Polls current Aliases defined on the local system, to try to discern 'standard' but non-formally-documented 'noun' aliases for a given Powershell Noun (as Verb's have aliases have formal/recommended aliases in MS documentation, but Noun's are not covered with the same guidence). (E.g. the common Noun 'module' uses the standard alias 'mo', in get-module (gmo), import-module (ipmo), etc))
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-12-12
    FileName    : find-NounAliasesTDO.ps1
    License     : MIT License
    Copyright   : (c) 2023 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    REVISION
    * 1:32 PM 12/13/2023 init
    .DESCRIPTION
    find-NounAliasesTDO.ps1 - Polls current Aliases defined on the local system, to try to discern 'standard' but non-formally-documented 'noun' aliases for a given Powershell Noun (as Verb's have aliases have formal/recommended aliases in MS documentation, but Noun's are not covered with the same guidence). (E.g. the common Noun 'module' uses the standard alias 'mo', in get-module (gmo), import-module (ipmo), etc))

    I use this for building mnemoic splatted variable names: $plt[verbAlias][NounAlias]

    While Verb Aliases are documented at...
    
        [Approved Verbs for PowerShell Commands - PowerShell | Microsoft Learn - UID - learn.microsoft.com/](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3)
    
    ...commonly-used Noun's lack the same guidence. 

    But there are discernable patterns: 
    Fore example all the '[verb]-Module' cmdlet Alias varants use:
        - the standard one or two-character verb aliases (g=get, ip = import, r=remove), 
        - and the same trailing pair of characters in each default Alias: 'mo'
    
    => which implies 'mo' is the NounAlias for 'module'

    So given the above, we can derive patterns of 'Noun Aliases' by:
    1) looping through the standard Verb list, 
    2) pulling all defined aliases with a definition using a given verb-Noun combo, 
    3) disards any alias that:
        - includes a dash (-), implies variant verb-noun names coverage, not short aliases
        - or is greater than 4 charaters, again, implies *not* a Microsoft standard alias, which observationally appear to be 3-4 characters long, by defailt.
    3) and examine/parse off the known-verb-Alias portion of the Alias, 
    4) and consider the remainder - for builtin or common-Microsoft-Modules, to be 'semi-standards'.
    5) Once the number of matched/analyzed aliases have been completed - as specified by MatchThreshold (3 default), the processing on the current verb-Noun combo is ended, and the process moves onto the next verb in the series.
   
    As this process needs to discover **all aliases**, _including_ verb-aliases MS has historically used that *aren't* compliant with the current published get-Verb list, 
    this code includes *non-compliant* historical MS verb-> alias mappings (cnsn -> Connect-PSSession, verb docs says use 'cc' with cn == Confirm), in it's analysis. 
    As even in those older cases, the non-stqandard Verb aliases may steal yield functional standard Noun Aliases, for our own guidence.
    
    > 🏷️  **Note**
    > 
    > Microsoft has *not* been consistent in the verb aliases they've used in cmdlets over time. 
    > The below includes notations of observed instances where MS has used a _different_ alias for the same verb, on different 'official' modules and cmdlets.

        a | Add
        ap | Approve
        as | Assert
        ba | Backup
        bl | Block
        bd | Build
        ch | Checkpoint
        cl | Clear
        cs | Close
        cr | Compare
        cp | Complete
        cm | Compress
        cn | Confirm
        cc,cn | Connect (cnsn -> Connect-PSSession, verb docs says cc, and cn == Confirm)
        cv | Convert
        cf | ConvertFrom
        ct | ConvertTo
        cp | Copy
        db | Debug
        dn | Deny
        dp | Deploy
        d | Disable
        dc,dn | Disconnect (dnsn -> Disconnect-PSSession, verb docs says dc)
        dm | Dismount
        ed | Edit
        e | Enable
        et | Enter
        ex | Exit
        en | Expand
        ep | Export
        f | Format
        g | Get
        gr | Grant
        gp | Group
        h | Hide 
        j | Join 
        ip | Import
        i | Invoke
        in | Initialize
        is | Install
        l | Limit
        lk | Lock 
        ms | Measure
        mg | Merge
        mt | Mount
        m | Move
        n | New
        op | Open 
        om | Optimize 
        o | Out
        pi | Ping
        pop | Pop 
        pt | Protect
        pb | Publish
        pu | Push
        rd | Read 
        re | Redo
        rc | Receive
        rg | Register
        r | Remove
        rn | Rename
        rp | Repair
        rq | Request
        rv | Resolve
        rt | Restart
        rr | Restore
        ru | Resume
        rk | Revoke
        sv | Save
        sr | Search 
        sc | Select
        sd | Send
        s | Set
        sh | Show
        sk | Skip
        sl | Split 
        sa | Start
        st | Step 
        sp | Stop
        sb | Submit
        ss,su | Suspend (sujb -> Suspend-Job, verb docs says ss)
        sy | Sync
        sw | Switch 
        t | Test
        tr | Trace
        ul | Unblock
        un | Undo 
        us | Uninstall
        uk | Unlock
        up | Unprotect
        ub | Unpublish
        ur | Unregister
        ud | Update
        u | Use
        w | Wait
        wc | Watch
        ? | Where
        wr | Write

    ## Powershell code to convert a markdown table like the above, to the input $sdata value above:
     (uses my verb-IO module's convertfrom-MarkdownTable())

    ```powershell
    $verbAliases = @"
Prefix | Verb
a | Add
ap | Approve
as | Assert
ba | Backup
bl | Block
bd | Build
ch | Checkpoint
cl | Clear
cs | Close
cr | Compare
cp | Complete
cm | Compress
cn | Confirm
cc | Connect
cv | Convert
cf | ConvertFrom
ct | ConvertTo
cp | Copy
db | Debug
dn | Deny
dp | Deploy
d | Disable
dc | Disconnect
dm | Dismount
ed | Edit
e | Enable
et | Enter
ex | Exit
en | Expand
ep | Export
f | Format
g | Get
gr | Grant
gp | Group
h | Hide
j | Join
ip | Import
i | Invoke
in | Initialize
is | Install
l | Limit
lk | Lock
ms | Measure
mg | Merge
mt | Mount
m | Move
n | New
op | Open
om | Optimize
o | Out
pi | Ping
pop | Pop
pt | Protect
pb | Publish
pu | Push
rd | Read
re | Redo
rc | Receive
rg | Register
r | Remove
rn | Rename
rp | Repair
rq | Request
rv | Resolve
rt | Restart
rr | Restore
ru | Resume
rk | Revoke
sv | Save
sr | Search
sc | Select
sd | Send
s | Set
sh | Show
sk | Skip
sl | Split
sa | Start
st | Step
sp | Stop
sb | Submit
ss | Suspend
sy | Sync
sw | Switch
t | Test
tr | Trace
ul | Unblock
un | Undo
us | Uninstall
uk | Unlock
up | Unprotect
ub | Unpublish
ur | Unregister
ud | Update
u | Use
w | Wait
wc | Watch
? | Where
wr | Write
"@ ; 
    write-verbose "split & replace ea line with a quote-wrapped [alias];[verb] combo, then join the array with commas" ;
    $sdata = "'$(($verbAliases.Split([Environment]::NewLine).replace(' | ',';') | %{ "$($_)" }) -join "','")'" ; 
    ```
    
    .PARAMETER ResultSize
    Integer maximum number of results to request from get-command (defaults to 10)[-ResultSize 100]
    .PARAMETER MatchThreshold
    Integer maximum number of matches to process, before moving on to the next verb in the series (defaults to 10)[-MatchThreshold 10]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.string
    .EXAMPLE
    PS> $NounAliasesFound = find-NounAliasesTDO ;
    Return the 'standard' MS alias for the 'Compare' verb (returns 'cr')
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('get-VerbAlias')]
    [OutputType([boolean])]
    PARAM (
        #[Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Verb to find the assoicated standard alias[-verb report]")]
        #[string[]] $Verb
        [Parameter(HelpMessage="Integer maximum number of results to request from get-command (defaults to 10)[-ResultSize 100]")]
            [int]$ResultSize = 20,
        [Parameter(HelpMessage="Integer maximum number of matches to process, before moving on to the next verb in the series (defaults to 10)[-MatchThreshold 10]")]
            [int]$MatchThreshold = 3
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 

        $verbAliases = @"
Prefix | Verb
a | Add
ap | Approve
as | Assert
ba | Backup
bl | Block
bd | Build
ch | Checkpoint
cl | Clear
cs | Close
cr | Compare
cp | Complete
cm | Compress
cn | Confirm
cn | Connect
cc | Connect
cv | Convert
cf | ConvertFrom
ct | ConvertTo
cp | Copy
db | Debug
dn | Deny
dp | Deploy
d | Disable
dc | Disconnect
dn | Disconnect 
dm | Dismount
ed | Edit
e | Enable
et | Enter
ex | Exit
en | Expand
ep | Export
f | Format
g | Get
gr | Grant
gp | Group
h | Hide
j | Join
ip | Import
i | Invoke
in | Initialize
is | Install
l | Limit
lk | Lock
ms | Measure
mg | Merge
mt | Mount
m | Move
n | New
op | Open
om | Optimize
o | Out
pi | Ping
pop | Pop
pt | Protect
pb | Publish
pu | Push
rd | Read
re | Redo
rc | Receive
rg | Register
r | Remove
rn | Rename
rp | Repair
rq | Request
rv | Resolve
rt | Restart
rr | Restore
ru | Resume
rk | Revoke
sv | Save
sr | Search
sc | Select
sd | Send
s | Set
sh | Show
sk | Skip
sl | Split
sa | Start
st | Step
sp | Stop
sb | Submit
ss | Suspend
su | Suspend
sy | Sync
sw | Switch
t | Test
tr | Trace
ul | Unblock
un | Undo
us | Uninstall
uk | Unlock
up | Unprotect
ub | Unpublish
ur | Unregister
ud | Update
u | Use
w | Wait
wc | Watch
? | Where
wr | Write
"@ | convertfrom-markdowntable ; 

        $allAliases = get-alias ; 
        write-verbose "$($allAliases | measure-object | select -expand count) total system aliases discovered" ;  
        $Aggreg = @() ;
} ;
    PROCESS {
        
        foreach($alPre in $verbAliases){
            write-host "Procesing Verb (alias): $($alPre.verb):($($alPre.Prefix))" ; 
            if($alPre.Prefix -eq 'cc'){
                write-verbose 'gotcha!' ; 
            } ; 
            #ResultSize, MatchThreshold
            $cmds = get-command -verb $alPre.verb -totalcount $ResultSize ; 
            $smsg = "get-command -verb $($alPre.verb) matched $(($cmds|measure-object).count) commands:" ; 
            $smsg += "`n$(($cmds.name|out-string).trim())" ; 
            write-verbose $smsg ; 
            $prcd = 0 ; 
            foreach($cmd in $cmds){
                if($als = $allAliases  | ?{$_.Definition -eq $cmd.name}){
                    $smsg = "`$allAliases  | `?{$_.Definition -eq '$($cmd.name)'} matched $(($als|measure-object).count) commands:" ;
                    $smsg += "`n$(($als.name|out-string).trim())" ; 
                    write-verbose $smsg ; 

                    foreach($al in $als){
                        if( $al.name.tostring().contains('-') ){
                            write-verbose "name contains dash"
                        }elseif($al.name.tostring().length -gt 4){
                            write-verbose "$($al.name).length -gt 4:$($al.name.tostring().length)"
                        }else{
                            $prcd++ ; 
                            if($prcd -gt $MatchThreshold){ 
                                write-verbose "$($prcd) matched aliases found: Halting loop on verb:$($alPre.verb)" ; 
                                break ;
                            } ; 
                            write-host "$($cmd.name):$($al.name.tostring()):noun:$($cmd.noun), derived assoc nounAlias:$($al.name.tostring().replace($alPre.Prefix,''))"
                            $hsh=@{
                                Noun = $cmd.noun ; 
                                NounAlias = $al.name.tostring().replace($alPre.Prefix,'') ; 
                            } ; 
                            $aggreg += New-Object -TypeName PsObject -Property $hsh ; 
                        } ; 
                    } ;  # loop-E
                    #if($prcd -eq 0){
                    #    write-verbose "(no matching aliases were discovered processing verb:$($alPre.verb)" ; 
                    #} ; 
                } else {
                    write-host -nonewline '.'
                }; 
            } ; 
        } ; 
        
    } ;  # PROC-E
    END {
        $aggreg | sort noun | write-output  ; 
        write-host "Post analysis:" ; 
        foreach($agg in ($AGGREG | sort noun)){
            $tnoun = $agg ; 
            $smsg = "==$($tnoun.noun):NounAlias distribution:" ; 
            $smsg += "`n$(($aggreg |?{$_.noun -eq $tnoun.noun} | group nounalias  |  ft -a count,name|out-string).trim())`n" ; 
            write-host $smsg ;   
        } ; 
    } ; # END-E
}
#*------^ find-NounAliasesTDO.ps1 ^------
