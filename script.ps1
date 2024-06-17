# Define your secrets and configurations
$FLEX_SERVER_NAME = "magento-mysql-ukah7zfaqeg42.mysql.database.azure.com"
$AZURE_STORAGE_ACCOUNT_NAME = "magentofsukah7zfaqeg42"
$AZURE_STORAGE_ACCOUNT_KEY = "vK+oTd2AlxG5WTWWSMGHb/owJmzgPeHpRo+K3Y7cw4U4hv9SnMZR9hsumED/+E8yYphUC3Dy+sq4+AStvoQadQ=="
$FLEX_SERVER_USER = "pooja"
$FLEX_SERVER_PASSWORD = "Pooja@1234"

# Base64 encode secrets
$FLEX_SERVER_NAME_ENCODED = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($FLEX_SERVER_NAME))
$AZURE_STORAGE_ACCOUNT_NAME_ENCODED = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($AZURE_STORAGE_ACCOUNT_NAME))
$AZURE_STORAGE_ACCOUNT_KEY_ENCODED = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($AZURE_STORAGE_ACCOUNT_KEY))
$FLEX_SERVER_USER_ENCODED = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($FLEX_SERVER_USER))
$FLEX_SERVER_PASSWORD_ENCODED = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($FLEX_SERVER_PASSWORD))

# Create YAML content for the secret
$secretYamlContent = @"
apiVersion: v1
kind: Secret
metadata:
  name: flex-server-credentials
type: Opaque
data:
  FLEX_SERVER_NAME: $FLEX_SERVER_NAME_ENCODED
  AZURE_STORAGE_ACCOUNT_NAME: $AZURE_STORAGE_ACCOUNT_NAME_ENCODED
  AZURE_STORAGE_ACCOUNT_KEY: $AZURE_STORAGE_ACCOUNT_KEY_ENCODED
  FLEX_SERVER_USER: $FLEX_SERVER_USER_ENCODED
  FLEX_SERVER_PASSWORD: $FLEX_SERVER_PASSWORD_ENCODED
"@

# Write the secret YAML content to a file
$secretYamlFilePath = "flex-server-credentials.yaml"
$secretYamlContent | Out-File -FilePath $secretYamlFilePath -Encoding utf8

# Apply the secret YAML file to create the secret in Kubernetes
kubectl apply -f $secretYamlFilePath

# Define other YAML configurations
$elasticSearchServiceYaml = @"
apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: C:\Kompose\kompose.exe convert
    kompose.version: 1.33.0 (3ce457399)
  labels:
    io.kompose.service: elasticsearch
  name: elasticsearch
spec:
  ports:
    - name: "9200"
      port: 9200
      targetPort: 9200
  selector:
    io.kompose.service: elasticsearch
"@

$elasticSearchDeploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    kompose.cmd: C:\Kompose\kompose.exe convert
    kompose.version: 1.33.0 (3ce457399)
  labels:
    io.kompose.service: elasticsearch
  name: elasticsearch
spec:
  replicas: 1
  selector:
    matchLabels:
      io.kompose.service: elasticsearch
  template:
    metadata:
      annotations:
        kompose.cmd: C:\Kompose\kompose.exe convert
        kompose.version: 1.33.0 (3ce457399)
      labels:
        io.kompose.network/6-compose-flexdb-magento-network: "true"
        io.kompose.service: elasticsearch
    spec:
      containers:
        - env:
            - name: discovery.type
              value: single-node
          image: docker.elastic.co/elasticsearch/elasticsearch:7.10.1
          name: elasticsearch
          ports:
            - containerPort: 9200
              hostPort: 9200
              protocol: TCP
      restartPolicy: Always
"@

$pvYaml = @"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: magento-pv
spec:
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteMany
  azureFile:
    secretName: azure-secret
    shareName: magento
    readOnly: false
  mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=1000
  - gid=1000
  - mfsymlinks
"@

$pvcYaml = @"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: magento-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile-csi
  resources:
    requests:
      storage: 2Gi
"@

$magentoJobSetupYaml = @"
apiVersion: batch/v1
kind: Job
metadata:
  name: magento-setup-job
  labels:
    io.kompose.service: magento-setup
