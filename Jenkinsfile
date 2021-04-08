pipeline {
  agent {
    docker { 
      image 'amazon/aws-sam-cli-build-image-python3.8'
    }
  }
  environment {
    aws_access_key_id_ = "${env.AWS_ACCESS_KEY_ID}"
    aws_secret_access_key_ = "${env.AWS_SECRET_ACCESS_KEY}"
    sam_template = "template.yaml"
    testing_stack_name = "test-stack"
    prod_stack_name = "prod-stack"
  }
  stages {
    // uncomment and modify the following step for running the unit-tests
    // stage('test') {
    //   steps {
    //     // Assuming python runtime
    //     sh 'pip install pytest'
    //     sh 'pip install -r /path/to/requirements.txt'
    //     sh 'python -m pytest /path/to/unit-tests'
    //   }
    // }

    stage('build-and-deploy-test') {
      when {
        branch 'feature*'
      }
      steps {
        // Add assume role script in future
        sh '''
          . cicd/init-env-vars.sh
          . ./assume-role.sh ${testing_region} ${testing_deployer_role} testing-packaging 
          sam build --template ${sam_template} --use-container
          sam deploy --stack-name features-${CI_COMMIT_REF_NAME}-cfn-stack \
            --capabilities CAPABILITY_IAM \
            --region ${testing_region} \
            --s3-bucket ${testing_artifacts_bucket} \
            --image-repository ${testing_ecr_repo} \
            --no-fail-on-empty-changeset \
            --role-arn ${testing_cfn_deployment_role}
        '''
      }
    }

    stage('build') {
      when {
        branch 'main'
      }
      steps {
        // Add assume role script in future
        sh '''
          . cicd/init-env-vars.sh
          sam build --template ${sam_template} --use-container

          . ./assume-role.sh ${testing_region} ${testing_deployer_role} testing-packaging 
          sam package \
            --s3-bucket ${testing_artifacts_bucket} \
            --image-repository ${testing_ecr_repo} \
            --region ${testing_region} \
            --output-template-file packaged-testing.yaml
          
          . ./assume-role.sh ${prod_region} ${prod_deployer_role} prod-packaging 
          sam package \
            --s3-bucket ${prod_artifacts_bucket} \
            --image-repository ${prod_ecr_repo} \
            --region ${prod_region} \
            --output-template-file packaged-prod.yaml
        '''
      }
    }
  }
}