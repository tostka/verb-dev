# Installing VERB-dev

    # Install VERB-dev from the private repo
    Find-Module VERB-dev -repo $localRepo | Install-Module ;

    # install the lastest version of all pkgs on the repo:

    ```powershell
    # pull pkgs
    $pkgs = find-module -repo $localRepo ;
    $pkgs | count ;
    # install latest version of each
    $pkgs | select -unique name |%{"==$($_.name)" ; $vers = find-module -repo tinrepo -name $_.name ; $vers | sort version | select -last 1 | install-module -force -allowclobber -whatif } ;
    # test-import each
    $pkgs | select -unique name |%{"==$($_.name)" ; import-module -force -name $_.name -verbose } ;
    ```
