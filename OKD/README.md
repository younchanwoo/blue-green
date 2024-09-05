# Tomcat 블루-그린 배포
이 문서는 OpenShift에서 Tomcat 애플리케이션의 blue-green 배포를 설정하고 테스트하는 절차를 설명합니다. 이 배포 전략은 최소한의 다운타임으로 새로운 버전을 배포하기 위해 사용됩니다.

## 1. 사전 준비
### 필수 조건
- OpenShift 클러스터 접근
- Podman/Docker 설치 및 이미지 레지스트리 준비
- 기존 Tomcat 애플리케이션 배포 상태 (`blue` 버전)

## 2. 배포 절차
### 2.1. `blue` 버전 애플리케이션 기동
먼저 `blue` 버전의 Tomcat 애플리케이션을 배포합니다.

#### blue-pod-deployment.yaml 예시:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat-blue
  namespace: tomcat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tomcat
      version: blue
  template:
    metadata:
      labels:
        app: tomcat
        version: blue
    spec:
      containers:
      - name: tomcat
        image: "bastion.cwokd.com:444/tomcat:v5.0"
        ports:
        - containerPort: 8080
      securityContext:
        runAsUser: 0
```

### 2.2. `green` 버전 애플리케이션 배포
`blue` 버전이 정상적으로 기동된 상태에서, 새로운 버전인 `green` 버전을 배포합니다.

#### green-pod-deployment.yaml 예시:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat-green
  namespace: tomcat
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tomcat
      version: green
  template:
    metadata:
      labels:
        app: tomcat
        version: green
    spec:
      containers:
      - name: tomcat
        image: "bastion.cwokd.com:444/tomcat:v5.1"
        ports:
        - containerPort: 8080
      securityContext:
        runAsUser: 0
```

### 2.3. 프록시 설정 및 트래픽 전환
블루-그린 배포를 위해 프록시(Service)를 설정하여 트래픽을 관리합니다.

#### tomcat-service.yaml  예시:
```
apiVersion: v1
kind: Service
metadata:
  name: tomcat-service
  namespace: tomcat
spec:
  selector:
    app: tomcat
    version: blue  # 기본적으로 blue 버전으로 트래픽 라우팅
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

`green` 버전이 준비되면, `svc`의 `selector`를 `blue`에서 `green`으로 변경하여 트래픽을 새 버전으로 전환합니다.

#### 트래픽 전환 예시
```
oc patch svc tomcat-service -p '{"spec":{"selector":{"app":"tomcat", "version":"green"}}}'
```

### 2.4. blue 버전 종료
트래픽이 `green` 버전으로 전환된 후, 기존 `blue` 버전을 안전하게 종료합니다.
```
oc delete deployment tomcat-blue
```

## 3. 배포 테스트
### 3.1. green 버전 배포 확인
`green` 버전으로 트래픽이 전환되었는지 확인합니다.
```
oc get pods -l version=green -n tomcat
```

### 3.2. 정상 동작 확인
애플리케이션에 접속하여 새로운 `green` 버전이 정상적으로 동작하는지 확인합니다.

```
curl http://<your-route-url>
```

## 4. 요약
* `blue` 파드를 먼저 실행하여 기존 버전을 유지
* `green` 파드를 기동한 후 트래픽을 `green`으로 전환
* 전환 후 `blue` 파드를 안전하게 종료
