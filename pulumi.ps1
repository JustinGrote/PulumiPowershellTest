using namespace Pulumi.Azure
using namespace Pulumi.Azure.Core
using namespace Pulumi.Azure.Storage
#Prepare the libraries for easy pwsh import. The dotnet publish probably doesn't need to be done every time.
#TODO: Use the C# scopes libraries maybe?

#TODO:This could move into the C# Powershell Invoke initialization
if (-not (test-path pwsh/Infra.dll)) {
    & dotnet publish -o pwsh
}

#Don't load any DLLs already loaded. Fixes a bug in vscode where powershell editor services uses serilog which conflicts. THIS WORKS BUT IS NOT SAFE.
Add-Type -Path (gci "pwsh/*.dll" | where name -notin ([io.fileinfo[]][appdomain]::currentdomain.getassemblies().location).Name)

#Here is a base implementation of https://www.pulumi.com/docs/get-started/azure/review-project/ with multiple powershell styles

#region Style1-NewObjectSyntax
    #Description: Closest to the .NET example for purposes of adapting .NET examples

    #Create an Azure Resource Group
    $resourceGroup = New-Object ResourceGroup 'newObjectResourceGroup'

    #Create an Azure Storage Account
    $account = New-Object Account 'nostorage',(New-Object AccountArgs -Property @{
        ResourceGroupName = $resourceGroup.Name
        AccountTier = "Standard"
        AccountReplicationType = "LRS"
    })

    Clear-Variable resourcegroup,account
#endregion Style1-NewObjectSyntax



#region Style2-NewObjectExpanded
    #Description: More explicity defined and strongly typed to be more readable

    #Create an Azure Resource Group
    [ResourceGroup]$resourceGroup = New-Object -TypeName ResourceGroup -ArgumentList 'newObjectExpandedResourceGroup'

    #Create an Azure Storage Account
    [AccountArgs]$storageAccountArgs = New-Object -TypeName AccountArgs -Property @{
        ResourceGroupName = $resourceGroup.Name
        AccountTier = "Standard"
        AccountReplicationType = "LRS"
    }
    [Account]$account = New-Object -TypeName Account -ArgumentList 'noestorage',$storageAccountArgs

    Clear-Variable resourcegroup,storageaccountargs,account
#endregion Style2-NewObjectExpanded



#region Style3-NewStaticMethod
    #Description: Uses the PS5 ::new() syntax and property constructor for brevity

    #Create an Azure Resource Group
    $resourceGroup = [ResourceGroup]::new('PS5NewSyntaxResourceGroup', $null, $null)

    #Create an Azure Storage Account
    $account = [Account]::new('ps5nstorage', [AccountArgs]@{ResourceGroupName=$resourceGroup.Name;AccountTier='Standard';AccountReplicationType='LRS'}, $null)
    
    Clear-Variable resourcegroup,account
#endregion Style3-NewStaticMethod



#region Style4-NewStaticMethodExpanded
    #Description: Uses the PS5 ::new() syntax in a more expanded format with variable substitution

    #Create an Azure Resource Group
    $rgName = 'PS5NewSyntaxExpandedResourceGroup'
    $resourceGroupArgs = [ResourceGroupArgs]@{
        Location = 'westus2'
        Name = $rgName
    }
    $resourceGroup = [ResourceGroup]::new($rgName, $resourceGroupArgs, $null)

    #Create an Azure Storage Account
    $storageAccountName = 'ps5nestorage'
    $storageAccountArgs = [AccountArgs]@{
        ResourceGroupName = $resourceGroup.Name
        AccountTier = "Standard"
        AccountReplicationType = "LRS"
    }
    $account = [Account]::new($storageAccountName,$storageAccountArgs)

    Clear-Variable rgName,resourcegroupArgs,resourcegroup,account,storageaccountArgs,storageaccountname
#endregion Style4-NewStaticMethodExpanded



#region Style5-Cmdlets
    #Description: Construct some cmdlets that would behave like a powershell module and use them to instantiate the resources
    #NOTE: These are terrible examples of cmdlets, just done for brevity. Real ones would include whatif, validation, strong typing, etc.
    
    #Create an Azure Resource Group
    function New-PulumiAzResourceGroup {
        [CmdletBinding()]
        param(
            $Name
        )
        [ResourceGroup]::new($Name,$null,$null)
    }

    #Create an Azure Storage Account
    function New-PulumiAzStorageAccount {
        [CmdletBinding()]
        param(
            [String]$Name,
            [String]$AccountTier = 'Standard',
            [ValidateSet('LRS','GRS')][String]$AccountReplicationType = 'LRS',
            [Parameter(ValueFromPipeline)][ResourceGroup]$resourceGroup
        )
        $storageAccountArgs = [AccountArgs]@{
            ResourceGroupName = $resourceGroup.Name
            AccountTier = $AccountTier
            AccountReplicationType = $AccountReplicationType
        }
        [Account]::new($name,$storageAccountArgs)
    }

    #Here's where the magic happens
    $null = New-PulumiAzResourceGroup 'CmdletResourceGroup' | New-PulumiAzStorageAccount 'cmdletstorage'
#endregion Style5-Cmdlets

#region Style6-DSL
    #Use the cmdlets created above to make a DSL. Again, very bad examples with very little safety/sanity checks
    function ResourceGroup ([String]$Name) {
        New-PulumiAzResourceGroup $Name
    }
    function StorageAccount ([String]$Name,[hashtable]$Properties) {
        $ResourceGroup = $Properties.ResourceGroup
        New-PulumiAzStorageAccount -Name $Name -resourceGroup $ResourceGroup
    }

    #Here's where the magic happens
    $null = StorageAccount 'dslstorage' @{
        ResourceGroup = (ResourceGroup 'DSLResourceGroup')
    }


#endregion Style6-DSL
return @{}

#region Style7-Class
    #Make a powershell class that creates the resources when instantiated, useful as a "shortcut" or the equivalent of a terraform "module"
    #TODO: Write this
#endregion Style7-Class