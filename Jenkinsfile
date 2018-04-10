#!groovy
import groovy.json.JsonSlurperClassic
node {

    def BUILD_NUMBER=env.BUILD_NUMBER
    def RUN_ARTIFACT_DIR="tests/${BUILD_NUMBER}"
    def SFDC_USERNAME
    def SFDC_PASSWORD

    def HUB_ORG=env.HUB_ORG_DH
    def SFDC_HOST = env.SFDC_HOST_DH
    def JWT_KEY_CRED_ID = env.JWT_CRED_ID_DH
    def CONNECTED_APP_CONSUMER_KEY=env.CONNECTED_APP_CONSUMER_KEY_DH

    def toolbelt = tool 'toolbelt'

    stage('checkout source') {
        checkout scm
    }

    withCredentials([file(credentialsId: JWT_KEY_CRED_ID, variable: 'jwt_key_file')]) {
        stage('Create Scratch Org') {

            rc = sh returnStatus: true, script: "${toolbelt}/sfdx force:auth:jwt:grant --clientid ${CONNECTED_APP_CONSUMER_KEY} --username ${HUB_ORG} --jwtkeyfile ${jwt_key_file} --setdefaultdevhubusername --instanceurl ${SFDC_HOST}"
            if (rc != 0) { error 'hub org authorization failed' }

            // need to pull out assigned username
            rmsg = sh returnStdout: true, script: "${toolbelt}/sfdx force:org:create --definitionfile config/project-scratch-def.json --json --setdefaultusername"
            echo '******JSON OUPUT******* '+ rmsg
            printf rmsg
            def jsonSlurper = new JsonSlurperClassic()
            def robj = jsonSlurper.parseText(rmsg)
            echo '******JSONSLURERCLASSIC OUPUT******* '+ robj.result.username
            if (robj.status != 0) { error 'org creation failed: ' + robj.result.message }
            SFDC_USERNAME=robj.result.username
            echo '******USERNAME******* '+ SFDC_USERNAME
            robj = null

        }

        stage('Push To Test Org') {
            rc = sh returnStatus: true, script: "${toolbelt}/sfdx force:source:push --targetusername ${SFDC_USERNAME}"
            if (rc != 0) {
                error 'push failed'
            }
            // assign permset
            rc = sh returnStatus: true, script: "${toolbelt}/sfdx force:user:permset:assign --targetusername ${SFDC_USERNAME} --permsetname DreamHouse"
            if (rc != 0) {
                error 'permset:assign failed'
            }
        }

        stage('Run Apex Test') {
            sh "mkdir -p ${RUN_ARTIFACT_DIR}"
            timeout(time: 120, unit: 'SECONDS') {
                rc = sh returnStatus: true, script: "${toolbelt}/sfdx force:apex:test:run --testlevel RunLocalTests --outputdir ${RUN_ARTIFACT_DIR} --resultformat tap --targetusername ${SFDC_USERNAME}"
                if (rc != 0) {
                    error 'apex test run failed'
                }
            }
        }

        stage('collect results') {
            junit keepLongStdio: true, testResults: 'tests/**/*-junit.xml'
        }

        stage('Gerate password'){
             rmsgx = sh returnStdout: true, script: "${toolbelt}/sfdx force:user:password:generate -u ${SFDC_USERNAME} --json"
             echo  '*************JSON OUPUT************* : ' + rmsgx
             def jsonSlurperx = new JsonSlurperClassic()
             def robjx = jsonSlurperx.parseText(rmsgx)
             echo  '*************JSON OUPUT************* : ' + robjx.result.password
             SFDC_PASSWORD=robjx.result.password
             robjx = null
        }

        stage('Update ScratOrgInfo Password__c'){
             rc = sh returnStatus: true, script: "${toolbelt}/sfdx force:data:record:update -s ScratchOrgInfo -w SignupUsername=${SFDC_USERNAME} -v Password__c=${SFDC_PASSWORD} --targetusername jagrelot@dxdemo.com"
                if (rc != 0) {
                     error 'Update failed'
                 }	
        }

        stage('Display Org'){
            rc = sh returnStdout: true, script: "${toolbelt}/sfdx force:org:display -u ${SFDC_USERNAME} --json"
            echo "----------- " + rc
        }
    }
}
