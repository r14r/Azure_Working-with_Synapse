$InformationPreference = "Continue"

# These need to be run only if the Az modules are not yet installed
# Install-Module -Name Az -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.CosmosDB -AllowClobber -Scope CurrentUser
# Import-Module Az.CosmosDB

#
# TODO: Keep all required configuration in C:\LabFiles\AzureCreds.ps1 file
$IsCloudLabs = Test-Path C:\LabFiles\AzureCreds.ps1;
$iscloudlabs = $false;

if($IsCloudLabs){
        Remove-Module solliance-synapse-automation
        Import-Module ".\artifacts\environment-setup\solliance-synapse-automation"

        . C:\LabFiles\AzureCreds.ps1

        $userName = $AzureUserName                # READ FROM FILE
        $password = $AzurePassword                # READ FROM FILE
        $clientId = $TokenGeneratorClientId       # READ FROM FILE
        $global:sqlPassword = $AzureSQLPassword          # READ FROM FILE

        $securePassword = $password | ConvertTo-SecureString -AsPlainText -Force
        $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $userName, $SecurePassword
        
        Connect-AzAccount -Credential $cred | Out-Null

        $ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
        $global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
        $global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
        $global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"
        $global:ropcBodyPowerBI = "$($ropcBodyCore)&scope=https://analysis.windows.net/powerbi/api/.default"

        $templatesPath = ".\artifacts\environment-setup\templates"
        $datasetsPath = ".\artifacts\environment-setup\datasets"
        $dataflowsPath = ".\artifacts\environment-setup\dataflows"
        $pipelinesPath = ".\artifacts\environment-setup\pipelines"
        $sqlScriptsPath = ".\artifacts\environment-setup\sql"
} else {
        if(Get-Module -Name solliance-synapse-automation){
                Remove-Module solliance-synapse-automation
        }
        Import-Module "..\solliance-synapse-automation"

        #Different approach to run automation in Cloud Shell
        $subs = Get-AzSubscription | Select-Object -ExpandProperty Name
        if($subs.GetType().IsArray -and $subs.length -gt 1){
                $subOptions = [System.Collections.ArrayList]::new()
                for($subIdx=0; $subIdx -lt $subs.length; $subIdx++){
                        $opt = New-Object System.Management.Automation.Host.ChoiceDescription "$($subs[$subIdx])", "Selects the $($subs[$subIdx]) subscription."   
                        $subOptions.Add($opt)
                }
                $selectedSubIdx = $host.ui.PromptForChoice('Enter the desired Azure Subscription for this lab','Copy and paste the name of the subscription to make your choice.', $subOptions.ToArray(),0)
                $selectedSubName = $subs[$selectedSubIdx]
                Write-Information "Selecting the $selectedSubName subscription"
                Select-AzSubscription -SubscriptionName $selectedSubName
        }
        
        $userName = ((az ad signed-in-user show) | ConvertFrom-JSON).UserPrincipalName
        $global:sqlPassword = Read-Host -Prompt "Enter the SQL Administrator password you used in the deployment" -AsSecureString
        $global:sqlPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($sqlPassword))

        $reportsPath = "..\reports"
        $templatesPath = "..\templates"
        $datasetsPath = "..\datasets"
        $dataflowsPath = "..\dataflows"
        $pipelinesPath = "..\pipelines"
        $sqlScriptsPath = "..\sql"
}

$resourceGroupName = (Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "*L400*" }).ResourceGroupName
$uniqueId =  (Get-AzResourceGroup -Name $resourceGroupName).Tags["DeploymentId"]
$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

$workspaceName = "asaworkspace$($uniqueId)"
$cosmosDbAccountName = "asacosmosdb$($uniqueId)"
$cosmosDbDatabase = "CustomerProfile"
$cosmosDbContainer = "OnlineUserProfile01"
$dataLakeAccountName = "asadatalake$($uniqueId)"
$blobStorageAccountName = "asastore$($uniqueId)"
$keyVaultName = "asakeyvault$($uniqueId)"
$keyVaultSQLUserSecretName = "SQL-USER-ASA"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$sparkPoolName = "SparkPool01"
$amlWorkspaceName = "amlworkspace$($uniqueId)"
$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asa.sql.admin"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

Write-Information "Start the $($sqlPoolName) SQL pool if needed."

$result = Get-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($result.properties.status -ne "Online") {
    Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action resume
    Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Online
}

Write-Information "Create wwi_poc schema in $($sqlPoolName)"

$params = @{}
$result = Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName "16-create-poc-schema" -Parameters $params
$result


Write-Information "Create tables in wwi_poc schema in SQL pool $($sqlPoolName)"

$params = @{}
$scripts = [ordered]@{
        "17-create-wwi-poc-sale-heap" = "CTAS : wwi_poc.Sale"
}

foreach ($script in $scripts.Keys) {

        $refTime = (Get-Date).ToUniversalTime()
        Write-Information "Starting $($script) with label $($scripts[$script])"
        
        # initiate the script and wait until it finishes
        Execute-SQLScriptFile -SQLScriptsPath $sqlScriptsPath -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -FileName $script
        #Wait-ForSQLQuery -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Label $scripts[$script] -ReferenceTime $refTime
}


Write-Information "Create data sets for PoC data load in SQL pool $($sqlPoolName)"

$loadingDatasets = @{
        wwi02_poc_customer_adls = $dataLakeAccountName
        wwi02_poc_customer_asa = $sqlPoolName.ToLower()
}

foreach ($dataset in $loadingDatasets.Keys) {
        Write-Information "Creating dataset $($dataset)"
        $result = Create-Dataset -DatasetsPath $datasetsPath -WorkspaceName $workspaceName -Name $dataset -LinkedServiceName $loadingDatasets[$dataset]
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}

Write-Information "Create pipeline to load PoC data into the SQL pool"

$params = @{
        BLOB_STORAGE_LINKED_SERVICE_NAME = $blobStorageAccountName
}
$loadingPipelineName = "Setup - Load SQL Pool"
$fileName = "import_poc_customer_data"

Write-Information "Creating pipeline $($loadingPipelineName)"

$result = Create-Pipeline -PipelinesPath $pipelinesPath -WorkspaceName $workspaceName -Name $loadingPipelineName -FileName $fileName -Parameters $params
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

Write-Information "Running pipeline $($loadingPipelineName)"

$result = Run-Pipeline -WorkspaceName $workspaceName -Name $loadingPipelineName
$result = Wait-ForPipelineRun -WorkspaceName $workspaceName -RunId $result.runId
$result

Write-Information "Deleting pipeline $($loadingPipelineName)"

$result = Delete-ASAObject -WorkspaceName $workspaceName -Category "pipelines" -Name $loadingPipelineName
Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId

foreach ($dataset in $loadingDatasets.Keys) {
        Write-Information "Deleting dataset $($dataset)"
        $result = Delete-ASAObject -WorkspaceName $workspaceName -Category "datasets" -Name $dataset
        Wait-ForOperation -WorkspaceName $workspaceName -OperationId $result.operationId
}


#Write-Information "Pause the $($sqlPoolName) SQL pool to DW500c after PoC import."
#
#Control-SQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action pause
#Wait-ForSQLPool -SubscriptionId $subscriptionId -ResourceGroupName $resourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -TargetStatus Paused