# Jenkins artifacts for STF
Use these to run a jenkins in Openshift that will do CI tests on STF

## Start a new project for CI
```
oc new-project ci
```

## Build the Jenkins master image
```
oc new-build --binary=true --name=jenkins
oc start-build jenkins --from-file ./Dockerfile --follow=true
```

## Build the Jenkins agent image
NOTE: The operator-sdk version in the Dockerfile is the latest version that will work with the STO build scripts
```
cd agent
oc new-build --binary=true --name=jenkins-agent
oc start-build jenkins-agent --from-file ./Dockerfile --follow=true
cd ..
```

## Set your local secret stuff
You'll need to get/generate a GitHub App ID & Privkey and put the key in gh-app-privkey.pem
```
GH_APPID=<YOUR GITHUB APP ID>
GH_ORG=<YOUR_GITHUB_ORGANIZATION>

oc create secret generic github-app-key --from-literal=owner=${GH_ORG} --from-literal=appID=${GH_APPID} --from-literal=privateKey="$(cat ./gh-app-privkey.pem)"
oc annotate secret/github-app-key jenkins.io/credentials-description="gh-app-key"
oc label secret/github-app-key jenkins.io/credentials-type=gitHubApp
```

## Deploy all the things
```
oc apply -f deploy/service-route.yaml

export SMEE_CHANNEL=<YOUR_SMEE_CHANNEL>  #(just the slug, not the whole URL)
export GH_ORG=<YOUR_GITHUB_ORGANIZATION>
export JENKINS_URL=$(oc get route jenkins -ojsonpath='{.spec.host}')

for f in deploy/*; do
  envsubst < "${f}" | oc apply -f -
done
```

## Access the console and load the jobs
`xdg-open https://$JENKINS_URL`

The Jenkins master pod is configured to use OpenShift SSO. To login as an admin, use the host cluster's "kubeadmin" credentials.

After logging in, navigate to your organization from the home panel and press the "Scan Organization Now" button. This will discover all projects in the organization that have valid Jenkinsfiles in them.
