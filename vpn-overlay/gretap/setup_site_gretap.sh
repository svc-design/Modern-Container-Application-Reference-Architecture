
#!/bin/bash

# 启动 WireGuard
wg-quick up wg0

# gretap to Site A
ip link add gretap_a type gretap local 10.100.0.1 remote 10.100.0.2
ip link set gretap_a up

# gretap to Site B
ip link add gretap_b type gretap local 10.100.0.1 remote 10.100.0.3
ip link set gretap_b up

# 创建桥接
ip link add br0 type bridge
ip link set gretap_a master br0
ip link set gretap_b master br0
ip addr add 172.16.0.1/16 dev br0
ip link set br0 up

