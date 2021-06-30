pipeline {
  agent any
  environment {
    PIPELINE_USER_CREDENTIAL_ID = 'aws-credentials'
    SAM_TEMPLATE = 'template.yaml'
    MAIN_BRANCH = 'main'
    TESTING_STACK_NAME = 'test'
    TESTING_PIPELINE_EXECUTION_ROLE = 'arn:aws:iam::191762412092:role/aws-sam-cli-managed-test-pip-PipelineExecutionRole-1UPENALC3ILO3'
    TESTING_CLOUDFORMATION_EXECUTION_ROLE = 'arn:aws:iam::191762412092:role/aws-sam-cli-managed-test-CloudFormationExecutionR-LTPUFSZPT6BC'
    TESTING_ARTIFACTS_BUCKET = 'aws-sam-cli-managed-test-pipeline-artifactsbucket-2tcp5h7n0fu0'
    TESTING_IMAGE_REPOSITORY = '191762412092.dkr.ecr.us-west-2.amazonaws.com/aws-sam-cli-managed-test-pipeline-resources-imagerepository-4xuroxswjutq'
    TESTING_REGION = 'us-west-2'
    PROD_STACK_NAME = 'prod'
    PROD_PIPELINE_EXECUTION_ROLE = 'arn:aws:iam::013714286599:role/aws-sam-cli-managed-prod-pip-PipelineExecutionRole-1052V7X9T7W71'
    PROD_CLOUDFORMATION_EXECUTION_ROLE = 'arn:aws:iam::013714286599:role/aws-sam-cli-managed-prod-CloudFormationExecutionR-5I4W9KB56KB1'
    PROD_ARTIFACTS_BUCKET = 'aws-sam-cli-managed-prod-pipeline-artifactsbucket-9o5l9go2lprm'
    PROD_IMAGE_REPOSITORY = '013714286599.dkr.ecr.us-east-1.amazonaws.com/aws-sam-cli-managed-prod-pipeline-resources-imagerepository-kmouuwmn0ecb'
    PROD_REGION = 'us-east-1'
  }
  stages {
    // uncomment and modify the following step for running the unit-tests
    // stage('test') {
    //   steps {
    //     sh '''
    //       # trigger the tests here
    //     '''
    //   }
    // }

    stage('build-and-deploy-feature') {
      // this stage is triggered only for feature branches (feature*),
      // which will build the stack and deploy to a stack named with branch name.
      when {
        branch 'feature*'
      }
      agent {
        docker {
          image 'public.ecr.aws/sam/build-provided'
          args '--user 0:0 -v /var/run/docker.sock:/var/run/docker.sock'
        }
      }
      steps {
        sh 'sam build --template ${SAM_TEMPLATE} --use-container'
        withAWS(
            credentials: env.PIPELINE_USER_CREDENTIAL_ID,
            region: env.TESTING_REGION,
            role: env.TESTING_PIPELINE_EXECUTION_ROLE,
            roleSessionName: 'deploying-feature') {
          sh '''
            sam deploy --stack-name $(echo ${BRANCH_NAME} | tr -cd '[a-zA-Z0-9-]') \
              --capabilities CAPABILITY_IAM \
              --region ${TESTING_REGION} \
              --s3-bucket ${TESTING_ARTIFACTS_BUCKET} \
              --image-repository ${TESTING_IMAGE_REPOSITORY} \
              --no-fail-on-empty-changeset \
              --role-arn ${TESTING_CLOUDFORMATION_EXECUTION_ROLE}
          '''
        }
      }
    }

    stage('build-and-package') {
      when {
        branch env.MAIN_BRANCH
      }
      agent {
        docker {
          image 'public.ecr.aws/sam/build-provided'
          args '--user 0:0 -v /var/run/docker.sock:/var/run/docker.sock'
        }
      }
      steps {
        sh 'sam build --template ${SAM_TEMPLATE} --use-container'
        withAWS(
            credentials: env.PIPELINE_USER_CREDENTIAL_ID,
            region: env.TESTING_REGION,
            role: env.TESTING_PIPELINE_EXECUTION_ROLE,
            roleSessionName: 'testing-packaging') {
          sh '''
            sam package \
              --s3-bucket ${TESTING_ARTIFACTS_BUCKET} \
              --image-repository ${TESTING_IMAGE_REPOSITORY} \
              --region ${TESTING_REGION} \
              --output-template-file packaged-testing.yaml
          '''
        }

        withAWS(
            credentials: env.PIPELINE_USER_CREDENTIAL_ID,
            region: env.PROD_REGION,
            role: env.PROD_PIPELINE_EXECUTION_ROLE,
            roleSessionName: 'prod-packaging') {
          sh '''
            sam package \
              --s3-bucket ${PROD_ARTIFACTS_BUCKET} \
              --image-repository ${PROD_IMAGE_REPOSITORY} \
              --region ${PROD_REGION} \
              --output-template-file packaged-prod.yaml
          '''
        }

        archiveArtifacts artifacts: 'packaged-testing.yaml'
        archiveArtifacts artifacts: 'packaged-prod.yaml'
      }
    }

    stage('deploy-testing') {
      when {
        branch env.MAIN_BRANCH
      }
      agent {
        docker {
          image 'public.ecr.aws/sam/build-provided'
        }
      }
      steps {
        withAWS(
            credentials: env.PIPELINE_USER_CREDENTIAL_ID, 
            region: env.TESTING_REGION,
            role: env.TESTING_PIPELINE_EXECUTION_ROLE,
            roleSessionName: 'testing-deployment') {
          sh '''
            sam deploy --stack-name ${TESTING_STACK_NAME} \
              --template packaged-testing.yaml \
              --capabilities CAPABILITY_IAM \
              --region ${TESTING_REGION} \
              --s3-bucket ${TESTING_ARTIFACTS_BUCKET} \
              --image-repository ${TESTING_IMAGE_REPOSITORY} \
              --no-fail-on-empty-changeset \
              --role-arn ${TESTING_CLOUDFORMATION_EXECUTION_ROLE}
          '''
        }
      }
    }

    // uncomment and modify the following step for running the integration-tests
    // stage('integration-test') {
    //   when {
    //     branch env.MAIN_BRANCH
    //   }
    //   steps {
    //     sh '''
    //       # trigger the integration tests here
    //     '''
    //   }
    // }
    stage('production-deployment-approval'){
      steps {
        input "Do you want to deploy to production environment?"
      }
    }

    stage('deploy-prod') {
      when {
        branch env.MAIN_BRANCH
      }
      agent {
        docker {
          image 'public.ecr.aws/sam/build-provided'
        }
      }
      steps {
        withAWS(
            credentials: env.PIPELINE_USER_CREDENTIAL_ID, 
            region: env.PROD_REGION,
            role: env.PROD_PIPELINE_EXECUTION_ROLE,
            roleSessionName: 'prod-deployment') {
          sh '''
            sam deploy --stack-name ${PROD_STACK_NAME} \
              --template packaged-prod.yaml \
              --capabilities CAPABILITY_IAM \
              --region ${PROD_REGION} \
              --s3-bucket ${PROD_ARTIFACTS_BUCKET} \
              --image-repository ${PROD_IMAGE_REPOSITORY} \
              --no-fail-on-empty-changeset \
              --role-arn ${PROD_CLOUDFORMATION_EXECUTION_ROLE}
          '''
        }
      }
    }
  }
}
