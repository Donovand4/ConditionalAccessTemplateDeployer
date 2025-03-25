# Description
  This script allows the user to select a Conditional Access Policy Template from a list and deploy it in Microsoft Graph. The user can also choose to deploy all templates or specify a custom name for the policy.
    The script connects to Microsoft Graph, retrieves the available templates, and prompts the user for their selection. It then creates a new Conditional Access Policy based on the selected template and specified naming convention.
    The script also handles errors and provides feedback on the deployment status.
    
Below is an example of the templates that are available from a tenant that will be available for the tool.

![image](https://github.com/user-attachments/assets/fa78ee0c-748a-4a48-83a8-8d460c7d9762)

# Examples
  Deploy-ConditionalAccessTemplates.ps1 -TenantID "TenantID" -Status "enabled"  
This example deploys a Conditional Access Policy Template in the specified tenant with the status set to "enabled".

  Deploy-ConditionalAccessTemplates.ps1 -TenantID "TenantID"  
This example deploys a Conditional Access Policy Template in the specified tenant with the default status "enabledForReportingButNotEnforced".

# Links
- https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicytemplate?view=graph-rest-1.0
- https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy?view=graph-rest-1.0
- https://www.powershellgallery.com/packages/Microsoft.Graph
- https://github.com/microsoftgraph/msgraph-sdk-powershell

