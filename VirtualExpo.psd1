@{
    <# Virtual Expo demo configuration document#>
    AllNodes = @(
        @{
            NodeName                 = '*';
            DomainName               = 'lab.local';
            NetBIOSDomainName        = 'LAB';
            PfxCertificatePath       = 'C:\Resources\star.lab.local.pfx';
            PfxCertificateThumbprint = 'F6F557A00B74FE60BCCD6EF70B6D31D2C8B94F1E';
            PfxCertificatePassword   = 'T3stlab';
            CertificateFile          = "$env:ProgramData\Lability\Certificates\LabClient.cer";
            Thumbprint               = 'AAC41ECDDB3B582B133527E4DE0D2F8FEB17AAB2';
            PSDscAllowDomainUser     = $true;
            Lability_BootDelay       = 20;
            XenDesktopMediaPath      = 'C:\Resources\XenDesktop78';
        }
        @{
            NodeName           = 'EXPODC01';
            Role               = @('DC');
            Lability_BootOrder = 10;
        }
        @{
            NodeName           = 'EUDBLS01';
            Role               = @('SQL','XD7LicenseServer');
            Lability_BootOrder = 20;
        }
        @{
           NodeName           = 'EXPOXC01';
           Role               = @('XD7Controller');
           IPAddress          = '10.200.0.121';
           Lability_BootOrder = 30;
        }
        @{
            NodeName           = 'EXPOSF01';
            Role               = @('XD7StoreFront','XD7Director');
            Lability_BootOrder = 40;
        }
        @{
            NodeName           = 'EXPOSH01';
            Role               = @('XD7SessionHost');
            XD7MachineCatalog  = 'Manual Server Catalog';
            XD7DeliveryGroup   = 'Server Desktop';
            Lability_BootOrder = 40;
        }
    )
    NonNodeData = @{
        XenDesktop = @{
            
            Site = @{
                Name            = 'VirtualExpo';
                DatabaseServer  = 'EUDBLS01.lab.local';
                Administrators  = 'LAB\XenDesktop Admins','LAB\Domain Admins';
                LicenseFilePath = 'C:\Resources\EUDBLS01_XenDesktop_25_Partner_20012017.lic';
            }
            
            MachineCatalogs = @(
                @{
                    Name           = 'Manual Server Catalog';
                    Description    = 'Manual RDS Session Hosts';
                    Allocation     = 'Random';
                    Persistence    = 'Local';
                    Provisioning   = 'Manual';
                    IsMultiSession = $true;
                }
            )

            DeliveryGroups = @(
                @{
                    Name           = 'Server Desktop';
                    DisplayName    = 'Standard Desktop';
                    Description    = 'Published XenApp Desktop KEYWORDS:Auto';
                    DeliveryType   = 'DesktopsAndApps'
                    DesktopType    = 'Shared';
                    IsMultiSession = $true;
                    Users          = 'LAB\Domain Users';
                    Applications   = @(
                        @{
                            Name = 'Notepad';
                            Path = 'C:\Windows\System32\Notepad.exe';
                            Description = 'KEYWORDS:Auto';
                        }
                        @{
                            Name = 'Notepad++';
                            Path = 'C:\Program Files (x86)\Notepad++\Notepad++.exe';
                            Description = 'KEYWORDS:Auto';
                        }
                    )
                }
            )
                
            Storefront = @{
                DnsAlias = 'storefront';
                DnsZone  = 'lab.local';
                BaseUrl  = 'https://storefront.lab.local/';
                AuthenticationVirtualPath = '/Citrix/Authentication';
                StoreVirtualPath = '/Citrix/Store';
            }

            Director = @{
                DnsAlias = 'director';
                DnsZone  = 'lab.local';
            }

        } #end XenDesktop

        Lability = @{ <# https://github.com/VirtualEngine/Lability #>
            Resource = @(
                @{  Id = 'SQLEXPRWT_x64_ENU';
                    Filename = 'SQLEXPRWT_x64_ENU.zip';
                    Uri = '\\10.100.50.1\Public\Software\Microsoft\SQLEXPRWT_x64_ENU.zip';
                    Expand = $true; }
                @{  Id = 'XenDesktop78';
                    Filename = 'XenDesktop78.iso';
                    Uri = '\\10.100.50.1\ISOs\XenDesktop78.iso';
                    Checksum = '04512A3DFFB647558979BCC33AAE5905';
                    Expand = $true; }
                @{  Id = 'XD77License';
                    Filename = 'EUDBLS01_XenDesktop_25_Partner_20012017.lic';
                    Uri = '\\10.100.50.1\Public\VirtualExpo\EUDBLS01_XenDesktop_25_Partner_20012017.lic';
                    Checksum = '740EAA6B4C78FD0F82D814A20A4E3E03'; }
                @{  Id = 'starlablocalpfx';
                    Filename = 'star.lab.local.pfx';
                    Uri = 'https://s3.eu-central-1.amazonaws.com/bootstrap.demoscale.com/Certificates/star.lab.local.pfx';
                    Checksum = 'E6307E5EB7E7B970FCE39F6E30A0EA42'; }
                @{  Id = 'CitrixReceiver';
                    Filename = 'CitrixReceiverWeb.exe';
                    Uri = 'http://downloadplugins.citrix.com/Windows/CitrixReceiver.exe'; }
                @{  Id = 'NotepadPlusPlus';
                    Filename = 'npp.6.8.8.Installer.exe';
                    Uri = 'https://notepad-plus-plus.org/repository/6.x/6.8.8/npp.6.8.8.Installer.exe'; }
                @{  Id = 'Firefox';
                    Filename = 'FirefoxSetup44.0.exe';
                    Uri = 'https://download.mozilla.org/?product=firefox-44.0-SSL&os=win&lang=en-GB'; }
            );
            DSCResource = @(
                @{ Name = 'xActiveDirectory'; }
                @{ Name = 'xNetworking'; }
                @{ Name = 'xComputerManagement'; }
                @{ Name = 'xCredSSP'; }
                @{ Name = 'xWebAdministration'; }
                @{ Name = 'xRemoteDesktopAdmin'; }
                @{ Name = 'xCertificate'; }
                @{ Name = 'xPSDesiredStateConfiguration'; }
                @{ Name = 'xDNSServer'; }
                @{ Name = 'VirtualEngineLab'; Provider = 'Github'; Owner = 'VirtualEngine'; }
                @{ Name = 'XenDesktop7'; Provider = 'Github'; Owner = 'VirtualEngine'; }
                @{ Name = 'XenDesktop7Lab'; Provider = 'Github'; Owner = 'VirtualEngine'; }
                @{ Name = 'Storefront'; Provider = 'Github'; Owner = 'VirtualEngine'; }
            );
        } #end Lability
    };
};
