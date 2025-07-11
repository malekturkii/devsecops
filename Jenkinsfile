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
                sh 'npm audit --audit-level=high || true'
            }
        }
    
        stage('OWASP Dependency Check') {
            steps {
                echo 'Running OWASP Dependency-Check...'
                sh '''
                dependency-check.sh --project telecom --scan frontend --format HTML --out dependency-check-report 
                '''
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
}
    post {
        always {
            echo 'Publishing OWASP Dependency-Check report...'
            dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.html'

            echo 'Pipeline finished.'
        }
    }
  
}
