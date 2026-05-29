# get-UnifiedDiffTDO.ps1

#region COMPARE_OBJECTSTDO ; #*------v get-UnifiedDiffTDO v------
function get-UnifiedDiffTDO {
    <#
    .SYNOPSIS
    get-UnifiedDiffTDO() - Produce a UnifiedDiff output of two files, without both being in a git repo (or even same git repo ; leverages: git diff --no-index --unified=3)
    .NOTES
    Version     : 0.0.
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2026-
    FileName    : get-UnifiedDiffTDO.ps1
    License     : MIT License
    Copyright   : (c) 2026 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Git,SourceControl,Diff,format
    AddedCredit : 
    AddedWebsite: 
    AddedTwitter: URL
    REVISIONS
    * 8:38 AM 5/29/2026 added trailing reports; flipped -nopager -> -pager; updated CBH, and demos.
    * 2:00 PM 5/28/2026 init
    .DESCRIPTION
    get-UnifiedDiffTDO() - Produce a UnifiedDiff file of two files, without both being in a git repo (or even same git repo ; leverages: git diff --no-index --unified=3)
    
    When run without the -pager paramter, outputs a trailing summary of the files, lines count, and added/subtracted lines.
    
    
        LastWriteTime         Lines Length Name
        -------------         ----- ------ ----
        5/12/2026 10:52:17 AM  1072  61942 CreateCloudOnlyUsers_catapult_20221019vers.ps1
        5/28/2026 1:51:40 PM   3044 211778 CreateCloudOnlyUsers_KADRITS.ps1

        Action Count
        ------ -----
        ^\+     2904
        ^-       932

    Wraps underlying commandline:
    git diff --no-index --unified=3 -- $OldFile $NewFile
    
    By default outputs a streamed output to console (for pipeline into variables or postfiltering)
    -pager enables underlying git.exe paged onscreen output
    
    ## Git Pager Navigation Commands

    Command | Action
    --- | --- 
    k or ↑ (Up Arrow) | Move up one line.
    j or ↓ (Down Arrow) |	Move down one line.
    Spacebar or f |	Move forward a full screen/page.
    b |	Move backward a full screen/page.
    d |	Move forward a half screen.
    u |	Move backward a half screen.
    G |	Go to the end of the output.
    g |	Go to the beginning of the output.
    / |	Search for a specific pattern.

    ## Exiting the Pager

    To exit the git diff display and return to your regular command prompt:

      • Press the q key (for "quit"). 
      • If you are on Windows and pressing q alone doesn't work, you may need to press q followed by Enter. 
        
    .PARAMETER Ref
    The first file to compare(generally the earlier rev)[-Ref c:\pathto\file1.ps1]
    .PARAMETER diff
    The second file to compare(generally the later rev)[-Diff c:\pathto\file2.ps1]
    .PARAMETER pager
    switch to enable git default pager output, dumps one screen at a time to console (disabled by default)[-pager]
    .INPUTS
    Does not accept pipeline input.
    .EXAMPLE
    PS> $results = get-UnifiedDiffTDO -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1 
    
            LastWriteTime         Lines Length Name
            -------------         ----- ------ ----
            5/12/2026 10:52:17 AM  1072  61942 CreateCloudOnlyUsers_catapult_20221019vers.ps1
            5/28/2026 1:51:40 PM   3044 211778 CreateCloudOnlyUsers_KADRITS.ps1

            Action Count
            ------ -----
            ^\+     2904
            ^-       932

    PS> write-verbose "filter adds & count " ; 
    PS> $results |?{$_ -match '^\+'} ; 
    
        +++ "b/C:\\sc\\powershell\\MergerScripts\\CreateCloudOnlyUsers_KADRITS.ps1"
        +# C:\usr\work\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1
        +# D:\scripts\TON\CreateCloudOnlyUsers_KADRITS.ps1
        +        
        ...
        
    PS> write-verbose "filter removes" ; 
    PS> $results |?{$_ -match '^\-'} ; 

        --- "a/C:\\sc\\powershell\\MergerScripts\\CreateCloudOnlyUsers_catapult_20221019vers.ps1"
        -∩╗┐# CreateCloudOnlyUsers_catapult_20221019vers.ps1
        -
        -#Requires -Module AzureAD
        -
        ...
        
    PS> @('+','-') | %{ $rgxthis = [regex]"^$([regex]::escape($_))" ; write-host "==$($rgxthis.tostring()) count:`t" -nonewline ; $results | ?{$_ -match $rgxthis} |  measure | select -expand count } ;

        ==^\+ count:    2904
        ==^- count:     932
    
    Demo eval of object status changes over time, without pager paged ouput (to assign stream to variable), with postfiltering for change types and metrics
    .EXAMPLE
    PS> $results = get-UnifiedDiffTDO -Ref C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_catapult_20221019vers.ps1 -Diff C:\sc\powershell\MergerScripts\CreateCloudOnlyUsers_KADRITS.ps1 -pager
    Demo that enables git default pager interface (one page at a time, vs streamed)
    .LINK
    https://github.com/Phil-Factor/PowerShell-Utility-Cmdlets/blob/main/Diff-Objects/Diff-Objects.ps1
    .LINK
    https://github.com/tostka/verb-dev
    #>
    #[CmdletBinding(DefaultParameterSetName="NoExpectation")]
    [CmdletBinding()]
    [Alias('get-UnifiedDiff')]
    PARAM (
        [Parameter(Mandatory = $true,Position = 0,HelpMessage="The first file to compare(generally the earlier rev)[-Ref c:\pathto\file1.ps1]")]
            [ValidateScript({Test-Path $_ -type:leaf})]
            [system.io.fileinfo[]]$Ref,
        [Parameter(Mandatory = $true,Position = 1,HelpMessage="The second file to compare(generally the later rev)[-Diff c:\pathto\file2.ps1]")]
            [ValidateScript({Test-Path $_ -type:leaf})]
            [system.io.fileinfo[]]$Diff,        
        [Parameter(HelpMessage="switch to enable git default pager output, dumps one screen at a time to console (disabled by default)[-pager]")]
            [switch]$pager
    ) ;  
    BEGIN{
        $prpFiles = 'Lastwritetime',
            @{Name='Lines';Expression={gc $_.fullname |  measure | select -expand count }},
            'length','name'   
        if(-not (get-command git.exe -ea 0) -OR -not (get-command git -ea 0)){
            throw "missing required dependancy: git.exe/git!" ; 
            return ; 
        }
    }
    PROCESS {        
        if($Ref.fullname -AND $Diff.FullName){            
            write-verbose "`n$((@($Ref.fullname,$Diff.FullName)| gci |out-string).trim())" ; 
            if($pager){
                #git diff --no-index --unified=3 -- $Ref.fullname $Diff.FullName           
                 git.exe diff --no-index --unified=3 -- "$($Ref.fullname)" "$($Diff.FullName)"
            }else{
                #git diff --no-index --unified=3 -- $Ref.fullname $Diff.FullName --no-pager 
                $result = git.exe --no-pager diff --no-index --unified=3 -- "$($Ref.fullname)" "$($Diff.FullName)" 
            }
        } ; 
    } # PROC-E 
    END{
        if($result){ $result | write-output } ;                  
        write-host -foregroundcolor green "`n$((@($Ref.fullname,$Diff.FullName)| gci | ft -a $prpFiles |out-string).trim())" ;         
        if($result){
            $Summary = @('+','-') | %{
                $rgxthis = [regex]"^$([regex]::escape($_))" ;                
                [pscustomobject]@{
                    Action = "$($rgxthis.tostring())";
                    Count = ($results | ?{$_ -match $rgxthis} |  measure | select -expand count);
                } 
            } ; 
            write-host -foregroundcolor green "`n$(($Summary|out-string).trim())" ;         
        }
    } 
}
#endregion COMPARE_OBJECTSTDO ; #*------^ END get-UnifiedDiffTDO ^------
