@{
    <# Virtual Expo lab base build/configuration document #>
    AllNodes = @(
        @{
            NodeName                    = '*';
            InterfaceAlias              = 'Ethernet';
            DefaultGateway              = '10.200.0.254';
            SubnetMask                  = 24;
            AddressFamily               = 'IPv4';
            DnsServerAddress            = '10.200.0.101';
            DomainName                  = 'lab.local';
            NetBIOSDomainName           = 'LAB';
            PfxCertificatePath          = 'C:\Resources\star.lab.local.pfx';
            PfxCertificateThumbprint    = 'F6F557A00B74FE60BCCD6EF70B6D31D2C8B94F1E';
            PfxCertificatePassword      = 'T3stlab';
            CertificateFile             = "$env:ProgramData\Lability\Certificates\LabClient.cer";
            Thumbprint                  = 'AAC41ECDDB3B582B133527E4DE0D2F8FEB17AAB2';
            PSDscAllowDomainUser        = $true;
            Lability_Media              = '2012R2_x64_Standard_EN_v5_Eval';
            Lability_SwitchName         = 'NAT';
            Lability_ProcessorCount     = 1;
            Lability_StartupMemory      = 2GB;
            Lability_BootDelay = 30;
        }
        @{  ## Domain Controller
            NodeName = 'EXPODC01';
            Role = @('DC');
            IPAddress = '10.200.0.101';
            DnsServerAddress = '127.0.0.1';
            Lability_Resource = 'CitrixReceiver';
            Lability_BootOrder = 10;
        }
        @{  ## SQL Server and Citrix licensing
            NodeName = 'EUDBLS01';
            Role = @('SQL','XD7LicenseServer');
            IPAddress = '10.200.0.111';
            Lability_Resource = 'SQLEXPRWT_x64_ENU','XenDesktop78','XD77License';
            Lability_BootOrder = 20;
        }
        @{  ## Citrix XenDesktop Delivery Controller
            NodeName  = 'EXPOXC01';
            Role      = @('XD7Controller');
            IPAddress = '10.200.0.121';
            Lability_Resource = 'starlablocalpfx','XenDesktop78';
            Lability_BootOrder = 30;
        }
        @{  ## Citrix XenDesktop Storefront and Director
            NodeName  = 'EXPOSF01';
            Role      = @('XD7StoreFront');
            IPAddress = '10.200.0.131';
            Lability_Resource = 'starlablocalpfx','XenDesktop78';
            Lability_BootOrder = 40;
        }
        @{  ## Citrix XenDesktop RDS Session Host
            NodeName  = 'EXPOSH01';
            Role      = @('XD7SessionHost');
            IPAddress = '10.200.0.141';
            Lability_Resource = 'XenDesktop78','NotepadPlusPlus','Firefox';
            Lability_BootOrder = 40;
            Lability_SecureBoot = $false;
        }
    )

    NonNodeData = @{
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
                    Filename = 'EUDBLS01_XenDesktop_PLAT_PartnerUse_15022016.lic';
                    Uri = '\\10.100.50.1\Public\VirtualExpo\EUDBLS01_XenDesktop_PLAT_PartnerUse_15022016.lic';
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
        };
    };
};
