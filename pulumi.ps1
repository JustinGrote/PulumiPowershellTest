using namespace Pulumi
using namespace Pulumi.Azure.Core
#Prepare the libraries for easy pwsh consumptions. The dotnet publish probably doesn't need to be done every time.
#& dotnet publish -o pwsh
add-type -path "./pwsh/*.dll"

# NOTE: This currently fails with 
$resourceGroup = [ResourceGroup]::new('test', $null, $null)

$outputs = @{}
Get-ChildItem env: | where name -like 'PULUMI_*' | foreach {
    $outputs[$PSItem.Name] = $PSItem.Value
}

$pulumiInstance = [Pulumi.Deployment]::Instance
$Outputs.Instance_StackName = $pulumiInstance.stackName
$Outputs.Instance_ProjectName = $pulumiInstance.projectname
$Outputs.Instance_IsDryRun = $pulumiInstance.isDryRun
return $outputs