# Guía de Instalación - SIM-RED EXTENDIDO

Esta guía te ayudará a instalar y configurar SIM-RED EXTENDIDO en tu sistema Ubuntu.

## 📋 Requisitos Previos

### Sistema Operativo
- **Ubuntu 20.04 LTS o superior** (recomendado)
- Otras distribuciones basadas en Debian pueden funcionar con ajustes menores

### Permisos
- Acceso a cuenta con privilegios `sudo`
- Conexión a Internet (para instalar dependencias)

### Espacio en Disco
- Mínimo: 50 MB
- Recomendado: 200 MB (para logs e informes)

## 🚀 Instalación Paso a Paso

### Paso 1: Descargar el Proyecto

Si tienes el proyecto en un archivo comprimido:
```bash
cd ~/Downloads
unzip SIM-RED.zip
cd SIM-RED
```

Si ya tienes la carpeta del proyecto:
```bash
cd /ruta/a/SIM-RED
```

### Paso 2: Verificar la Estructura

Asegúrate de que todos los archivos estén presentes:
```bash
ls -la
```

Deberías ver:
- `sim-red.sh` - Script principal
- `bin/` - Carpeta con scripts de funciones
- `lib/` - Carpeta con bibliotecas
- `config/` - Carpeta con configuraciones
- `logs/` - Carpeta para logs
- `reports/` - Carpeta para informes
- `data/` - Carpeta para datos históricos

### Paso 3: Dar Permisos de Ejecución

```bash
chmod +x sim-red.sh
chmod +x bin/*.sh
chmod +x lib/*.awk
chmod +x lib/*.pl
```

### Paso 4: Ejecutar por Primera Vez

```bash
sudo ./sim-red.sh
```

El sistema automáticamente:
1. Verificará las herramientas necesarias
2. Te preguntará si deseas instalar las faltantes
3. Instalará las dependencias (si aceptas)
4. Mostrará el menú principal

## 🔧 Instalación Manual de Dependencias

Si prefieres instalar las dependencias manualmente:

### Actualizar Repositorios
```bash
sudo apt-get update
```

### Instalar Herramientas Esenciales
```bash
sudo apt-get install -y arp-scan nmap gawk bc perl
```

### Instalar Herramientas Opcionales
```bash
sudo apt-get install -y ifstat dnsutils net-tools iproute2
```

### Verificar Instalación
```bash
# Verificar cada herramienta
which arp-scan
which nmap
which gawk
which bc
which perl
```

## ⚙️ Configuración Inicial

### 1. Configurar Hosts Autorizados

Edita el archivo `config/hosts.conf`:
```bash
nano config/hosts.conf
```

Añade tus dispositivos en el formato:
```
IP|MAC|HOSTNAME|DESCRIPCIÓN
```

Ejemplo:
```
192.168.1.1|aa:bb:cc:dd:ee:ff|Router|Gateway principal
192.168.1.10|11:22:33:44:55:66|WebServer|Servidor Apache
192.168.1.100|77:88:99:aa:bb:cc|PC-Admin|Computadora del administrador
```

**Cómo obtener las MACs de tus dispositivos:**
```bash
# Escanear la red
sudo arp-scan --localnet

# O ver la tabla ARP actual
arp -a
```

### 2. Configurar Horarios Permitidos

Edita el archivo `config/schedule.conf`:
```bash
nano config/schedule.conf
```

Define los horarios en el formato:
```
IP|DÍAS|HORA_INICIO|HORA_FIN
```

Ejemplo:
```
192.168.1.1|Mon-Sun|00:00|23:59     # Router siempre activo
192.168.1.10|Mon-Sun|00:00|23:59    # Servidor 24/7
192.168.1.100|Mon-Sun|00:00|23:59   # Admin sin restricciones
192.168.1.101|Mon-Fri|08:00|18:00   # Usuario solo horario laboral
```

**Formatos de días:**
- Días específicos: `Mon`, `Tue`, `Wed`, `Thu`, `Fri`, `Sat`, `Sun`
- Rangos: `Mon-Fri`, `Sat-Sun`
- Todos los días: `Mon-Sun` o `*`

### 3. Configurar Parámetros del Sistema

Edita el archivo `config/config.conf`:
```bash
nano config/config.conf
```

Parámetros importantes:
```bash
# Tu subred local
SUBNET="192.168.1.0/24"

# Interfaz de red principal
NETWORK_INTERFACE="eth0"  # o "wlan0" para WiFi

# Servidores DNS a probar
DNS_SERVERS="8.8.8.8 8.8.4.4 1.1.1.1"

# Umbrales de alerta
LATENCY_ALERT_MS=200
TRAFFIC_ANOMALY_MULTIPLIER=2.0
```

**Cómo encontrar tu interfaz de red:**
```bash
ip link show
# o
ifconfig
```

**Cómo encontrar tu subred:**
```bash
ip addr show
# Busca la línea con "inet" (no 127.0.0.1)
```

