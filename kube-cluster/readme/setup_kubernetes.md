# Setup Kubenetes

## Kubeadm : Bring Your Own Nodes (BYON)
This documents describes how to setup kubernetes from scratch on your own nodes,
without using a managed service.
This setup uses kubeadm to install and configure kubernetes cluster.

## Compatibility

Kubernetes is an open-source system for automating deployment, scaling, and management of containerized applications.

The below steps are applicabe for the below mentioned OS


| OS | Version | Codename |  
| --- | --- | -- |  
| **Ubuntu** | **16.04** | **Xenial** |  


## Initializing Master (As per the Vagrant Setup)

This tutorial assumes **kube-01**  as the master and used **kubeadm as a tool to install and setup the cluster**. This section also assumes that you are using vagrant based setup provided along with this tutorial. If not, please update the IP address of the master accordingly.

To initialize master, run this on kube-01

```
sudo su

hostname -i

kubeadm config images pull

kubeadm init --apiserver-advertise-address 192.168.56.101 --pod-network-cidr=192.168.0.0/16
```
### Initialization of the Nodes (Previously Minions)

After master being initialized, it should display the command which could be used on all worker/nodes to join the k8s cluster.
In kube-02 and kube-03
e.g.
```
kubeadm join 192.168.56.101:6443 --token kw07tc.ltaft1oiooz9f2mt --discovery-token-ca-cert-hash sha256:492fea3562f8517badd4528196a0c2b9bd1c8e8147e35373b87db3bf9f9970d6
```

Copy and paste it on all node (kube-02, kube-03)

##### Troubleshooting Tips
If you lose  the join token, you could retrieve it using

```
kubeadm token list
```

On successfully joining the master, you should see output similar to following,

```
root@kube-03:~# kubeadm join --token c04797.8db60f6b2c0dd078 159.203.170.84:6443 --discovery-token-ca-cert-hash sha256:88ebb5d5f7fdfcbbc3cde98690b1dea9d0f96de4a7e6bf69198172debca74cd0
[kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
[preflight] Running pre-flight checks
[discovery] Trying to connect to API Server "159.203.170.84:6443"
[discovery] Created cluster-info discovery client, requesting info from "https://159.203.170.84:6443"
[discovery] Requesting info from "https://159.203.170.84:6443" again to validate TLS against the pinned public key
[discovery] Cluster info signature and contents are valid and TLS certificate validates against pinned roots, will use API Server "159.203.170.84:6443"
[discovery] Successfully established connection with API Server "159.203.170.84:6443"
[bootstrap] Detected server version: v1.8.2
[bootstrap] The server supports the Certificates API (certificates.k8s.io/v1beta1)

Node join complete:
* Certificate signing request sent to master and response
  received.
* Kubelet informed of new secure connection details.

Run 'kubectl get nodes' on the master to see this machine join.
```

### Setup the admin client - Kubectl

On Master Node
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

**Verification**
```
kubectl get nodes
```
We will see three nodes - kube-01, kube-02, kube-03 in not ready status.
This might take time.

For Watching node status:
```
watch -n 1 kubectl get nodes -o wide
watch -n 1 kubectl get nodes,pods --all-namespaces -o wide
```

## Copy Kubenetes Config from Master (kube-01) to Local Machine (mac)

On Master Node (kube-01)
```cat /etc/kubernetes/admin.conf```

On Local Machine (Mac Os)
```nano .kube/config```

**Verification**
```kubectl get nodes```

Output :
NAME      STATUS     ROLES    AGE     VERSION
kube-01   NotReady   master   12m     v1.14.1
kube-02   NotReady   <none>   8m47s   v1.14.1
kube-03   NotReady   <none>   8m45s   v1.14.1

Note : Permission for config should be set correctly in order to work.
-rw-r--r--  1 ashimkhadka  staff   5.3K May 13 23:13 .kube/config


## Installing CNI (Container Network Interface) with Weave

Installing overlay network is necessary for the pods to communicate with each other across the hosts. It is necessary to do this before you try to deploy any applications to your cluster.

There are various overlay networking drivers available for kubernetes. We are going to use **Weave Net**.

As soon as, you execute following command every node will be in ready state. (Might take few minutes)

Execute it from local machine (mac).
```
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"
```

```
Output :
serviceaccount/weave-net created
clusterrole.rbac.authorization.k8s.io/weave-net created
clusterrolebinding.rbac.authorization.k8s.io/weave-net created
role.rbac.authorization.k8s.io/weave-net created
rolebinding.rbac.authorization.k8s.io/weave-net created
daemonset.extensions/weave-net created
```

## Validating the Setup

You could validate the status of this cluster, health of pods and whether all the components are up or not by using a few or all of the following commands.

To check if nodes are ready

```
kubectl get nodes
kubectl get cs
```

[ Expected output ]

```
root@kube-01:~# kubectl get nodes
NAME      STATUS    ROLES     AGE       VERSION
kube-01   Ready     master    9m        v1.8.2
kube-02   Ready     <none>    4m        v1.8.2
kube-03   Ready     <none>    4m        v1.8.2
```

