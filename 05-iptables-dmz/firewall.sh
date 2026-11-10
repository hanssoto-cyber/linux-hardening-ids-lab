#!/usr/bin/env bash
# Firewall perimetral Ubuntu (EV2, VirtualBox): zonas WAN / DMZ / LAN con NAT.
#   enp0s3 = WAN (NAT de VirtualBox, DHCP 10.0.2.15/24)
#   enp0s8 = DMZ (192.168.56.1/24)  -> Metasploitable 192.168.56.200
#   enp0s9 = LAN (192.168.100.1/24) -> Windows 192.168.100.200
# Comandos tal como aparecen en el informe EV2, secciones 1.2 a 1.6.
set -euo pipefail

# --- 1.2 Estado inicial --------------------------------------------------------
# firewalld no existe en Ubuntu (es propio de Red Hat/CentOS)
sudo systemctl status firewalld || true
sudo iptables --version
sudo iptables -L -n -v

# --- 1.3 Políticas por defecto y reglas generales -----------------------------
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Loopback
sudo iptables -A INPUT -i lo -j ACCEPT
# Conexiones establecidas/relacionadas en la WAN
sudo iptables -A INPUT -i enp0s3 -m state --state ESTABLISHED,RELATED -j ACCEPT

# --- 1.4 NAT / POSTROUTING (LAN -> Internet) -----------------------------------
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p

sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o enp0s3 -j MASQUERADE
sudo iptables -A FORWARD -i enp0s9 -o enp0s3 -j ACCEPT
sudo iptables -A FORWARD -i enp0s3 -o enp0s9 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -L -n -v

# --- 1.5 SSH solo desde la LAN -------------------------------------------------
# NOTA: la captura de "iptables -L INPUT --line-numbers" (03-input-ssh-solo-lan.png)
# muestra además, en la posición 3, la regla:
#   ACCEPT tcp -- enp0s8 * 0.0.0.0/0 0.0.0.0/0 tcp dpt:22
# (SSH aceptado desde la DMZ). El comando que la creó NO está documentado en el
# informe, por eso no se incluye aquí.
sudo iptables -A INPUT -i enp0s9 -s 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j DROP
sudo iptables -L INPUT -n -v --line-numbers

# --- 1.6 ICMP entre LAN y DMZ --------------------------------------------------
cat /proc/sys/net/ipv4/ip_forward
sudo iptables -A FORWARD -i enp0s9 -o enp0s8 -p icmp -j ACCEPT   # LAN -> DMZ
sudo iptables -A FORWARD -i enp0s8 -o enp0s9 -p icmp -j ACCEPT   # DMZ -> LAN (respuestas)
sudo iptables -L FORWARD -n -v --line-numbers
