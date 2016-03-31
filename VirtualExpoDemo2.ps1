<#
  VirtualExpoBase.ps1/.psd1 already deployed
    EXPODC01 - AD, DNS
              o Citrix Receiver installed
              o XDA, XDU and XenDesktop Admins users/groups created
    EUDBLS01 - SQL 2014 Express and RDS Licensing installed
    EXPOXC01
    EXPOSF01 - IIS and SSL certificate installed
    EXPOSH01 - RDS Session Host and Desktop Experience installed
#>

#region Storefront Configuration

## Check Storefront configuration

## Configure Storefront (note: Storefront is already installed)
Start-DscConfiguration -Path '\\10.100.50.1\Public\XenAppBlog\VirtualExpoStorefront' -Wait -Verbose;

PSEdit '\\10.100.50.1\Public\XenAppBlog\VirtualExpoStorefront.ps1','\\10.100.50.1\Public\XenAppBlog\VirtualExpoStorefront\EXPOSF01.mof';

## Launch desktop/applications
& 'C:\Program Files (x86)\Internet Explorer\iexplore.exe' 'https://storefront.lab.local/Citrix/StoreWeb';

#endregion Storefront Configuration
