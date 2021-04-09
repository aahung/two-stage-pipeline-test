pipeline {
  agent {
    docker { 
      image 'public.ecr.aws/sam/build-python3.8'
      args '--user 0:0'
    }
  }
  environment {
    SAM_TEMPLATE = "template.yaml"
    TESTING_STACK_NAME = "test-stack"
    TESTING_DEPLOYER_ROLE = "arn:aws:iam::191762412092:role/stage-resource-stack-DeployerRole-F3UDMRJEAPVP"
    TESTING_CFN_DEPLOYMENT_ROLE = "arn:aws:iam::191762412092:role/stage-resource-stack-CFNDeploymentRole-1LHD5N7FSUGB6"
    TESTING_ARTIFACTS_BUCKET = "stage-resource-stack-artifactsbucket-1t96af9pkc631"
    TESTING_ECR_REPO = "191762412092.dkr.ecr.us-east-2.amazonaws.com/test"
    TESTING_REGION = "us-east-2"
    PROD_STACK_NAME = "prod-stack"
    PROD_DEPLOYER_ROLE = "arn:aws:iam::013714286599:role/stack-resource-stack-DeployerRole-1MKUWNLR7G6I9"
    PROD_CFN_DEPLOYMENT_ROLE = "arn:aws:iam::013714286599:role/stack-resource-stack-CFNDeploymentRole-1UHQLSY8D9LY1"
    PROD_ARTIFACTS_BUCKET = "stack-resource-stack-artifactsbucket-1tecc3mhymec7"
    PROD_ECR_REPO = "013714286599.dkr.ecr.us-east-2.amazonaws.com/test"
    PROD_REGION = "us-east-2"
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
        withAWS(credentials: 'test', region: 'us-east-2') {
          sh '''
            . pipeline/assume-role.sh ${TESTING_DEPLOYER_ROLE} testing-packaging 
            sam build --template ${SAM_TEMPLATE}
            sam deploy --stack-name features-${env.BRANCH_NAME}-cfn-stack \
              --capabilities CAPABILITY_IAM \
              --region ${TESTING_REGION} \
              --s3-bucket ${TESTING_ARTIFACTS_BUCKET} \
              --image-repository ${TESTING_ECR_REPO} \
              --no-fail-on-empty-changeset \
              --role-arn ${TESTING_CFN_DEPLOYMENT_ROLE}
          '''
        }
      }
    }

    stage('build') {
      when {
        branch 'main'
      }
      steps {
        sh 'sam build --template ${SAM_TEMPLATE}'
        withAWS(credentials: 'test', region: 'us-east-2') {
          sh '''
            . pipeline/assume-role.sh ${TESTING_DEPLOYER_ROLE} testing-packaging 
            sam package \
              --s3-bucket ${TESTING_ARTIFACTS_BUCKET} \
              --image-repository ${TESTING_ECR_REPO} \
              --region ${TESTING_REGION} \
              --output-template-file packaged-testing.yaml
          '''
        }

        withAWS(credentials: 'test', region: 'us-east-2') {
          sh '''
            . pipeline/assume-role.sh ${PROD_DEPLOYER_ROLE} prod-packaging 
            sam package \
              --s3-bucket ${PROD_ARTIFACTS_BUCKET} \
              --image-repository ${PROD_ECR_REPO} \
              --region ${PROD_REGION} \
              --output-template-file packaged-prod.yaml
          '''
        }

        archiveArtifacts artifacts: 'packaged-testing.yaml'
        archiveArtifacts artifacts: 'packaged-prod.yaml'
      }
    }

    stage('integration-test') {
      when {
        branch 'main'
      }
      steps {
        sh '''
          
          # trigger the integration tests here
        '''
      }
    }

    stage('deploy-prod') {
      when {
        branch 'main'
      }
      steps {
        withAWS(credentials: 'test', region: 'us-east-2') {
          sh '''
            . pipeline/assume-role.sh ${PROD_DEPLOYER_ROLE} prod-deployment 
            sam deploy --stack-name ${PROD_STACK_NAME} \
              --template packaged-prod.yaml \
              --capabilities CAPABILITY_IAM \
              --region ${PROD_REGION} \
              --s3-bucket ${PROD_ARTIFACTS_BUCKET} \
              --image-repository ${PROD_ECR_REPO} \
              --no-fail-on-empty-changeset \
              --role-arn ${PROD_CFN_DEPLOYMENT_ROLE}
          '''
        }
      }
    }
  }
}