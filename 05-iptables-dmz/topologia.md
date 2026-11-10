# Topología y pruebas del firewall iptables (EV2)

Laboratorio en Oracle VirtualBox. Un firewall Ubuntu con tres adaptadores hace de router entre las zonas WAN, DMZ y LAN.

```
Internet ── enp0s3 (WAN, NAT) ── [Firewall Ubuntu] ── enp0s8 (DMZ 192.168.56.1/24) ── Metasploitable 192.168.56.200
                                       └── enp0s9 (LAN 192.168.100.1/24) ── Windows 192.168.100.200
```

| Interfaz | Adaptador | Zona | IP |
|---|---|---|---|
| `enp0s3` | NAT | WAN / Internet | DHCP de VirtualBox (10.0.2.15/24) |
| `enp0s8` | Solo Anfitrión | DMZ | 192.168.56.1/24 estática |
| `enp0s9` | Red interna | LAN | 192.168.100.1/24 estática |

Equipos: Metasploitable `192.168.56.200/24` (DMZ) y cliente Windows `192.168.100.200/24` con gateway `192.168.100.1` (LAN).

Script completo: [`firewall.sh`](firewall.sh).

## Políticas
| Cadena | Inicial | Configurada |
|---|---|---|
| INPUT | ACCEPT | **DROP** |
| FORWARD | ACCEPT | **DROP** |
| OUTPUT | ACCEPT | ACCEPT |

## NAT / MASQUERADE (LAN → Internet)
Se activa `net.ipv4.ip_forward = 1` y se crea la regla `MASQUERADE` de `192.168.100.0/24` hacia `enp0s3`.

![Habilitación de ip_forward (sysctl -p devuelve net.ipv4.ip_forward = 1), regla MASQUERADE, FORWARD LAN-WAN y salida de iptables -t nat -L -n -v](../evidencias/05-iptables-dmz/01-ip-forward-y-nat.png)

![Salida de sudo iptables -t nat -L -n -v: cadena POSTROUTING con MASQUERADE all, out enp0s3, source 192.168.100.0/24](../evidencias/05-iptables-dmz/02-nat-masquerade.png)

## SSH solo desde la LAN
```bash
sudo iptables -L INPUT -n -v --line-numbers
```
| # | Objetivo | Prot | In | Origen | Condición |
|---|---|---|---|---|---|
| 1 | ACCEPT | all | lo | 0.0.0.0/0 | |
| 2 | ACCEPT | all | enp0s3 | 0.0.0.0/0 | state RELATED,ESTABLISHED |
| 3 | ACCEPT | tcp | enp0s8 | 0.0.0.0/0 | tcp dpt:22 |
| 4 | ACCEPT | tcp | enp0s9 | 192.168.100.0/24 | tcp dpt:22 |
| 5 | DROP | tcp | * | 0.0.0.0/0 | tcp dpt:22 |

> Nota: la regla 3 (SSH aceptado por `enp0s8`, la DMZ) aparece en la captura, pero el comando que la creó no está en el informe. Con ella, el SSH también se acepta desde la DMZ.

![Salida de sudo iptables -L INPUT -n -v --line-numbers: política DROP y reglas 1 a 5, incluido ACCEPT tcp dpt:22 desde 192.168.100.0/24 por enp0s9 y DROP tcp dpt:22](../evidencias/05-iptables-dmz/03-input-ssh-solo-lan.png)

Desde el Windows de la LAN (192.168.100.200) la conexión SSH con PuTTY funcionó. Desde un equipo fuera de `192.168.100.0/24`, el intento `ssh alumno@192.168.100.1` termina en `Connection timed out`:

![Git Bash en un equipo fuera de la LAN: ssh alumno@192.168.100.1 responde "connect to host 192.168.100.1 port 22: Connection timed out"](../evidencias/05-iptables-dmz/04-ssh-bloqueado-fuera-lan.png)

## ICMP entre LAN y DMZ
Las reglas `FORWARD` permiten ICMP en ambos sentidos entre `enp0s9` (LAN) y `enp0s8` (DMZ).

![Ping desde Windows en la LAN a Metasploitable 192.168.56.200: 4 enviados, 4 recibidos, 0% perdidos, TTL=63](../evidencias/05-iptables-dmz/05-ping-lan-a-dmz.png)
