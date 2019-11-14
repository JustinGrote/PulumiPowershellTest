using namespace Pulumi.Azure
using namespace Pulumi.Azure.Core
using namespace Pulumi.Azure.Storage
using namespace Pulumi.Azure.AppService;
using namespace Pulumi.Azure.AppService.Inputs;
#Prepare the libraries for easy pwsh import. The dotnet publish probably doesn't need to be done every time.
#TODO: Use the C# scopes libraries maybe?

#TODO:This could move into the C# Powershell Invoke initialization
if (-not (test-path pwsh/Infra.dll)) {
    & dotnet publish -o pwsh
}

#Don't load any DLLs already loaded. Fixes a bug in vscode where powershell editor services uses serilog which conflicts. THIS WORKS BUT IS NOT SAFE.
Add-Type -Path (gci "pwsh/*.dll" | where name -notin ([io.fileinfo[]][appdomain]::currentdomain.getassemblies().location).Name)


$Name = 'myTestFuncApp'
$resourceGroup = [ResourceGroup]::new($Name)

$functionApp = [FunctionApp]::new($Name, @{
    ResourceGroupName = $resourceGroup.Name
    StorageConnectionString = [Account]::new($Name,@{
        ResourceGroupName      = $resourceGroup.Name
        AccountReplicationType = 'LRS'
        AccountTier            = "Standard"
    }).PrimaryConnectionString
    AppServicePlanId = [Plan]::new($Name,@{
        ResourceGroupName = $resourceGroup.Name
        Kind = 'FunctionApp'
        Sku = [PlanSkuArgs]@{
            Tier = 'Dynamic'
            Size = 'Y1'
        }
        
    }).Id
})

return @{}