## 🧪 Prueba de Instalación

### Verificar que Todo Funciona

1. **Ejecutar el menú principal:**
```bash
sudo ./sim-red.sh
```

2. **Probar la verificación de herramientas (Opción 15):**
   - Selecciona opción `15`
   - Debe mostrar "Todo listo para iniciar"

3. **Probar verificación de dispositivos (Opción 1):**
   - Selecciona opción `1`
   - Debe escanear la red y mostrar dispositivos

4. **Generar un informe de prueba (Opción 12):**
   - Selecciona opción `12`
   - Revisa el informe en `reports/`

## 🐛 Solución de Problemas

### Error: "arp-scan: command not found"

**Solución:**
```bash
sudo apt-get install arp-scan
```

### Error: "Permission denied"

**Solución:**
```bash
# Asegúrate de ejecutar con sudo
sudo ./sim-red.sh

# O dar permisos de ejecución
chmod +x sim-red.sh
```

### Error: "No se pueden escanear dispositivos"

**Causas posibles:**
1. No estás ejecutando como root
2. La interfaz de red está mal configurada
3. La subred no es correcta

**Solución:**
```bash
# Verificar interfaz
ip link show

# Editar config.conf con la interfaz correcta
nano config/config.conf

# Cambiar NETWORK_INTERFACE y SUBNET
```

### Los Scripts No se Ejecutan

**Solución:**
```bash
# Dar permisos a todos los scripts
chmod +x sim-red.sh
chmod +x bin/*.sh
chmod +x lib/*.awk
chmod +x lib/*.pl
```

### Error: "dig: command not found"

**Solución:**
```bash
sudo apt-get install dnsutils
```

### Perl No Genera Informes HTML

**Solución:**
```bash
# Verificar que Perl esté instalado
perl --version

# Si no está instalado
sudo apt-get install perl
```

## 📊 Verificación de Instalación Completa

Ejecuta este comando para verificar todas las dependencias:
```bash
for cmd in arp-scan nmap gawk bc perl dig ping ip; do
    if command -v $cmd &> /dev/null; then
        echo "✓ $cmd instalado"
    else
        echo "✗ $cmd NO instalado"
    fi
done
```

## 🔄 Actualización

Para actualizar el sistema:
1. Respalda tus configuraciones:
```bash
cp -r config/ config_backup/
```

2. Descarga la nueva versión
3. Restaura tus configuraciones:
```bash
cp config_backup/* config/
```

## 🗑️ Desinstalación

Para eliminar SIM-RED EXTENDIDO:
```bash
# Desde la carpeta del proyecto
cd ..
rm -rf SIM-RED

# Opcionalmente, desinstalar dependencias
# (solo si no las usas para otras cosas)
sudo apt-get remove arp-scan nmap
```

## 📚 Uso Avanzado

### Ejecutar Funciones Individuales

Puedes ejecutar funciones específicas directamente:
```bash
sudo bash bin/check_devices.sh
sudo bash bin/measure_latency.sh
sudo bash bin/generate_report.sh
```

### Automatización con Cron

Para ejecutar verificaciones automáticas:
```bash
# Editar crontab
sudo crontab -e

# Añadir líneas como:
# Verificar dispositivos cada hora
0 * * * * /ruta/a/SIM-RED/bin/check_devices.sh >> /var/log/sim-red.log 2>&1

# Generar informe diario a las 23:00
0 23 * * * /ruta/a/SIM-RED/bin/generate_report.sh >> /var/log/sim-red.log 2>&1
```

### Logs Centralizados

Para enviar logs a syslog:
```bash
# Editar common.sh y modificar la función log_message
# para usar logger en lugar de echo
```

## 🆘 Soporte Adicional

Si encuentras problemas:

1. **Revisa los logs:**
```bash
cat logs/system.log
tail -f logs/system.log  # Ver en tiempo real
```

2. **Ejecuta el verificador de herramientas:**
```bash
sudo ./sim-red.sh
# Opción 15
```

3. **Verifica permisos:**
```bash
ls -la sim-red.sh
ls -la bin/
```

4. **Revisa la configuración:**
```bash
cat config/config.conf
cat config/hosts.conf
```

## ✅ Checklist de Instalación

- [ ] Ubuntu 20.04+ instalado
- [ ] Acceso sudo disponible
- [ ] Proyecto descargado y descomprimido
- [ ] Permisos de ejecución otorgados
- [ ] Dependencias instaladas
- [ ] `hosts.conf` configurado
- [ ] `schedule.conf` configurado
- [ ] `config.conf` ajustado a tu red
- [ ] Prueba exitosa del menú principal
- [ ] Verificación de herramientas OK
- [ ] Primer escaneo de red exitoso

---

**¡Instalación completada!** Ya puedes usar SIM-RED EXTENDIDO para monitorear y asegurar tu red.

Para más información, consulta el [README.md](README.md)
