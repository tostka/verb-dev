# convert-ISEOpenSession.ps1
# buffer in, from the mybox end, as can't reach SID profile dirs from \\tsclient\c on l7330

#*------v Function convert-ISEOpenSession v------
Function convert-ISEOpenSession {

  <#
    .SYNOPSIS
    convert-ISEOpenSession - Converts remote devbox ISE debugging session (CU\documents\windowspowershell\scripts\ISESavedSession.psXML), and associated Breakpoint files (-ps1-BP.xml) to local use, converting stored paths.
    .NOTES
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2022-07-26
    FileName    : convert-ISEOpenSession.ps1
    License     : MIT License
    Copyright   : (c) 2022 Todd Kadrie
    Tags        : Powershell,FileSystem,Network
    REVISIONS   :
    * 5:02 PM 9/7/2022 fully debugged both push & pull, looks done ; debugged push fully; updated push/pull logic on rfile & lfiles; fixed bug in destfile gen code for push; added END block (largely for tailing bp target);  debugged Pull fully; added exemption for CU/AU/System installed modules/scripts, to avoid improper copy back (should be manually pulled over at the include file level). Need to debug Push.
    * 4:43 PM 8/30/2022 debugged(?)
    * 2:02 PM 8/25/2022 init
    .DESCRIPTION
    convert-ISEOpenSession - Converts remote devbox ISE debugging session (CU\documents\windowspowershell\scripts\ISESavedSession.psXML), and associated Breakpoint files (-ps1-BP.xml) to local use, converting stored paths.
    .PARAMETER FileName
    Filename for ISESadSession.psxml file to be processed (SID CU\docs\winPS\Scripts assumed))[-FileName ISESavedSession.psXML
    .PARAMETER devbox
    Remote dev box computername [-devbox c:\pathto\file]
    .PARAMETER Rfolder
    Remote dev box stock script storage path [-Rfolder c:\pathto\]
    .PARAMETER Lfolder
    Local stock script storage path [-Lfolder c:\pathto\]
    .PARAMETER SID
    Account from Remote devbox, to be copied from[-SID logonid
    .PARAMETER Push
    Switch to Pull content FROM -DevBox[-Push]
    .PARAMETER Pull
    Switch to Push content TO -Devbbox[-Pull]
    .PARAMETER Whatif
    Switch to suppress explicit resolution of share (e.g. wrote conversion wo validation converted share exists on host)[-NoValidate]
    .INPUTS
    Accepts piped input.
    .OUTPUTS
    System.String
    .EXAMPLE
    PS>  convert-ISEOpenSession -pull -verbose ;
    Demo -pull: remote $devbox C:\Users\ACCT\Documents\WindowsPowerShell\Scripts\ISESavedSession.psXML, of files, copy to local machine, along with any matching -ps1-BP.xml files, then post-conversion of the .psxmls and BP.xml files to translating remote $rpath paths to local $lpath paths, with verbose output
    .EXAMPLE
    PS>  convert-ISEOpenSession -push -verbose ;
    Demo -push: from local workstation to remote $devbox, C:\Users\ACCT\Documents\WindowsPowerShell\Scripts\ISESavedSession.psXML of files, copy to $devbox, along with any matching -ps1-BP.xml files, then post-conversion of the .psxmls and BP.xml files to translating local $lpath paths to remote $rpath paths, with verbose output
    .LINK
    https://github.com/tostka/verb-IO\
    #>
    [CmdletBinding()]
    [OutputType([string])]
    #[Alias('')]
    Param(
        [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage = 'Filename for ISESadSession.psxml file to be processed (SID CU\docs\winPS\Scripts assumed))[-FileName ISESavedSession.psXML')]
        [ValidateNotNullOrEmpty()]
        [String]$FileName = 'ISESavedSession.psXML',
        [Parameter(Mandatory=$false,HelpMessage = 'Remote dev box computername [-devbox c:\pathto\file]')]
        [ValidateNotNullOrEmpty()]
        [String]$devbox = $AdminJumpBox,
        [Parameter(Mandatory=$false,HelpMessage = 'Remote dev box stock script storage path [-Rfolder c:\pathto\]')]
        [string]$Rfolder = 'd:\scripts\',
        [Parameter(Mandatory=$false,HelpMessage = 'Local stock script storage path [-Lfolder c:\pathto\]')]
        [string]$Lfolder = 'C:\usr\work\o365\scripts\',
        [Parameter(Mandatory=$false,HelpMessage = 'Account from Remote devbox, to be copied from[-SID logonid')]
        [ValidateNotNullOrEmpty()]
        $SID = $TorMeta.logon_SID.split('\')[1],
        [Parameter(HelpMessage = 'Switch to Pull content FROM -DevBox[-Push]')]
        [switch]$Push,
        [Parameter(HelpMessage = 'Switch to Push content TO -Devbbox[-Pull]')]
        [switch]$Pull,
        [Parameter(HelpMessage = 'Whatif switch[-whatif]')]
        [switch]$whatif
    )
    BEGIN {
        $verbose = ($VerbosePreference -eq "Continue") ; 
        
        if ($PSCmdlet.MyInvocation.ExpectingInput) {
            write-verbose "Data received from pipeline input: '$($InputObject)'" ; 
        } else {
            #write-verbose "Data received from parameter input: '$($InputObject)'" ; 
            write-verbose "(non-pipeline - param - input)" ; 
        } ; 

    } ;  # BEGIN-E
    PROCESS {
        foreach($item in $FileName) {
            
            write-host "Processing:$($item)" ; 
            TRY{
                if($Pull){
                    $srcOpenFile = (gci -path "\\$devbox\c$\users\$($SID)\documents\windowspowershell\scripts\$($item)" -ErrorAction 'STOP').fullname ; 
                    # \\DEVBOX\c$\users\LOGON\documents\windowspowershell\scripts\ISESavedSession.psXML
                    # local equiv, same acct
                    $destOpenFile = (($srcOpenFile.split('\') | select -skip 3) -join '\').replace('$',':') ; 
                } elseif($Push){
                    $srcOpenFile = (gci -path "c:\users\$($SID)\documents\windowspowershell\scripts\$($item)" -ErrorAction 'STOP').fullname ; 
                    $destOpenFile = "\\$($devbox)\$("C:\users\$($SID)\documents\windowspowershell\scripts\ISESavedSession.psXML".replace(':','$'))"; 
                } else { 
                    throw "Neither -Push or -Pull specified!: Please use one or the other!" ; 
                } ; 
                $smsg = "(`$srcOpenFile:$($srcOpenFile)" 
                if(test-path -path $srcOpenFile){$smsg += ":(exists)"}
                else{$smsg += ":(missing)"}; 
                $smsg += "`n`$destOpenFile:$($destOpenFile))" ; 
                if(test-path -path $destOpenFile){$smsg += ":(exists))"} 
                else{$smsg += ":(missing)"}; 
                write-verbose $smsg ; 
                if($srcOpenFile){
                    write-verbose "(confirmed:`$srcOpenFile:$($srcOpenFile))" ; 
                } else { 
                    $smsg = "UNABLE TO LOCATE `$srcOpenFile:$($srcOpenFile)!" ; 
                    write-warning $smsg ; 
                    throw $smsg ; 
                    Break ; 
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #-=-record a STATUSWARN=-=-=-=-=-=-=
                $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
                #-=-=-=-=-=-=-=-=
                $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ; 


            <#
            $pltCI=[ordered]@{ 
                path = (gci $srcOpenFile -ea 'STOP').fullname ;
                destination = $lfolder ;
                erroraction = 'STOP' ;
            } ;         
            write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):copy-item w`n$(($pltCI|out-string).trim())" ;
            copy-item @pltCI -whatif:$($whatif); 
            #>
            # why copy locally, if we can output direct to a variant filename, sourced from remote
            

            if($push){
                $smsg = "Create remote variant:$($destOpenFile)" ;
            }elseif($pull){
                $smsg = "Create local variant:$($destOpenFile)" ;
            } ; 
            write-host $smsg ; 
            write-host "(localize paths)" ; 
            TRY{
                if($Pull){
                    (get-content $srcOpenFile) | Foreach-Object {
                        $_ -replace [Regex]::Escape($rfolder), $lfolder 
                    } | set-content -Encoding UTF8 -path $destOpenFile -whatif:$($whatif); 
                } elseif($Push){
                    (get-content $srcOpenFile) | Foreach-Object {
                        $_ -replace [Regex]::Escape($lfolder), $rfolder
                    } | set-content -Encoding UTF8 -path $destOpenFile -whatif:$($whatif); 
                    
                } ; 
            } CATCH {
                $ErrTrapd=$Error[0] ;
                $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                #-=-record a STATUSWARN=-=-=-=-=-=-=
                $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
                #-=-=-=-=-=-=-=-=
                $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
            } ; 

            write-verbose "Localized `$destOpenFile`n$((gc $destOpenFile|out-string).trim())" ; 
            
            if($pull){
                write-verbose "(processing remote OpenFile)" ; 
                $lfiles = ixml $destOpenFile; 
                $rfiles = ixml $srcOpenFile ; 
                $tOpenfile = $rfiles ; 
            }elseif($push){
                write-verbose "(processing local OpenFile)" ; 
                $lfiles = ixml $srcOpenFile; 
                $rfiles = ixml $destOpenFile ; 
                $tOpenfile = $lfiles ; 
            } ; 

            foreach($xfile in $tOpenfile){
                write-host "==$($xfile):" ; 

                # exempt installed module files & scripts (don't want to copy those back, they should be manually copied over and spliced into source module code)
                if($xfile -match $rgxPSAllUsersScope){
                    write-host "exempting AllUsersScope-installed file!:`n$($xfile)" ; 
                    break ; 
                }elseif($xfile -match $rgxModsSystemScope){
                    write-host "exempting SystemScope-installed file!:`n$($xfile)" ; 
                    break ; 
                }elseif($xfile -match $rgxPSCurrUserScope){
                    write-host "exempting CurrentUserScope-installed file!:`n$($xfile)" ; 
                    break ; 
                } else {
                    write-verbose "(file confirmed non-installed content)" ; 
                } ; 
                $pltCI=[ordered]@{ 
                    path = $null 
                    destination = $null ;
                    erroraction = 'STOP' ;
                    whatif = $($whatif) ;
                } ;     
                
                TRY{
                    
                    if($Pull){
                        $pltCI.path = (gci "\\$($devbox)\$($xfile.replace(':','$'))" -ErrorAction 'STOP').fullname ; 
                        #$pltCI.destination = $lfolder ; 
                        # use full path dest, provides something to copy for follow on commands
                        $pltCI.destination = (join-path -path $lfolder -childpath (split-path $xfile -leaf) ) ; 
                    } elseif($Push){
                        $pltCI.path = (gci -path $xfile -ErrorAction 'STOP').fullname
                        # full path dest:
                        $pltCI.destination = join-path -path "\\$($devbox)\$($rfolder.replace(':','$'))" -childpath (split-path $xfile -leaf) ; 
                    } else { 
                        throw "Neither -Push or -Pull specified!: Please use one or the other!" ; 
                    } ; 
                    if($pltCI.path){
                        write-verbose "(confirmed:`$pltCI.path:$($pltCI.path))" ; 
                        
                    } else { 
                        $smsg = "UNABLE TO LOCATE `$pltCI.path:$($pltCI.path)!" ; 
                        write-warning $smsg ; 
                        throw $smsg ; 
                        Break ; 
                    } ; 

                    if($pltCI.path -AND $pltCI.destination){
                         
                        write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):copy-item w`n$(($pltCI|out-string).trim())" ; 
                        copy-item @pltCI ; 

                        write-host "(checking for matching -ps1-BP.xml file...)" ;         
                        
                        if($Pull){
                            $srcBPFile  = (gci "\\$($devbox)\$($xfile.replace(':','$').replace('.ps1','-ps1-BP.xml'))").fullname ; 
                            # local equiv, same acct
                            if($srcBPFile) {
                                
                                $destBPFile = (join-path -path $lfolder -child (split-path $srcBPFile -leaf) ) 
                                write-host "(localize BP file paths)" ; 
                                (get-content -path $srcBPFile) | Foreach-Object {
                                    $_ -replace [Regex]::Escape($rfolder), $lfolder 
                                } | set-content -Encoding UTF8 -path $destBPFile -whatif:$($whatif) ; 
                                
                            } ; 
                                
                        } elseif($Push){
                            $srcBPFile  = (gci $xfile.replace('.ps1','-ps1-BP.xml') ).fullname ; 
                            if($srcBPFile) {
                                
                                $destBPFile = join-path -path (join-path -path "\\$($devbox)\" -childpath $rfolder.replace(':','$')) -childpath (split-path $srcBPFile -leaf) ; 
                                write-host "(localize BP file paths)" ; 
                                (get-content -path $srcBPFile) | Foreach-Object {
                                    $_ -replace [Regex]::Escape($lfolder), $rfolder
                                } | set-content -Encoding UTF8 -path $destBPFile -whatif:$($whatif); 
                                
                            } ; 
                        }
                        
                        if($srcBPFile -AND -not($whatif)) {
                            write-verbose "Localized `$destBPFile`n$((gc $destBPFile|out-string).trim())" ; 
                        }elseif($whatif){
                            # drop through
                        }else {
                            write-host -ForegroundColor yellow "(Unable to locatea matching BP file:`n$("\\$($devbox)\$($xfile.replace(':','$').replace('.ps1','-ps1-BP.xml'))"))" ; 
                        } ; 
                    } else { 
                        write-warning "Unable to locate:$("\\$($devbox)\$($xfile.replace(':','$'))")!" ; 
                    } ; 
                } CATCH {
                    $ErrTrapd=$Error[0] ;
                    $smsg = "$('*'*5)`nFailed processing $($ErrTrapd.Exception.ItemName). `nError Message: $($ErrTrapd.Exception.Message)`nError Details: `n$(($ErrTrapd|out-string).trim())`n$('-'*5)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level WARN } #Error|Warn|Debug 
                    else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    #-=-record a STATUSWARN=-=-=-=-=-=-=
                    $statusdelta = ";WARN"; # CHANGE|INCOMPLETE|ERROR|WARN|FAIL ;
                    if(gv passstatus -scope Script -ea 0){$script:PassStatus += $statusdelta } ;
                    if(gv -Name PassStatus_$($tenorg) -scope Script -ea 0){set-Variable -Name PassStatus_$($tenorg) -scope Script -Value ((get-Variable -Name PassStatus_$($tenorg)).value + $statusdelta)} ; 
                    #-=-=-=-=-=-=-=-=
                    $smsg = "FULL ERROR TRAPPED (EXPLICIT CATCH BLOCK WOULD LOOK LIKE): } catch[$($ErrTrapd.Exception.GetType().FullName)]{" ; 
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level ERROR } #Error|Warn|Debug 
                    else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ;
                    Break #Opts: STOP(debug)|EXIT(close)|CONTINUE(move on in loop cycle)|BREAK(exit loop iteration)|THROW $_/'CustomMsg'(end script with Err output)
                } ; 

            } ;  # loop-E


        } ;  # loop-E
    } ;  # PROC-E
    END{
        write-host "Pass completed" ; 
    } ; 
} ; 
#*------^ END Function convert-ISEOpenSession ^------ ;
