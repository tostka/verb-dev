# Convert-CommandToSplatTDO.ps1

#region CONVERT_COMMANDTOSPLATTDO ; #*------v Convert-CommandToSplatTDO v------
Function Convert-CommandToSplatTDO {
    <#
    .SYNOPSIS
    Convert-CommandToSplatTDO - Convert the named parameter part of a command into a splat (hash table oif parameters): In the ISE works from current selected text; pastes result over the selection (otherwise copies to CB and echoes to pipeline)
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     : http://www.toddomation.com
    Twitter     : @tostka / http://twitter.com/tostka
    CreatedDate : 2024-07-11
    FileName    : Convert-CommandToSplatTDO.ps1
    License     : (non asserted)
    Copyright   : (non asserted)
    Github      : https://github.com/tostka/verb-dev
    Tags        : Powershell,ISE,development,debugging
    REVISIONS
    * 8:46 AM 4/16/2026 init; works on cmdline as well as JH's intent as menu item in ISE; 
        added testing for positional params (won't have -parametername), explicit error for correction. 
        Also patched over internal functions and other cmdlets that won't gcm resolve (forces $cmd to $AstTokens[0].text)
        -> resolves what it finds into a splat whether all the components are resolvable or not.
    - Adapted from Jeff Hicks posted Convert-CommandToSplat: jdhitsolutions/ISEScriptingGeek

    .DESCRIPTION
    Convert-CommandToSplatTDO - Convert the named parameter part of a command into a splat (hash table oif parameters): In the ISE works from current selected text; pastes result over the selection (otherwise copies to CB and echoes to pipeline)
    .EXAMPLE
    PS> convert-commandtoSplatTDO -Text "gci -path d:\scripts\* -include @('*.ps1','*.psm1','*.xml') -recurse" ; 

        $plt = @{
            path = 'd:\scripts\*'            include = '@('''*.ps1'',''*.psm1'',''*.xml''')'        }
        Get-ChildItem @plt


    Convert command line text specification to splat [hashtable]
    .LINK
    https://github.com/jdhitsolutions/ISEScriptingGeek/tree/master/functions
    .LINK
    Github      : https://github.com/tostka/verb-dev
    #>
    [CmdletBinding()]
    [Alias('Convert-CommandToSplat')]
    Param(
        #[ValidateNotNullOrEmpty()]
        [String]$Text #= $psISE.CurrentFile.editor.SelectedText
    )
    if(-not $Text -AND $psISE -AND $psISE.CurrentFile.editor.SelectedText){$Text = $psISE.CurrentFile.editor.SelectedText}
    if(-not $Text){
        write-warning 'unable to locate either an ISE selection, or an explicit -Text "code commandline" input!'
        return ; 
    } ; 
    Set-StrictMode -Version latest
    #New-Variable $AstTokens -Force
    New-Variable AstTokens -Force
    New-Variable astErr -Force
    Write-Verbose "Converting $text"
    $AST = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$AstTokens, [ref]$astErr)
    #resolve the command name
    TRY{
        $cmdType = Get-Command $AstTokens[0].text -erroraction STOP
        if ($cmdType.CommandType -eq 'Alias') {
            $cmd = $cmdType.ResolvedCommandName
        }
        else {
            $cmd = $cmdType.Name
        }
    }CATCH{
        # it will fail on internal or undefined functions/cmdlets, try to get it to rote parse the cmdline
        $cmd = $AstTokens[0].text ; 
    }
    Write-Verbose "Command is $cmd"
    Write-Verbose ($AstTokens | Out-String)
    #last item is end of input token
    $r = for ($i = 1; $i -lt $AstTokens.count - 2 ; $i++) {
        #if ($AstTokens[$i].ParameterName) {
        if (($AstTokens[$i] | gm).Name.contains('ParameterName') -AND $AstTokens[$i].ParameterName) {
            $p = $AstTokens[$i].ParameterName
            Write-Verbose "Parameter name = $p"
            Write-Verbose ($AstTokens[$i] | Out-String)
            $v = ''
            #check next token
            if ($AstTokens[$i + 1].Kind -match 'Parameter|NewLine|EndOfInput') {
                #the parameter must be a switch
                $v = "`$True"
            }
            else {
                While ($AstTokens[$i + 1].Kind -notmatch 'Parameter|NewLine|EndOfInput') {
                    #break out of loop if there is no text
                    Write-Verbose "While: $($AstTokens[$i])"
                    $i++
                    #test if value is a string and if it is quoted, if not include quotes
                    if ($AstTokens[$i].Text -match '\D' -AND $AstTokens[$i].Text -notmatch '"\w+.*"' -AND $AstTokens[$i].Text -notmatch "'\w+.*'") {
                        #ignore commas and variables
                        if ($AstTokens[$i].Kind -match 'Comma|Variable') {
                            $value = $AstTokens[$i].Text
                        }
                        else {
                            #Assume text and quote it
                            Write-Verbose "Quoting $($AstTokens[$i].Text)"
                            $value = "'$($AstTokens[$i].Text)'"
                        }
                    }
                    else {
                        Write-Verbose "Using text as is for $($AstTokens[$i].Text)"
                        $value = $AstTokens[$i].Text
                    }
                    Write-Verbose "Adding $Value to `$v"
                    $v += $value
                }
            } #while
            "$p = $v`r"
            Write-Verbose "hashentry -> $p = $v`r"
        }else{
            if($i -eq 1){
                write-warning "First parameter - $( $asttokens[$i].value) has *NO* explicit Parameter name: postiional parameter? You need to use explicit parameter names for this function!" ; 
                return ; 
            } ; 
        }
    } #for
    Write-Verbose 'Finished processing AST'
    Write-Verbose ($r | Out-String)
    #create text
    $HashText = @"
`$plt = @{
 $r}
$cmd @plt
"@
    if($HashText -AND $psISE -AND $psISE.CurrentFile.editor.SelectedText){
        #insert the text which should replace the highlighted line
        $psISE.CurrentFile.Editor.InsertText($HashText)
    }else{
        $hashText | out-clipboard ; 
        write-host "Copied results to clipboard" ; 
        $hashText | write-output ; 
    } ; 
} ; 
#endregion CONVERT_COMMANDTOSPLATTDO ; #*------^ END Convert-CommandToSplatTDO ^------