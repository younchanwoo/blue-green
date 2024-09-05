#!/bin/bash

# 스크립트를 루트 권한으로 실행하는지 확인합니다.
if [ "$EUID" -ne 0 ]; then
  echo "이 스크립트를 루트 권한으로 실행해야 합니다."
  exit
fi

# 시스템 업데이트
dnf -y update

# Java 17 설치
dnf install -y java-17-openjdk

# Jenkins 저장소 추가 및 GPG 키 가져오기
dnf config-manager --add-repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key

# Jenkins 패키지 설치 (GPG 체크 활성화)
dnf install -y jenkins

# Jenkins 서비스가 제대로 설치되었는지 확인
if ! systemctl list-unit-files | grep -q jenkins.service; then
    echo "Jenkins 서비스 파일이 설치되지 않았습니다. 설치를 다시 시도하세요."
    exit 1
fi

# Jenkins 서비스를 시작하고 부팅 시 자동 시작 설정
systemctl enable --now jenkins

# Jenkins 초기화가 완료될 때까지 대기 (약 30초, 상황에 따라 조정 가능)
sleep 30

# 방화벽에서 Jenkins 포트(8080) 열기
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --reload

# 설치 및 서비스 상태 확인
echo "Jenkins 설치 완료 및 서비스 상태:"
systemctl status jenkins

# 초기 비밀번호 확인 안내
echo "Jenkins 초기 비밀번호를 확인하려면 다음 명령을 사용하세요:"
echo "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
