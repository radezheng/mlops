az extension add -n ml -y

az ml environment list -g rg-aml -o table

#创建环境
az ml environment create --file ./basic-env.yml -g rg-aml

az ml environment list -g rg-aml -o table | grep basic



#创建dataset

az ml data create --file ./env/data-local-path.yml -g rg-aml -w aml-ea

##如果报没有权限，需要添加权限

### 先查看当前用户id
az ad signed-in-user show
az ad signed-in-user show --query id --output tsv


#查看AML存储账户
az storage account list -o tablel
az storage account show --name amlea9646585866 --resource-group rg-aml --query id



# az role assignment create --assignee 61cd9539-4326-4901-a1be-9917bccecb73 --role "Storage Blob Data Reader" --scope /subscriptions/3a444aea-8fbe-45fc-8482-cfb84452837d/resourceGroups/rg-aml/providers/Microsoft.Storage/storageAccounts/amlea9646585866
az role assignment create --assignee 61cd9539-4326-4901-a1be-9917bccecb73 --role "Storage Blob Data Contributor" --scope /subscriptions/3a444aea-8fbe-45fc-8482-cfb84452837d/resourceGroups/rg-aml/providers/Microsoft.Storage/storageAccounts/amlea9646585866


ep_name=test-ep02
az ml online-deployment create --name depTest011 --endpoint $ep_name -f ./src/mlflow-deployment.yml --all-traffic