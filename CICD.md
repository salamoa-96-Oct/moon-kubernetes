## Docker로 인증서 생성

```java
docker run -it --rm --name certbot -v '/etc/letsencrypt:/etc/letsencrypt' \
-v '/var/lib/letsencrypt:/var/lib/letsencrypt' \
certbot/certbot certonly -d '*.kuber.kro.kr' \
--email mjs1212@gmail.com \
--agree-tos --no-eff-email -d kuber.kro.kr \
--manual \
--preferred-challenges dns \
--server https://acme-v02.api.letsencrypt.org/directory
```

## TLS용 secret 생성

harbor tls secret 생성

```java
kubectl create secret tls [tls-name] --key private.key --cert certificate.crt

-------------

kubectl create -n harbor secret tls harbor-secret \   ## namespace 지정
  --cert=/etc/letsencrypt/live/kuber.kro.kr/fullchain.pem \ ## Cert 있는 경로 지정 fullchain.pem 파일명
  --key=/etc/letsencrypt/live/kuber.kro.kr/privkey.pem  ## key 있는 경로 지정 privkey.pem 파일명
```

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

---

## ArgoCD 설치

```java
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update
helm pull argocd/argo-cd
tar xzvf argo-cd-4.5.0.tg

-----------

values.yaml 수정
927 -> tls 설정 줄

기존 ingresscontroller와 연동하기 위해서
1021   ingress:
1022     # -- Enable an ingress resource for the Argo CD server
1023     enabled: true
1024     # -- Additional ingress annotations
1025     annotations: {}
1026     # -- Additional ingress labels
1027     labels: {}
1028     # -- Defines which ingress controller will implement the resource
1029     ingressClassName: nginx
1031     # -- List of ingress hosts
1032     ## Argo Ingress.
1033     ## Hostnames must be provided if Ingress is enabled.
1034     ## Secrets must be manually created in the namespace
1035     hosts:
1036       - argocd.kuber.kro.kr
1037
1038     # -- List of ingress paths
1039     paths:
1040       - /
kubectl create namespace argocd

helm install argocd . \
-n argocd
로 하려고 했으나 리다이렉션이 많아 접속이 안됨.(TS 중)

급한대로 ingress말고 servicetype: LoadBalancer로 생성하여 사용 진행

--------------
NAME: argocd
LAST DEPLOYED: Thu Apr  7 05:05:53 2022
NAMESPACE: argocd
STATUS: deployed
REVISION: 1
NOTES:
In order to access the server UI you have the following options:

1. kubectl port-forward service/argocd-server -n argocd 8080:443

    and then open the browser on http://localhost:8080 and accept the certificate

2. enable ingress in the values file `server.ingress.enabled` and either
      - Add the annotation for ssl passthrough: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/ingress.md#option-1-ssl-passthrough
      - Add the `--insecure` flag to `server.extraArgs` in the values file and terminate SSL at your ingress: https://github.com/argoproj/argo-cd/blob/master/docs/operator-manual/ingress.md#option-2-multiple-ingress-objects-and-hosts

After reaching the UI the first time you can login with username: admin and the random password generated during the installation. You can find the password by running:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

(You should delete the initial secret afterwards as suggested by the Getting Started Guide: https://github.com/argoproj/argo-cd/blob/master/docs/getting_started.md#4-login-using-the-cli)
```

## argocd- cli 설치

```java
VERSION=v2.0.0; curl -sL -o argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/argocd
```

## argocd 초기 비밀번호

```java
$ kubectl -n argo get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

## argocd login 정보

```java
argocd login --insecure 192.168.97.209:30800
Username: admin
Password:
'admin:login' logged in successfully
```

## argocd - cluster 등록

```java
kubectl config view -o jsonpath='{.current-context}' && echo

argocd login --insecure [IP-address]:30800 --username admin --password [password]
argocd cluster add [cluster-config] --name [name] --upsert
```

## argocd -project 생성

```java
argocd proj create lma --dest "*,*" --src "*" --allow-cluster-resource "*/*"
argocd proj create service-mesh --dest "*,*" --src "*" --allow-cluster-resource "*/*"
```

---

## harbor 설치

```java
helm repo add harbor https://helm.goharbor.io
helm repo update
helm search repo harbor

helm pull harbor/harbor
tar xvzf harbor-1.8.2.tgz

values.yaml 수정

1 expose:
  2   # Set the way how to expose the service. Set the type as "ingress",
  3   # "clusterIP", "nodePort" or "loadBalancer" and fill the information
  4   # in the corresponding section
  5   type: loadBalancer
  6   tls:
  7     # Enable the tls or not.
  8     # Delete the "ssl-redirect" annotations in "expose.ingress.annotations" when TLS is disabled and "expose.type" is "ingress"
  9     # Note: if the "expose.type" is "ingress" and the tls
 10     # is disabled, the port must be included in the command when pull/push
 11     # images. Refer to https://github.com/goharbor/harbor/issues/5291
 12     # for the detail.
 13     enabled: true
 14     # The source of the tls certificate. Set it as "auto", "secret"
 15     # or "none" and fill the information in the corresponding section
 16     # 1) auto: generate the tls certificate automatically
 17     # 2) secret: read the tls certificate from the specified secret.
 18     # The tls certificate can be generated manually or by cert manager
 19     # 3) none: configure no tls certificate for the ingress. If the default
 20     # tls certificate is configured in the ingress controller, choose this option
 21     certSource: secret
 22     auto:
 23       # The common name used to generate the certificate, it's necessary
 24       # when the type isn't "ingress"
 25       commonName: ""
 26     secret:
 27       # The name of secret which contains keys named:
 28       # "tls.crt" - the certificate
 29       # "tls.key" - the private key
 30       secretName: "harbor-secret"
 31       # The name of secret which contains keys named:
 32       # "tls.crt" - the certificate
 33       # "tls.key" - the private key
 34       # Only needed when the "expose.type" is "ingress".
 35       notarySecretName: ""
 36   ingress:
 37     hosts:
 38       core: core.kuber.kro.kr
 39       notary: notary.kuber.kro.kr

122 externalURL: https://harbor.kuber.kro.kr

helm install harbor . -n harbor
```
