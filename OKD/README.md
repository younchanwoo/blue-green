# Tomcat 블루-그린 배포
이 문서는 OpenShift에서 Tomcat 애플리케이션의 blue-green 배포를 설정하고 테스트하는 절차를 설명합니다. 이 배포 전략은 최소한의 다운타임으로 새로운 버전을 배포하기 위해 사용됩니다.

## 1. 사전 준비
### 필수 조건
- OpenShift 클러스터 접근
- Podman/Docker 설치 및 이미지 레지스트리 준비
- 기존 Tomcat 애플리케이션 배포 상태 (`blue` 버전)

## 2. 적용 및 테스트 절차
### 2.1. 현재 상태 확인
먼저, 기존에 배포된 블루 버전이 제대로 실행되고 있는지 확인합니다.

#### 1. 블루 버전 배포 확인
```
]# oc get pods -l version=blue -n tomcat
NAME                           READY   STATUS    RESTARTS   AGE
tomcat-blue-68bf8b59f6-sgztv   1/1     Running   0          15m
```

#### 2. 서비스 및 라우트 상태 확인
```
]# oc get route tomcat -n tomcat
NAME     HOST/PORT                      PATH   SERVICES         PORT   TERMINATION   WILDCARD
tomcat   tomcat-tomcat.apps.cwokd.com          tomcat-service   8080   edge          None

]# oc describe svc tomcat-service 
Name:              tomcat-service
Namespace:         tomcat
Labels:            <none>
Annotations:       <none>
Selector:          app=tomcat,version=blue
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                172.30.188.248
IPs:               172.30.188.248
Port:              <unset>  80/TCP
TargetPort:        8080/TCP
Endpoints:         10.40.8.38:8080
Session Affinity:  None
Events:            <none>

```
위 명령어를 통해 tomcat-service가 블루 파드와 정상적으로 연결되어 있고, 외부에서 Route를 통해 트래픽이 블루 파드로 전달되는지 확인합니다.

#### 3. 트래픽 확인
```
]# ./tail.sh
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
```


### 2.2 그린 버전 배포
아직 트래픽은 블루 버전으로 유지 해야 합니다.

#### 1. 그린 버전 배포 및 버전 상태 확인
```
]# oc apply -f tomcat-green-deployment.yaml
]# oc get pods -l version=green -n tomcat
NAME                           READY   STATUS    RESTARTS   AGE
tomcat-green-9c8cdc968-d5nmq   1/1     Running   0          22s
```
### 3. 트래픽을 블루에서 그린으로 전환
#### 1. 트래픽 전환 스크립트 실행 후 전황 상태 확인
```
]# ./2.change_green.sh
]# oc get svc tomcat-service -n tomcat --output=yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"name":"tomcat-service","namespace":"tomcat"},"spec":{"ports":[{"port":80,"protocol":"TCP","targetPort":8080}],"selector":{"app":"tomcat","version":"blue"}}}
  creationTimestamp: "2024-09-06T01:31:14Z"
  name: tomcat-service
  namespace: tomcat
  resourceVersion: "2451951"
  uid: cf0e92a6-1c2f-484a-bd1a-4fc7e4c16777
spec:
  clusterIP: 172.30.188.248
  clusterIPs:
  - 172.30.188.248
  internalTrafficPolicy: Cluster
  ipFamilies:
  - IPv4
  ipFamilyPolicy: SingleStack
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8080
  selector:
    app: tomcat
    version: green <--
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}

```

#### 2. 트래픽 확인
```
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
BLUE SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
GREEN SCREEN
```


# 요약
* 기존 배포된 블루 버전을 유지하면서 그린 버전을 배포합니다.
* 트래픽을 블루에서 그린으로 전환하며, 각 과정에서 상태를 확인하고, 트래픽 전환 후 그린 버전이 정상적으로 작동하는지 테스트합니다.
* 필요 시 트래픽을 다시 블루로 전환하거나 블루 버전을 종료할 수 있습니다.
