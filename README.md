# Nginx와 Apache를 사용한 블루-그린 배포
Docker Compose를 사용하여 Nginx와 Apache를 설정하고, 블루-그린 배포 전략을 구현하는 방법을 설명합니다. 이 설정은 두 개의 Nginx 인스턴스를 각각 Blue와 Green 환경으로 구성하여, 애플리케이션의 무중단 배포와 신속한 롤백을 가능하게 합니다.

## Blue Green배포란?
``Blue Green배포``는 애플리케이션 업데이트 시 서비스 중단을 최소화하고, 배포 과정에서 발생할 수 있는 문제를 신속하게 해결하기 위해 사용되는 전략입니다. 이 전략은 다음과 같은 방식으로 동작합니다.
1. ``Blue 환경``: 현재 운영 중인 애플리케이션이 배포되어 있는 환경입니다.
2. ``Green 환경``: 새 버전의 애플리케이션이 배포되고 테스트되는 환경입니다.
3. ``트래픽 전환``: Green 환경에서 새 버전의 애플리케이션이 안정적으로 동작하는 것이 확인되면, 트래픽을 Blue 환경에서 Green 환경으로 전환합니다.
4. ``롤백``: 만약 Green 환경에서 문제가 발생하면, 즉시 Blue 환경으로 트래픽을 다시 전환하여 문제를 해결할 수 있습니다.

# 파일구조
```
.
├── docker-compose.yml
├── /tmp
│   ├── blue
│   │   └── index.html
│   └── green
│       └── index.html
└── /conf.d
    └── default.conf
```
* docker-compose.yml: Nginx의 두 개 인스턴스를 설정한 Docker Compose 파일입니다(nginx-blue와 nginx-green).
* /tmp/blue: Blue 환경에서 사용할 HTML 파일이 저장된 디렉토리입니다.
* /tmp/green: Green 환경에서 사용할 HTML 파일이 저장된 디렉토리입니다.
* /conf.d/default.conf: 두 Nginx 인스턴스가 사용하는 Nginx 설정 파일입니다.

# 설정 방법
## 1. 환경준비
Blue와 Green 환경에 필요한 디렉토리와 HTML 파일을 준비합니다.

Blue 환경:
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Blue Deployment</title>
</head>
<body style="background-color: lightblue; text-align: center;">
    <h1>Blue Deployment</h1>
    <p>This is the blue environment.</p>
    <img src="blue.png" alt="Blue Image" style="width:300px;">
</body>
</html>
```

Green 환경:
```
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Green Deployment</title>
</head>
<body style="background-color: lightgreen; text-align: center;">
    <h1>Green Deployment</h1>
    <p>This is the green environment.</p>
    <img src="green.png" alt="Green Image" style="width:300px;">
</body>
</html>
```
## 2. Nginx 설정 파일 작성
Nginx가 HTML 파일을 서빙할 수 있도록 설정 파일을 준비합니다.

```
]# mkdir -p /conf.d
server {
    listen 80;
    server_name localhost;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    error_page 404 /404.html;
    location = /404.html {
        root /usr/share/nginx/html;
    }
}
```

## 3. Docker Compose 작성 후 실행
docker-compose.yml 파일을 준비 후 실행을 합니다.

```
]# vi docker-compose.yml
version: '3'
services:
  nginx-blue:
    image: nginx:latest
    container_name: nginx-blue
    user: root  # 루트 사용자로 Nginx 실행
    volumes:
      - /tmp/blue:/usr/share/nginx/html:ro
      - /conf.d/default.conf:/etc/nginx/conf.d/default.conf
    ports:
      - "8081:80"
    networks:
      - bluegreen-net

  nginx-green:
    image: nginx:latest
    container_name: nginx-green
    user: root  # 루트 사용자로 Nginx 실행
    volumes:
      - /tmp/green:/usr/share/nginx/html:ro
      - /conf.d/default.conf:/etc/nginx/conf.d/default.conf
    ports:
      - "8082:80"
    networks:
      - bluegreen-net

networks:
  bluegreen-net:
    driver: bridge

]# docker-compose up -d
```

## 4. Apache HTTP 서버 설정 (Optional)
Apache HTTP 서버를 리버스 프록시로 설정할 수 있습니다.

```
]# yum install httpd
]# systemctl start httpd
]# systemctl stop firewalld
]# /usr/sbin/setsebool -P httpd_can_network_connect 1

# Apache 리버스 프록시 설정
]# vim /etc/httpd/conf.d/reverseproxy.conf
```

`reverseproxy.conf` 파일에 다음과 같이 설정합니다.
```
<VirtualHost *:80>
    ProxyPreserveHost On
    ProxyPass / http://localhost:8081/
    ProxyPassReverse / http://localhost:8081/
</VirtualHost>
```

## 5. 배포 테스트
브라우저에서 다음 URL을 통해 Blue와 Green 환경을 테스트합니다.

* Blue 환경: http://<서버-IP>:8082/index.html
* Green 환경: http://<서버-IP>:8083/index.html

정상적으로 페이지가 표시되는지 확인합니다.

## 6. 지속적인 모니터링
Apache HTTP 서버가 Nginx 인스턴스들을 올바르게 프록시하고 있는지 지속적으로 확인하기 위해 다음 명령어를 실행합니다.
```
while true; do curl localhost:80; sleep 1; done
```

## 7. 트래픽 전환 및 모니터링
실제 운영 환경에서 트래픽을 Blue 또는 Green 환경으로 전환하며, 필요시 빠르게 롤백할 수 있습니다.
