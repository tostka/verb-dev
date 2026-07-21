# get-FileVerbNounCmdletSummaries.ps1

#region GET_FILEVERBNOUNCMDLETSUMMARIES ; #*------v get-FileVerbNounCmdletSummaries v------
#if(-not (get-childitem function:get-CodeProfileAST -ea 0)){
    function get-FileVerbNounCmdletSummaries {
        <#
        .SYNOPSIS
        get-FileVerbNounCmdletSummaries - Leverages verb-dev\get-CodeProfileAST (and underlying [System.Management.Automation.Language.Parser]) to Parse out 'GenericCommands'; isolate those in verb-noun name format; gcm the information and source/Module for each; and echo the summary to the pipeline. 
        .NOTES
        Author: Todd Kadrie
        Based on Code by: Philip Giuliani (broken example), functional AST code & example by Bartek Bielawski
        Website:	http://tinstoys.blogspot.com
        Twitter:	http://twitter.com/tostka
        REVISIONS   :
        * 8:51 AM 7/21/2026 init
        .DESCRIPTION
        get-FileVerbNounCmdletSummaries - Leverages verb-dev\get-CodeProfileAST (and underlying [System.Management.Automation.Language.Parser]) to Parse out 'GenericCommands'; isolate those in verb-noun name format; gcm the information and source/Module for each; and echo the summary to the pipeline. 
        .PARAMETER  ParseFile
        Powershell file to be parsed [path-to\script.ps1
        .INPUTS
        Accepts piped input.
        .OUTPUTS
        PsCustomobject summary of matched GenericCommands with verb-noun names, to pipeline.
        .EXAMPLE
        $CmdletsVerbNoun = get-FileVerbNounCmdletSummaries C:\usr\work\exch\scripts\Set-Empl-Offboard-20160601-1217PM.ps1 ;
        Pull ALL VerbNoun-named GenericCommands and store in a variable for further processing.
        .LINK
        https://stackoverflow.com/questions/22335439/get-the-last-line-of-a-specific-function-in-a-ps1-file (returns 440 to the pipeline)
        https://blogs.technet.microsoft.com/heyscriptingguy/2012/09/26/learn-how-it-pros-can-use-the-powershell-ast/
        #>
        [CmdletBinding()]
        #[Alias('show-TrayTip')]
        Param(
            [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, HelpMessage = "Powershell file to be parsed [path-to\script.ps1]")][ValidateNotNullOrEmpty()]
                [Alias('ParseFile')]
                [system.io.fileinfo]$Path
        )  ;
        BEGIN{
            $rgxverbNounNames = "\b\w+\-\w+\b" ;
            if(get-command -name get-CodeProfileAST){}else{
                $smsg = "missing dependant verb-dev\get-CodeProfileAST()!" ; 
                write-warning $smsg ; 
                throw $smsg ; 
                return ; 
            } ; 
        } ; 
        PROCESS{
            $sw = [Diagnostics.Stopwatch]::StartNew();
            write-verbose "$((get-date).ToString('HH:mm:ss')):(running AST parse...)" ; 
            if($GCmds = (get-CodeProfileAST -File $Path.fullname -GenericCommands).GenericCommands){            
                # match extents with verb-noun substrings
                $CmdletNames = @() ;
                ($GCmds|where-object{$_.extent -match $rgxverbNounNames}) | foreach-object{
                  $isolatedlines = $_ ;
                  # isolate the actual verb-noun substrings
                  $CmdletNames += $isolatedlines.extent.text | foreach-object{if($_ -match $rgxverbNounNames){ $matches[0]}}
                } ;
                # unique the list
                #$CmdletNames = $CmdletNames | select -unique | sort ; # isn't unbiqueing for some reason (passes dupes), use group
                $CmdletNames = $CmdletNames | group | select -expand  name | sort ;
                # resolve each to a source (and properly case the name), or default source to 'unresolved' if fails gcm (note function [Alias()] names in use will come back with $null source: they gcm, but there's no source to return)
                $ResolvedCmds = $CmdletNames | foreach-object{
                    $thiscmd = $_ ;
                    $hsCmdSummary = [ordered]@{'name'=$null;'source'=$null;'verb'=$null;'noun'=$null; CommandType=$null} ;
                    if($rvGcm = gcm $thiscmd  -ea 0){
                        $hsCmdSummary.name = $rvGcm.name ; $hsCmdSummary.source = $rvGcm.source ;;
                        $hsCmdSummary.verb = $rvGcm.verb ; $hsCmdSummary.noun = $rvGcm.noun ; $hsCmdSummary.CommandType=$rvGcm.CommandType ;
                    }else {
                        # fake it from what we know
                        $hsCmdSummary.name = $thiscmd  ; $hsCmdSummary.source = 'UNRESOLVED' ;
                        $hsCmdSummary.verb,$hsCmdSummary.noun = $thiscmd.split('-');
                        $hsCmdSummary.CommandType="UNRESOLVED" ;
                    };
                    [pscustomobject]$hsCmdSummary ;
                } | sort source,name ;
                $ResolvedCmds | write-output  ; 
            }else{
                $smsg = "AST Parser failed to parse and return any GenericCommands from the specified file" ; 
                $smsg += "`n$($Path.fullname)" ;
            }
            $sw.Stop() ;
            write-verbose ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
        } ;     
    } ; 
#} ; 
#endregion GET_FILEVERBNOUNCMDLETSUMMARIES ; #*------^ END get-FileVerbNounCmdletSummaries ^------