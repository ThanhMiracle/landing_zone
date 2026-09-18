[CmdletBinding()]
param(
  [string] $ResourceGroupName = "thanhproject-dev-rg",
  [string] $ClusterName = "thanhproject-dev-aks",
  [string] $KeyVaultName = "thanhproject-dev-kv",
  [string] $Namespace = "default"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required. Install it, sign in with 'az login', and run this script again."
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
  $kubectlDirectory = Join-Path $env:USERPROFILE ".azure-kubectl"
  if (Test-Path (Join-Path $kubectlDirectory "kubectl.exe")) {
    $env:Path = "$kubectlDirectory;$env:Path"
  } else {
    throw "kubectl is required. Run 'az aks install-cli' first."
  }
}

az aks get-credentials --resource-group $ResourceGroupName --name $ClusterName --overwrite-existing --only-show-errors
if ($LASTEXITCODE -ne 0) { throw "Unable to retrieve AKS credentials." }

$clientId = az aks show --resource-group $ResourceGroupName --name $ClusterName --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" --output tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($clientId)) {
  throw "The AKS Key Vault Secrets Provider add-on is not enabled or has no managed identity."
}

$tenantId = az account show --query tenantId --output tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($tenantId)) {
  throw "Unable to determine the Azure tenant ID."
}

az keyvault show --name $KeyVaultName --resource-group $ResourceGroupName --only-show-errors | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Key Vault '$KeyVaultName' was not found." }

$secretProviderClassName = "postgresql-connection-url"
$testPodName = "postgresql-connection-url-check"

$secretProviderClass = @"
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: $secretProviderClassName
  namespace: $Namespace
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "$clientId"
    keyvaultName: "$KeyVaultName"
    cloudName: ""
    objects: |
      array:
        - |
          objectName: postgresql-connection-url
          objectType: secret
    tenantId: "$tenantId"
"@

$testPod = @"
apiVersion: v1
kind: Pod
metadata:
  name: $testPodName
  namespace: $Namespace
spec:
  restartPolicy: Never
  containers:
    - name: check
      image: busybox:1.36
      command: ["sh", "-c", "test -s /mnt/secrets-store/postgresql-connection-url && echo mounted && sleep 3600"]
      volumeMounts:
        - name: secrets-store
          mountPath: /mnt/secrets-store
          readOnly: true
  volumes:
    - name: secrets-store
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: $secretProviderClassName
"@

$secretProviderClass | kubectl apply -f -
if ($LASTEXITCODE -ne 0) { throw "Unable to create the SecretProviderClass." }

kubectl delete pod $testPodName --namespace $Namespace --ignore-not-found | Out-Null
try {
  $testPod | kubectl apply -f -
  if ($LASTEXITCODE -ne 0) { throw "Unable to create the Key Vault verification pod." }

  kubectl wait --namespace $Namespace --for=condition=Ready "pod/$testPodName" --timeout=180s
  if ($LASTEXITCODE -ne 0) {
    kubectl describe pod $testPodName --namespace $Namespace
    throw "The verification pod did not become ready."
  }

  $mountStatus = kubectl exec --namespace $Namespace $testPodName -- test -s /mnt/secrets-store/postgresql-connection-url
  if ($LASTEXITCODE -ne 0) { throw "The PostgreSQL connection URL was not mounted from Key Vault." }

  Write-Host "Success: AKS mounted the postgresql-connection-url secret from Key Vault."
} finally {
  kubectl delete pod $testPodName --namespace $Namespace --ignore-not-found | Out-Null
}
