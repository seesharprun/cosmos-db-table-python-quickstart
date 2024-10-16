targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention.')
param environmentName string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Id of the principal to assign database and application roles.')
param principalId string = ''

// Optional parameters
param cosmosDbAccountName string = ''
param containerRegistryName string = ''
param containerAppsEnvName string = ''
param containerAppsAppName string = ''

// serviceName is used as value for the tag (azd-service-name) azd uses to identify deployment host
param serviceName string = 'web'

var abbreviations = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  repo: 'https://github.com/azure-samples/cosmos-db-table-python-quickstart'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: environmentName
  location: location
  tags: tags
}

module database 'app/database.bicep' = {
  name: 'database'
  scope: resourceGroup
  params: {
    accountName: !empty(cosmosDbAccountName) ? cosmosDbAccountName : '${abbreviations.cosmosDbAccount}-${resourceToken}'
    location: location
    tags: tags
  }
}

module data 'app/data.bicep' = {
  name: 'data'
  scope: resourceGroup
  params: {
    databaseAccountName: database.outputs.accountName
    tags: tags
  }
}

module registry 'app/registry.bicep' = {
  name: 'registry'
  scope: resourceGroup
  params: {
    registryName: !empty(containerRegistryName) ? containerRegistryName : '${abbreviations.containerRegistry}${resourceToken}'
    location: location
    tags: tags
  }
}

module web 'app/web.bicep' = {
  name: serviceName
  scope: resourceGroup
  params: {
    envName: !empty(containerAppsEnvName) ? containerAppsEnvName : '${abbreviations.containerAppsEnv}-${resourceToken}'
    appName: !empty(containerAppsAppName) ? containerAppsAppName : '${abbreviations.containerAppsApp}-${resourceToken}'
    databaseAccountEndpoint: database.outputs.endpoint
    databaseTableName: data.outputs.table.name
    location: location
    tags: tags
    serviceTag: serviceName
  }
}

module security 'app/security.bicep' = {
  name: 'security'
  scope: resourceGroup
  params: {
    databaseAccountName: database.outputs.accountName
    appPrincipalId: web.outputs.systemAssignedManagedIdentityPrincipalId
    userPrincipalId: !empty(principalId) ? principalId : null
  }
}

// Database outputs
output AZURE_COSMOS_DB_TABLE_ENDPOINT string = database.outputs.endpoint
output AZURE_COSMOS_DB_TABLE_NAME string = data.outputs.table.name

// Container outputs
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = registry.outputs.endpoint
output AZURE_CONTAINER_REGISTRY_NAME string = registry.outputs.name

// Application outputs
output AZURE_CONTAINER_APP_ENDPOINT string = web.outputs.endpoint
output AZURE_CONTAINER_ENVIRONMENT_NAME string = web.outputs.envName

// Security outputs
output AZURE_TABLE_ROLE_DEFINITION_ID string = security.outputs.roleDefinitions.table
