k8s_node=`sudo kubectl  get nodes | awk 'NR>1{print $1}'`

sudo kubectl label node $k8s_node master_controller=enable
sudo kubectl label node $k8s_node tsdb=enable
sudo kubectl label node $k8s_node dfdb=enable
sudo kubectl label node $k8s_node elasticsearch-warm=enable
