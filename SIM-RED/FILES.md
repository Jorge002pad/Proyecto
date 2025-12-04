# SIM-RED EXTENDIDO - Lista Completa de Archivos

## 📁 Estructura Completa del Proyecto

### Directorio Raíz
```
SIM-RED/
├── sim-red.sh (7.9 KB)                          # Script principal con menú interactivo
├── generar_documentacion_profesor.py (41.3 KB)  # Generador de documentación completa
├── generar_presentacion.py (23.5 KB)            # Generador de presentación Word
├── convertir_a_pdf.py (0.9 KB)                  # Convertidor Word a PDF
├── README.md (9.5 KB)                           # Documentación principal del proyecto
├── INSTALL.md (8.3 KB)                          # Guía de instalación completa
├── GUIA_COMPLETA.md (32.6 KB)                   # Documentación técnica detallada
├── FILES.md (7.8 KB)                            # Lista completa de archivos
├── AUTO_DETECTION.md (5.4 KB)                   # Guía de autodetección de red
└── NETWORK_SETUP.md (6.0 KB)                    # Configuración de red
```

### Directorio bin/ (15 scripts de funciones)
```
bin/
├── check_devices.sh (5.6 KB)        # Función 1: Verificar dispositivos conectados
├── check_spoofing.sh (5.1 KB)      # Función 2: Anti-spoofing (detección de suplantación)
├── detect_vpn.sh (4.6 KB)          # Función 3: Detección de VPN/Proxy
├── measure_latency.sh (4.9 KB)     # Función 4: Medición de latencia promedio
├── monitor_latency.sh (5.1 KB)     # Función 5: Monitoreo continuo de latencia
├── measure_traffic.sh (4.5 KB)     # Función 6: Medición de tráfico de red
├── monitor_arp.sh (3.1 KB)         # Función 7: Monitoreo ARP en tiempo real
├── check_integrity.sh (2.5 KB)     # Función 8: Verificación de integridad
├── scan_ports.sh (3.0 KB)          # Función 9: Escaneo de puertos
├── check_dns.sh (3.4 KB)           # Función 10: Verificación de DNS
├── detect_anomalies.sh (6.0 KB)    # Función 11: Detección de anomalías
├── generate_report.sh (7.0 KB)     # Función 12: Generación de informes
├── manage_logs.sh (4.4 KB)         # Función 13: Gestión de logs
├── configure.sh (8.4 KB)           # Función 14: Configuración del sistema
└── check_requirements.sh (5.1 KB)  # Función 15: Verificación de herramientas
```

### Directorio lib/ (4 bibliotecas)
```
lib/
├── common.sh (6.2 KB)              # Funciones comunes (logging, colores, validación)
├── network_utils.sh (5.8 KB)       # Utilidades de red (ARP, ping, validación IP/MAC)
├── graph_ascii.awk (4.7 KB)        # Generador de gráficas ASCII (AWK)
└── report_generator.pl (13.8 KB)   # Generador de informes HTML (Perl)
```

### Directorio config/ (4 archivos de configuración)
```
config/
├── hosts.conf (0.8 KB)             # Lista de hosts autorizados (IP|MAC|HOSTNAME|DESC)
├── schedule.conf (0.9 KB)          # Horarios permitidos (IP|DÍAS|INICIO|FIN)
├── config.conf (1.2 KB)            # Configuración del sistema
└── requirements.txt (0.4 KB)       # Lista de herramientas requeridas
```

### Directorios de Datos
```
logs/                               # Directorio para archivos de log
├── .gitkeep
└── (archivos .log se crean automáticamente)

reports/                            # Directorio para informes generados
├── .gitkeep
└── (informes .txt y .html se generan aquí)

data/                               # Directorio para datos históricos
├── .gitkeep
└── (archivos .dat se crean automáticamente)

diagramas/                          # Diagramas del proyecto
├── arquitectura_sistema.png (631 KB)
├── flujo_trabajo.png (560 KB)
└── estructura_archivos.png (578 KB)

Documentacion_Profesor/             # Documentación completa para presentación
├── DOCUMENTACION_COMPLETA_SIM-RED.html (40 KB)
├── arquitectura_sistema.png (631 KB)
├── flujo_trabajo.png (560 KB)
├── estructura_archivos.png (578 KB)
└── LEEME.txt (1.5 KB)
```

## 📊 Resumen de Archivos

| Categoría | Cantidad | Tamaño Total |
|-----------|----------|--------------|
| Scripts principales | 1 | 7.9 KB |
| Scripts de funciones | 15 | 74.7 KB |
| Bibliotecas | 4 | 30.5 KB |
| Configuración | 4 | 3.3 KB |
| Documentación | 6 | 71.9 KB |
| Scripts Python | 3 | 65.7 KB |
| Diagramas | 3 | 1.7 MB |
| **TOTAL** | **36** | **~2.0 MB** |

## 🎯 Archivos por Función

### Monitoreo de Dispositivos
1. `bin/check_devices.sh` - Verificación de dispositivos con validación de horarios
2. `bin/check_spoofing.sh` - Detección de ataques de suplantación IP/MAC
3. `bin/detect_vpn.sh` - Identificación de uso de VPN o Proxy

### Análisis de Rendimiento
4. `bin/measure_latency.sh` - Medición estadística de latencia
5. `bin/monitor_latency.sh` - Monitoreo en tiempo real con gráficas
6. `bin/measure_traffic.sh` - Análisis de tráfico por interfaz

