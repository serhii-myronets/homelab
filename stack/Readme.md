# Create macvlan network
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --ip-range=192.168.1.8/29 \
  --gateway=192.168.1.1 \
  -o parent=enp1s0 \
  lan_infra

# Create host macvlan interface
sudo ip link add mac0 link enp1s0 type macvlan mode bridge
sudo ip addr add 192.168.1.200/24 dev mac0
sudo ip link set mac0 up

# Route for host ↔ macvlan communication
sudo ip route add 192.168.1.8/29 dev mac0


Proxmox 

mkdir -p /mnt/media
mount /dev/sda1 /mnt/data

pct set 100 -mp0 /mnt/data,mp=/mnt/data
