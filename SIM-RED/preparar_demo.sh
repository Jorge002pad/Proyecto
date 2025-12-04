#!/bin/bash
# Script para preparar demostración rápidamente
# Autor: SIM-RED EXTENDIDO
# Uso: ./preparar_demo.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🎬 PREPARACIÓN DE DEMOSTRACIÓN SIM-RED   ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo ""

# Verificar que estamos en el directorio correcto
if [ ! -f "sim-red.sh" ]; then
    echo -e "${RED}❌ Error: No se encuentra sim-red.sh${NC}"
    echo -e "${YELLOW}   Ejecuta este script desde el directorio SIM-RED${NC}"
    exit 1
fi

echo -e "${YELLOW}📝 Paso 1: Limpiando logs antiguos...${NC}"
if [ -d "logs" ]; then
    rm -f logs/*.log 2>/dev/null
    echo -e "${GREEN}   ✅ Logs limpiados${NC}"
else
    echo -e "${YELLOW}   ⚠️  Directorio logs/ no existe, creándolo...${NC}"
    mkdir -p logs
fi

echo ""
echo -e "${YELLOW}🗑️  Paso 2: Limpiando datos históricos (para demo fresca)...${NC}"
if [ -d "data" ]; then
    rm -f data/*.dat 2>/dev/null
    echo -e "${GREEN}   ✅ Datos históricos limpiados${NC}"
else
    echo -e "${YELLOW}   ⚠️  Directorio data/ no existe, creándolo...${NC}"
    mkdir -p data
fi

echo ""
echo -e "${YELLOW}🔍 Paso 3: Verificando conectividad con clientes...${NC}"

# Lista de IPs a verificar (ajusta según tu configuración)
CLIENTES=(
    "192.168.100.10:Cliente-Autorizado"
    "192.168.100.20:Cliente-Intruso"
    "192.168.100.30:Cliente-Horario"
)

ONLINE=0
OFFLINE=0

for cliente in "${CLIENTES[@]}"; do
    IP="${cliente%%:*}"
    NOMBRE="${cliente##*:}"
    
    if ping -c 1 -W 1 "$IP" > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ $NOMBRE ($IP): ONLINE${NC}"
        ((ONLINE++))
    else
        echo -e "${RED}   ❌ $NOMBRE ($IP): OFFLINE${NC}"
        ((OFFLINE++))
    fi
done

echo ""
echo -e "${BLUE}📊 Resumen de conectividad:${NC}"
echo -e "   ${GREEN}Online: $ONLINE${NC}"
echo -e "   ${RED}Offline: $OFFLINE${NC}"

echo ""
echo -e "${YELLOW}🔧 Paso 4: Verificando configuración...${NC}"

# Verificar archivos de configuración
if [ -f "config/hosts.conf" ]; then
    HOSTS_COUNT=$(grep -v '^#' config/hosts.conf | grep -v '^$' | wc -l)
    echo -e "${GREEN}   ✅ hosts.conf: $HOSTS_COUNT dispositivos configurados${NC}"
else
    echo -e "${RED}   ❌ hosts.conf no encontrado${NC}"
fi

if [ -f "config/schedule.conf" ]; then
    SCHEDULE_COUNT=$(grep -v '^#' config/schedule.conf | grep -v '^$' | wc -l)
    echo -e "${GREEN}   ✅ schedule.conf: $SCHEDULE_COUNT horarios configurados${NC}"
else
    echo -e "${RED}   ❌ schedule.conf no encontrado${NC}"
fi

if [ -f "config/config.conf" ]; then
    echo -e "${GREEN}   ✅ config.conf encontrado${NC}"
else
    echo -e "${RED}   ❌ config.conf no encontrado${NC}"
fi

echo ""
echo -e "${YELLOW}⏰ Paso 5: Verificando hora del sistema...${NC}"
CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
DAY_OF_WEEK=$(date +"%A")
echo -e "${GREEN}   📅 Fecha/Hora actual: $CURRENT_TIME${NC}"
echo -e "${GREEN}   📆 Día de la semana: $DAY_OF_WEEK${NC}"

# Verificar si estamos en horario laboral (para demos de horarios)
HOUR=$(date +"%H")
if [ "$HOUR" -ge 8 ] && [ "$HOUR" -lt 18 ]; then
    echo -e "${GREEN}   ✅ Estamos en horario laboral (8am-6pm)${NC}"
    echo -e "${BLUE}      → Los dispositivos con horario 8-18 aparecerán como AUTORIZADOS${NC}"
else
    echo -e "${YELLOW}   ⚠️  Estamos fuera de horario laboral${NC}"
    echo -e "${BLUE}      → Los dispositivos con horario 8-18 aparecerán como FUERA DE HORARIO${NC}"
fi

echo ""
echo -e "${YELLOW}🛠️  Paso 6: Verificando herramientas necesarias...${NC}"

TOOLS=("arp-scan" "nmap" "gawk" "ping" "bc")
MISSING=0

for tool in "${TOOLS[@]}"; do
    if command -v "$tool" > /dev/null 2>&1; then
        echo -e "${GREEN}   ✅ $tool instalado${NC}"
    else
        echo -e "${RED}   ❌ $tool NO instalado${NC}"
        ((MISSING++))
    fi
done

if [ $MISSING -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}   ⚠️  Faltan $MISSING herramientas. Ejecuta:${NC}"
    echo -e "${BLUE}      sudo ./sim-red.sh${NC}"
    echo -e "${BLUE}      Luego selecciona opción 15 para instalar dependencias${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ PREPARACIÓN COMPLETA                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

if [ $ONLINE -eq 0 ]; then
    echo -e "${RED}⚠️  ADVERTENCIA: No hay clientes online${NC}"
    echo -e "${YELLOW}   Enciende al menos una VM cliente antes de la demo${NC}"
    echo ""
fi

echo -e "${BLUE}🚀 Puedes iniciar SIM-RED con:${NC}"
echo -e "${GREEN}   sudo ./sim-red.sh${NC}"
echo ""
echo -e "${BLUE}📋 Opciones recomendadas para la demo:${NC}"
echo -e "   ${GREEN}1${NC} - Verificar dispositivos conectados"
echo -e "   ${GREEN}2${NC} - Verificar suplantación de IP (Anti-Spoofing)"
echo -e "   ${GREEN}4${NC} - Medir latencia promedio de toda la red"
echo -e "   ${GREEN}12${NC} - Generar informe completo del estado de la red"
echo ""
echo -e "${YELLOW}💡 Tip: Abre otra terminal y ejecuta:${NC}"
echo -e "${BLUE}   tail -f logs/devices.log${NC}"
echo -e "${YELLOW}   Para ver los logs en tiempo real durante la demo${NC}"
echo ""
