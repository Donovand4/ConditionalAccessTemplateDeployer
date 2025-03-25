<#
#############################################################################  
#                                                                           #  
#   This Sample Code is provided for the purpose of illustration only       #  
#   and is not intended to be used in a production environment.  THIS       #  
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #  
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #  
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #  
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #  
#   right to use and modify the Sample Code and to reproduce and distribute #  
#   the object code form of the Sample Code, provided that You agree:       #  
#   (i) to not use Our name, logo, or trademarks to market Your software    #  
#   product in which the Sample Code is embedded; (ii) to include a valid   #  
#   copyright notice on Your software product in which the Sample Code is   #  
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #  
#   Our suppliers from and against any claims or lawsuits, including        #  
#   attorneys' fees, that arise or result from the use or distribution      #  
#   of the Sample Code.                                                     # 
#                                                                           # 
#   This posting is provided "AS IS" with no warranties, and confers        # 
#   no rights. Use of included script samples are subject to the terms      # 
#   specified at http://www.microsoft.com/info/cpyright.htm.                # 
#                                                                           #  
#   Author: Donovan du Val                                                  #  
#   Version 1.0         Date Last Modified: 25 March 2025                   #  
#                                                                           #  
#############################################################################  
.SYNOPSIS
    Deploys a Conditional Access Policy Template in Microsoft Graph.
.DESCRIPTION
    This script allows the user to select a Conditional Access Policy Template from a list and deploy it in Microsoft Graph. The user can also choose to deploy all templates or specify a custom name for the policy.
    The script connects to Microsoft Graph, retrieves the available templates, and prompts the user for their selection. It then creates a new Conditional Access Policy based on the selected template and specified naming convention.
    The script also handles errors and provides feedback on the deployment status.
.PARAMETER TenantID
    The Tenant ID of the Azure AD tenant where the Conditional Access Policy will be deployed.
.PARAMETER Status
    The status of the Conditional Access Policy. Possible values are "enabledForReportingButNotEnforced", "enabled", or "disabled". Default is "enabledForReportingButNotEnforced".
.EXAMPLE
    Deploy-ConditionalAccessTemplates.ps1 -TenantID "TenantID" -Status "enabled"
    This example deploys a Conditional Access Policy Template in the specified tenant with the status set to "enabled".
.EXAMPLE
    Deploy-ConditionalAccessTemplates.ps1 -TenantID "TenantID"
    This example deploys a Conditional Access Policy Template in the specified tenant with the default status "enabledForReportingButNotEnforced".
.LINK
    https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicytemplate?view=graph-rest-1.0
    https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccesspolicy?view=graph-rest-1.0
    https://www.powershellgallery.com/packages/Microsoft.Graph
    https://github.com/microsoftgraph/msgraph-sdk-powershell
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory, Position = 0)]
    [string] $TenantID,
    [Parameter(Position = 1)]
    [ValidateSet("enabledForReportingButNotEnforced", "enabled", "disabled")]
    [string] $Status = "EnabledForReportingButNotEnforced"
)
#Requires -Modules @{ ModuleName = "Microsoft.Graph.Authentication"; ModuleVersion = "2.25.0" }
#Requires -Modules @{ ModuleName = "Microsoft.Graph.Identity.SignIns"; ModuleVersion = "2.25.0" }

