# Arquitectura del laboratorio

El laboratorio se ejecutó en dos fases, cada una con su propio entorno virtualizado y aislado.

## Fase A: hardening e IDS (VMware Workstation 17 Pro)

Tres máquinas virtuales conectadas a una red **Solo Anfitrión (Host-Only)** aislada, `192.168.56.0/24`. Los servidores Linux tienen además un adaptador NAT para salir a Internet.

| Equipo | Sistema operativo | Rol | IP Host-Only |
|---|---|---|---|
| `ossec-hanssoto` | Ubuntu 18.04.6 LTS | Servidor OSSEC / objetivo de análisis | 192.168.56.10 |
| `snort-hanssoto` | Ubuntu 24.04.2 LTS | Servidor Snort (NIDS) | 192.168.56.20 |
| `WIN-HANSSOTO` | Windows 10 Pro | Cliente / agente OSSEC | 192.168.56.100 |

```
            Red Host-Only 192.168.56.0/24 (aislada)
   ┌──────────────────────┬───────────────────────────┐
   │                      │                           │
ossec-hanssoto         snort-hanssoto              WIN-HANSSOTO
192.168.56.10          192.168.56.20               192.168.56.100
Servidor OSSEC         Snort 2.9.20 (iface ens34)  Agente OSSEC 3.7.0
Lynis / objetivo       Origen del escaneo Nmap
```

Flujos usados en las pruebas:
- `snort-hanssoto` → `ossec-hanssoto`: escaneo externo con Nmap.
- `WIN-HANSSOTO` → `ossec-hanssoto`: SSH al puerto 2222 con clave; agente OSSEC (1514/udp, 1515/tcp).
- `WIN-HANSSOTO` y `ossec-hanssoto` → `snort-hanssoto`: tráfico de prueba para las reglas de Snort.

## Fase B: perímetro con iptables (Oracle VirtualBox)

Un firewall Ubuntu con tres adaptadores actúa como router entre tres zonas:

| Interfaz | Adaptador VirtualBox | Zona | Dirección |
|---|---|---|---|
| `enp0s3` | NAT | WAN / Internet | DHCP de VirtualBox (10.0.2.15/24) |
| `enp0s8` | Solo Anfitrión | DMZ | 192.168.56.1/24 |
| `enp0s9` | Red interna | LAN | 192.168.100.1/24 |

| Equipo | Zona | Dirección |
|---|---|---|
| Metasploitable | DMZ | 192.168.56.200/24 |
| Cliente Windows | LAN | 192.168.100.200/24, gateway 192.168.100.1 |

```
Internet ── enp0s3 (WAN, NAT) ── [Firewall Ubuntu] ── enp0s8 (DMZ 192.168.56.1/24) ── Metasploitable 192.168.56.200
                                       └── enp0s9 (LAN 192.168.100.1/24) ── Windows 192.168.100.200
```

En esta fase el mismo firewall Ubuntu actúa también como servidor OSSEC, y el agente Windows apunta a `192.168.100.1`. Detalle en [`05-iptables-dmz/topologia.md`](../05-iptables-dmz/topologia.md) y [`03-ossec/agente-windows.md`](../03-ossec/agente-windows.md).
