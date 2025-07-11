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
               // sh 'docker build -t telecom-pfe:latest .'
                   echo "Hello world"       
           }
        }
        stage('DAST - OWASP ZAP Baseline Scan') {
              steps {
                 script {
                      // Lancer OWASP ZAP baseline scan via Docker
                      sh '''
                      docker run -t --rm \
                      -v /var/lib/jenkins/workspace/jenkins-test-1:/zap/wrk/:rw \
                      --network host \
                      zaproxy/zap-stable \
                      zap-baseline.py -t http://localhost:3000 -r zap-report.html || [ $? -eq 2 ]
          '''
        }
        // Archiver le rapport dans Jenkins
             archiveArtifacts artifacts: 'zap-report.html', fingerprint: true
        // Publier le rapport dans la console
             sh 'cat zap-report.html || true'
      }
    }

}
   
  
}
