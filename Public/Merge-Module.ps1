#*------v Function Merge-Module v------
function Merge-Module {

    <#
    .SYNOPSIS
    Merge-Module.ps1 - Merge function .ps1 files into a monolisthic module.psm1 module file
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : https://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2019-12-10
    FileName    : Merge-Module.ps1
    License     : MIT License
    Copyright   : (c) 2019 Todd Kadrie
    Github      : https://github.com/tostka
    AddedCredit : Przemyslaw Klys
    AddedWebsite: https://evotec.xyz/powershell-single-psm1-file-versus-multi-file-modules/
    AddedTwitter:
    REVISIONS
    *8:50 PM 12/18/2019 sorted hard-coded verb-aad typo 
    2:54 PM 12/11/2019 rewrote, added backup of psm1, parsing out the stock dyn-include code from the orig psm1, leverages fault-tolerant set-fileContent(), switched sourcepaths to array type, and looped, detecting public/internal by path and prepping for the export list.
    * 2018/11/06 Przemyslaw Klys posted version
    .DESCRIPTION
    .PARAMETER  ModuleName
    Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]
    .PARAMETER  ModuleSourcePaths
    Directory containing .ps1 function files to be combined [-ModuleSourcePaths c:\path-to\module\Public]
    .PARAMETER ModuleDestinationPath
    Final monolithic module .psm1 file name to be populated [-ModuleDestinationPath c:\path-to\module\module.psm1]
    .PARAMETER ShowDebug
    Parameter to display Debugging messages [-ShowDebug switch]
    .PARAMETER Whatif
    Parameter to run a Test no-change pass [-Whatif switch]
    .EXAMPLE
    .\merge-Module.ps1 -ModuleName verb-AAD -ModuleSourcePaths C:\sc\verb-AAD\Public -ModuleDestinationPath C:\sc\verb-AAD\verb-AAD -showdebug -whatif ;
    .LINK
    https://www.toddomation.com
    #>
    param (
        [Parameter(Mandatory = $True, HelpMessage = "Module Name (used to name the ModuleName.psm1 file)[-ModuleName verb-XXX]")]
        [string] $ModuleName,
        [Parameter(Mandatory = $True, HelpMessage = "Array of directory paths containing .ps1 function files to be combined [-ModuleSourcePaths c:\path-to\module\Public]")]
        [array] $ModuleSourcePaths,
        [Parameter(Mandatory = $True, HelpMessage = "Directory path in which the final .psm1 file should be constructed [-ModuleDestinationPath c:\path-to\module\module.psm1]")]
        [string] $ModuleDestinationPath,
        [Parameter(HelpMessage = "Debugging Flag [-showDebug]")]
        [switch] $showDebug,
        [Parameter(HelpMessage = "Whatif Flag  [-whatIf]")]
        [switch] $whatIf
    ) ;


    if ($ModuleDestinationPath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
        $ModuleDestinationPath = get-item -path $ModuleDestinationPath ;
    } ;

    $ttl = ($ModuleSourcePaths | measure).count ;
    $iProcd = 0 ;

    $ExportFunctions = @() ;
    $PrivateFunctions = @() ;

    $PsmName="$ModuleDestinationPath\$ModuleName.psm1" ;

    # backup existing & purge the dyn-include block
    if(test-path -path $PsmName){
        $rawSourceLines = get-content $PsmName  ;
        $SrcLineTtl = ($rawSourceLines | Measure-Object).count ;
        $bRet = backup-File -path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$bRet) {throw "FAILURE" } ;

        # this script *appends* to the existing .psm1 file.
        # which by default includes a dynamic include block:
        <#
        #Get public and private function definition files.
        $functionFolders = @('Public', 'Internal', 'Classes') ;
        ForEach ($folder in $functionFolders) {
            $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder ;
            If (Test-Path -Path $folderPath) {
                Write-Verbose -Message "Importing from $folder" ;
                $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'  ;
                ForEach ($function in $functions) {
                    Write-Verbose -Message "  Importing $($function.BaseName)" ;
                    . $($function.FullName) ;
                } ;
            } ;
        } ;
        $publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\Public" -Filter '*.ps1').BaseName ;
        Export-ModuleMember -Function $publicFunctions ;
        #>
        # detect and drop out the above, for the monolithic version
        $rgxPurgeblockStart = '#Get\spublic\sand\sprivate\sfunction\sdefinition\sfiles\.' ;
        $rgxPurgeBlockEnd = 'Export-ModuleMember\s-Function\s\$publicFunctions\s;';
        $dynIncludeOpen = (ss -Path  $PsmName -Pattern $rgxPurgeblockStart).linenumber ;
        $dynIncludeClose = (ss -Path  $PsmName -Pattern $rgxPurgeBlockEnd).linenumber ;
        if(!$dynIncludeOpen){$dynIncludeClose = 0 } ;
        $updatedContent = @() ; $DropContent=@() ;
        $updatedContent = $rawSourceLines[0..($dynIncludeOpen-2)] ;
        $updatedContent += $rawSourceLines[($dynIncludeClose)..$Srclinettl] ;
        $DropContent = $rawsourcelines[$dynIncludeOpen..$dynIncludeClose] ;
        if($showdebug){
            $smsg= "`$DropContent:`n$($DropContent|out-string)" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug } ; #Error|Warn|Debug
        } ;
        $bRet = Set-FileContent -Text $updatedContent -Path $PsmName -showdebug:$($showdebug) -whatif:$($whatif) ;
        if (!$bRet) {throw "FAILURE" } ;
    } ;

    foreach ($ModuleSourcePath in $ModuleSourcePaths) {

        $iProcd++ ;

        if ($ModuleSourcePath.GetType().FullName -ne 'System.IO.DirectoryInfo') {
            $ModuleSourcePath = get-item -path $ModuleSourcePath ;
        } ;
        $sBnrS = "`n#*------v ($($iProcd)/$($ttl)):$($ModuleSourcePath) v------" ;
        $smsg = "$($sBnrS)" ;
        if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug **
        $error.clear() ;
        TRY {


            [array]$ComponentScripts = Get-ChildItem -Path $ModuleSourcePath\*.ps1 -Recurse -ErrorAction SilentlyContinue   ;
            [array]$ComponentModules = Get-ChildItem -Path $ModuleSourcePath\*.psm1 -Recurse -ErrorAction SilentlyContinue  ;

            $pltAdd = @{
                Path=$PsmName ;
                whatif=$whatif;
            } ;
            foreach ($ScriptFile in $ComponentScripts) {
                $ParsedContent = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$null) ;
                # above is literally the entire AST, unfiltered. Should be ALL parsed entities.
                #$Functions = $ParsedContent.EndBlock.Extent.Text  ;
                #$Functions | Add-Content @pltAdd ;
                $ParsedContent.EndBlock.Extent.Text | Add-Content @pltAdd ;

                # public & functions = public ; private & internal = private
                if($ModuleSourcePath -match '(Public|Functions)'){
                    $AST = [System.Management.Automation.Language.Parser]::ParseFile($ScriptFile, [ref]$null, [ref]$Null ) ; 
                    $ASTFunctions =  $AST.FindAll( { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) ;
                    $ExportFunctions += $ASTFunctions.name ;
                } elseif($ModuleSourcePath -match '(Private|Internal)'){
                    $smsg= "PRIV FUNC:`n$(($ASTFunctions) -join ',' |out-string)" ;
                    if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Debug } ; #Error|Warn|Debug
                } ;
            } ; # loop-E

            foreach ($ModFile in $ComponentModules) {
                $Content = Get-Content $ModFile ;
                $Content | Add-Content @pltAdd ;
            } ;
            # append the Export-ModuleMember -Function $publicFunctions  ? 
            #"Export-ModuleMember -Function $(($ExportFunctions) -join ',')" | Add-Content @pltAdd ;

            $smsg = "$($sBnrS.replace('-v','-^').replace('v-','^-'))" ;
            if ($logging) { Write-Log -LogContent $smsg -Path $logfile -useHost -Level Info } ; #Error|Warn|Debug

            # this is copying the manifest (assumes public & psd1 are in same dir) - Plaster is doing that separately, not needed
            #Copy-Item -Path "$ModuleSourcePath\$ModuleName.psd1" "$ModuleDestinationPath\$ModuleName.psd1" ;

            $true | write-output ;

        } CATCH {
            Write-Error "$(get-date -format 'HH:mm:ss'): Failed processing $($_.Exception.ItemName). `nError Message: $($_.Exception.Message)`nError Details: $($_)" ;
            $false | write-output ;
            #Exit #STOP(debug)|EXIT(close)|Continue(move on in loop cycle) ;
            Continue ;
        } ;
    } ; # loop-E
} ; #*------^ END Function Merge-Module ^------
# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUT2LnpDueR5CFrfw3yKgfhAS2
# 3fCgggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDEyMjkxNzA3MzNaFw0zOTEyMzEyMzU5NTlaMBUxEzARBgNVBAMTClRvZGRT
# ZWxmSUkwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBALqRVt7uNweTkZZ+16QG
# a+NnFYNRPPa8Bnm071ohGe27jNWKPVUbDfd0OY2sqCBQCEFVb5pqcIECRRnlhN5H
# +EEJmm2x9AU0uS7IHxHeUo8fkW4vm49adkat5gAoOZOwbuNntBOAJy9LCyNs4F1I
# KKphP3TyDwe8XqsEVwB2m9FPAgMBAAGjdjB0MBMGA1UdJQQMMAoGCCsGAQUFBwMD
# MF0GA1UdAQRWMFSAEL95r+Rh65kgqZl+tgchMuKhLjAsMSowKAYDVQQDEyFQb3dl
# clNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3SCEGwiXbeZNci7Rxiz/r43gVsw
# CQYFKw4DAh0FAAOBgQB6ECSnXHUs7/bCr6Z556K6IDJNWsccjcV89fHA/zKMX0w0
# 6NefCtxas/QHUA9mS87HRHLzKjFqweA3BnQ5lr5mPDlho8U90Nvtpj58G9I5SPUg
# CspNr5jEHOL5EdJFBIv3zI2jQ8TPbFGC0Cz72+4oYzSxWpftNX41MmEsZkMaADGC
# AWAwggFcAgEBMEAwLDEqMCgGA1UEAxMhUG93ZXJTaGVsbCBMb2NhbCBDZXJ0aWZp
# Y2F0ZSBSb290AhBaydK0VS5IhU1Hy6E1KUTpMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRjCQ7H
# NxxfWGKouWHHS5CtS7vwvTANBgkqhkiG9w0BAQEFAASBgE39FfreHVXQj2XVC6YI
# XXg1ng7CZI5W+5dZxTPf+IQfgWvmUTwNtszIv4KDtHRpJiklF6YVNYqAZ5OzBeaK
# zbVusfgC6o15BSla8pUWPzyHZ9Bq7eijBwAaQYLSl0z1rgNtR/YgihGT1QdL7I3v
# VFbtLtJV9yjcxO3z/92iBSaT
# SIG # End signature block
