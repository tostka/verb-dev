function export-CommentBasedHelpToFileTDO{
    <#
    .SYNOPSIS
    export-CommentBasedHelpToFileTDO - Exports comment-based help for a specified command to a text file.
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-01-16
    FileName    : export-CommentBasedHelpToFileTDO.ps1
    License     : MIT License
    Copyright   : (c) 2024 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,Help,CommentBasedHelp,CBH,Documentation
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS
    * 2:44 PM 1/16/2025 init
    .DESCRIPTION
    export-CommentBasedHelpToFileTDO - This function retrieves the full help content for a specified command and exports it to a text file. If the help content is populated, it saves the content to a file (named [cmdlet.name].help.txt) and opens it in a text editor if available.
    .PARAMETER Command
    The name of the command for which to export the help content.
    .PARAMETER Destination
    Destination path for output xxx.help.txt file [-path c:\path-to\]"
    .INPUTS
    None. The function accepts pipeline input.
    .OUTPUTS
    None. The function writes the help content to a file.
    .EXAMPLE
    PS> export-CommentBasedHelpToFileTDO -Command "Get-Process"
    .EXAMPLE
$tmod = 'verb-dev' ; 
if($modroot = (join-path -path $GIT_REPOSROOT -child $tmod)){
    if(-not (test-path "$modroot\Help")){ mkdir "$modroot\Help" -verbose } ;
    $hlpRoot = (Resolve-Path -Path "$modroot\Help" -ea STOP).path ; 
    gcm -mod verb-dev | select -expand name | select -first 1 | export-CommentBasedHelpToFileTDO -destination $hlpRoot -verbose ;
} ; 
    PS> 
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('epCBH','export-CBH')]
    PARAM(
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="CommandName [-Command 'resolve-user']")]
            [string]$Command,
        [Parameter(Mandatory = $true,Position = 0,ValueFromPipeline = $True, HelpMessage = "Destination path for output xxx.help.txt file [-path c:\path-to\]")]
            [Alias('PsPath')]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            [System.IO.DirectoryInfo[]]$Destination,
        [Parameter(HelpMessage="switch to suppress post-open in Editor[-noReview]")]
            [switch]$noReview            
        [Parameter(HelpMessage="Minimum Length threshold (to recognize populated CBH)(defaults 200)[-LengthThreshold 1000]")]
            [int]$LengthThreshold=200
    );
    BEGIN {
      [string[]]$Aggrfails = @() ; 
    }
    PROCESS{
        foreach($item in $command){
            TRY{
                write-verbose "get-command ($item)" ; 
                $gcmd = get-command $item -ErrorAction STOP ;
                $ofhelp = (join-path -path $Destination -childpath "$($gcmd.name).help.txt" -ErrorAction STOP) ;
                write-verbose "resolved output file:$($ofhelp)" ; 
                write-verbose "get-help ($gcmd.name) -full" ; 
                $hlp = get-help $gcmd.name -full -ErrorAction STOP ; 
                $hlpChars = (($hlp | out-string).ToCharArray() |  measure).count ; 
                write-verbose "`$hlpChars: $($hlpChars)" ; 
                #if($hlp.length -gt $LengthThreshold){
                #if( (($hlp | out-string).ToCharArray() |  measure).count -gt $LengthThreshold){
                if($hlpChars -gt $LengthThreshold){
                    write-host "Out-File -FilePath ($ofhelp)" ; 
                    $hlp| Out-File -FilePath $ofhelp -verbose ; 
                } else { 
                    $smsg =  "get-help $($gcmd.name) -full returned an tiny output`n$(($hlp|out-string).trim())" ; 
                    write-warning $smsg ;
                    $failsumm = 
                    $Aggrfails += [pscustomobject]@{
                        name = $item ; 
                        chars = $hlpChars ; 
                    } ; 
                    throw $smsg ; 
                } ; 
                if( -not $noReview){
                    write-host "(Opening output in editor)" ; 
                    if(get-command notepad2.exe){notepad2 $ofhelp ; }
                    elseif(get-command notepad.exe){notepad $ofhelp ; }
                    elseif(get-command vim){vim $ofhelp ; }
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "`n$(($ErrTrapd | fl * -Force|out-string).trim())" ;
                write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" ;
                Continue ; 
            } ; 
        } ; 
    } ; 
    END{
        if(($Aggrfails|  measure).count){
            $Aggrfails | write-output ; 
        } ; 
    }
} ; 