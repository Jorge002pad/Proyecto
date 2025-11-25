# 🎉 Auto-Detección de Red Implementada

## ✅ Cambios Realizados

Se ha implementado la **auto-detección automática de red** en SIM-RED EXTENDIDO. Ahora el sistema identifica automáticamente tu configuración de red sin necesidad de editar archivos manualmente.

---

## 🚀 Nuevas Funcionalidades

### 1. **Detección Automática al Inicio**
Cuando ejecutes `sim-red.sh`, el sistema automáticamente:
- ✅ Detecta tu **interfaz de red activa** (eth0, enp0s3, wlan0, etc.)
- ✅ Identifica tu **dirección IP**
- ✅ Encuentra tu **gateway/router**
- ✅ Calcula el **rango de red (subnet)**

### 2. **Actualización Automática de Configuración**
Si el sistema detecta que la red actual es diferente a la configurada:
- 📝 Te pregunta si deseas actualizar la configuración
- 💾 Crea un backup automático de `config.conf`
- ⚙️ Actualiza `SUBNET` y `NETWORK_INTERFACE` automáticamente

### 3. **Variables Exportadas**
Las siguientes variables están disponibles en todos los scripts:
- `DETECTED_INTERFACE` - Interfaz de red detectada
- `DETECTED_SUBNET` - Rango de red detectado
- `DETECTED_GATEWAY` - Gateway/router detectado
- `DETECTED_IP` - Tu dirección IP

---

## 📋 Cómo Funciona

### Antes (Manual):
```bash
# Tenías que editar manualmente config/config.conf
nano config/config.conf

# Y cambiar estas líneas:
SUBNET="192.168.1.0/24"
NETWORK_INTERFACE="eth0"
```

### Ahora (Automático):
```bash
# Simplemente ejecuta el programa
sudo bash sim-red.sh

# El sistema detecta automáticamente:
╔═══════════════════════════════════════════════════════════════════════╗
║                    Auto-Detección de Red                              ║
╚═══════════════════════════════════════════════════════════════════════╝

ℹ Interfaz de red detectada: enp0s3
ℹ Tu dirección IP: 192.168.1.100
ℹ Gateway (Router): 192.168.1.1
ℹ Rango de red (Subnet): 192.168.1.0/24

⚠ La configuración actual (192.168.0.0/24) difiere de la red detectada (192.168.1.0/24)
¿Deseas actualizar la configuración automáticamente? [S/n]: s

✓ Configuración actualizada correctamente
ℹ Backup guardado en: ./config/config.conf.bak
```

---

## 🔧 Funciones Disponibles

### `detect_network_interface()`
Detecta la interfaz de red activa.

```bash
iface=$(detect_network_interface)
echo "Interfaz: $iface"
# Salida: Interfaz: enp0s3
```

### `detect_network_subnet()`
Detecta el rango de red (subnet).

```bash
subnet=$(detect_network_subnet)
echo "Subnet: $subnet"
# Salida: Subnet: 192.168.1.0/24
```

### `detect_network_gateway()`
Detecta el gateway/router.

```bash
gateway=$(detect_network_gateway)
echo "Gateway: $gateway"
# Salida: Gateway: 192.168.1.1
```

### `auto_detect_network()`
Función principal que detecta todo y muestra la información.

```bash
# Con salida visible
auto_detect_network "yes"

# Sin salida (silencioso)
auto_detect_network "no"
```

---

## 💡 Casos de Uso

### Caso 1: Primera Ejecución
El sistema detecta tu red y te pregunta si deseas guardar la configuración.

### Caso 2: Cambio de Red
Si te conectas a una red diferente (ej: de casa a la universidad), el sistema lo detecta y te pregunta si deseas actualizar.

### Caso 3: Múltiples Interfaces
Si tienes múltiples interfaces (eth0, wlan0), el sistema selecciona automáticamente la que tiene la ruta por defecto.

---

## 🛡️ Seguridad

- ✅ **Backup automático**: Antes de modificar `config.conf`, se crea un backup en `config.conf.bak`
- ✅ **Confirmación del usuario**: El sistema siempre pregunta antes de actualizar la configuración
- ✅ **Validación de datos**: Se validan las IPs y rangos de red antes de guardarlos

---

## 📝 Archivos Modificados

1. **`lib/common.sh`**
   - Agregadas funciones de auto-detección
   - Exportadas para uso en todos los scripts

2. **`sim-red.sh`**
   - Integrada auto-detección en el inicio del programa

---

## 🎯 Próximos Pasos

Ya no necesitas editar manualmente los archivos de configuración. El sistema se encarga de todo automáticamente.

**Para usar SIM-RED ahora:**
```bash
cd ~/Descargas/Proyecto-main/SIM-RED
sudo bash sim-red.sh
```

El sistema detectará tu red automáticamente y estará listo para usar. 🚀

---

## ❓ Preguntas Frecuentes

**P: ¿Puedo seguir editando manualmente la configuración?**  
R: Sí, puedes editar `config/config.conf` manualmente si lo prefieres.

**P: ¿Qué pasa si tengo múltiples interfaces de red?**  
R: El sistema selecciona automáticamente la interfaz con la ruta por defecto (la que usas para conectarte a Internet).

**P: ¿Se guarda un backup antes de modificar la configuración?**  
R: Sí, siempre se crea un backup en `config/config.conf.bak`.

**P: ¿Puedo desactivar la auto-detección?**  
R: Sí, simplemente responde "n" cuando te pregunte si deseas actualizar la configuración.

---

**¡Disfruta de SIM-RED EXTENDIDO con auto-detección de red!** 🎉
