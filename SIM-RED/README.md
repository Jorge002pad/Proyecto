# SIM-RED EXTENDIDO

**Sistema de Análisis y Seguridad para Redes Locales**

![Version](https://img.shields.io/badge/version-1.0-blue)
![Platform](https://img.shields.io/badge/platform-Ubuntu-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 📋 Descripción

SIM-RED EXTENDIDO es un sistema completo de monitoreo, análisis y seguridad para redes locales, desarrollado completamente en **Bash**, **AWK** y **Perl**. Diseñado para ejecutarse nativamente en Ubuntu Linux sin necesidad de contenedores.

El sistema proporciona 15 funciones especializadas para:
- ✅ Verificación de dispositivos autorizados
- 🛡️ Detección de ataques de suplantación (spoofing)
- 🔐 Identificación de uso de VPN/Proxy
- ⚡ Medición de latencia y rendimiento
- 📊 Análisis de tráfico de red
- 🚨 Detección de anomalías
- 📝 Generación de informes completos

## 🎯 Características Principales

### Monitoreo de Dispositivos
1. **Verificación de Dispositivos Conectados**
   - Escaneo de subred local
   - Comparación con lista de hosts autorizados
   - Validación de horarios permitidos (schedule-based access control)
   - Identificación de dispositivos desconocidos

2. **Anti-Spoofing**
   - Detección de IPs duplicadas con diferentes MACs
   - Detección de MACs duplicadas con diferentes IPs
   - Monitoreo de cambios en la tabla ARP
   - Alertas en tiempo real

3. **Detección de VPN/Proxy**
   - Análisis de variaciones de TTL
   - Detección de cambios bruscos en latencia
   - Escaneo de puertos típicos de VPN (1194, 500, 4500)
   - Cálculo de probabilidad de uso de VPN

### Análisis de Rendimiento
4. **Medición de Latencia Promedio**
   - Ping a todos los hosts autorizados
   - Cálculo de estadísticas (min, max, avg, stddev)
   - Tabla ordenada por latencia
   - Registro en logs

5. **Monitoreo Continuo de Latencia**
   - Actualización en tiempo real
   - Gráficas ASCII de latencia
   - Alertas configurables
   - Histórico de mediciones

6. **Medición de Tráfico de Red**
   - Lectura de estadísticas de `/sys/class/net`
   - Medición de upload/download por interfaz
   - Modo instantáneo y continuo
   - Registro histórico

### Seguridad y Monitoreo
7. **Monitoreo ARP en Tiempo Real**
   - Vigilancia de `/proc/net/arp`
   - Detección de nuevas MACs
   - Alertas de cambios en tabla ARP
   - Identificación de actividad sospechosa

8. **Verificación de Integridad**
   - Hashes SHA256 de archivos de configuración
   - Detección de modificaciones no autorizadas
   - Actualización de hashes
   - Registro de cambios

9. **Escaneo de Puertos**
   - Uso de nmap para escaneo rápido
   - Puertos esenciales configurables
   - Identificación de servicios inesperados
   - Reporte de seguridad

10. **Comprobación de DNS**
    - Test de disponibilidad de servidores DNS
    - Medición de tiempos de respuesta
    - Soporte para múltiples servidores
    - Alertas de fallos

11. **Detección de Anomalías**
    - Análisis estadístico de latencia histórica
    - Análisis de tráfico histórico
    - Umbral configurable (2x promedio por defecto)
    - Alertas automáticas

### Informes y Configuración
12. **Generación de Informes**
    - Reporte completo del estado de la red
    - Formato TXT y HTML
    - Incluye todos los análisis de seguridad
    - Exportable y archivable

13. **Gestión de Logs**
    - Visualización de logs
    - Limpieza de logs
    - Exportación en formato tar.gz
    - Estadísticas de logs

14. **Configuración del Sistema**
    - Cambio de subred a escanear
    - Ajuste de intervalos de monitoreo
    - Gestión de hosts autorizados
    - Configuración de umbrales de alerta

15. **Verificación de Herramientas**
    - Análisis de dependencias
    - Instalación automática de herramientas faltantes
    - Verificación en cada ejecución
    - Validación por función

## 📁 Estructura del Proyecto

```
SIM-RED/
├── sim-red.sh              # Script principal con menú
├── bin/                    # Scripts de funciones
│   ├── check_devices.sh
│   ├── check_spoofing.sh
│   ├── detect_vpn.sh
│   ├── measure_latency.sh
│   ├── monitor_latency.sh
│   ├── measure_traffic.sh
│   ├── monitor_arp.sh
│   ├── check_integrity.sh
│   ├── scan_ports.sh
│   ├── check_dns.sh
│   ├── detect_anomalies.sh
│   ├── generate_report.sh
│   ├── manage_logs.sh
│   ├── configure.sh
│   └── check_requirements.sh
├── lib/                    # Bibliotecas y utilidades
│   ├── common.sh
│   ├── network_utils.sh
│   ├── graph_ascii.awk
│   └── report_generator.pl
├── config/                 # Archivos de configuración
│   ├── hosts.conf
│   ├── schedule.conf
│   ├── config.conf
│   └── requirements.txt
├── logs/                   # Archivos de log
├── reports/                # Informes generados
├── data/                   # Datos históricos
├── README.md
└── INSTALL.md
```

## 🚀 Inicio Rápido

### Instalación
```bash
cd SIM-RED
chmod +x sim-red.sh
sudo ./sim-red.sh
```

El sistema verificará automáticamente las herramientas necesarias y ofrecerá instalarlas si faltan.

### Uso Básico
1. Ejecuta el script principal: `sudo ./sim-red.sh`
2. Selecciona una opción del menú (1-15)
3. Sigue las instrucciones en pantalla

### Configuración Inicial
1. Edita `config/hosts.conf` para añadir tus dispositivos autorizados
2. Configura `config/schedule.conf` para definir horarios permitidos
3. Ajusta `config/config.conf` según tus necesidades de red

## 📖 Archivos de Configuración

### hosts.conf
Define los dispositivos autorizados en tu red:
```
# Formato: IP|MAC|HOSTNAME|DESCRIPCIÓN
192.168.1.1|aa:bb:cc:dd:ee:ff|Router|Gateway principal
192.168.1.10|11:22:33:44:55:66|Server01|Servidor web
```

### schedule.conf
Define los horarios permitidos para cada dispositivo:
```
# Formato: IP|DÍAS|HORA_INICIO|HORA_FIN
192.168.1.10|Mon-Fri|08:00|18:00
192.168.1.20|Mon-Sun|00:00|23:59
```

### config.conf
Configuración general del sistema:
- Subred a escanear
- Intervalos de monitoreo
- Umbrales de alerta
- Servidores DNS
- Puertos a escanear

## 🛠️ Requisitos del Sistema

### Sistema Operativo
- Ubuntu 20.04 LTS o superior
- Acceso root (sudo)

### Herramientas Requeridas
- `arp-scan` - Escaneo de red
- `nmap` - Escaneo de puertos
- `ifstat` - Estadísticas de red (opcional)
- `gawk` - Procesamiento de texto
- `bc` - Calculadora
- `perl` - Generación de informes HTML
- `dig/host` - Consultas DNS

**Nota:** El sistema puede instalar automáticamente las herramientas faltantes.

## 📊 Ejemplos de Uso

### Verificar Dispositivos Conectados
```bash
sudo ./sim-red.sh
# Selecciona opción 1
```

### Generar Informe Completo
```bash
sudo ./sim-red.sh
# Selecciona opción 12
# Los informes se guardan en reports/
```

### Monitoreo en Tiempo Real
```bash
sudo ./sim-red.sh
# Selecciona opción 5 (latencia) o 7 (ARP)
# Presiona Ctrl+C para detener
```

## 🔒 Seguridad

- Requiere permisos de root para escaneo de red
- Verifica integridad de archivos de configuración
- Registra todas las actividades en logs
- Detecta modificaciones no autorizadas

## 📝 Logs

Los logs se almacenan en `logs/` con el siguiente formato:
```
[YYYY-MM-DD HH:MM:SS] [NIVEL] Mensaje
```

Niveles de log:
- `INFO` - Información general
- `WARNING` - Advertencias
- `ERROR` - Errores
- `ALERT` - Alertas de seguridad

## 🤝 Contribuciones

Este proyecto fue desarrollado como sistema de monitoreo y seguridad de red para entornos educativos y de producción.

## 📄 Licencia

MIT License - Libre para uso educativo y comercial.

## 👨‍💻 Autor

Desarrollado para el curso de Administración de Redes.

## 📞 Soporte

Para reportar problemas o sugerencias:
1. Revisa los logs en `logs/`
2. Ejecuta la opción 15 para verificar herramientas
3. Consulta INSTALL.md para instrucciones detalladas

---

**SIM-RED EXTENDIDO** - Sistema de Análisis y Seguridad de Red v1.0
