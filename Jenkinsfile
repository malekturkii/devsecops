pipeline {
    agent any
     
    tools {
        nodejs 'NODE24'
    }
    environment {
        CI = 'true'
        
    }

    stages {
       stage('Install') {
            steps {
                sh 'npm install'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build:frontend'
            }
        }

        stage('Tests') {
            steps {
                sh 'npm run test:ci || true'
            }
        }

        stage('Audit NPM') {
            steps {
                sh 'npm audit --audit-level=high --json > audit-report.json || true'
                archiveArtifacts artifacts: 'audit-report.json', fingerprint: true
            }
        }
    
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                    sonar-scanner \
                      -Dsonar.projectKey=telecom \
                      -Dsonar.projectName=telecom \
                      -Dsonar.sources=. \
                      -Dsonar.sourceEncoding=UTF-8
                    '''
                }
            } 
        }    
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t telecom-pfe:latest .'
            }
        }


}
   
  
}
