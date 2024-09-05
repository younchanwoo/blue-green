#!/bin/bash

# 스크립트를 루트 권한으로 실행하는지 확인합니다.
if [ "$EUID" -ne 0 ]; then
  echo "이 스크립트를 루트 권한으로 실행해야 합니다."
  exit
fi

echo "Jenkins 서비스를 중지하고 제거 중입니다..."

# Jenkins 서비스 중지
systemctl stop jenkins
systemctl disable jenkins

# Jenkins 패키지 제거
dnf remove -y jenkins

# Jenkins 관련 디렉토리 제거
rm -rf /var/lib/jenkins /var/log/jenkins /var/cache/jenkins

# 방화벽에서 Jenkins 포트(8080) 닫기
echo "방화벽에서 Jenkins 포트(8080) 닫기"
firewall-cmd --permanent --zone=public --remove-port=8080/tcp
firewall-cmd --reload

# Jenkins 저장소 제거
echo "Jenkins 저장소를 제거 중입니다..."
rm -f /etc/yum.repos.d/jenkins.repo

echo "Jenkins가 시스템에서 완전히 제거되었습니다."

