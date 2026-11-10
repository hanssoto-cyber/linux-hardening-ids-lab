#!/usr/bin/env bash
# Firewall UFW en ossec-hanssoto: política restrictiva y solo los puertos necesarios.
# Comandos tal como aparecen en la evidencia (02-ufw-status-verbose.png).
#
# ORDEN CRÍTICO: el puerto SSH (2222) se autoriza ANTES de "ufw enable",
# para no cortar la sesión de administración.
set -euo pipefail

# Política por defecto
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Puertos permitidos
sudo ufw allow 2222/tcp comment 'SSH hardened'
sudo ufw allow 1514/udp comment 'OSSEC agent'
sudo ufw allow 1515/tcp comment 'OSSEC enrollment'

# Activar y verificar
sudo ufw enable
sudo ufw status verbose
