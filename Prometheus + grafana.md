# aws-eks

- helm을 사용하여 설치할 예정이므로 helm 설치는 완료된 상태로 진행

## Grafana

```java
helm repo add grafana https://grafana.github.io/helm-charts
-> grafana helm-chart 등록

helm pull grafana/grafana
-> tgz 파일로 받아옴

tar xvzf [.tgz]
```

### Grafana에서 사용할 Storageclass 생성

storageclass.yaml

```java
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: grafana
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
  fsType: ext4

--------------------------
kubectl create -f storageclass.yaml

생성 후 확인

kubectl get storageclass
NAME                PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
gp2 (default)       kubernetes.io/aws-ebs   Delete          WaitForFirstConsumer   false                  3h50m
grafana             kubernetes.io/aws-ebs   Delete          Immediate              false                  6m11s

초기 생성된 gp2 말고 grafana의 storageclass에 마운트 시켜야함
```

### Grafana-values

```java
147 service:
148   enabled: true
149   #type: ClusterIP
149   type: LoadBalancer
150   port: 80
151   targetPort: 3000
152     # targetPort: 4181 To be used with a proxy extraContainer
153   annotations: 
				service.beta.kubernetes.io/aws-load-balancer-type: nlb
154   labels: {}
155   portName: service
-> LB 설정하여 외부랑 통신하기 위해 설정

275 persistence:
276   type: pvc
277   enabled: false
278   storageClassName: grafana
279   accessModes:
280     - ReadWriteOnce
281   size: 10Gi
282   # annotations: {}
283   finalizers:
284     - kubernetes.io/pvc-protection
285   # selectorLabels: {}
286   # subPath: ""
287   # existingClaim:

-> Grafana 전용 storageclass에 마운트 하기위해 설정값 수정

326 # Administrator credentials when not using an existing secret (see below)
327 adminUser: admin
328 # adminPassword: strongpassword
329
330 # Use an existing secret for the admin user.
331 admin:
332   existingSecret: ""
333   userKey: admin-user
334   passwordKey: admin-password

-> Grafana UI login admin 계정 생성

Grafana를 설치할 Namespace 생성

kubectl create namespace monitoring

helm install grafana grafana/grafana -n monitoring

1. Get your 'moon' user password by running:

   kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   grafana.monitoring.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:
NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace monitoring -w grafana'
     export SERVICE_IP=$(kubectl get svc --namespace monitoring grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
     http://$SERVICE_IP:80

3. Login with the password from step 1 and the username: moon
```

### Prometheus

```java
1083   service:
1084     ## If false, no Service will be created for the Prometheus server
1085     ##
1086     enabled: true
1087
1088     annotations:
1089       service.beta.kubernetes.io/aws-load-balancer-type: nlb
1090     labels: {}
1091     clusterIP: ""
1092
1093     ## List of IP addresses at which the Prometheus server service is available
1094     ## Ref: https://kubernetes.io/docs/user-guide/services/#external-ips
1095     ##
1096     externalIPs: []
1097
1098     loadBalancerIP: ""
1099     loadBalancerSourceRanges: []
1100     servicePort: 80
1101     sessionAffinity: None
1102     type: LoadBalancer

수정

helm install prometheus . -n monitoring
```

---

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/7a2b78e4-9b5d-473d-b303-267f94be78b4/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/af3b7d20-dbb1-4e63-98bd-fb5ab830f2f2/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/4fa15e6b-c17a-4fdd-96ec-64e90ae45534/Untitled.png)

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/18677980-7c8a-4a85-80cf-404411ad2a56/Untitled.png)

연동 완료

Alertin이나 대시보드는 추후에 작성
