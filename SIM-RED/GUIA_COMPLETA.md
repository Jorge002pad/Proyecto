# GUÍA COMPLETA - SIM-RED EXTENDIDO
## Tutorial y Documentación Detallada del Sistema

**Versión:** 1.0  
**Última actualización:** 2025-11-25

---

## 📑 Tabla de Contenidos

1. [Introducción](#introducción)
2. [Estructura del Menú](#estructura-del-menú)
3. [Documentación por Secciones](#documentación-por-secciones)
   - [Monitoreo de Dispositivos](#monitoreo-de-dispositivos)
   - [Análisis de Rendimiento](#análisis-de-rendimiento)
   - [Seguridad y Monitoreo](#seguridad-y-monitoreo)
   - [Informes y Configuración](#informes-y-configuración)
   - [Sistema](#sistema)
4. [Archivos de Configuración](#archivos-de-configuración)
5. [Casos de Uso](#casos-de-uso)
6. [Recomendaciones](#recomendaciones)

---

## Introducción

SIM-RED EXTENDIDO es un sistema completo de monitoreo, análisis y seguridad para redes locales. Este documento proporciona una explicación detallada de cada función del sistema para ayudarte a evaluar qué opciones mantener, modificar o eliminar.

### ¿Qué hace el proyecto?

El proyecto **SÍ hace:**
- ✅ Escaneo y verificación de dispositivos en la red local
- ✅ Detección de ataques de suplantación (spoofing)
- ✅ Identificación de uso de VPN/Proxy
- ✅ Medición de latencia y rendimiento de red
- ✅ Análisis de tráfico de red
- ✅ Monitoreo en tiempo real de tabla ARP
- ✅ Verificación de integridad de archivos
- ✅ Escaneo de puertos
- ✅ Comprobación de servidores DNS
- ✅ Detección de anomalías basada en históricos
- ✅ Generación de informes completos
- ✅ Gestión de logs del sistema

El proyecto **NO hace:**
- ❌ Bloqueo automático de dispositivos
- ❌ Modificación de configuración de red
- ❌ Instalación de firewall o reglas iptables
- ❌ Captura de paquetes completa (packet sniffing profundo)
- ❌ Análisis de contenido de tráfico
- ❌ Prevención activa de intrusiones (IPS)
- ❌ Gestión de usuarios o autenticación
- ❌ Configuración automática de dispositivos

---

## Estructura del Menú

El menú principal está organizado en **5 secciones** con **15 opciones** totales:

```
┌─────────────────────────────────────────────┐
│  SECCIÓN 1: MONITOREO DE DISPOSITIVOS       │
│  Opciones: 1, 2, 3                          │
├─────────────────────────────────────────────┤
│  SECCIÓN 2: ANÁLISIS DE RENDIMIENTO         │
│  Opciones: 4, 5, 6                          │
├─────────────────────────────────────────────┤
│  SECCIÓN 3: SEGURIDAD Y MONITOREO           │
│  Opciones: 7, 8, 9, 10, 11                  │
├─────────────────────────────────────────────┤
│  SECCIÓN 4: INFORMES Y CONFIGURACIÓN        │
│  Opciones: 12, 13, 14                       │
├─────────────────────────────────────────────┤
│  SECCIÓN 5: SISTEMA                         │
│  Opciones: 15, 0                            │
└─────────────────────────────────────────────┘
```

---

## Documentación por Secciones

### SECCIÓN 1: MONITOREO DE DISPOSITIVOS

Esta sección se enfoca en la **identificación y control de dispositivos** conectados a la red.

#### Opción 1: Verificar dispositivos conectados en la red

**Script:** `bin/check_devices.sh`

**¿Qué hace?**
- Escanea la subred local usando `arp-scan`
- Compara los dispositivos encontrados con la lista de hosts autorizados (`config/hosts.conf`)
- Verifica que cada dispositivo esté dentro de su horario permitido (`config/schedule.conf`)
- Identifica dispositivos desconocidos
- Detecta dispositivos autorizados que no están conectados
- Valida que la MAC coincida con la registrada

**Información que muestra:**
- IP, MAC y hostname de cada dispositivo
- Estado: AUTORIZADO, DESCONOCIDO, FUERA DE HORARIO, FUERA DE DÍA, MAC NO COINCIDE
- Resumen con contadores de cada categoría

**Cuándo usarla:**
- Al inicio del día para verificar qué dispositivos están conectados
- Cuando sospechas de dispositivos no autorizados
- Para auditorías de seguridad periódicas

**Dependencias:**
- `arp-scan` (esencial)
- `gawk`
- Requiere permisos de root

**Archivos que utiliza:**
- `config/hosts.conf` - Lista de dispositivos autorizados
- `config/schedule.conf` - Horarios permitidos
- `logs/devices.log` - Registro de actividad

**¿Deberías mantenerla?**
- ✅ **SÍ** si necesitas control de acceso a la red
- ✅ **SÍ** si tienes una lista definida de dispositivos autorizados
- ❌ **NO** si tu red es completamente abierta o muy dinámica

---

#### Opción 2: Verificar suplantación de IP (Anti-Spoofing)

**Script:** `bin/check_spoofing.sh`

**¿Qué hace?**
- Detecta si una misma IP tiene múltiples direcciones MAC (IP spoofing)
- Detecta si una misma MAC tiene múltiples IPs (MAC spoofing)
- Compara la tabla ARP actual con el histórico para detectar cambios de MAC en IPs conocidas
- Guarda un histórico de la tabla ARP para comparaciones futuras

**Información que muestra:**
- IPs con múltiples MACs
- MACs con múltiples IPs
- Cambios de MAC en IPs conocidas (comparado con ejecuciones anteriores)
- Resumen de seguridad

**Cuándo usarla:**
- Cuando sospechas de ataques ARP spoofing o man-in-the-middle
- Como verificación de seguridad periódica
- Después de detectar comportamiento anómalo en la red

**Dependencias:**
- `gawk`
- Acceso a `/proc/net/arp`

**Archivos que utiliza:**
- `data/arp_history.dat` - Histórico de tabla ARP
- `logs/spoofing.log` - Registro de alertas

**¿Deberías mantenerla?**
- ✅ **SÍ** si la seguridad es importante en tu red
- ✅ **SÍ** si manejas información sensible
- ⚠️ **CONSIDERA** combinarla con la opción 7 (Monitoreo ARP en tiempo real)
- ❌ **NO** si solo tienes dispositivos de confianza

---

#### Opción 3: Detectar si un usuario está usando VPN o Proxy

**Script:** `bin/detect_vpn.sh`

**¿Qué hace?**
- Analiza variaciones en el TTL (Time To Live) de los paquetes
- Mide variaciones en la latencia
- Escanea puertos típicos de VPN (1194, 500, 4500, 1723)
- Calcula una probabilidad de uso de VPN basada en múltiples indicadores
- Mantiene un histórico de TTL para detectar cambios

**Información que muestra:**
- IP y hostname del dispositivo
- Indicadores detectados (TTL_CHANGE, UNUSUAL_TTL, HIGH_LATENCY_VAR, VPN_PORTS)
- Probabilidad: BAJA, MEDIA o ALTA
- Porcentaje de confianza

**Cuándo usarla:**
- En redes corporativas donde el uso de VPN no está permitido
- Para detectar usuarios que intentan evadir restricciones de red
- Como parte de auditorías de seguridad

**Dependencias:**
- `ping`
- `nmap` (para escaneo de puertos)
- `gawk`

**Archivos que utiliza:**
- `data/ttl_history_<IP>.dat` - Histórico de TTL por dispositivo
- `logs/vpn.log` - Registro de detecciones

**¿Deberías mantenerla?**
- ✅ **SÍ** si necesitas controlar el uso de VPN/Proxy
- ✅ **SÍ** en entornos corporativos o educativos con políticas estrictas
- ❌ **NO** si permites o fomentas el uso de VPN
- ❌ **NO** si la privacidad de usuarios es prioritaria

---

### SECCIÓN 2: ANÁLISIS DE RENDIMIENTO

Esta sección se enfoca en **medir y monitorear el rendimiento** de la red.

#### Opción 4: Medir latencia promedio de toda la red

**Script:** `bin/measure_latency.sh`

**¿Qué hace?**
- Hace ping a todos los hosts autorizados
- Calcula estadísticas: mínimo, máximo, promedio y desviación estándar
- Ordena los resultados por latencia
- Identifica hosts con latencia alta o que no responden
- Guarda los resultados en el histórico

**Información que muestra:**
- Tabla con IP, hostname, latencia mínima, promedio, máxima y desviación
- Hosts que no responden
- Estadísticas generales de la red

**Cuándo usarla:**
- Para diagnóstico de problemas de rendimiento
- Como línea base para comparaciones futuras
- Antes y después de cambios en la red

**Dependencias:**
- `ping`
- `gawk`
- `bc` (para cálculos matemáticos)

**Archivos que utiliza:**
- `config/hosts.conf` - Lista de hosts a medir
- `data/latency_history.dat` - Histórico de mediciones
- `logs/latency.log` - Registro de mediciones

**¿Deberías mantenerla?**
- ✅ **SÍ** si necesitas diagnóstico de rendimiento
- ✅ **SÍ** para documentación y reportes
- ⚠️ **CONSIDERA** usar la opción 5 si prefieres monitoreo continuo
- ❌ **NO** si solo tienes pocos dispositivos y no hay problemas de rendimiento

---

#### Opción 5: Medición continua de latencia (modo monitor)

**Script:** `bin/monitor_latency.sh`

**¿Qué hace?**
- Monitorea la latencia de forma continua en tiempo real
- Actualiza las mediciones cada segundo (configurable)
- Muestra gráficas ASCII de la latencia
- Genera alertas cuando la latencia supera umbrales configurados
- Se ejecuta hasta que presionas Ctrl+C

**Información que muestra:**
- Tabla actualizada en tiempo real con latencias actuales
- Gráficas ASCII mostrando tendencias
- Alertas visuales cuando se superan umbrales
- Timestamp de cada actualización

**Cuándo usarla:**
- Durante diagnóstico activo de problemas de red
- Para monitorear el impacto de cambios en la red
- Durante pruebas de carga o estrés
- Para vigilancia continua de servicios críticos

**Dependencias:**
- `ping`
- `gawk` (incluye `graph_ascii.awk` para gráficas)
- `bc`

**Archivos que utiliza:**
- `config/hosts.conf` - Hosts a monitorear
- `config/config.conf` - Intervalos y umbrales
- `lib/graph_ascii.awk` - Generación de gráficas
- `logs/latency.log` - Registro continuo

**¿Deberías mantenerla?**
- ✅ **SÍ** si necesitas monitoreo en tiempo real
- ✅ **SÍ** para diagnóstico interactivo
- ⚠️ **CONSIDERA** que consume recursos mientras está activa
- ❌ **NO** si solo necesitas mediciones puntuales (usa opción 4)

---

#### Opción 6: Medir tráfico de red por host (Up/Down)

**Script:** `bin/measure_traffic.sh`

**¿Qué hace?**
- Lee estadísticas de `/sys/class/net/<interface>/statistics/`
- Mide bytes transmitidos (TX) y recibidos (RX)
- Calcula velocidad de upload y download
- Puede funcionar en modo instantáneo o continuo
- Guarda histórico de tráfico

**Información que muestra:**
- Interfaz de red
- Bytes/KB/MB transmitidos y recibidos
- Velocidad actual (KB/s o MB/s)
- Comparación con mediciones anteriores

**Cuándo usarla:**
- Para identificar dispositivos con alto consumo de ancho de banda
- Durante diagnóstico de problemas de red lenta
- Para monitorear el uso de la red
- Para detectar actividad inusual

**Dependencias:**
- Acceso a `/sys/class/net/`
- `gawk`
- `bc`
- `ifstat` (opcional, para mediciones más precisas)

**Archivos que utiliza:**
- `config/config.conf` - Configuración de interfaz
- `data/traffic_history.dat` - Histórico de tráfico
- `logs/traffic.log` - Registro de mediciones

**¿Deberías mantenerla?**
- ✅ **SÍ** si necesitas monitorear consumo de ancho de banda
- ✅ **SÍ** para detectar anomalías de tráfico
- ⚠️ **CONSIDERA** que mide tráfico total de la interfaz, no por host individual
- ❌ **NO** si no tienes problemas de ancho de banda

---

### SECCIÓN 3: SEGURIDAD Y MONITOREO

Esta sección se enfoca en **seguridad y vigilancia** de la red.

#### Opción 7: Monitoreo ARP en tiempo real

**Script:** `bin/monitor_arp.sh`

**¿Qué hace?**
- Vigila continuamente la tabla ARP (`/proc/net/arp`)
- Detecta nuevas entradas en la tabla ARP
- Alerta sobre cambios en MACs conocidas
- Identifica actividad sospechosa
- Se ejecuta hasta que presionas Ctrl+C

**Información que muestra:**
- Tabla ARP actual
- Nuevas MACs detectadas
- Cambios en la tabla ARP
- Alertas en tiempo real
- Timestamp de cada evento

**Cuándo usarla:**
- Durante investigación de ataques ARP spoofing
- Para monitoreo de seguridad en tiempo real
- Cuando detectas actividad sospechosa
- Como herramienta de vigilancia continua

**Dependencias:**
- Acceso a `/proc/net/arp`
- `gawk`

**Archivos que utiliza:**
- `logs/arp_monitor.log` - Registro de eventos
- `data/arp_baseline.dat` - Línea base de ARP

**¿Deberías mantenerla?**
- ✅ **SÍ** si la seguridad es crítica
- ✅ **SÍ** para detección temprana de ataques
- ⚠️ **CONSIDERA** combinarla con la opción 2 (Anti-Spoofing)
- ⚠️ **CONSIDERA** que consume recursos mientras está activa
- ❌ **NO** si solo necesitas verificaciones puntuales

---

#### Opción 8: Verificar integridad del archivo de hosts autorizados

**Script:** `bin/check_integrity.sh`

**¿Qué hace?**
- Calcula hashes SHA256 de archivos de configuración críticos
- Compara con hashes almacenados previamente
- Detecta modificaciones no autorizadas
- Permite actualizar los hashes después de cambios legítimos
- Registra todos los cambios detectados

**Información que muestra:**
- Lista de archivos verificados
- Estado: ÍNTEGRO, MODIFICADO, NUEVO
- Opción para actualizar hashes

**Cuándo usarla:**
- Después de sospechar acceso no autorizado
- Como verificación de seguridad periódica
- Antes de generar informes de auditoría
- Después de realizar cambios en configuración (para actualizar hashes)

**Dependencias:**
- `sha256sum`

**Archivos que utiliza:**
- `config/hosts.conf` - Archivo a verificar
- `config/schedule.conf` - Archivo a verificar
- `config/config.conf` - Archivo a verificar
- `data/integrity.sha256` - Hashes almacenados
- `logs/integrity.log` - Registro de verificaciones

**¿Deberías mantenerla?**
- ✅ **SÍ** si múltiples personas tienen acceso al sistema
- ✅ **SÍ** para cumplimiento de auditorías de seguridad
- ✅ **SÍ** si la integridad de configuración es crítica
- ❌ **NO** si eres el único administrador y confías en tu entorno

---

#### Opción 9: Escanear puertos importantes de cada host

**Script:** `bin/scan_ports.sh`

**¿Qué hace?**
- Escanea puertos configurados en cada host autorizado
- Usa `nmap` para escaneo rápido
- Identifica servicios abiertos
- Detecta puertos inesperados
- Compara con escaneos anteriores

**Información que muestra:**
- IP y hostname
- Puertos abiertos encontrados
- Servicios identificados
- Puertos nuevos o cerrados (comparado con escaneos previos)

**Cuándo usarla:**
- Para auditorías de seguridad
- Para inventario de servicios
- Después de instalar o desinstalar software
- Para detectar servicios no autorizados

**Dependencias:**
- `nmap` (esencial)

**Archivos que utiliza:**
- `config/hosts.conf` - Hosts a escanear
- `config/config.conf` - Puertos a escanear (PORTS_TO_SCAN)
- `data/port_scan_history.dat` - Histórico de escaneos
- `logs/port_scan.log` - Registro de escaneos

**¿Deberías mantenerla?**
- ✅ **SÍ** para auditorías de seguridad
- ✅ **SÍ** si necesitas inventario de servicios
- ⚠️ **CONSIDERA** que el escaneo puede ser detectado por IDS/IPS
- ⚠️ **CONSIDERA** ajustar los puertos en config.conf según tus necesidades
- ❌ **NO** si no te preocupan los servicios abiertos

---

#### Opción 10: Comprobar disponibilidad del servidor DNS

**Script:** `bin/check_dns.sh`

**¿Qué hace?**
- Prueba la disponibilidad de servidores DNS configurados
- Mide tiempos de respuesta
- Realiza consultas de prueba
- Detecta fallos en resolución DNS
- Soporta múltiples servidores DNS

**Información que muestra:**
- Servidor DNS probado
- Estado: DISPONIBLE, NO RESPONDE, ERROR
- Tiempo de respuesta
- Resultado de consultas de prueba

**Cuándo usarla:**
- Cuando hay problemas de conectividad a internet
- Para diagnóstico de problemas de resolución de nombres
- Como verificación de infraestructura
- Antes de generar informes de red

**Dependencias:**
- `dig` o `host` (herramientas DNS)
- `ping`

**Archivos que utiliza:**
- `config/config.conf` - Servidores DNS (DNS_SERVERS)
- `logs/dns.log` - Registro de verificaciones

**¿Deberías mantenerla?**
- ✅ **SÍ** si dependes de DNS para servicios críticos
- ✅ **SÍ** si tienes servidores DNS propios
- ⚠️ **CONSIDERA** agregar más servidores DNS en config.conf
- ❌ **NO** si usas DNS del ISP sin problemas

---

#### Opción 11: Detectar anomalías de red

**Script:** `bin/detect_anomalies.sh`

**¿Qué hace?**
- Analiza históricos de latencia y tráfico
- Calcula promedios y desviaciones estándar
- Detecta valores que superan umbrales (por defecto 2x el promedio)
- Identifica patrones anómalos
- Genera alertas de anomalías

**Información que muestra:**
- Análisis de latencia histórica
- Análisis de tráfico histórico
- Anomalías detectadas con timestamps
- Comparación con valores normales
- Recomendaciones

**Cuándo usarla:**
- Para detectar comportamiento inusual en la red
- Como parte de análisis de seguridad
- Después de sospechar un ataque o problema
- Para análisis forense

**Dependencias:**
- `gawk`
- `bc`

**Archivos que utiliza:**
- `data/latency_history.dat` - Histórico de latencia
- `data/traffic_history.dat` - Histórico de tráfico
- `config/config.conf` - Umbrales (TRAFFIC_ANOMALY_MULTIPLIER)
- `logs/anomalies.log` - Registro de anomalías

**¿Deberías mantenerla?**
- ✅ **SÍ** si necesitas detección automática de problemas
- ✅ **SÍ** para análisis de seguridad avanzado
- ⚠️ **CONSIDERA** que requiere datos históricos para funcionar bien
- ⚠️ **CONSIDERA** ajustar umbrales en config.conf
- ❌ **NO** si no tienes suficiente histórico de datos

---

### SECCIÓN 4: INFORMES Y CONFIGURACIÓN

Esta sección se enfoca en **reportes y gestión** del sistema.

#### Opción 12: Generar informe completo del estado de la red

**Script:** `bin/generate_report.sh`

**¿Qué hace?**
- Ejecuta múltiples verificaciones automáticamente
- Recopila información de dispositivos, seguridad y rendimiento
- Genera informe en formato TXT y/o HTML
- Incluye gráficas y estadísticas
- Guarda el informe con timestamp

**Información que incluye:**
- Resumen ejecutivo
- Dispositivos conectados y autorizados
- Resultados de verificación anti-spoofing
- Estadísticas de latencia
- Estado de DNS
- Puertos abiertos
- Anomalías detectadas
- Recomendaciones de seguridad

**Cuándo usarla:**
- Para reportes periódicos (diarios, semanales, mensuales)
- Antes de reuniones o presentaciones
- Para auditorías de seguridad
- Para documentación del estado de la red

**Dependencias:**
- `perl` (para generación de HTML)
- Todas las herramientas de las otras funciones
- `gawk`

**Archivos que utiliza:**
- `lib/report_generator.pl` - Generador de HTML
- `config/config.conf` - Configuración de formato (REPORT_FORMAT)
- Todos los archivos de logs y datos
- `reports/` - Directorio de salida

**¿Deberías mantenerla?**
- ✅ **SÍ** si necesitas reportes formales
- ✅ **SÍ** para documentación y auditorías
- ✅ **SÍ** si tienes que reportar a superiores
- ⚠️ **CONSIDERA** que ejecuta múltiples verificaciones (puede tardar)
- ❌ **NO** si solo necesitas verificaciones puntuales

---

#### Opción 13: Gestión de logs

**Script:** `bin/manage_logs.sh`

**¿Qué hace?**
- Visualiza logs del sistema
- Permite filtrar por tipo de log
- Limpia logs antiguos
- Exporta logs en formato tar.gz
- Muestra estadísticas de logs

**Información que muestra:**
- Lista de archivos de log disponibles
- Tamaño de cada log
- Últimas entradas
- Estadísticas (número de INFO, WARNING, ERROR, ALERT)

**Opciones disponibles:**
1. Ver logs
2. Limpiar logs antiguos
3. Exportar logs
4. Ver estadísticas
5. Volver al menú principal

**Cuándo usarla:**
- Para revisar actividad del sistema
- Cuando los logs ocupan mucho espacio
- Para exportar logs para análisis externo
- Para investigación de incidentes

**Dependencias:**
- `tar`, `gzip` (para exportación)
- `gawk`

**Archivos que utiliza:**
- `logs/*.log` - Todos los archivos de log
- `config/config.conf` - Retención de logs (LOG_RETENTION_DAYS)

**¿Deberías mantenerla?**
- ✅ **SÍ** si generas muchos logs
- ✅ **SÍ** para mantenimiento del sistema
- ✅ **SÍ** si necesitas exportar logs para auditorías
- ⚠️ **CONSIDERA** automatizar limpieza con cron
- ❌ **NO** si prefieres gestionar logs manualmente

---

#### Opción 14: Configuración del sistema

**Script:** `bin/configure.sh`

**¿Qué hace?**
- Permite modificar configuración del sistema
- Gestiona hosts autorizados (agregar, eliminar, editar)
- Configura horarios permitidos
- Ajusta parámetros de red (subred, interfaz)
- Modifica umbrales de alerta
- Configura intervalos de monitoreo

**Opciones disponibles:**
1. Cambiar subred a escanear
2. Configurar interfaz de red
3. Gestionar hosts autorizados
4. Configurar horarios (schedule)
5. Ajustar umbrales de alerta
6. Configurar intervalos de monitoreo
7. Ver configuración actual
8. Volver al menú principal

**Cuándo usarla:**
- Durante la configuración inicial
- Al cambiar de red o subred
- Para agregar/eliminar dispositivos autorizados
- Para ajustar sensibilidad de alertas
- Cuando cambias de entorno de red

**Dependencias:**
- Editor de texto (nano, vi, etc.)

**Archivos que modifica:**
- `config/config.conf` - Configuración general
- `config/hosts.conf` - Hosts autorizados
- `config/schedule.conf` - Horarios

**¿Deberías mantenerla?**
- ✅ **SÍ** si prefieres interfaz interactiva para configuración
- ✅ **SÍ** si múltiples personas usan el sistema
- ⚠️ **CONSIDERA** que también puedes editar archivos directamente
- ❌ **NO** si prefieres editar archivos de configuración manualmente

---

### SECCIÓN 5: SISTEMA

Esta sección se enfoca en **mantenimiento y verificación** del sistema.

#### Opción 15: Verificación de herramientas

**Script:** `bin/check_requirements.sh`

**¿Qué hace?**
- Verifica que todas las herramientas necesarias estén instaladas
- Muestra versión de cada herramienta
- Indica qué funciones requieren cada herramienta
- Ofrece instalar herramientas faltantes automáticamente
- Valida permisos necesarios

**Información que muestra:**
- Lista de herramientas requeridas
- Estado: INSTALADO, NO INSTALADO
- Versión instalada
- Funciones que dependen de cada herramienta
- Comandos de instalación sugeridos

**Herramientas verificadas:**
- `arp-scan` - Escaneo de red
- `nmap` - Escaneo de puertos
- `gawk` - Procesamiento de texto
- `bc` - Calculadora
- `perl` - Generación de informes
- `dig/host` - Consultas DNS
- `ifstat` - Estadísticas de red (opcional)
- `ping` - Pruebas de conectividad
- `sha256sum` - Verificación de integridad

**Cuándo usarla:**
- En la primera ejecución del sistema
- Después de instalar el sistema en un nuevo servidor
- Cuando una función no trabaja correctamente
- Para verificar el entorno antes de ejecutar tareas críticas

**Dependencias:**
- Ninguna (es la función que verifica dependencias)

**Archivos que utiliza:**
- `config/requirements.txt` - Lista de herramientas requeridas

**¿Deberías mantenerla?**
- ✅ **SÍ** - Es esencial para el funcionamiento del sistema
- ✅ **SÍ** - Se ejecuta automáticamente al iniciar
- ✅ **SÍ** - Útil para diagnóstico de problemas
- ⚠️ **NO ELIMINAR** - Función crítica del sistema

---

#### Opción 0: Salir

**¿Qué hace?**
- Cierra el programa de forma ordenada
- Muestra mensaje de despedida
- No requiere confirmación

**Cuándo usarla:**
- Cuando terminas de usar el sistema

**¿Deberías mantenerla?**
- ✅ **SÍ** - Necesaria para salir del programa

---

## Archivos de Configuración

### config/hosts.conf

**Propósito:** Define los dispositivos autorizados en la red.

**Formato:**
```
IP|MAC|HOSTNAME|DESCRIPCIÓN
```

**Ejemplo:**
```
192.168.1.1|aa:bb:cc:dd:ee:ff|Router|Gateway principal
192.168.1.10|11:22:33:44:55:66|Server01|Servidor web
```

**Usado por:**
- Opción 1 (Verificar dispositivos)
- Opción 4 (Medir latencia)
- Opción 5 (Monitor latencia)
- Opción 9 (Escanear puertos)
- Opción 12 (Generar informe)

**¿Deberías mantenerlo?**
- ✅ **SÍ** - Es fundamental para el sistema

---

### config/schedule.conf

**Propósito:** Define horarios permitidos para cada dispositivo.

**Formato:**
```
IP|DÍAS|HORA_INICIO|HORA_FIN
```

**Ejemplo:**
```
192.168.1.10|Mon-Fri|08:00|18:00
192.168.1.20|Mon-Sun|00:00|23:59
```

**Días válidos:** Mon, Tue, Wed, Thu, Fri, Sat, Sun (o rangos como Mon-Fri)

**Usado por:**
- Opción 1 (Verificar dispositivos)
- Opción 12 (Generar informe)

**¿Deberías mantenerlo?**
- ✅ **SÍ** si necesitas control de acceso por horarios
- ❌ **NO** si todos los dispositivos pueden conectarse 24/7

---

### config/config.conf

**Propósito:** Configuración general del sistema.

**Parámetros principales:**
- `SUBNET` - Subred a escanear (ej: 192.168.1.0/24)
- `NETWORK_INTERFACE` - Interfaz de red (ej: eth0)
- `DNS_SERVERS` - Servidores DNS a probar
- `MONITOR_INTERVAL` - Intervalo de monitoreo general (segundos)
- `LATENCY_THRESHOLD_MS` - Umbral de latencia (ms)
- `PORTS_TO_SCAN` - Puertos a escanear
- `VPN_PORTS` - Puertos de VPN a detectar
- `LOG_RETENTION_DAYS` - Días de retención de logs
- `REPORT_FORMAT` - Formato de informes (txt, html, both)

**Usado por:**
- Todas las funciones del sistema

**¿Deberías mantenerlo?**
- ✅ **SÍ** - Es esencial para el sistema

---

### config/requirements.txt

**Propósito:** Lista de herramientas requeridas.

**Usado por:**
- Opción 15 (Verificación de herramientas)
- Inicio del sistema (verificación automática)

**¿Deberías mantenerlo?**
- ✅ **SÍ** - Necesario para verificación de dependencias

---

## Casos de Uso

### Caso 1: Red Corporativa con Control Estricto

**Escenario:** Empresa con políticas de seguridad estrictas, dispositivos autorizados definidos, horarios de acceso.

**Opciones recomendadas:**
- ✅ Opción 1 - Verificar dispositivos (diariamente)
- ✅ Opción 2 - Anti-spoofing (diariamente)
- ✅ Opción 3 - Detectar VPN (si está prohibido)
- ✅ Opción 7 - Monitoreo ARP (durante horas laborales)
- ✅ Opción 8 - Verificar integridad (semanalmente)
- ✅ Opción 9 - Escanear puertos (semanalmente)
- ✅ Opción 11 - Detectar anomalías (diariamente)
- ✅ Opción 12 - Generar informe (semanalmente)

**Opciones opcionales:**
- ⚠️ Opción 4, 5, 6 - Solo si hay problemas de rendimiento
- ⚠️ Opción 10 - Si tienen DNS propio

---

### Caso 2: Red Doméstica o Pequeña Oficina

**Escenario:** Red pequeña, pocos dispositivos, sin políticas estrictas.

**Opciones recomendadas:**
- ✅ Opción 1 - Verificar dispositivos (ocasionalmente)
- ✅ Opción 4 - Medir latencia (cuando hay problemas)
- ✅ Opción 15 - Verificar herramientas (inicial)

**Opciones opcionales:**
- ⚠️ Opción 2 - Solo si sospechas ataques
- ⚠️ Opción 12 - Si necesitas documentación

**Opciones NO necesarias:**
- ❌ Opción 3 - Detectar VPN (innecesario)
- ❌ Opción 7 - Monitoreo ARP continuo (excesivo)
- ❌ Opción 8 - Verificar integridad (innecesario)
- ❌ Opción 11 - Detectar anomalías (sin datos históricos)

---

### Caso 3: Red Educativa (Escuela/Universidad)

**Escenario:** Muchos usuarios, dispositivos dinámicos, necesidad de control pero con flexibilidad.

**Opciones recomendadas:**
- ✅ Opción 1 - Verificar dispositivos (con schedule por horarios de clase)
- ✅ Opción 3 - Detectar VPN (si está prohibido)
- ✅ Opción 4 - Medir latencia (para diagnóstico)
- ✅ Opción 6 - Medir tráfico (para gestión de ancho de banda)
- ✅ Opción 10 - Comprobar DNS (importante)
- ✅ Opción 12 - Generar informe (para reportes administrativos)

**Opciones opcionales:**
- ⚠️ Opción 2 - Anti-spoofing (si hay problemas de seguridad)
- ⚠️ Opción 9 - Escanear puertos (ocasionalmente)

---

### Caso 4: Servidor de Producción

**Escenario:** Servidor crítico, alta disponibilidad, monitoreo constante.

**Opciones recomendadas:**
- ✅ Opción 5 - Monitor latencia continuo (24/7)
- ✅ Opción 6 - Medir tráfico (continuo)
- ✅ Opción 7 - Monitoreo ARP (24/7)
- ✅ Opción 8 - Verificar integridad (diariamente)
- ✅ Opción 10 - Comprobar DNS (crítico)
- ✅ Opción 11 - Detectar anomalías (automático)
- ✅ Opción 12 - Generar informe (diariamente)

**Consideración:** Automatizar con cron para ejecución periódica.

---

## Recomendaciones

### Opciones ESENCIALES (No eliminar)
- ✅ **Opción 15** - Verificación de herramientas (crítica)
- ✅ **Opción 14** - Configuración (útil para gestión)
- ✅ **Opción 12** - Generar informe (para documentación)
- ✅ **Opción 1** - Verificar dispositivos (función principal)

### Opciones RECOMENDADAS (Mantener según necesidad)
- ⚠️ **Opción 2** - Anti-spoofing (seguridad)
- ⚠️ **Opción 4** - Medir latencia (diagnóstico)
- ⚠️ **Opción 8** - Verificar integridad (seguridad)
- ⚠️ **Opción 13** - Gestión de logs (mantenimiento)

### Opciones ESPECIALIZADAS (Evaluar según contexto)
- 🔍 **Opción 3** - Detectar VPN (solo si es política)
- 🔍 **Opción 5** - Monitor latencia continuo (diagnóstico activo)
- 🔍 **Opción 6** - Medir tráfico (gestión de ancho de banda)
- 🔍 **Opción 7** - Monitoreo ARP continuo (seguridad alta)
- 🔍 **Opción 9** - Escanear puertos (auditorías)
- 🔍 **Opción 10** - Comprobar DNS (si tienes DNS propio)
- 🔍 **Opción 11** - Detectar anomalías (requiere históricos)

### Posibles Mejoras

**Opciones que podrías AGREGAR:**
1. **Bloqueo automático de dispositivos** - Agregar reglas iptables para bloquear IPs no autorizadas
2. **Notificaciones por email/SMS** - Enviar alertas automáticas
3. **Dashboard web** - Interfaz web para visualización
4. **Análisis de tráfico profundo** - Captura y análisis de paquetes
5. **Integración con SIEM** - Exportar logs a sistemas de seguridad
6. **Automatización con cron** - Programar ejecuciones automáticas
7. **Backup de configuración** - Respaldo automático de configs
8. **Modo silencioso** - Ejecución sin interacción para scripts
9. **API REST** - Acceso programático a funciones
10. **Geolocalización de IPs** - Detectar IPs de países sospechosos

**Opciones que podrías ELIMINAR si:**
- **Opción 3** - Si permites VPN o no es relevante
- **Opción 5** - Si prefieres solo mediciones puntuales (opción 4)
- **Opción 6** - Si no te preocupa el ancho de banda
- **Opción 7** - Si no necesitas monitoreo en tiempo real
- **Opción 9** - Si no haces auditorías de puertos
- **Opción 10** - Si no tienes problemas de DNS
- **Opción 11** - Si no tienes suficientes datos históricos

---

## Conclusión

Este sistema proporciona un conjunto completo de herramientas para monitoreo y seguridad de red. La decisión de qué opciones mantener depende de:

1. **Tamaño de tu red** - Redes pequeñas necesitan menos funciones
2. **Requisitos de seguridad** - Entornos corporativos necesitan más controles
3. **Recursos disponibles** - Algunas funciones consumen recursos
4. **Políticas organizacionales** - Algunas funciones dependen de políticas
5. **Experiencia técnica** - Algunas funciones requieren conocimiento avanzado

**Recomendación final:** Comienza con las opciones esenciales (1, 12, 14, 15) y agrega funciones según las necesites. Usa esta guía para entender qué hace cada opción antes de decidir eliminarla.

---

**Documento creado:** 2025-11-25  
**Versión:** 1.0  
**Proyecto:** SIM-RED EXTENDIDO v1.0
