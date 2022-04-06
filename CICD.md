## Gitlab

핼름 차트 등록

```yaml
$ helm repo add gitlab/https://charts.gitlab.io/
$ helm pull gitlab/gitlab
$ tar -xvf gitlab-5.6.1.tgz
```

GitLab 설치 방법

```yaml
$ kubectl create namespace gitlab
$ helm upgrade --install -n gitlab gitlab . --set certmanager-issuer.email=mjs1212@kuberix.com

설치가 완료되면 LB랑 Ingress가 자동으로 생성되고 tls 인증서도 certmanager때문에 443 통신이 
가능하게 됩니다.

Gitlab의 values.yaml 파일 수정

$ vim values.yaml
56   hosts:
57     domain: kuber.kro.kr #1차 도메인만 넣어 줘야한다.
  																												 EXTERNAL-IP
$ kubectl get ingress -n gitlab
gitlab-nginx-ingress-controller LoadBalancer 10.0.121.161 20.200.232.246 80:32452/TCP,443:30049/TCP,22:31352/TCP   14m

$ helm upgrade --install -n gitlab gitlab .
```

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/59984390-8c75-4972-870a-a882e5fe9d93/Untitled.png)

Gitlab root 초기하 password 확인 명령어

```java
kubectl get secret -n gitlab gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

---

## Jenkins

[Kubernetes](https://www.jenkins.io/doc/book/installing/kubernetes/)

핼름 차트 등록

```yaml
helm repo add jenkinsci https://charts.jenkins.io
helm repo update
helm pull jenkins/jenkinsci
tar -xvf jenkins
```

Jenkins 설치 방법

```yaml
$ kubectl create namespace jenkins

$ wget https://raw.githubusercontent.com/jenkins-infra/jenkins.io/master/content/doc/tutorials/kubernetes/installing-jenkins-on-kubernetes/jenkins-sa.yaml
-> ServiceAccount 등록

12   annotations:
13     rbac.authorization.kubernetes.io/autoupdate: "true"
14     meta.helm.sh/release-name : jenkins
15     meta.helm.sh/release-namespace : jenkinsci
이유는 모르겠지만 annotations을 설정하지 않으면 핼름 설치가 안됨.
아무래도 private에 있다 보니 권한 문제인 것 같음

$ kubectl apply -f jenkins-sa.yaml

jenkins의 values.yaml 파일 수정
$ vim values.yaml

121   # For minikube, set this to NodePort, elsewhere use LoadBalancer
122   # Use ClusterIP if your setup includes ingress controller
123   serviceType: LoadBalancer

231   installPlugins:
232     - kubernetes:1.31.1
233     - workflow-aggregator:2.6
234     - git:4.10.1
235     - configuration-as-code:1.55

```

### Trouble-Shooting

```java
240   installPlugins:
241     - kubernetes:1.31.3
242     - workflow-aggregator:2.6
243     - git:4.10.2
244     - configuration-as-code:1414.v878271fc496f
```

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/fe2bbdde-afec-45d3-9908-7a2591682044/Untitled.png)

플러그인 Depend on 오류 때문에 values에서 수정함

```java
NAME: jenkins
LAST DEPLOYED: Tue Apr  5 07:36:32 2022
NAMESPACE: jenkinsci
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:
  kubectl exec --namespace jenkinsci -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/chart-admin-password && echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkinsci -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkinsci jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin
4. Configure security realm and authorization strategy
5. Use Jenkins Configuration as Code by specifying configScripts in your values.yaml file, see documentation: http:///configuration-as-code and examples: https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos

For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine

For more information about Jenkins Configuration as Code, visit:
https://jenkins.io/projects/jcasc/

NOTE: Consider using a custom image with pre-installed plugins
```