Additional Status Commands

```
kubectl version
```

```
kubectl cluster-info
Kubernetes master is running at https://192.168.56.101:6443
KubeDNS is running at https://192.168.56.101:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

```
kubectl get pods -n kube-system

kubectl get events

```

It will take a few minutes to have the cluster up and running with all the services.

### Possible Issues
  * Nodes are node in Ready status
  * kube-dns is crashing constantly
  * Some of the systems services are not up

Most of the times, kubernetes does self heal, unless its a issue with system resources not being adequate. Upgrading resources or launching it on bigger capacity VM/servers solves it. However, if the issues persist, you could try following techniques,

Troubleshooting Tips

Check events
```
kubectl get events
```

Check Logs
```
kubectl get pods -n kube-system

[get the name of the pod which has a problem]

kubectl logs <pod> -n kube-system

```

e.g.

```
root@kube-01:~# kubectl logs kube-dns-545bc4bfd4-dh994 -n kube-system
Error from server (BadRequest): a container name must be specified for pod kube-dns-545bc4bfd4-dh994, choose one of:
[kubedns dnsmasq sidecar]


root@kube-01:~# kubectl logs kube-dns-545bc4bfd4-dh994  kubedns  -n kube-system
I1106 14:41:15.542409       1 dns.go:48] version: 1.14.4-2-g5584e04
I1106 14:41:15.543487       1 server.go:70] Using

....

```

## Enable Kubernetes Dashboard

After the Pod networks is installled, We can install another add-on service which is Kubernetes Dashboard.

Execute from local machine (mac).

Installing Dashboard:
```
kubectl apply -f https://gist.githubusercontent.com/initcron/32ff89394c881414ea7ef7f4d3a1d499/raw/4863613585d05f9360321c7141cc32b8aa305605/kube-dashboard.yaml

Output :
serviceaccount/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.extensions/kubernetes-dashboard created
service/kubernetes-dashboard created
```
This will create a pod for the Kubernetes Dashboard.

Check the status
```
watch -n 1 kubectl get pods,deploy,svc --all-namespaces -o wide
```

To access the Dashboard in th browser, run the below command
```
kubectl get svc -n kube-system

OR

kubectl describe svc kubernetes-dashboard -n kube-system
```

Sample output:
```
kubectl describe svc kubernetes-dashboard -n kube-system
Name:                     kubernetes-dashboard
Namespace:                kube-system
Labels:                   k8s-app=kubernetes-dashboard
Annotations:              kubectl.kubernetes.io/last-applied-configuration:
                            {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"k8s-app":"kubernetes-dashboard"},"name":"kubernetes-dashboard"...
Selector:                 k8s-app=kubernetes-dashboard
Type:                     NodePort
IP:                       10.109.207.58
Port:                     <unset>  80/TCP
TargetPort:               9090/TCP
NodePort:                 <unset>  31000/TCP
Endpoints:                10.40.0.3:9090
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
In my case, port 31000 is the nodeport.
```

Now check for the node port, here it is 32756, and go to the browser,

```
http://MASTERIP:31000
http://NODEIP:31000
```

```
http://192.168.56.101:31000
OR
http://192.168.56.102:31000
OR
http://192.168.56.103:31000
```
The Dashboard Looks like:

![alt text](images/Kubernetes-Dashboard.png "Kubernetes Dashboard")

## Check out the supporting code

Before we proceed further, please checkout the code from the following git repo. This would offer the supporting code for the exercises that follow.

```
git clone https://github.com/schoolofdevops/k8s-code.git
```

## Kubernetes Visualizer

In this chapter we will see how to set up kubernetes visualizer that will show us the changes in our cluster in real time.

### Set up
Fork the repository and deploy the visualizer on kubernetes

```
git clone  https://github.com/schoolofdevops/kube-ops-view

kubectl apply -f kube-ops-view/deploy/
```

```
[Sample Output]

serviceaccount/kube-ops-view created
clusterrole.rbac.authorization.k8s.io/kube-ops-view created
clusterrolebinding.rbac.authorization.k8s.io/kube-ops-view created
deployment.apps/kube-ops-view created
ingress.extensions/kube-ops-view created
deployment.apps/kube-ops-view-redis created
service/kube-ops-view-redis created
service/kube-ops-view created
Get the nodeport for the service.
```

```
kubectl get svc

[output]
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kube-ops-view         NodePort    10.107.141.89   <none>        80:32000/TCP   3m36s
kube-ops-view-redis   ClusterIP   10.107.30.210   <none>        6379/TCP       3m36s
kubernetes            ClusterIP   10.96.0.1       <none>        443/TCP        47m
In my case, port 32000 is the nodeport.
```

Visit the port from the browser. You could add /#scale=2.0 or similar option where 2.0 = 200% the scale.
```
http://<NODE_IP:NODE_PORT>/#scale=2.0
```

```
http://192.168.56.101:32000/#scale=2.0
http://192.168.56.102:32000/#scale=2.0
http://192.168.56.103:32000/#scale=2.0
```