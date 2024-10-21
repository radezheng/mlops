cd ../src

az ml job create --file basic-pipeline-job.yml -g rg-aml -w aml-ea --name hello-job2

az ml job update --file basic-pipeline-job.yml -g rg-aml -w aml-ea -n hello_pipeline

az ml job -h


#====

git ls-remote --get-url

az ml schedule create --file schedule-job.yml -g rg-aml -w aml-ea

# 获取 Git 信息
repo_uri=$(git ls-remote --get-url)
branch=$(git symbolic-ref --short HEAD)
commit=$(git rev-parse HEAD)
commit_message=$(git log -1 --pretty=%B)

az ml schedule create --file schedule-job-adv.yml -g rg-aml -w aml-ea \
    --set tags.repo_uri=$repo_uri \
    tags.branch=$branch \
    tags.commit=$commit \
    tags.commit_message=$commit_message

az ml schedule list -g rg-aml -w aml-ea -o table

az ml schedule disable --name simple_cron_job_schedule -g rg-aml -w aml-ea



#####
git remote add github https://github.com/radezheng/mlops
git push github master