Begin {
    #function to display a menu and get user selection
    function Show-Menu {
        param (
            [string]$Title,
            [string[]]$Options
        )
        Write-Host " "
        Write-Host $Title
        Write-Host "-----------------------------"
        for ($i = 0; $i -lt $Options.Count; $i++) {
            Write-Host "$($i + 1): $($Options[$i])"
        }
        Write-Host " "
        $OutputValue = Read-Host "Please select an option (1-$($Options.Count)) or 'q' to quit: "
        Write-Host " "

        if ($OutputValue -eq "q") {
            Write-Host "Exiting..."
            exit
        }

        if ($OutputValue -gt 0 -or $OutputValue -le $Options.Count) {
            return $Options[$OutputValue - 1]
        }

        else {
            Write-Host " "
            Write-Host "Invalid selection. Please try again."
            return Show-Menu -Title $Title -Options $Options
        }
    }

    #function to get the selected template ID based on the template name
    function Get-SelectedTemplateID {
        param (
            [string]$TemplateName
        )
        $selectedTemplate = $AllCATemplates | Where-Object { $_.Name -eq $TemplateName }
        return $selectedTemplate.id
    }

    try {
        # Connect to Microsoft Graph with the specified tenant ID and required permissions
        Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Application.Read.All" -TenantId $TenantID -NoWelcome
    }
    catch {
        Write-Host 'Login Failed. Exiting.......' -ForegroundColor Red
        Start-Sleep -Seconds 2
        Exit
    }
}
process {
    # get all the CA templates
    $AllCATemplates = Get-MgIdentityConditionalAccessTemplate -All | sort-object -Property Name

    # build menu options and present menu to select the CA template or deploy all templates
    $menuOptions = $AllCATemplates.Name 
    $menuOptions += "Deploy All Templates"

    $selectedTemplateName = Show-Menu -Title "Available Conditional Access Policy Templates" -Options $menuOptions

    # Get the selected template name
    if ($selectedTemplateName -eq "Deploy All Templates") {
        # If "Deploy All Templates" is selected, set the template ID to null or handle accordingly
        foreach ($template in $AllCATemplates) {
            # Deploy each template
            $PolicyDeployment = New-MgIdentityConditionalAccessPolicy -TemplateId $template.id -DisplayName "$($template.Name)" -State "$($Status)"
            if ($null -ne $PolicyDeployment.Id) {
                Write-Host "Policy Deployment created successfully with name: Template Deployment - $($template.id) - $($template.Name)"
            }
            else {
                Write-Host "Failed to create Policy Deployment for template: $($template.Name)."
            }
        }
    }
    else {
        # Get the template ID based on the selected template name
        $TemplateID = Get-SelectedTemplateID -TemplateName $selectedTemplateName
        if ($null -ne $TemplateID) {
            # Deploy the selected template
            write-host "The selected policy for deployment is: $selectedTemplateName"
            write-host ""

            ## show new menu to select the naming convention
            $NamingConventionResponse = Show-Menu -Title "Select Naming Convention" -Options @("Use Template Name", "Use Custom Name")

            if ($NamingConventionResponse -eq "Use Template Name") {
            
                $PolicyDeployment = New-MgIdentityConditionalAccessPolicy -TemplateId $TemplateID -DisplayName "$selectedTemplateName" -State "$($Status)"
            
                if ($null -ne $PolicyDeployment.Id) {
                    Write-Host "Policy Deployment created successfully with name: $($selectedTemplateName)"
                }
                else {
                    Write-Host "Failed to create Policy Deployment for template: $($selectedTemplateName)"
                    Write-Host "$($Error[0].Exception.message)"
                }
            }
            elseif ($NamingConventionResponse -eq "Use Custom Name") {
                # If "Use Custom Name" is selected, prompt for a custom name
                $PolicyName = Read-Host "Enter a custom name for the policy"
                if ($null -ne $PolicyName) {

                    $PolicyDeployment = New-MgIdentityConditionalAccessPolicy -TemplateId $TemplateID -DisplayName "$($PolicyName)" -State "$($Status)"

                    if ($null -ne $PolicyDeployment.Id) {
                        Write-Host "Policy Deployment created successfully with name: $($PolicyName)"
                    }
                    else {
                        Write-Host "Failed to create Policy Deployment for template: $($selectedTemplateName)"
                        Write-Host "$($Error[0].Exception.message)"
                    }
                }
                else {
                    Write-Host "No custom name provided. Skipping deployment."
                }
            }

        }
        else {
            Write-Host "Invalid template selection."
        }
    }
}
end {
    # Disconnect from Microsoft Graph
    write-host " "
    Write-Host 'Disconnecting from Microsoft Graph' -ForegroundColor Green
    Disconnect-MgGraph
}
