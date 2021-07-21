pipeline {
  agent any
  environment {
    PIPELINE_USER_CREDENTIAL_ID = 'aws-credentials'
    SAM_TEMPLATE = 'template.yaml'
    MAIN_BRANCH = 'main'
    TESTING_STACK_NAME = 'sam-app'
    TESTING_PIPELINE_EXECUTION_ROLE = 'arn:aws:iam::191762412092:role/aws-sam-cli-managed-stage1-p-PipelineExecutionRole-1KNUTFS1X3Z05'
    TESTING_CLOUDFORMATION_EXECUTION_ROLE = 'arn:aws:iam::191762412092:role/aws-sam-cli-managed-stage-CloudFormationExecutionR-U3PR084JZPMA'
    TESTING_ARTIFACTS_BUCKET = 'aws-sam-cli-managed-stage1-pipeli-artifactsbucket-xiwz97am33h2'
    TESTING_IMAGE_REPOSITORY = '191762412092.dkr.ecr.us-west-2.amazonaws.com/aws-sam-cli-managed-stage1-pipeline-resources-imagerepository-mcyvqzl6ojpu'
    TESTING_REGION = 'us-west-2'
    PROD_STACK_NAME = 'sam-app'
    PROD_PIPELINE_EXECUTION_ROLE = 'arn:aws:iam::013714286599:role/aws-sam-cli-managed-stage2-p-PipelineExecutionRole-1CR173XTEO779'
    PROD_CLOUDFORMATION_EXECUTION_ROLE = 'arn:aws:iam::013714286599:role/aws-sam-cli-managed-stage-CloudFormationExecutionR-SPBX3XDHXDS1'
    PROD_ARTIFACTS_BUCKET = 'aws-sam-cli-managed-stage2-pipeli-artifactsbucket-1vvmo2x06lf2u'
    PROD_IMAGE_REPOSITORY = '013714286599.dkr.ecr.us-east-1.amazonaws.com/aws-sam-cli-managed-stage2-pipeline-resources-imagerepository-h1ymdq95r3dc'
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
      input "Do you want to deploy to production environment?"
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
