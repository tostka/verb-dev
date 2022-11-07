#*------v Function check-PsLocalRepoRegistration v------
function check-PsLocalRepoRegistration {
    <#
    .SYNOPSIS
    check-PsLocalRepoRegistration - Check for PSRepository for $localPSRepo, register if missing
    .NOTES
    Version     : 1.0.0
    Author: Todd Kadrie
    Website:	http://toddomation.com
    Twitter:	http://twitter.com/tostka
    CreatedDate : 2020-03-29
    FileName    : check-PsLocalRepoRegistration
    License     : MIT License
    Copyright   : (c) 2020 Todd Kadrie
    Github      : https://github.com/tostka
    Tags        : Powershell,Git,Repository
    REVISIONS
    * 7:00 PM 3/29/2020 init
    .DESCRIPTION
    check-PsLocalRepoRegistration - Check for PSRepository for $localPSRepo, register if missing
    .PARAMETER  User
    User security principal (defaults to current user)[-User `$SecPrinobj]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    $bRet = check-PsLocalRepoRegistration -Repository $localPSRepo 
    Check registration on the repo defined by variable $localPSRepo
    .LINK
    #>
    [CmdletBinding()]
    PARAM(
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,HelpMessage="Local Repository [-Repository repoName]")]
        $Repository = $localPSRepo,
        [Parameter(HelpMessage="Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage="Whatif Flag  [-whatIf]")]
        [switch] $whatIf=$true
    ) ; 
    $verbose = ($VerbosePreference -eq 'Continue') ; 
    # on cold installs there *is* no repo, precheck
    if($Repository){
        if(!(Get-PSRepository -Name $Repository -ea 0)){
            $repo = @{
                Name = 'lyncRepo' ;
                SourceLocation = $null;
                PublishLocation = $null;
                InstallationPolicy = 'Trusted' ;
            } ;
            if($Repository = 'lyncRepo'){
                $RepoPath = "\\lynmsv10\lync_fs\scripts\sc" ;
                $repo.Name = 'lyncRepo' ; 
                $repo.SourceLocation = $RepoPath ; 
                $repo.PublishLocation = $RepoPath ;
            } elseif($Repository = "tinRepo") {
                #Name = 'tinRepo', Location = '\\SYNNAS\archs\archs\sc'; IsTrusted = 'True'; IsRegistered = 'True'.
                $RepoPath = '\\SYNNAS\archs\archs\sc' ;
                $repo.Name = 'tinRepo' ; 
                $repo.SourceLocation = $RepoPath ; 
                $repo.PublishLocation = $RepoPath ;
            } else { 
                $smsg = "UNRECOGNIZED `$Repository" ; 
                if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warning } #Error|Warn|Debug 
                else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            }; 
            $smsg = "MISSING REPO REGISTRATION!`nRegister-PSRepository w`n$(($repo|out-string).trim())" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            if(!$whatif){
                $bReturn = Register-PSRepository @repo ;
                $bReturn | write-output ;             
            } else { 
                $smsg = "(whatif detected: skipping execution - Register-PSRepository lacks -whatif support)" ; 
                if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
                else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; 
            }
        } else {
            $smsg = "($Repository repository is already registered in this profile)" ; 
            if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } #Error|Warn|Debug 
            else{ write-host -foregroundcolor green "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
            $true | write-output ;              
        } ;  
    } else {
        $smsg = "MISSING REPO REGISTRATION!`nNO RECOGNIZED `$Repository DEFINED!" ; 
        if($verbose){ if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level warning } #Error|Warn|Debug 
        else{ write-warning "$((get-date).ToString('HH:mm:ss')):$($smsg)" } ; } ; 
    }; 
} #*------^ END Function check-PsLocalRepoRegistration ^------
