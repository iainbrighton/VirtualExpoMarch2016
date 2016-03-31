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

#region Pre Deployment

## >> NO Citrix products installed
## >> No DNS aliases

#endregion Pre Deployment

#region Deployment

<#
  VirtualExpo.ps1/.psd1
    EXPODC01 - Create storefront.lab.local DNS alias
              o Create director.lab.local DNS alias
    EUDBLS01 - Install Licensing server
              o Register XD license file
    EXPOXC01 - Install Studio role
              o Create SQL databases and deploy XD site
              o Create machine catalog
              o Add EXPOSH01
              o Create delivery group
    EXPOSF01 - Install Storefront and Director roles
    EXPOSH01 - Install Notepad++
              o Install Session VDA
#>

## Start Push configuration
Start-DscConfiguration -Path '\\10.100.50.1\Public\XenAppBlog\VirtualExpo' -Wait -Verbose;

## VirtualExpo.ps1
PSEdit '\\10.100.50.1\Public\XenAppBlog\VirtualExpo.ps1','\\10.100.50.1\Public\XenAppBlog\VirtualExpo.psd1';

## MOF files already created
PSEdit '\\10.100.50.1\Public\XenAppBlog\VirtualExpo\EXPOXC01.mof';

## Check deployment status
Test-DscConfiguration -ComputerName EXPOXC01, EXPOSH01, EXPOSF01 -Verbose;

#endregion Deployment

#region Post Deployment

## Restart Citrix Licensing service and Broker service to pick up licenses
Invoke-Command -ComputerName EUDBLS01 -ScriptBlock { Restart-Service -Name 'Citrix Licensing' };
Invoke-Command -ComputerName EXPOXC01 -ScriptBlock { Restart-Service -Name 'CitrixBrokerService' };

## Check Studio console (may require EXPOXC01 restart to pick up licenses)

## Check Director 
& 'C:\Program Files (x86)\Internet Explorer\iexplore.exe' 'https://director.lab.local/director'

#endregion Post Deployment
