## MLOps with Azure DevOps and Azure Machine Learning

# 准备工作
-  DevOps Repo 建立与AML workspace的连接
https://learn.microsoft.com/zh-cn/azure/machine-learning/how-to-devops-machine-learning?view=azureml-api-2&tabs=arm#step-3-create-a-service-connection
- DevOps Agent 安装 az cli
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```
有问题参考 https://learn.microsoft.com/zh-cn/cli/azure/install-azure-cli-linux?pivots=apt
- 创建环境
```bash
cd src
az ml environment create --file ./env/basic-env.yml -g <ResourceGroup> -w <WorkspaceName>
```

# 场景一、 Azure DevOps Pipeline 启动 AML 本地Job
### Pipeline 文件 [./start-basic-job.yml](./start-basic-job.yml)
- 调用启动AML Job的template [./src/start-aml-job.yml](./src/start-aml-job.yml) , 主要引用了到AML的服务连接权限，然后通过下面命令启动AML Job
```bash
az ml job create --file basic_job.yml --resource-group <ResourceGroup> --workspace-name <WorkspaceName>
```
- 具体Job 定义文件 [./src/basic_job.yml](./src/basic_job.yml), python 代码在[./src/job](./src/job)目录下
```yaml
$schema: https://azuremlschemas.azureedge.net/latest/commandJob.schema.json
code: job
command: >-
  python main.py 
environment: azureml:basic-env-scikit@latest
compute: cluster1
experiment_name: diabetes-example
description: Train a Logistic Regression classification model on the diabetes dataset that is stored locally.
```

# 场景二、Azure DevOps Pipeline 部署本地模型到AML Endpoint
### Pipeline 文件 [./deploy-endpoint-pipeline.yml](./deploy-endpoint-pipeline.yml)

- 因为部署模型需要上传文件，就要授权Azure DevOps到AML的服务帐号到AML存储的权限，可以从Azure Portal先获取服务帐号的应用ID，在AML WS的访问控制(IAM)的角色分配里，点开服务帐号后能看到应用ID(Application ID), 然后通过下面命令授权到AML存储的权限
```bash
#service principal application id 03f19bd2-1a38-4da6-993b-76dd44215dba

az role assignment create --assignee <APP_ID> --role "Storage Blob Data Reader" --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-aml/providers/Microsoft.Storage/storageAccounts/<Storage_Account>

az role assignment create --assignee --assignee <APP_ID> --role "Storage Blob Data Contributor" --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-aml/providers/Microsoft.Storage/storageAccounts/<Storage_Account>

```

- 先手动或使用下面命令创建一个AML Endpoint, endpoint 名称后面部署要用到， 如 ***test-ep02*** , 定义在[./src/aml/create-endpoint.yml](./src/aml/create-endpoint.yml)
```bash
ep_name=test-ep02
az ml online-endpoint create --name $ep_name -f ./aml/create-endpoint.yml
```

- 调用部署AML Endpoint的部署template [./src/deploy-endpoint.yml](./src/deploy-endpoint.yml) , 主要引用了到AML的服务连接权限，然后通过下面部署AML Endpoint
```bash
az ml online-deployment create --name depTest01  --resource-group rg-aml --workspace-name aml-ea --endpoint ${{ parameters.ep_name }} -f ./mlflow-deployment.yml --all-traffic
```
- 具体部署AML Endpoint的定义文件 [./src/mlflow-deployment.yml](./src/mlflow-deployment.yml),
```yaml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
model:
  name: sample-mlflow-sklearn-model
  version: 1
  path: model
  type: mlflow_model
instance_type: Standard_F4s_v2
instance_count: 1
```

部署模型定义参考：
https://learn.microsoft.com/zh-cn/azure/machine-learning/reference-yaml-deployment-managed-online?view=azureml-api-2#yaml-syntax

本地部署模型定义参考：
https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-model?view=azureml-api-2#yaml-syntax


# 场景三、Azure DevOps Pipeline 部署AML注册的模型
### Pipeline 文件 [./deploy-registered-pipeline.yml](./deploy-registered-pipeline.yml)

- 调用部署AML Endpoint的部署template [./src/deploy-registered.yml](./src/deploy-registered.yml) , 主要引用了到AML的服务连接权限，然后通过下面部署AML Endpoint
```bash
az ml online-deployment create --name $depName  --resource-group <RESOURCE_GROUP> --workspace-name <AML_WS> --endpoint ${{ parameters.ep_name }} -f ./registered-deployment.yml --all-traffic
```
- 具体部署AML Endpoint的定义文件 [./src/registered-deployment.yml](./src/registered-deployment.yml),

```yaml
$schema: https://azuremlschemas.azureedge.net/latest/managedOnlineDeployment.schema.json
model: azureml:test-model01:1
instance_type: Standard_F4s_v2
instance_count: 1
```

# 定时任务

```
cd src
az ml job create --file basic-pipeline-job.yml -g rg-aml -w aml-ea

az ml schedule create --file schedule-job.yml --no-wait -g <ResourceGroup> -w <WorkspaceName>
az ml schedule create --file schedule_job.yml --no-wait -g rg-aml -w aml-ea
```