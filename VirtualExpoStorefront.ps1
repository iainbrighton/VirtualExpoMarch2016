<# Virtual Expo lab base build/configuration #>

## TODO: Add 'https://storefront.lab.local' to Trusted Sites

configuration VirtualExpoStorefront {
 
    Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName Storefront;

    node $AllNodes.Where({ $_.Role -contains 'XD7Storefront' }).NodeName {
        
        $baseUrl = $ConfigurationData.NonNodeData.XenDesktop.Storefront.BaseUrl;
        $prefix = $baseUrl.Replace('/','').Replace(':','');

        SFCluster "$($prefix)Group" {
            BaseUrl = $baseUrl;
        }

        SFAuthenticationService "$($prefix)Authentication" {
            VirtualPath = $ConfigurationData.NonNodeData.XenDesktop.Storefront.AuthenticationVirtualPath;
            DependsOn = "[SFCluster]$($prefix)Group";
        }

        SFStore "$($prefix)Store" {
            VirtualPath = $ConfigurationData.NonNodeData.XenDesktop.Storefront.StoreVirtualPath;
            AuthenticationServiceVirtualPath = $ConfigurationData.NonNodeData.XenDesktop.Storefront.AuthenticationVirtualPath;
            DependsOn = "[SFAuthenticationService]$($prefix)Authentication";
        }

        SFStoreWebReceiver "$($prefix)WebReceiver" {
            StoreVirtualPath = $ConfigurationData.NonNodeData.XenDesktop.Storefront.StoreVirtualPath;
            DependsOn = "[SFStore]$($prefix)Store";
        }

        $deliveryControllers = @();
        foreach ($deliveryController in ($AllNodes | Where { $_.Role -eq 'XD7Controller' }).NodeName) {
            $deliveryControllers += '{0}.{1}' -f $deliveryController, $node.DomainName;
        }

        SFStoreFarm "$($prefix)Farm" {
            StoreVirtualPath = $ConfigurationData.NonNodeData.XenDesktop.Storefront.StoreVirtualPath;
            FarmName = $ConfigurationData.NonNodeData.XenDesktop.Site.Name;
            FarmType = 'XenDesktop';
            Servers = $deliveryControllers;
        }

    } #end node Storefront
    
} #end configuration VirtualExpoStorefront
