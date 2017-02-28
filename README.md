[![Join the chat at https://gitter.im/openshift/openshift-ansible](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/openshift/openshift-ansible)

# OpenShift 离线安装

为什么非要离线安装：
  - 节点网络环境不允许
  - 加速部署，方便调试

本项目主要实现离线安装，且包含下面的特性：
  - 启用master-HA
  - 指明多网卡时，默认内网通信
  - docker默认使用overlayFS
  - 修改上限，每个node最多可运行1000+个pod
  - 默认开启多租户SDN网络（project间强隔离）
  - 默认安装ceph，gluster，nfs共享存储的依赖组件
  - 启用http-auth认证，内置developer和tester用户

## 实现离线安装

基于openshift-ansible项目的分支``openshift-ansible-3.4.17-1``来搞的，主要改了三个原文件实现的离线部署
```
# git diff --stat HEAD HEAD^
inventory/byo/hosts.origin.example                                          | 61 +++++++++++++++----------------------
roles/openshift_facts/library/openshift_facts.py                            |  2 +-
.../files/origin/repos/openshift-ansible-centos-paas-sig.repo               | 48 ++++++++++++++---------------
3 files changed, 49 insertions(+), 62 deletions(-)
```
其中第二个文件如果不搞容器化的离线安装，没必要改。

一开始想着容器化安装，就可以实现离线安装了， 结果容器化+HA搞完后，发现即使有私有镜像仓，还是需要外网：
  - node上需要一些ansible的python依赖
  - LB节点上需要haproxy的安装

所以目前推荐rpm离线安装

## 自建yum repos

  - 找一台可联接外网的centos， clone此项目
    ```
    git clone --depth=1 https://github.com/xiaoping378/openshift-deploy.git
    cd openshift-deploy
    ```

  - 准备远程yum信息
    - 复制源码里的签名[文件](roles/openshift_repos/files/origin/gpg_keys/openshift-ansible-CentOS-SIG-PaaS)
    ```
    cp roles/openshift_repos/files/origin/gpg_keys/openshift-ansible-CentOS-SIG-PaaS /etc/pki/rpm-gpg/
    ```
    - 备份原yum信息并替换
    ```
    mv /etc/yum.repos.d /etc/yum.repod.d~
    mv offline/yum.repos.d /etc
    ```

  - 执行下面命令，会自动同步下载所需yum源，并启动webserver
    ```
    mkdir repos && cd repos
    yum install -y yum-utils createrepo

    # 必须要导入这个，不然无法同步下载origin的repo仓
    rpm --import /etc/pki/rpm-gpg/openshift-ansible-CentOS-SIG-PaaS

    # 批量下载
    for i in base centos-openshift-origin extras updates then; do reposync --gpgcheck -l --repoid=$i; done
    for i in base centos-openshift-origin extras updates then;  do cd $i && createrepo -v `pwd` && cd ../; done

    #启动webserver，以供其他节点使用
    python -m SimpleHTTPServer
    ```

## 开始安装

  - 源码文件``inventory/byo/hosts.origin.example``， 是我写好的例子

    - 自行修改成自己环境里的nodeIP

  - 在各node上加入离线yum仓信息

    注意修改``createRepo.sh``脚本内容，主要是更换自己环境里webserver的IP

    ```
    ansible -i ./inventory/byo/hosts.origin.example  all -m copy -a 'src="/home/xxp/Github/openshift-deploy/offline/createRepo.sh" dest="/root/createRepo.sh"'
    ansible -i ./inventory/byo/hosts.origin.example all -m shell -a 'bash /root/createRepo.sh'
    ```

  - 开装！

  ```
  ansible-playbook -i ./inventory/byo/hosts.origin.example  playbooks/byo/config.yml
  ```

## 说明

  - 成立独立项目说明， 后期要实践离线环境下，如何平滑升级openshift平台， 1.4->1.5.
  - 更多openshift的实践，可参考[blog](https://github.com/xiaoping378/blog/tree/master/posts)