spec:
  template:
    metadata:
      labels:
        io.kompose.service: magento-setup
    spec:
      containers:
      - name: magento-setup-upgrade
        image: poojaagarwal26/magento_pfs_install2:latest
        env:
        - name: MAGENTO_BASE_URL
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: MAGENTO_BASE_URL
        - name: NGINX_SERVER_NAME
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: NGINX_SERVER_NAME
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: FLEX_SERVER_NAME
        - name: DATABASE_USER
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: FLEX_SERVER_USER
        - name: DATABASE_PASSWORD
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: FLEX_SERVER_PASSWORD
        volumeMounts:
        - mountPath: /var/www/html/magento2/pub/media
          name: magento-media
      restartPolicy: OnFailure
      volumes:
      - name: magento-media
        persistentVolumeClaim:
          claimName: magento-pvc
"@

$magentoDeploymentYaml = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    kompose.cmd: C:\Kompose\kompose.exe convert
    kompose.version: 1.33.0 (3ce457399)
  labels:
    io.kompose.service: magento
  name: magento
spec:
  replicas: 1
  selector:
    matchLabels:
      io.kompose.service: magento
  template:
    metadata:
      annotations:
        kompose.cmd: C:\Kompose\kompose.exe convert
        kompose.version: 1.33.0 (3ce457399)
      labels:
        io.kompose.network/6-compose-flexdb-magento-network: "true"
        io.kompose.service: magento
    spec:
      containers:
      - image: poojaagarwal26/magento_pfs_runner3:latest
        name: magento
        ports:
        - containerPort: 8080
          hostPort: 8080
          protocol: TCP
        env:
        - name: MAGENTO_BASE_URL
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: MAGENTO_BASE_URL
        - name: NGINX_SERVER_NAME
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: NGINX_SERVER_NAME
        - name: DATABASE_HOST
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: FLEX_SERVER_NAME
        - name: DATABASE_USER
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: FLEX_SERVER_USER
        - name: DATABASE_PASSWORD
          valueFrom:
            configMapKeyRef:
              name: magento-config
              key: FLEX_SERVER_PASSWORD
        volumeMounts:
        - mountPath: /var/www/html/magento2/pub/media
          name: magento-media
      volumes:
      - name: magento-media
        persistentVolumeClaim:
          claimName: magento-pvc
"@

$magentoServiceYaml = @"
apiVersion: v1
kind: Service
metadata:
  annotations:
    kompose.cmd: C:\Kompose\kompose.exe convert
    kompose.version: 1.33.0 (3ce457399)
  labels:
    io.kompose.service: magento
  name: magento
spec:
  type: LoadBalancer
  ports:
    - name: "80"
      port: 80
      targetPort: 80
  selector:
    io.kompose.service: magento
"@

# Apply the YAML configurations in the correct order
$magentoServiceYaml | kubectl apply -f -
$elasticSearchDeploymentYaml | kubectl apply -f -
$elasticSearchServiceYaml | kubectl apply -f -

# Function to get the external IP of the service
function Get-ExternalIP {
    param (
        [string]$ServiceName
    )
    return (kubectl get service $ServiceName --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

# Retrieve the external IP for the Magento service
$externalIP = ""
while ([string]::IsNullOrEmpty($externalIP)) {
    Write-Output "Waiting for external IP..."
    $externalIP = Get-ExternalIP -ServiceName "magento"
    if ([string]::IsNullOrEmpty($externalIP)) {
        Start-Sleep -Seconds 10
    }
}

Write-Output "External IP found: $externalIP"
kubectl create secret generic azure-secret --from-literal=azurestorageaccountname=$AZURE_STORAGE_ACCOUNT_NAME --from-literal=azurestorageaccountkey=$AZURE_STORAGE_ACCOUNT_KEY 


# Create a configmap with the retrieved external IP and other configurations
kubectl create configmap magento-config --from-literal=MAGENTO_BASE_URL=http://$externalIP --from-literal=NGINX_SERVER_NAME=$externalIP --from-literal=FLEX_SERVER_NAME=$FLEX_SERVER_NAME --from-literal=FLEX_SERVER_USER=$FLEX_SERVER_USER --from-literal=FLEX_SERVER_PASSWORD=$FLEX_SERVER_PASSWORD

# Apply PV and PVC
$pvYaml | kubectl apply -f -
$pvcYaml | kubectl apply -f -

# Apply Magento setup job and wait for it to complete
$magentoJobSetupYaml | kubectl apply -f -

# Wait for Magento setup job to complete (approx 10 minutes)
Write-Output "Waiting for Magento setup to complete..."
Start-Sleep -Seconds 1000

# Apply Magento deployment
$magentoDeploymentYaml | kubectl apply -f -

Write-Output "Magento deployment completed."
