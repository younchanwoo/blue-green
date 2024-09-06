#!/bin/bash

# 블루 버전으로 트래픽 전환
oc patch svc tomcat-service -n tomcat -p '{"spec": {"selector": {"app": "tomcat", "version": "blue"}}}'
