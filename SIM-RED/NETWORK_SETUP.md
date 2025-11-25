# 🌐 Guía de Configuración de Red - SIM-RED EXTENDIDO

Esta guía te ayudará a identificar tu red y configurar correctamente los archivos de SIM-RED.

---

## 📋 Paso 1: Identificar tu Configuración de Red

### 1.1 Ver tu dirección IP actual

```bash
ip addr show
```

O más simple:
```bash
hostname -I
```

**Ejemplo de salida:**
```
192.168.1.100
```

### 1.2 Ver tu gateway (router)

```bash
ip route | grep default
```

**Ejemplo de salida:**
```
default via 192.168.1.1 dev eth0
```

Aquí `192.168.1.1` es tu **gateway/router**.

### 1.3 Ver tu rango de red completo

```bash
ip -4 addr show | grep inet
```

**Ejemplo de salida:**
```
inet 192.168.1.100/24 brd 192.168.1.255 scope global eth0
```

El `/24` significa:
- **Red:** 192.168.1.0/24
- **Rango de IPs:** 192.168.1.1 - 192.168.1.254
- **Máscara:** 255.255.255.0

### 1.4 Ver tu interfaz de red

```bash
ip link show
```

Busca interfaces como: `eth0`, `enp0s3`, `wlan0`, etc.

---

## 🔍 Paso 2: Escanear Dispositivos en tu Red

### 2.1 Escaneo rápido con nmap (descubrimiento de hosts)

```bash
sudo nmap -sn 192.168.1.0/24
```

**Reemplaza `192.168.1.0/24` con tu rango de red**

**Ejemplo de salida:**
```
Nmap scan report for 192.168.1.1
Host is up (0.0010s latency).
MAC Address: AA:BB:CC:DD:EE:FF (Manufacturer)

Nmap scan report for 192.168.1.10
Host is up (0.0020s latency).
MAC Address: 11:22:33:44:55:66 (Manufacturer)
```

### 2.2 Escaneo detallado con MAC addresses

```bash
sudo nmap -sn -PR 192.168.1.0/24 | grep -E "Nmap scan|MAC Address"
```

### 2.3 Ver tabla ARP (dispositivos conectados recientemente)

```bash
ip neigh show
```

O:
```bash
arp -a
```

---

## ⚙️ Paso 3: Configurar SIM-RED

### 3.1 Editar `config/config.conf`

Abre el archivo:
```bash
nano config/config.conf
```

Modifica estas líneas según tu red:

```bash
# Network Configuration
SUBNET="192.168.1.0/24"          # ← Cambia esto a tu rango de red
NETWORK_INTERFACE="eth0"         # ← Cambia esto a tu interfaz de red
```

**Ejemplos comunes:**

| Tipo de Red | SUBNET | Rango de IPs |
|-------------|--------|--------------|
| Red doméstica típica | `192.168.1.0/24` | 192.168.1.1 - 192.168.1.254 |
| Red doméstica alternativa | `192.168.0.0/24` | 192.168.0.1 - 192.168.0.254 |
| Red corporativa | `10.0.0.0/24` | 10.0.0.1 - 10.0.0.254 |
| Red VirtualBox | `10.0.2.0/24` | 10.0.2.1 - 10.0.2.254 |

### 3.2 Editar `config/hosts.conf`

Abre el archivo:
```bash
nano config/hosts.conf
```

Agrega tus dispositivos en el formato:
```
IP|MAC|HOSTNAME|DESCRIPTION
```

**Ejemplo real:**
```bash
# Network Infrastructure
192.168.1.1|aa:bb:cc:dd:ee:ff|Router|Gateway principal de la red

# Servers
192.168.1.10|11:22:33:44:55:66|WebServer|Servidor web Apache
192.168.1.11|22:33:44:55:66:77|DBServer|Servidor de base de datos

# Workstations
192.168.1.100|33:44:55:66:77:88|PC-Admin|Computadora del administrador
192.168.1.101|44:55:66:77:88:99|PC-User1|Computadora usuario 1
```

---

## 🎯 Paso 4: Obtener MACs de tus Dispositivos

### Método 1: Desde el escaneo nmap
```bash
sudo nmap -sn 192.168.1.0/24
```

### Método 2: Desde la tabla ARP
```bash
ip neigh show
```

### Método 3: Desde cada dispositivo

**En Linux/Ubuntu:**
```bash
ip link show
```

**En Windows:**
```cmd
ipconfig /all
```

**En tu router:**
- Accede a la interfaz web del router (usualmente `http://192.168.1.1`)
- Busca la sección "Dispositivos conectados" o "DHCP Clients"

---

## 📝 Ejemplo Completo de Configuración

### Escenario: Red doméstica típica

**Tu configuración de red:**
- IP de tu PC: `192.168.1.100`
- Gateway: `192.168.1.1`
- Rango: `192.168.1.0/24`
- Interfaz: `enp0s3`

### 1. Archivo `config/config.conf`:
```bash
SUBNET="192.168.1.0/24"
NETWORK_INTERFACE="enp0s3"
```

### 2. Archivo `config/hosts.conf`:
```bash
# Network Infrastructure
192.168.1.1|a1:b2:c3:d4:e5:f6|Router|TP-Link Router

# Computers
192.168.1.100|11:22:33:44:55:66|MiPC|Mi computadora principal
192.168.1.101|22:33:44:55:66:77|Laptop|Laptop del trabajo

# IoT Devices
192.168.1.150|33:44:55:66:77:88|SmartTV|Samsung Smart TV
192.168.1.151|44:55:66:77:88:99|Printer|Impresora HP
```

---

## ✅ Paso 5: Verificar la Configuración

### 5.1 Ejecutar SIM-RED
```bash
cd ~/Descargas/Proyecto-main/SIM-RED
sudo bash sim-red.sh
```

### 5.2 Probar la opción 1 (Verificar dispositivos)
Selecciona la opción `1` para ver si detecta correctamente los dispositivos de tu red.

### 5.3 Revisar logs
```bash
cat logs/system.log
```

---

## 🔧 Comandos Útiles de Referencia Rápida

```bash
# Ver mi IP
hostname -I

# Ver mi gateway
ip route | grep default

# Ver mi interfaz de red
ip link show

# Escanear red completa
sudo nmap -sn 192.168.1.0/24

# Ver dispositivos conectados (ARP)
ip neigh show

# Ver información completa de red
ip addr show
```

---

## 🆘 Solución de Problemas

### Problema: "No se detectan dispositivos"
**Solución:**
1. Verifica que `SUBNET` en `config.conf` sea correcto
2. Verifica que `NETWORK_INTERFACE` sea la interfaz correcta
3. Ejecuta con `sudo` (necesario para escaneo de red)

### Problema: "nmap no está instalado"
**Solución:**
```bash
sudo apt update
sudo apt install nmap
```

### Problema: "Interfaz de red incorrecta"
**Solución:**
```bash
# Ver todas las interfaces
ip link show

# Actualizar config.conf con la interfaz correcta
nano config/config.conf
```

---

## 📚 Recursos Adicionales

- [Documentación de nmap](https://nmap.org/book/man.html)
- [Guía de subredes IP](https://www.calculator.net/ip-subnet-calculator.html)
- Archivo de instalación: `INSTALL.md`
- Archivo de estructura: `FILES.md`

---

**¡Listo!** Ahora ya sabes cómo configurar tu red en SIM-RED EXTENDIDO. 🎉
