#!/bin/bash
cd /etc/yum.repos.d/
[ -f CentOS-PAAS-local.repo ] && exit 0
for i in `ls`; do mv -f $i `echo $i".bak"`; done
cat <<EOF>>CentOS-PAAS-local.repo
[Base]
name=local base\$basearch
baseurl=http://192.168.56.1:8000/base/
enable=1
gpgcheck=0
[extras]
name=local extras \$basearch
baseurl=http://192.168.56.1:8000/extras/
enable=1
gpgcheck=0
[updates]
name=local updates \$basearch
baseurl=http://192.168.56.1:8000/updates/
enable=1
gpgcheck=0
[origin]
name=local origin \$basearch
baseurl=http://192.168.56.1:8000/centos-openshift-origin/
enable=1
gpgcheck=0
EOF
yum clean all
yum makecache
