#*------v Function Split-CommandLine v------
function Split-CommandLine {
    <#
    .SYNOPSIS
    Split-CommandLine - Parse command-line arguments using Win32 API CommandLineToArgvW function.
    .NOTES
    Version     : 1.6.2
    Author      : beatcracker
    Website     :	http://beatcracker.wordpress.com
    Twitter     :	@beatcracker / http://twitter.com/beatcracker
    CreatedDate : 2014-11-22
    FileName    : Split-CommandLine
    License     :
    Copyright   :
    Github      : https://github.com/beatcracker
    AddedCredit : Todd Kadrie
    AddedWebsite:	http://www.toddomation.com
    AddedTwitter:	@tostka / http://twitter.com/tostka
    REVISIONS
    * 8:21 AM 8/3/2020 shifted into verb-dev module
    * 1:17 PM 12/14/2019 TSK:Split-CommandLine():  minor reformatting & commenting
    * 11/22/2014 posted version
    .DESCRIPTION
    This is the Cmdlet version of the code from the article http://edgylogic.com/blog/powershell-and-external-commands-done-right. It can parse command-line arguments using Win32 API function CommandLineToArgvW .
    .PARAMETER  CommandLine
    This parameter is optional.
    A string representing the command-line to parse. If not specified, the command-line of the current PowerShell host is used.
    .EXAMPLE
    Split-CommandLine
    Description
    -----------
    Get the command-line of the current PowerShell host, parse it and return arguments.
    .EXAMPLE
    Split-CommandLine -CommandLine '"c:\windows\notepad.exe" test.txt'
    Description
    -----------
    Parse user-specified command-line and return arguments.
    .EXAMPLE
    '"c:\windows\notepad.exe" test.txt',  '%SystemRoot%\system32\svchost.exe -k LocalServiceNetworkRestricted' | Split-CommandLine
    Description
    -----------
    Parse user-specified command-line from pipeline input and return arguments.
    .EXAMPLE
    Get-WmiObject Win32_Process -Filter "Name='notepad.exe'" | Split-CommandLine
    Description
    -----------
    Parse user-specified command-line from property name of the pipeline object and return arguments.
    .LINK
    https://github.com/beatcracker/Powershell-Misc/blob/master/Split-CommandLine
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandLine
    ) ;
    Begin {
        $Kernel32Definition = @'
            [DllImport("kernel32")]
            public static extern IntPtr GetCommandLineW();
            [DllImport("kernel32")]
            public static extern IntPtr LocalFree(IntPtr hMem);
'@ ;
        $Kernel32 = Add-Type -MemberDefinition $Kernel32Definition -Name 'Kernel32' -Namespace 'Win32' -PassThru ;
        $Shell32Definition = @'
            [DllImport("shell32.dll", SetLastError = true)]
            public static extern IntPtr CommandLineToArgvW(
                [MarshalAs(UnmanagedType.LPWStr)] string lpCmdLine,
                out int pNumArgs);
'@ ;
        $Shell32 = Add-Type -MemberDefinition $Shell32Definition -Name 'Shell32' -Namespace 'Win32' -PassThru ;
        if (!$CommandLine) {
            $CommandLine = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Kernel32::GetCommandLineW());
        } ;
    } ;

    Process {
        $ParsedArgCount = 0 ;
        $ParsedArgsPtr = $Shell32::CommandLineToArgvW($CommandLine, [ref]$ParsedArgCount) ;

        Try {
            $ParsedArgs = @();

            0..$ParsedArgCount | ForEach-Object {
                $ParsedArgs += [System.Runtime.InteropServices.Marshal]::PtrToStringUni(
                    [System.Runtime.InteropServices.Marshal]::ReadIntPtr($ParsedArgsPtr, $_ * [IntPtr]::Size)
                )
            }
        }
        Finally {
            $Kernel32::LocalFree($ParsedArgsPtr) | Out-Null
        } ;

        $ret = @() ;

        # -lt to skip the last item, which is a NULL ptr
        for ($i = 0; $i -lt $ParsedArgCount; $i += 1) {
            $ret += $ParsedArgs[$i]
        } ;

        return $ret ;
    } ;
} ; #*------^ END Function split-CommandLine ^------
