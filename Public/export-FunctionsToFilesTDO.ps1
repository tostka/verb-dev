# export-FunctionsToFilesTDO.ps1

#region EXPORT_FUNCTIONSTOFILESTDO ; #*------v export-FunctionsToFilesTDO v------
function export-FunctionsToFilesTDO {
    <#
    .SYNOPSIS
    export-FunctionsToFilesTDO - Parse out all functions from the specified -Path (via AST Parser), and output each to _func.ps1 files in specified destination dir
    .NOTES
    Version     : 0.0.1
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2025-10-07
    FileName    : export-FunctionsToFilesTDO.ps1
    License     : MIT License
    Copyright   : (c) 2025 Todd Kadrie
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,development,function,export
    AddedCredit : REFERENCE
    AddedWebsite: URL
    AddedTwitter: URL
    REVISIONS   :
    * 10:48 AM 10/7/2025 port from get-FunctionBlocks(), works, add to vdev
    * 2:53 PM 5/18/2022 $parsefile -> $path, strong typed
    # 5:55 PM 3/15/2020 fix corrupt ABC typo
    # 10:21 AM 9/27/2019 just pull the functions in a file and pipeline them, nothing more.
    .DESCRIPTION
    export-FunctionsToFilesTDO - Parse out all functions from the specified -Path (via AST Parser), and output each to _func.ps1 files in specified destination dir
    .PARAMETER  Path
    Script/Module file(s) to be parsed [path-to\script.ps1]
    .PARAMETER  Destination
    Directory into which new [functionname]_func.ps1 files should be written[-Destination path-to\]
    .PARAMETER  NoFunc
    Switch to output exported functions without standard _func.ps1 suffix.[-NoFunc]
    .PARAMETER Include
    String Array of function names to be included in export - the only functions found, that will be exported - from specified Path file.[-Include @('func1','func2')]
    .PARAMETER Exclude
    String Array of function names to be excluded from export, in specified Path file (defaults to '2b4','2b4c','fb4').[-Exclude @('2b4','2b4c','fb4')]
    .PARAMETER IncludeInternalFunctions
    Switch to override default behavior - skip internal functions (as indicated by underscore prefix in function naame) - and instead export internal functions BOTH as part of their parent function, and as a separate function file[-IncludeInternalFunctions)]
    .PARAMETER whatIf
    Whatif Flag  [-whatIf]
    .INPUTS
    system.io.fileinfo[] Accepts piped input for Path variable Array
    .OUTPUTS
    System.String outputs count summary to pipeline
    .EXAMPLE
    PS> $results = export-FunctionsToFilesTDO -Path C:\sc\powershell\PSScripts\build\xopBuildLibrary.psm1 -Destination "C:\sc\powershell\PSScripts\build\epFuncs" -verbose  ;
    Parse and export all items in the specified file, to the destination directory
    .LINK
    https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('export-FunctionsToFiles')]
    PARAM(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Script/Module file(s) to be parsed [path-to\script.ps1]")]
            [ValidateNotNullOrEmpty()]
            [Alias('ParseFile')]
            [system.io.fileinfo[]]$Path,
        [Parameter(Position = 1, Mandatory = $True, HelpMessage = "Directory into which new [functionname]_func.ps1 files should be written[-Destination path-to\]")]
            [ValidateNotNullOrEmpty()]
            [System.IO.DirectoryInfo]$Destination,
        [Parameter(HelpMessage = "Switch to output exported functions without standard _func.ps1 suffix.[-NoFunc]")]
            [switch]$NoFunc,
        [Parameter(HelpMessage = "String Array of function names to be included in export - the only functions found, that will be exported - from specified Path file.[-Include @('func1','func2')]")]
            [string[]]$Include,
        [Parameter(HelpMessage = "String Array of function names to be excluded from export, in specified Path file (defaults to '2b4','2b4c','fb4').[-Exclude @('2b4','2b4c','fb4')]")]
            [string[]]$Exclude = @('2b4','2b4c','fb4'),
        [Parameter(HelpMessage = "Switch to override default behavior - skip internal functions (as indicated by underscore prefix in function naame) - and instead export internal functions BOTH as part of their parent function, and as a separate function file[-IncludeInternalFunctions)]")]
            [string[]]$IncludeInternalFunctions,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
            [switch] $whatIf
    )  ;
    BEGIN{
        $sw = [Diagnostics.Stopwatch]::StartNew();
        $prcd = 0 ; 
    } # BEG-E
    PROCESS{
        foreach($item in $Path){
            $smsg = "(running AST parse on $($item.fullname)...)" ; 
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
            #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
            $AST = [System.Management.Automation.Language.Parser]::ParseFile($item.fullname, [ref]$null, [ref]$Null ) ;
            $smsg = "(parsing Functions from AST...)" ; 
            if($VerbosePreference -eq "Continue"){if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level VERBOSE } 
            else{ write-verbose "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $funcsInFile = $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
            # this variant pulls commands v functions
            #$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)
            <# available properties/methods of parsed return
                $funcs[5] | gm
                   TypeName: System.Management.Automation.Language.FunctionDefinitionAst
                Name           MemberType Definition
                ----           ---------- ----------
                Copy           Method     System.Management.Automation.Language.Ast Copy()
                Equals         Method     bool Equals(System.Object obj)
                Find           Method     System.Management.Automation.Language.Ast Find(System.Func[System.Management.Automation.Language.Ast,bool] ...
                FindAll        Method     System.Collections.Generic.IEnumerable[System.Management.Automation.Language.Ast] FindAll(System.Func[Syste...
                GetHashCode    Method     int GetHashCode()
                GetHelpContent Method     System.Management.Automation.Language.CommentHelpInfo GetHelpContent(System.Collections.Generic.Dictionary[...
                GetType        Method     type GetType()
                SafeGetValue   Method     System.Object SafeGetValue()
                ToString       Method     string ToString()
                Visit          Method     System.Object Visit(System.Management.Automation.Language.ICustomAstVisitor astVisitor), void Visit(System....
                Body           Property   System.Management.Automation.Language.ScriptBlockAst Body {get;}
                Extent         Property   System.Management.Automation.Language.IScriptExtent Extent {get;}
                IsFilter       Property   bool IsFilter {get;}
                IsWorkflow     Property   bool IsWorkflow {get;}
                Name           Property   string Name {get;}
                Parameters     Property   System.Collections.ObjectModel.ReadOnlyCollection[System.Management.Automation.Language.ParameterAst] Param...
                Parent         Property   System.Management.Automation.Language.Ast Parent {get;}
            #>
            $ttl = $funcsInFile |  measure | select -expand count ;             
            foreach ($func in $funcsInFile) {
                $prcd++ ; 
                #$func | write-output ;
                $smsg = $sBnrS="`n#*------v PROCESSING ($($prcd)/$($ttl)): $($func.name) : v------" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level H2 } else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                if(-NOT $IncludeInternalFunctions -AND ($func.name -match '^_')){
                    $smsg = "Function name - $($func.name) - prefixed by _ (underscore) -> traditionally marks an INTERNAL function" ; 
                    $smsg += "`n-IncludeInternalFunctions *not* in use -> Skipping internal function export" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    Continue ; 
                } ; 
                if($Exclude -contains $func.name){
                    $smsg = "(skipping -Exclude:$($func.name))" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    Continue ; 
                } ; 
                if(-NOT $Include -OR ($Include -AND ($Include -contains $func.name))){
                    if($Include){
                        $smsg = "(-Include:$($func.name))" ; 
                        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                        else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    } ; 
                
                    if($NoFunc){
                        $ofilename = join-path -path $Destination -ChildPath "$($func.name).ps1" ; 
                    }else{
                        $ofilename = join-path -path $Destination -ChildPath "$($func.name)_func.ps1" ; 
                    }; 
                    $pltSCFE=[ordered]@{PassThru=$true ;Verbose=$($verbose) ;whatif= $($whatif) ; } 
                    #$bRet = Set-ContentFixEncoding -Value $updatedContent -Path $PsmNameTmp @pltSCFE ; 
                    # we're getting 4 writes in set-cfe, for each block added to updatedcontent, lets try |out-string before passing, to see if they fold into one write
                    $outContent = @() ; 
                    $outContent += @("# $($func.name).ps1")
                    $outContent += @("`n")
                    $outContent += @("#region $($func.name.toUpper() -replace '-', '_') ; #*------v $($func.name) v------")
                    $outContent += @($func.extent.text) ; 
                    $outContent += @("#endregion $($func.name.toUpper() -replace '-', '_') ; #*------^ END $($func.name) ^------")        
                    #$bRet = Set-ContentFixEncoding -Value ($func.extent.text| out-string) -Path $PsmNameTmp @pltSCFE ; 
                    $bRet = Set-ContentFixEncoding -Value ($outContent| out-string) -Path $ofilename @pltSCFE ; 
                    if(-not $bRet -AND -not $whatif){throw "Set-ContentFixEncoding $($ofilename)!" } else {
                        $PassStatus += ";UPDATED:Set-ContentFixEncoding ";
                    }  ;
                } else { 
                   $smsg = "(skipping -non-Include:$($func.name))" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
                    else{ write-host -foregroundcolor gray "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
                    Continue ;  
                } ; 
                $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            } ;
        } ;  # loop-E $item
    } ;  # PROC-E
    END{
        $sw.Stop() ;
        write-verbose ("Elapsed Time: {0:dd}d {0:hh}h {0:mm}m {0:ss}s {0:fff}ms" -f $sw.Elapsed) ; 
        $smsg = "$($prcd) functions exported to $($destination)" 
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } 
        else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
        #Levels:Error|Warn|Info|H1|H2|H3|H4|H5|Debug|Verbose|Prompt|Success
        $smsg | write-output ; 
    } ; 
} ; 
#endregion EXPORT_FUNCTIONSTOFILESTDO ; #*------^ END export-FunctionsToFilesTDO ^------
