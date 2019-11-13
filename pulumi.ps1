using namespace Pulumi.Azure.Core
#Prepare the libraries for easy pwsh import. The dotnet publish probably doesn't need to be done every time.
#TODO: Use the C# scopes libraries maybe?

#TODO:This could move into the C# Powershell Invoke initialization
if (-not (test-path pwsh/Infra.dll)) {
    & dotnet publish -o pwsh
}
add-type -path "./pwsh/*.dll"

#Create 3 resource groups, just to show off using Powershell constructs
$outputs = @{}
1..3 | foreach {
    $rgName = "PulumiPSTestGroup$PSItem"
    $resourceGroupArgs = [ResourceGroupArgs]@{
        Location = 'westus2'
        Name = $rgName
    }
    $resourceGroup = [ResourceGroup]::new($rgName, $resourceGroupArgs, $null)
    $outputs."resourceGroup${psItem}Name" = $resourceGroup.Name
    $outputs."resourceGroup${psItem}Location" = $resourceGroup.Location
}
return $outputs