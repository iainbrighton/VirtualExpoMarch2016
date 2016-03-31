<# Virtual Expo demo configuration #>

## TODO: Add XD7ControllerPort/PortBinding resource 'netsh http add sslcert ipport=0.0.0.0:443 certhash=72825832F6FCE7A53C0F72019921A51380238ADB appid={234ED26A-5812-DF24-98C2-709915D0BD4C}'

configuration VirtualExpo {
    param (
        [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Username 'Administrator' -Message 'Enter Domain administrator username/password.')
    )
    Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName xPSDesiredStateConfiguration;
    Import-DscResource -ModuleName xDnsServer;
    Import-DscResource -ModuleName xCredSSP;
    Import-DscResource -ModuleName XenDesktop7;
    Import-DscResource -ModuleName xWebAdministration;
    
    ## Need delegated access to all Controllers (NetBIOS and FQDN) and the database server
    $credSSPDelegatedComputers = $AllNodes | Where { $_.Role -in 'XD7Controller','SQL','XD7SessionHost'} | ForEach {
        Write-Output $_.NodeName;
        if ($_.NodeName.Contains('.')) {
            Write-Output ('{0}' -f $_.Split('.')[0]);  ## Output NetBIOS name
        }
        else {
            Write-Output ('{0}.{1}' -f $_.NodeName, $_.DomainName); ## Output FQDN
        }
    };
        
    node ($AllNodes | Where { $_.Role -contains 'DC' } | Select -First 1).NodeName {

        ## Create a DNS alias for first Storefront server
        $storefrontHost = ($AllNodes | Where { $_.Role -contains 'XD7StoreFront' } | Select -First 1).NodeName;
        xDnsRecord "storefront_CNAME_$storefrontHost" {
            Zone = $node.DomainName;
            Name = $ConfigurationData.NonNodeData.XenDesktop.Storefront.DnsAlias;
            Type = 'CName';
            Target = '{0}.{1}' -f $storefrontHost, $node.DomainName;
        }

        ## Create a DNS alias for first Director server
        $directorHost = ($AllNodes | Where { $_.Role -contains 'XD7Director' } | Select -First 1).NodeName;
        xDnsRecord "director_CNAME_$directorHost" {
            Zone = $node.DomainName;
            Name = $ConfigurationData.NonNodeData.XenDesktop.Director.DnsAlias;
            Type = 'CName';
            Target = '{0}.{1}' -f $directorHost, $node.DomainName;
        }
        
    } #end node Primary Domain Controller

    node ($AllNodes | Where { $_.Role -contains 'DC' } | Select -Skip 1).NodeName {
        
    
    }  #end node Secondary Domain Controller
    
    node $AllNodes.Where({ $_.Role -notcontains 'DC' }).NodeName {


    } #end node Non Domain Controller

    node $AllNodes.Where({ $_.Role -contains 'SQL' }).NodeName {
        

    } #end node SQL

    node $AllNodes.Where({ $_.Role -contains 'XD7Controller' }).NodeName {

        ## Create DOMAIN\UserName credential
        $netBIOSUsername = '{0}\{1}' -f $node.NetBIOSDomainName, $Credential.UserName;
        $domainCredential = New-Object System.Management.Automation.PSCredential($netBIOSUsername, $Credential.Password);
        
        xCredSSP 'CredSSPServer' {
            Role = 'Server';
        }

        xCredSSP 'CredSSPClient' {
            Role = 'Client';
            DelegateComputers = $credSSPDelegatedComputers;
        }
        
        XD7Feature 'XDStudio' {
            Role = 'Studio';
            SourcePath = $node.XenDesktopMediaPath;
        }

        XD7Feature 'XDController' {
            Role = 'Controller';
            SourcePath = $node.XenDesktopMediaPath;
            DependsOn = '[xCredSSP]CredSSPServer','[xCredSSP]CredSSPClient';
        }

        XD7Database 'XDSiteDatabase' {
            SiteName = $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            DataStore = 'Site';
            DatabaseName = '{0}Site' -f $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            DatabaseServer = $ConfigurationData.NonNodeData.XenDesktop.Site.DatabaseServer;
            DependsOn = '[XD7Feature]XDController';
            PsDscRunAsCredential = $domainCredential; # << PsDscRunAsCredential is supported with PowerShell modules
        }

        XD7Database 'XDMonitorDatabase' {
            SiteName = $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            DataStore = 'Monitor';
            DatabaseName = '{0}Monitor' -f $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            DatabaseServer = $ConfigurationData.NonNodeData.XenDesktop.Site.DatabaseServer;
            DependsOn = '[XD7Feature]XDController';
            PsDscRunAsCredential = $domainCredential;
        }

        XD7Database 'XDLoggingDatabase' {
            SiteName = $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            DataStore = 'Logging';
            DatabaseName = '{0}Logging' -f $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            DatabaseServer = $ConfigurationData.NonNodeData.XenDesktop.Site.DatabaseServer;
            DependsOn = '[XD7Feature]XDController';
            PsDscRunAsCredential = $domainCredential;
        }

        XD7Site 'XDSite' {
            SiteName = $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            DatabaseServer = $ConfigurationData.NonNodeData.XenDesktop.Site.DatabaseServer;
            SiteDatabaseName = '{0}Site' -f $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            MonitorDatabaseName = '{0}Monitor' -f $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            LoggingDatabaseName = '{0}Logging' -f $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            PsDscRunAsCredential = $domainCredential;
            DependsOn = '[XD7Database]XDSiteDatabase','[XD7Database]XDMonitorDatabase','[XD7Database]XDLoggingDatabase';
        }
        

        XD7SiteLicense 'XDSiteLicense' {
            LicenseServer = ($ConfigurationData.AllNodes | Where Role -eq 'XD7LicenseServer' | Select -First 1).NodeName;
            Credential = $Credential;
            DependsOn = '[XD7Site]XDSite';
        }

        $administratorDependsOn = @();
        foreach ($administrator in $ConfigurationData.NonNodeData.XenDesktop.Site.Administrators) {

            $administratorName = $administrator.Replace('\','_').Replace(' ','');

            XD7Administrator "XDAdministrator_$administratorName" {
                Name = $administrator;
                Credential = $domainCredential; # << PsDscRunAsCredential NOT SUPPORTED with PowerShell Snap-ins
                DependsOn = '[XD7Site]XDSite';
            }

            $administratorDependsOn += "[XD7Administrator]XDAdministrator_$administratorName";

        } #end foreach Administrator

        XD7Role 'XDRole_FullAdministrators' {
            Name = 'Full Administrator';
            Members = $ConfigurationData.NonNodeData.XenDesktop.Site.Administrators;
            Credential = $domainCredential;
            DependsOn = $administratorDependsOn;
        }

        foreach ($machineCatalog in $ConfigurationData.NonNodeData.XenDesktop.MachineCatalogs) {
            
            $machineCatalogName = $machineCatalog.Name.Replace(' ','');

            XD7Catalog "Catalog_$machineCatalogName" {
                Name = $machineCatalog.Name;
                Description = $machineCatalog.Description;
                Allocation = $machineCatalog.Allocation;
                Persistence = $machineCatalog.Persistence;
                Provisioning = $machineCatalog.Provisioning;
                IsMultiSession = $machineCatalog.IsMultiSession;
                Credential = $domainCredential;
            }

            XD7CatalogMachine "Catalog_$($machineCatalogName)_Machines" {
                Name = $machineCatalog.Name;
                Members = $AllNodes.Where({ $_.XD7MachineCatalog -eq $machineCatalog.Name }).NodeName;
                Credential = $domainCredential;
                DependsOn = "[XD7Catalog]Catalog_$machineCatalogName";
            }
        
        } #end foreach Machine Catalog

        foreach ($deliveryGroup in $ConfigurationData.NonNodeData.XenDesktop.DeliveryGroups) {

            $deliveryGroupName = $deliveryGroup.Name.Replace(' ','');

            XD7DesktopGroup "DesktopGroup_$deliveryGroupName" {
                Name = $deliveryGroup.Name;
                DisplayName = $deliveryGroup.DisplayName;
                Description = $deliveryGroup.Description;
                DeliveryType = $deliveryGroup.DeliveryType;
                DesktopType = $deliveryGroup.DesktopType;
                IsMultiSession = $deliveryGroup.IsMultiSession;
                Credential = $Credential;
            }

            $deliveryGroupMembers = @();
            foreach ($deliveryGroupMember in $AllNodes.Where({ $_.XD7DeliveryGroup -eq $deliveryGroup.Name }).NodeName) {
                $deliveryGroupMembers = '{0}.{1}' -f $deliveryGroupMember, $node.DomainName;
            }

            XD7DesktopGroupMember "DesktopGroupMember_$deliveryGroupName" {
                Name = $deliveryGroup.Name;
                Members = $deliveryGroupMembers;
                Credential = $Credential;
                DependsOn = "[XD7DesktopGroup]DesktopGroup_$deliveryGroupName";
            }

            if ($deliveryGroup.DeliveryType -in 'DesktopsAndApps','DesktopsOnly') {
                
                XD7EntitlementPolicy "$($deliveryGroupName)_DesktopEntitlement" {
                    DeliveryGroup = $deliveryGroup.Name;
                    Name = $deliveryGroup.DisplayName;
                    EntitlementType = 'Desktop';
                    Credential = $domainCredential;
                    DependsOn = "[XD7DesktopGroup]DesktopGroup_$deliveryGroupName";
                }

            }
        
            if ($deliveryGroup.DeliveryType -in 'DesktopsAndApps','AppsOnly') {
                
                XD7EntitlementPolicy "$($deliveryGroupName)_ApplicationEntitlement" {
                    DeliveryGroup = $deliveryGroup.Name;
                    Name = $deliveryGroup.DisplayName;
                    EntitlementType = 'Application';
                    Credential = $domainCredential;
                    DependsOn = "[XD7DesktopGroup]DesktopGroup_$deliveryGroupName";
                }

            }

            XD7AccessPolicy "DesktopGroup_$($deliveryGroupName)_Direct" {
                DeliveryGroup = $deliveryGroup.Name;
                AccessType = 'Direct';
                Credential = $domainCredential;
                IncludeUsers = $deliveryGroup.Users;
                DependsOn = "[XD7DesktopGroup]DesktopGroup_$deliveryGroupName";
            }

            XD7AccessPolicy "DesktopGroup_$($deliveryGroupName)_AG" {
                DeliveryGroup = $deliveryGroup.Name;
                AccessType = 'AccessGateway';
                Credential = $Credential;
                IncludeUsers = $deliveryGroup.Users;
                DependsOn = "[XD7DesktopGroup]DesktopGroup_$deliveryGroupName";
            }

            foreach ($application in $deliveryGroup.Applications) {
            
                $applicationResourceId = $application.Name.Replace(' ','');
                XD7DesktopGroupApplication $applicationResourceId {
                    DesktopGroupName = $deliveryGroup.Name;
                    Name = $application.Name;
                    Path = $application.Path;
                    Description = $application.Description;
                    Credential = $domainCredential;
                }
            
            } #end foreach application

        } #end foreach Delivery Group

    } #end node XD7Controller

    node $AllNodes.Where({ $_.Role -contains 'XD7LicenseServer' }).NodeName {
        
        WindowsFeature RDSLicensing {
            Name = 'RDS-Licensing';
        }
        
        WindowsFeature RDSLicensingUI {
            Name = 'RDS-Licensing-UI';
        }
        
        XD7Feature 'XD7LicenseServer' {
            Role = 'Licensing';
            SourcePath = $Node.XenDesktopMediaPath;
        }

        File 'XDLicenseFile' {
            Type = 'File';
            SourcePath = $ConfigurationData.NonNodeData.XenDesktop.Site.LicenseFilePath;
            DestinationPath = "${env:ProgramFiles(x86)}\Citrix\Licensing\MyFiles";
        }

    } #end node XD7LicenseServer

    node $AllNodes.Where({ $_.Role -contains 'XD7StoreFront' }).NodeName {

        XD7Feature 'XDStorefront' {
            Role = 'Storefront';
            SourcePath = $Node.XenDesktopMediaPath;
        }

    } #end node XD7StoreFront

    node $AllNodes.Where({ $_.Role -contains 'XD7Director' }).NodeName {

        XD7Feature 'XDDirector' {
            Role = 'Director';
            SourcePath = $Node.XenDesktopMediaPath;
        }

        $deliveryController = ($AllNodes | Where { $_.Role -contains 'XD7Controller' } | Select -First 1).NodeName;
        xWebConfigKeyValue "ServiceAutoDiscovery_$deliveryController" {
            ConfigSection = 'AppSettings';
            Key = 'Service.AutoDiscoveryAddresses';
            Value = $deliveryController;
            IsAttribute = $false;
            WebsitePath = 'IIS:\Sites\Default Web Site\Director';
            DependsOn = '[XD7Feature]XDDirector';
        }
    } #end node XD7Director

    node $AllNodes.Where({ $_.Role -contains 'XD7SessionHost' }).NodeName {
        
        xPackage 'NotepadPlusPlus' {
            Name = 'Notepad++';
            ProductId = '';
            Path = 'C:\Resources\{0}' -f $ConfigurationData.NonNodeData.Lability.Resource.Where({ $_.Id -eq 'NotepadPlusPlus' }).Filename;
            Arguments = '/S';
            ReturnCode = 0;
            InstalledCheckRegKey = 'SOFTWARE\Notepad++';
        }

        XD7VDAFeature 'VDA' {
            Role = 'SessionVDA';
            SourcePath = $Node.XenDesktopMediaPath;
        }

        foreach ($controller in $AllNodes.Where({ $_.Role -contains 'XD7Controller' }).NodeName) {
            XD7VDAController 'VDAController' {
                Name = '{0}.{1}' -f $controller, $node.DomainName;       
                DependsOn = '[XD7VDAFeature]VDA';
            }
        }

    } #end node XD7SessionHost
    
} #end configuration VirtualExpo
