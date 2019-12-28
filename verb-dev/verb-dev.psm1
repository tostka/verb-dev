# verb-dev.psm1


  <#
  .SYNOPSIS
  verb-dev - Development-related generic functions
  .NOTES
  Version     : 1.1.1
  Author      : Todd Kadrie
  Website     :	https://www.toddomation.com
  Twitter     :	@tostka
  CreatedDate : 12/26/2019
  FileName    : verb-dev.psm1
  License     : MIT
  Copyright   : (c) 12/26/2019 Todd Kadrie
  Github      : https://github.com/tostka
  AddedCredit : REFERENCE
  AddedWebsite:	REFERENCEURL
  AddedTwitter:	@HANDLE / http://twitter.com/HANDLE
  REVISIONS
  * 12/26/2019 - 1.1.1
  # * 5:22 PM 12/15/2019initial vers includes Get-CommentBlocks, parseHelp, profile-FileAST, build-VSCConfig, Merge-Module  
  .DESCRIPTION
  verb-dev - Development-related generic functions
  .EXAMPLE
  .EXAMPLE
  .LINK
  https://github.com/tostka/verb-dev
  #>


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
