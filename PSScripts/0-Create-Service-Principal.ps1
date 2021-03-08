          $CustomerPrefix = "ucorp"
          
          # Needed for AZURE_CREDENTIALS 
          $sp = New-AzADServicePrincipal -DisplayName "$CustomerPrefix-wvd-sp"
          $clientsec = [System.Net.NetworkCredential]::new("", $sp.Secret).Password
          $tenantID = (get-aztenant).Id
          $jsonresp = 
          @{client_id=$sp.ApplicationId 
              client_secret=$clientsec
              tenant_id=$tenantID
              activeDirectoryEndpointUrl="https://login.microsoftonline.com"
              resourceManagerEndpointUrl="https://management.azure.com/"
              activeDirectoryGraphResourceID="https://graph.windows.net/"
              sqlManagementEdnpointUrl="https://management.core.windows.net:8443/"
              galleryEndpointUrl="https://gallery.azure.com/"
              managementEndpointUrl="https://management.core.windows.net/"}
          $jsonresp | ConvertTo-Json
