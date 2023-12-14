# get-VerbAliasTDO.ps1 

# #*------v get-VerbAliasTDO.ps1 v------
Function get-VerbAliasTDO {
    <#
    .SYNOPSIS
    get-VerbAliasTDO.ps1 - Returns the 'standard' alias prefix for a given Powershell verb (according to MS documentation). (E.g. the common verb 'copy' has uses the standard alias prefix 'cp')
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2023-12-12
    FileName    : get-VerbAliasTDO.ps1
    License     : MIT License
    Copyright   : (c) 2023 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,verbs
    REVISION
    * 3:00 PM 7/20/2022 init
    .DESCRIPTION
    get-VerbAliasTDO.ps1 - Returns the 'standard' alias prefix for a given Powershell verb (according to MS documentation). (E.g. the common verb 'copy' has uses the standard alias prefix 'cp')

    I use this for building mnemoic splatted variable names: $plt[verbAlias][objectalias]

    As documented at:
    
    [Approved Verbs for PowerShell Commands - PowerShell | Microsoft Learn - UID - learn.microsoft.com/](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3)
    
   
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
    
    .PARAMETER Verb
    Verb to find the associated standard alias[-verb report]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.string
    .EXAMPLE
    PS> 'Compare' | get-NounAliasTDO ;
    Return the 'standard' MS alias for the 'Compare' verb (returns 'cr')
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('get-VerbAlias')]
    #[OutputType([boolean])]
    PARAM (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Verb to find the associated standard alias[-verb report]")]
        [string[]] $Verb
    ) ;
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        # array of mappings: [verb];[std alias] (1st entry is the column name row, for use when an input for a data table, or into convertto-Markdowntable)
        $sdata = 'Prefix;Verb','a;Add','ap;Approve','as;Assert','ba;Backup','bl;Block','bd;Build','ch;Checkpoint','cl;Clear',
            'cs;Close','cr;Compare','cp;Complete','cm;Compress','cn;Confirm','cc;Connect','cv;Convert','cf;ConvertFrom',
            'ct;ConvertTo','cp;Copy','db;Debug','dn;Deny','dp;Deploy','d;Disable','dc;Disconnect','dm;Dismount','ed;Edit',
            'e;Enable','et;Enter','ex;Exit','en;Expand','ep;Export','f;Format','g;Get','gr;Grant','gp;Group','h;Hide','j;Join',
            'ip;Import','i;Invoke','in;Initialize','is;Install','l;Limit','lk;Lock','ms;Measure','mg;Merge','mt;Mount','m;Move',
            'n;New','op;Open','om;Optimize','o;Out','pi;Ping','pop;Pop','pt;Protect','pb;Publish','pu;Push','rd;Read','re;Redo',
            'rc;Receive','rg;Register','r;Remove','rn;Rename','rp;Repair','rq;Request','rv;Resolve','rt;Restart','rr;Restore',
            'ru;Resume','rk;Revoke','sv;Save','sr;Search','sc;Select','sc;Select-object','sd;Send','s;Set','sh;Show','sk;Skip','sl;Split','sa;Start',
            'st;Step','sp;Stop','sb;Submit','ss;Suspend','sy;Sync','sw;Switch','t;Test','tr;Trace','ul;Unblock','un;Undo',
            'us;Uninstall','uk;Unlock','up;Unprotect','ub;Unpublish','ur;Unregister','ud;Update','u;Use','w;Wait','wc;Watch',
            '?;Where','wr;Write' ; 
        # convert semi-delimted array of values into indexed hash for lookups
        $hshAliasesPrfx = @{} ;
        $sdata | select-object -skip 1 |foreach-object{
            # split at semi, and assign the array elements to $value & $key respectively
            $value,$key = $_.split(';') ; 
            # add indexed hash element on $key with $value
            $hshAliasesPrfx[$key] = $value ;
        } ;
        # clear temp varis
        'sdata','key','value' | remove-variable -ea 0 -verbose ; 
    } ;
    PROCESS {
        foreach($item in $verb){
            write-verbose "(checking: $($item))" ; 
            #[boolean]((Get-Verb).Verb -match $item) | write-output ;
            if($hshAliasesPrfx[$item]){
                $hshAliasesPrfx[$item] | write-output 
            }else {
                write-warning "no lookup match for verb '$($item)'" 
                $false | write-output ; 
            } ;
        } ; 
    } ;  # PROC-E
    END {} ; # END-E
}
#*------^ get-NounAliasTDO.ps1 ^------
