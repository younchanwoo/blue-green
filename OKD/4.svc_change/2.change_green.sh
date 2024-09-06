#!/bin/bash

oc patch svc tomcat-service -n tomcat -p '{"spec": {"selector": {"app": "tomcat", "version": "green"}}}'
