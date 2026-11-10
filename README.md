# linux-hardening-ids-lab

Laboratorio académico (IPLACEX) de **hardening de Linux, firewall con iptables, detección de intrusiones en host (OSSEC) y en red (Snort)**, ejecutado en máquinas virtuales aisladas.

> Entorno de laboratorio: no es un sistema en producción. Para un servidor real endurecido, ver [`vps-hardening-lab`](https://github.com/hanssoto-cyber/vps-hardening-lab).

## Resumen de resultados
| Área | Resultado |
|---|---|
| Auditoría (Lynis) | Hardening index **58 → 63** tras aplicar controles |
| Escaneo externo (Nmap) | Puertos 22/OpenSSH 7.6p1 y 80/Apache 2.4.29 abiertos; sin firewall (hallazgo FIRE-4512) |
| SSH | Puerto 2222, solo claves ed25519, `PermitRootLogin no` |
| Firewall | UFW con entrada denegada por defecto; iptables con zonas WAN/DMZ/LAN y NAT |
| Contraseñas | `pam_pwquality`: 12 caracteres, mayúsculas, minúsculas, dígitos y símbolos |
| HIDS | OSSEC servidor + agente Windows: alertas User account changed (regla 18111, nivel 8), generada al crear el usuario auditoria_hsoto, cambio de grupo (18233) e inicios de sesión (18107) |
| NIDS | Snort con 4 reglas propias (accesos no autorizados, escaneo de puertos, shell remoto) |

## Arquitectura
**Fase A: hardening e IDS (VMware, red aislada 192.168.56.0/24)**
| Host | SO | Rol |
|---|---|---|
| `ossec-hanssoto` | Ubuntu 18.04.6 | Servidor OSSEC y objetivo de auditoría |
| `snort-hanssoto` | Ubuntu 24.04.2 | NIDS Snort y origen del escaneo |
| `WIN-HANSSOTO` | Windows 10 Pro | Cliente y agente OSSEC |

**Fase B: perímetro (VirtualBox)**
```
Internet ── enp0s3 (WAN, NAT) ── [Firewall Ubuntu] ── enp0s8 (DMZ 192.168.56.1/24) ── Metasploitable 192.168.56.200
                                       └── enp0s9 (LAN 192.168.100.1/24) ── Windows 192.168.100.200
```

## Estructura del repositorio
```
linux-hardening-ids-lab/
├── README.md
├── LICENSE
├── docs/
│   ├── arquitectura.md            # diagramas y direccionamiento
│   ├── lecciones-y-mejoras.md     # qué se haría distinto
│   └── informe-original.pdf       # opcional, sin datos sensibles
├── 01-evaluacion/
│   ├── lynis-antes.md             # índice 58 y hallazgos clave
│   ├── nmap-externo.md            # sudo nmap -sS -sV -O -p- <objetivo>
│   └── analisis-windows.md        # Nmap -Pn y comandos PowerShell
├── 02-hardening/
│   ├── ssh/sshd_config.hardened   # Port 2222, PasswordAuthentication no, PermitRootLogin no
│   ├── ufw/reglas.sh              # deny incoming; allow 2222/tcp, 1514/udp, 1515/tcp
│   ├── pam/common-password.snippet# pam_pwquality (minlen=12, complejidad)
│   └── lynis-despues.md           # índice 63
├── 03-ossec/
│   ├── instalacion-servidor.md
│   ├── agente-windows.md          # manage_agents, clave (NO publicar la clave real)
│   └── alertas-probadas.md        # reglas 18111, 18233, 18107
├── 04-snort/
│   ├── local.rules                # las 4 reglas personalizadas
│   └── pruebas.md                 # ping ICMP, intento SSH, nmap 1-100
├── 05-iptables-dmz/
│   ├── firewall.sh                # script con las reglas
│   └── topologia.md
└── evidencias/                    # capturas sanitizadas (sin IP públicas ni claves)
```

## Comandos clave
```bash
# Auditoría interna
sudo lynis audit system

# Escaneo externo (desde otra VM)
sudo nmap -sS -sV -O -p- 192.168.56.10

# Validar sshd antes de reiniciar
sudo sshd -t && sudo systemctl restart ssh

# Validar configuración de Snort
sudo snort -T -c /etc/snort/snort.conf
```

```bash
# iptables: política restrictiva y NAT (zona LAN)
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -i enp0s3 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o enp0s3 -j MASQUERADE
# SSH solo desde la LAN
sudo iptables -A INPUT -i enp0s9 -s 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j DROP
```

## Lecciones y mejoras
- El índice de Lynis solo subió de 58 a 63: quedaron sugerencias pendientes (auditd, banner legal, umask restrictivo). En el servidor real se llegó a 75.
- Enviar las alertas de OSSEC y Snort a un SIEM (ELK) para correlación.
- Probar las reglas de Snort contra técnicas más variadas y medir falsos positivos.

## Tecnologías
Ubuntu, Windows 10, Lynis, Nmap, OpenSSH, UFW, iptables, PAM/pwquality, OSSEC HIDS, Snort NIDS, VMware, VirtualBox.

## Aviso
Trabajo académico realizado en un entorno aislado. Las técnicas se aplicaron solo sobre máquinas propias del laboratorio.
