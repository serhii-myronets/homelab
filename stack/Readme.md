docker network create -d macvlan \
--subnet=192.168.1.0/24 \
--ip-range=192.168.1.8/29 \
--gateway=192.168.1.1 \
-o parent=enp1s0 lan_infra