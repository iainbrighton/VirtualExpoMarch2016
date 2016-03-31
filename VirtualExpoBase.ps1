<# Virtual Expo lab base build/configuration #>
configuration VirtualExpoBase {
    param (
        [Parameter()] [ValidateNotNull()] [PSCredential] $Credential = (Get-Credential -Username 'Administrator' -Message 'Enter Domain administrator username/password.')
    )
    Import-DscResource -ModuleNam PSDesiredStateConfiguration;
    Import-DscResource -ModuleNam xActiveDirectory;
    Import-DscResource -ModuleNam xDnsServer;
    Import-DscResource -ModuleNam xCertificate;
    Import-DscResource -ModuleNam VirtualEngineLab;
        
    node $AllNodes.NodeName {

        LocalConfigurationManager {
            RebootNodeIfNeeded = $true;
            ActionAfterReboot = 'ContinueConfiguration';
            ConfigurationMode = 'ApplyOnly';
            AllowModuleOverwrite = $true;
            DebugMode = 'ForceModuleImport';
            CertificateID = $node.Thumbprint;
        }

        vICMP 'EnableICMP' {
            IPv4 = $true;
            IPv6 = $true;
        }

        vRemoteDesktopAdmin 'EnableRDP' {
            EnableFirewallException = $true;
        }

        vServerManager 'ServerManager' {
            Enable = $false;
        }

    } #end node AllNodes

    node ($AllNodes | Where { $_.Role -contains 'DC' } | Select -First 1).NodeName {
        
        vWorkgroupMember 'WorkgroupMember' {
            ComputerName = $node.NodeName;
            IPAddress = $node.IPAddress;
            DefaultGateway = $node.DefaultGateway;
            DnsServer = $node.DnsServerAddress;
        }

        vADDomain 'ADDomain' {
           DomainName = $node.DomainName;
           Credential = $Credential;
           IncludeManagementTools = $true;
           DependsOn = '[vWorkgroupMember]WorkgroupMember';
        }

        $ipQuartets = $node.IPAddress.Split('.');
        xDnsServerPrimaryZone 'ReverseLookup' {
            Name = '{0}.{1}.{2}.in-addr.arpa' -f $ipQuartets[2], $ipQuartets[1], $ipQuartets[0];
            DynamicUpdate = 'NonsecureAndSecure';
        }

        xADUser 'XenDesktopAdmin' { 
            DomainName = $node.DomainName;
            DomainAdministratorCredential = $credential;
            UserName = 'XDA';
            GivenName = 'XenDesktop';
            Surname = 'Admin';
            Description = 'Citrix XenDesktop Administrator account';
            Password = $Credential;
            Ensure = 'Present';
            DependsOn = '[vADDomain]ADDomain';
        }

        xADGroup 'XenDesktopAdmins' {
            GroupName = 'XenDesktop Admins';
            Description = 'Citrix XenDesktop Administrators';
            Members = 'XDA';
            DependsOn = '[xADUser]XenDesktopAdmin'
        }

        xADUser 'XenDesktopUser' { 
            DomainName = $node.DomainName;
            DomainAdministratorCredential = $credential;
            UserName = 'XDU';
            GivenName = 'XenDesktop';
            Surname = 'User';
            Description = 'Citrix XenDesktop test user account';
            Password = $Credential;
            Ensure = 'Present';
            DependsOn = '[vADDomain]ADDomain';
        }

        vRemoteAssistance 'RemoteAssistance' {
            EnableFirewallException = $true;
            Ensure = 'Present';
        }

        vCitrixReceiver 'CitrixReceiver' {
            Path = 'C:\Resources\{0}' -f $ConfigurationData.NonNodeData.Lability.Resource.Where({ $_.Id -eq 'CitrixReceiver' }).Filename;
        }

    } #end node Primary Domain Controller

    node ($AllNodes | Where { $_.Role -contains 'DC' } | Select -Skip 1).NodeName {
        
        ## Create DOMAIN\UserName credential
        $netBIOSUsername = '{0}\{1}' -f $node.NetBIOSDomainName, $Credential.UserName;
        $domainCredential = New-Object System.Management.Automation.PSCredential($netBIOSUsername, $Credential.Password);
        
        vWorkgroupMember 'WorkgroupMember' {
            ComputerName = $node.NodeName;
            IPAddress = $node.IPAddress;
            DefaultGateway = $node.DefaultGateway;
            DnsServer = $node.DnsServerAddress;
        }
    
        vADDomainController 'ADDomain' {
            DomainName = $node.DomainName;
            Credential = $Credential;
            IncludeManagementTools = $true;
            DependsOn = '[vWorkgroupMember]WorkgroupMember';
        }
    
    }  #end node Secondary Domain Controller
    
    node $AllNodes.Where({ $_.Role -notcontains 'DC' }).NodeName {

        ## Create DOMAIN\UserName credential
        $netBIOSUsername = '{0}\{1}' -f $node.NetBIOSDomainName, $Credential.UserName;
        $domainCredential = New-Object System.Management.Automation.PSCredential($netBIOSUsername, $Credential.Password);

        vDomainMember 'DomainMember' {
            ComputerName = $node.NodeName;
            DomainName = $node.DomainName;
            Credential = $domainCredential;
            IPAddress = $node.IPAddress;
            DefaultGateway = $node.DefaultGateway;
            DnsServer = $node.DnsServerAddress;
        }

        Group 'LocalAdmins' {
            GroupName = 'Administrators';
            Credential = $domainCredential;
            MembersToInclude = "$($node.NetBIOSDomainName)\XenDesktop Admins";
            DependsOn = '[vDomainMember]DomainMember';
        }

    } #end node Non Domain Controller

    node $AllNodes.Where({ $_.Role -contains 'SQL' }).NodeName {
        
        vSQLExpress 'SQL2014Express' {
           Path = "C:\Resources\SQLEXPRWT_x64_ENU\Setup.exe";
           SAPassword = $Credential;
           DependsOn = '[vDomainMember]DomainMember';
       }

    } #end node SQL

    node $AllNodes.Where({ $_.Role -contains 'XD7Controller' }).NodeName {

        $pfxCredentialPassword = ConvertTo-SecureString -String $node.PfxCertificatePassword -AsPlainText -Force;
        
        xPfxImport 'PfxCertificate' {
            Thumbprint = $node.PfxCertificateThumbprint;
            Location = 'LocalMachine';
            Store = 'My';
            Path = $node.PfxCertificatePath;
            Credential = New-Object System.Management.Automation.PSCredential('Pfx', $pfxCredentialPassword);
        }

    } #end node XD7Controller

    node $AllNodes.Where({ $_.Role -contains 'XD7LicenseServer' }).NodeName {
        
        vRemoteDesktopLicensing 'RDSLicensing' {
            InstallRDSLicensingUI = $true;
        }

    } #end node XD7LicenseServer

    node $AllNodes.Where({ $_.Role -contains 'XD7StoreFront' }).NodeName {

        $pfxCredentialPassword = ConvertTo-SecureString -String $node.PfxCertificatePassword -AsPlainText -Force;
        
        vWebServerHttps 'HttpsWebServer' {
            PfxCertificatePath = $node.PfxCertificatePath;
            PfxCertificateThumbprint = $node.PfxCertificateThumbprint;
            PfxCertificateCredential = New-Object System.Management.Automation.PSCredential('Pfx', $pfxCredentialPassword);
        }

    } #end node XD7StoreFront

    node $AllNodes.Where({ $_.Role -contains 'XD7SessionHost' }).NodeName {

        $rdsLicenseServer = '{0}.{1}' -f ($AllNodes.Where({ $_.Role -eq 'XD7LicenseServer' }).NodeName | Select -First 1), $node.DomainName;
        vRemoteDesktopSessionHost 'RDSSessionHost' {
            RDSLicenseServer = $rdsLicenseServer;
        }

    } #end node XD7SessionHost
    
} #end configuration VirtualExpoBase
