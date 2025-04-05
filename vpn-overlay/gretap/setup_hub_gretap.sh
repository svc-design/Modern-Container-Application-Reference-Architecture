# 添加 br0 和多个 gretap 接口（每个分支一个）
ip link add gretap_a type gretap local 10.100.0.1 remote 10.100.0.2
ip link add gretap_b type gretap local 10.100.0.1 remote 10.100.0.3
ip link add gretap_c type gretap local 10.100.0.1 remote 10.100.0.4

ip link add br0 type bridge
brctl addif br0 gretap_a
brctl addif br0 gretap_b
brctl addif br0 gretap_c
ip addr add 172.16.0.1/16 dev br0
ip link set br0 up

