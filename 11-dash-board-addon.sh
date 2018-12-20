
X="- apiGroups:
  - \"\"
  resources:
  - nodes/stats
  verbs:
  - get"

kubectl get clusterroles system:heapster -o yaml >heapster_role.yaml
echo "${X}" >>heapster_role.yaml
kubectl apply -f heapster_role.yaml

mkdir dash-board
cd dash-board

YAML_FILES="grafana.yaml
heapster.yaml
influxdb.yaml"

for FILE in ${YAML_FILES}
do
 wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/${FILE}
done
cd ..
wget https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml

sed -i 's@--source=kubernetes:https://kubernetes\.default@--source=kubernetes.summary_api:https://kubernetes.default?kubeletHttps=true\&kubeletPort=10250\&insecure=true@' dash-board/heapster.yaml

kubectl create -f dash-board
kubectl create -f heapster-rbac.yaml
sleep 10
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
kubectl create serviceaccount cluster-admin-dashboard-sa
kubectl create clusterrolebinding cluster-admin-dashboard-sa \
  --clusterrole=cluster-admin \
  --serviceaccount=default:cluster-admin-dashboard-sa

kubectl describe secret $(kubectl get secret | grep cluster-admin-dashboard-sa|awk '{print $1}') |awk '/token/{print $2}' >~/.dash_token
