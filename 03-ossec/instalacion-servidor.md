# Instalación del servidor OSSEC

**Equipo:** `ossec-hanssoto` (Ubuntu 18.04.6 LTS, 192.168.56.10)
**Versión:** OSSEC HIDS 3.7.0, compilado desde el código fuente oficial

## Dependencias de compilación
```bash
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev libpcre2-dev zlib1g-dev libsystemd-dev
```

En EV2 los prerrequisitos de compilación fueron `build-essential make gcc libssl-dev`.

## Descarga, instalación y arranque
Comandos documentados en EV2; en ambos laboratorios se usó la misma versión 3.7.0.
```bash
wget https://github.com/ossec/ossec-hids/archive/3.7.0.tar.gz
tar -zxvf 3.7.0.tar.gz && cd ossec-hids-3.7.0
sudo ./install.sh                         # tipo de instalación: server
sudo /var/ossec/bin/ossec-control start
sudo /var/ossec/bin/ossec-control status
```

Opciones elegidas durante `install.sh`:
- Modo **servidor**
- Verificación de integridad de archivos (**syscheck**)
- Detección de rootkits (**rootcheck**)
- **Respuesta activa**
- Monitoreo de logs locales

Al terminar la compilación, el servicio arrancó sin errores y `ossec-control status` mostró los demonios en ejecución.

## Puertos
UFW abre `1514/udp` (comunicación con el agente) y `1515/tcp` (registro de agentes). Ver [`../02-hardening/ufw/reglas.sh`](../02-hardening/ufw/reglas.sh).