### Seguridad y Monitoreo
7. `bin/monitor_arp.sh` - Vigilancia de tabla ARP
8. `bin/check_integrity.sh` - Verificación SHA256 de archivos
9. `bin/scan_ports.sh` - Escaneo de puertos con nmap
10. `bin/check_dns.sh` - Prueba de servidores DNS
11. `bin/detect_anomalies.sh` - Análisis estadístico de anomalías

### Informes y Configuración
12. `bin/generate_report.sh` + `lib/report_generator.pl` - Informes TXT/HTML
13. `bin/manage_logs.sh` - Gestión completa de logs
14. `bin/configure.sh` - Configuración interactiva

### Sistema
15. `bin/check_requirements.sh` - Verificación e instalación de herramientas

## 🔧 Archivos de Soporte

### Bibliotecas Compartidas
- `lib/common.sh` - 50+ funciones de utilidad
- `lib/network_utils.sh` - Funciones específicas de red
- `lib/graph_ascii.awk` - Generación de gráficas ASCII
- `lib/report_generator.pl` - Generación de HTML con CSS

### Configuración
- `config/hosts.conf` - Base de datos de hosts autorizados
- `config/schedule.conf` - Control de acceso basado en horarios
- `config/config.conf` - Parámetros globales del sistema
- `config/requirements.txt` - Dependencias del sistema

## 📝 Archivos que se Generan Automáticamente

### Logs (en logs/)
- `devices.log` - Log de verificación de dispositivos
- `spoofing.log` - Log de detección de spoofing
- `vpn.log` - Log de detección de VPN
- `latency.log` - Log de mediciones de latencia
- `traffic.log` - Log de tráfico de red
- `arp.log` - Log de monitoreo ARP
- `integrity.log` - Log de verificación de integridad
- `ports.log` - Log de escaneo de puertos
- `dns.log` - Log de verificación DNS
- `anomalies.log` - Log de detección de anomalías
- `system.log` - Log general del sistema

### Datos Históricos (en data/)
- `integrity.sha256` - Hashes de integridad
- `latency_history.dat` - Histórico de latencias
- `traffic_history.dat` - Histórico de tráfico
- `arp_history.dat` - Histórico de tabla ARP
- `ttl_history_*.dat` - Histórico de TTL por IP

### Informes (en reports/)
- `report_YYYYMMDD_HHMMSS.txt` - Informes en formato texto
- `report_YYYYMMDD_HHMMSS.html` - Informes en formato HTML
- `report_YYYYMMDD_HHMMSS.dat` - Datos del informe

## 🚀 Cómo Usar los Archivos

### Ejecución Principal
```bash
sudo ./sim-red.sh
```

### Ejecución de Funciones Individuales
```bash
sudo bash bin/check_devices.sh
sudo bash bin/measure_latency.sh
sudo bash bin/generate_report.sh
```

### Edición de Configuración
```bash
nano config/hosts.conf
nano config/schedule.conf
nano config/config.conf
```

### Visualización de Logs
```bash
cat logs/system.log
tail -f logs/devices.log
less logs/spoofing.log
```

### Visualización de Informes
```bash
cat reports/report_*.txt
firefox reports/report_*.html
```

## 📍 Ubicación del Proyecto

**Ruta completa:** 
```
c:\Users\jorge\Documents\902-A\AdministracionRedes\Proyecto\SIM-RED\
```

## ✅ Verificación de Archivos

Para verificar que todos los archivos estén presentes:

```bash
cd SIM-RED

# Verificar estructura
ls -la

# Verificar scripts de funciones
ls -la bin/

# Verificar bibliotecas
ls -la lib/

# Verificar configuración
ls -la config/

# Contar archivos
find . -type f | wc -l
# Debe mostrar: 26+ archivos
```

## 🎓 Tecnologías por Archivo

### Bash Scripts (20 archivos)
- `sim-red.sh`
- Todos los archivos en `bin/`
- `lib/common.sh`
- `lib/network_utils.sh`

### AWK Scripts (1 archivo)
- `lib/graph_ascii.awk`

### Perl Scripts (1 archivo)
- `lib/report_generator.pl`

### Archivos de Configuración (4 archivos)
- `config/hosts.conf`
- `config/schedule.conf`
- `config/config.conf`
- `config/requirements.txt`

### Documentación Markdown (6 archivos)
- `README.md`
- `INSTALL.md`
- `GUIA_COMPLETA.md`
- `FILES.md`
- `AUTO_DETECTION.md`
- `NETWORK_SETUP.md`

### Scripts Python (3 archivos)
- `generar_documentacion_profesor.py` - Generador de documentación HTML
- `generar_presentacion.py` - Generador de presentación Word
- `convertir_a_pdf.py` - Convertidor Word a PDF

### Diagramas (3 archivos)
- `diagramas/arquitectura_sistema.png`
- `diagramas/flujo_trabajo.png`
- `diagramas/estructura_archivos.png`

## 📚 Documentación Generada

### Carpeta Documentacion_Profesor/
Contiene documentación completa para presentaciones:
- **DOCUMENTACION_COMPLETA_SIM-RED.html** - Documento HTML profesional con:
  - Introducción y contexto del proyecto
  - Arquitectura del sistema con diagramas
  - Tutorial de las 15 funcionalidades
  - Guía de configuración
  - Preguntas frecuentes (FAQ)

Para generar/actualizar:
```bash
python generar_documentacion_profesor.py
```

---

**Total de archivos del proyecto: 36 archivos + 5 directorios de datos**

**Proyecto completo y listo para usar en Ubuntu Linux**
