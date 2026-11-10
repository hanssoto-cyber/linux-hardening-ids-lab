# Lecciones y mejoras

## Lo que mostró el laboratorio
- **Hardening.** El índice de Lynis solo subió de 58 a 63: quedaron sugerencias pendientes (auditd, banner legal, umask restrictivo). En el servidor real se llegó a 75.
- **Cliente Windows.** El firewall y Defender estaban bien configurados, pero la cuenta activa tenía `PasswordRequired = False` y el sistema no tenía parches posteriores a enero de 2020 (ver [`01-evaluacion/analisis-windows.md`](../01-evaluacion/analisis-windows.md)).
- **Snort.** La regla de Netcat (SID 1000003), que busca el byte nulo, también se disparó con tráfico binario legítimo como el SSH cifrado del puerto 2222. En producción habría que afinarla con patrones adicionales para reducir falsos positivos.

## Qué se haría distinto
- Enviar las alertas de OSSEC y Snort a un SIEM (ELK) para correlación.
- Probar las reglas de Snort contra técnicas más variadas y medir falsos positivos.
