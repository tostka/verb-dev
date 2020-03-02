﻿#VERB-dev.Tests.ps1
<#
.SYNOPSIS
VERB-dev.Tests.ps1 - Pester Tests 
.NOTES
Version     : 1.0.0
Author      : Todd Kadrie
Website     :	http://www.toddomation.com
Twitter     :	@tostka / http://twitter.com/tostka
CreatedDate : 2020-
FileName    : 
License     : MIT License
Copyright   : (c) 2020 Todd Kadrie
Github      : https://github.com/tostka
Tags        : Powershell
AddedCredit : REFERENCE
AddedWebsite:	URL
AddedTwitter:	URL
REVISIONS
.DESCRIPTION
VERB-dev.Tests.ps1 - Pester Tests 
-Whatif switch]
.EXAMPLE
cd c:\sc\verb-dev\ ; 
.\Tests\VERB-dev.tests.ps1 ; 
Change to the Module source root dir, and execute the script (Script discovery assumes the pwd is the module root)
.LINK
#>

# patch in ISE support
if ($psISE){
    $ScriptDir = Split-Path -Path $psISE.CurrentFile.FullPath ;
    $ScriptBaseName = split-path -leaf $psise.currentfile.fullpath ;
    $ScriptNameNoExt = [system.io.path]::GetFilenameWithoutExtension($psise.currentfile.fullpath) ;
    $PSScriptRoot = $ScriptDir ;
    if($PSScriptRoot -ne $ScriptDir){ write-warning "UNABLE TO UPDATE BLANK `$PSScriptRoot TO CURRENT `$ScriptDir!"} ;
    $PSCommandPath = $psise.currentfile.fullpath ;
    if($PSCommandPath -ne $psise.currentfile.fullpath){ write-warning "UNABLE TO UPDATE BLANK `$PSCommandPath TO CURRENT `$psise.currentfile.fullpath!"} ;
}

$ModuleName = Split-Path (Resolve-Path "$PSScriptRoot\..\" ) -Leaf
$ModuleManifest = Resolve-Path "$PSScriptRoot\..\$ModuleName\$ModuleName.psd1"
$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace('tests', '')
$scriptsModules = Get-ChildItem $here -Include *.psd1, *.psm1, *.ps1 -Exclude *.tests.ps1 -Recurse
if($scriptsModules.count -eq 0){
    $scriptsModules = Get-ChildItem (split-path $here) -Include *.psd1, *.psm1, *.ps1 -Exclude *.tests.ps1 -Recurse
} ; 


Get-Module $ModuleName | Remove-Module
Import-Module $ModuleManifest -Force

Describe 'Module Information' -Tags 'Command'{
    Context 'Manifest Testing' {
        It 'Valid Module Manifest' {
            {
                $Script:Manifest = Test-ModuleManifest -Path $ModuleManifest -ErrorAction Stop -WarningAction SilentlyContinue
            } | Should Not Throw
        }
        It 'Valid Manifest Name' {
            $Script:Manifest.Name | Should -Be $ModuleName
        }
        It 'Generic Version Check' {
            $Script:Manifest.Version -as [Version] | Should -Not -BeNullOrEmpty
        }
        It 'Valid Manifest Description' {
            $Script:Manifest.Description | Should -Not -BeNullOrEmpty
        }
        It 'Valid Manifest Root Module' {
            $Script:Manifest.RootModule | Should -Be "$ModuleName.psm1"
        }
        It 'Valid Manifest GUID' {
            $Script:Manifest.Guid | Should -Be "af7c9182-3b10-416d-bace-aab0aab77828"
        }
    }

    Context 'Exported Functions' {
        It 'Proper Number of Functions Exported' {
            $ExportedCount = Get-Command -Module $ModuleName | Measure-Object | Select-Object -ExpandProperty Count
            if(!$PSScriptRoot.length -eq 0){
                $FileCount = Get-ChildItem -Path "$ScriptDir\..\$ModuleName\Public" -Filter *.ps1 -Recurse | Measure-Object | Select-Object -ExpandProperty Count
                if($FileCount -eq 0){
                    $FileCount = Get-ChildItem -Path "$ScriptDir\..\..\$ModuleName\Public" -Filter *.ps1 -Recurse | Measure-Object | Select-Object -ExpandProperty Count
                } ; 
            } else { 
                $FileCount = Get-ChildItem -Path "$PSScriptRoot\..\$ModuleName\Public" -Filter *.ps1 -Recurse | Measure-Object | Select-Object -ExpandProperty Count
            } ; 

            $ExportedCount | Should be $FileCount
        }
    }


}

Describe 'General - Testing all scripts and modules against the Script Analyzer Rules' {
	Context "Checking files to test exist and Invoke-ScriptAnalyzer cmdLet is available" {
		It "Checking files exist to test." {
			$scriptsModules.count | Should Not Be 0
		}
		It "Checking Invoke-ScriptAnalyzer exists." {
			{ Get-Command Invoke-ScriptAnalyzer -ErrorAction Stop } | Should Not Throw
		}
	}

	$scriptAnalyzerRules = Get-ScriptAnalyzerRule

	forEach ($scriptModule in $scriptsModules) {
		switch -wildCard ($scriptModule) { 
			'*.psm1' { $typeTesting = 'Module' } 
			'*.ps1'  { $typeTesting = 'Script' } 
			'*.psd1' { $typeTesting = 'Manifest' } 
		}

		Context "Checking $typeTesting - $($scriptModule) - conforms to Script Analyzer Rules" {
			<# stock code
            forEach ($scriptAnalyzerRule in $scriptAnalyzerRules) {
				It "Script Analyzer Rule $scriptAnalyzerRule" {
					(Invoke-ScriptAnalyzer -Path $scriptModule -IncludeRule $scriptAnalyzerRule).count | Should Be 0
				}
			}
            #>
            # try to adopt in PPosh style code from the psake.ps1 build script to here
            $scriptStylePath = "$PSScriptRoot\PPoShScriptingStyle.psd1"
            (Invoke-ScriptAnalyzer -Path $ProjectRoot -Recurse -Settings $scriptStylePath).count | Should Be 0 

		}
	}
}

# SIG # Begin signature block
# MIIELgYJKoZIhvcNAQcCoIIEHzCCBBsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUm9qPwBDIKVXjVcMaACieQEcW
# NfCgggI4MIICNDCCAaGgAwIBAgIQWsnStFUuSIVNR8uhNSlE6TAJBgUrDgMCHQUA
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
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRLGS+w
# mB3zYT5u5sg7eHNDJ4WpFzANBgkqhkiG9w0BAQEFAASBgBmlclZDM9pSpHdwwDl6
# VVNwuJdq57GVxvzC1r1sC0HlxiqSyirKo3ApGGQ9JoDhVtgmkMGVE9J3+CC606II
# NCsu5QYtdXm/3d1lmS1nweKe8Hd58XZ+pfeoWbo0guJDx1LsSQ5G7pb3DekdSJNb
# 9o2JjIZSZz2wUuLCjrPe/fAg
# SIG # End signature block
