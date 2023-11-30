#!/bin/bash
# Ferramenta de Instalação de Aplicações Android via ADB Wireless
# Criado por Leonardo Fonseca
# Licença: Licença MIT (Open Source)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem Cor

# Obter o diretório do script
DIR=$(dirname "$(readlink -f "$0")")

# URL para download do ADB
ADB_ZIP_URL="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"
ADB_ZIP_FILE="$DIR/platform-tools-latest-darwin.zip"
ADB_DIR="$DIR/platform-tools"

# Função para mostrar termos e condições
exibir_termos_e_condicoes() {
    clear
    echo -e "${CYAN}Termos e Condições de Uso${NC}"
    echo "-------------------------"
    echo "Este script utiliza o Android Debug Bridge (ADB) para instalar aplicativos."
    echo "Para mais informações sobre como ativar o modo debug em seu dispositivo, visite:"
    echo "https://developer.android.com/studio/command-line/adb?hl=pt-br"
    echo -e "\nAVISO LEGAL: Este software é fornecido 'como está', sem garantia de qualquer tipo. O uso é por conta e risco do utilizador."
    echo "O criador deste script não se responsabiliza por quaisquer danos resultantes do uso deste software."
    echo -e "\nPressione Enter para aceitar os termos e condições e continuar ou qualquer outra tecla para sair."
    read -s -n 1 aceitacao
    if [ "$aceitacao" != "" ]; then
        echo -e "${RED}Você escolheu sair. Os termos e condições não foram aceitos.${NC}"
        exit 4
    fi
}

# Função para contar APKs no diretório
contar_apks() {
    find "$1" -maxdepth 1 -name "*.apk" | wc -l
}

# Verificar se há APKs na pasta apk
APK_DIR="$DIR/apk"
if [ $(contar_apks "$APK_DIR") -eq 0 ]; then
    echo -e "${RED}Nenhum APK foi encontrado na pasta 'apk'.${NC}"
    exit 5
fi

# Função para verificar e baixar o ADB
download_adb() {
    if [ ! -f "$ADB_DIR/adb" ]; then
        echo -e "${YELLOW}ADB não encontrado. Deseja baixar o ADB agora? (y/n):${NC}"
        read -r resp
        if [[ $resp == "y" ]]; then
            echo "Baixando ADB para macOS..."
            curl -L -o "$ADB_ZIP_FILE" "$ADB_ZIP_URL" --progress-bar && {
                unzip -q "$ADB_ZIP_FILE" -d "$DIR" && {
                    chmod +x "$ADB_DIR/adb"
                    echo -e "${GREEN}ADB baixado e configurado com sucesso.${NC}"
                } || {
                    echo -e "${RED}Falha ao descompactar o ADB.${NC}"
                    exit 2
                }
            } || {
                echo -e "${RED}Erro ao baixar o ADB.${NC}"
                exit 1
            }
        fi
    fi
}

# Função para conectar ao dispositivo
conectar_dispositivo() {
    local ip_dispositivo
    local nome_dispositivo

    # Verificar se o arquivo de última conexão existe
    if [ -f "$DIR/last_connection.txt" ]; then
        read -r ip_dispositivo nome_dispositivo < "$DIR/last_connection.txt"
        echo "Última conexão foi com o dispositivo '$nome_dispositivo' com IP $ip_dispositivo."
        echo -e "${YELLOW}Deseja utilizar os dados da última conexão? (y/n):${NC}"
        read resp
        if [[ $resp != "y" ]]; then
            echo -e "${YELLOW}Digite o IP do dispositivo:${NC}"
            read ip_dispositivo
            nome_dispositivo=""  # Resetar o nome do dispositivo, pois será obtido novamente
        fi
    else
        echo "Nenhuma conexão anterior encontrada."
        echo -e "${YELLOW}Digite o IP do dispositivo:${NC}"
        read ip_dispositivo
    fi

    if ! "$ADB_DIR/adb" connect "$ip_dispositivo"; then
        echo -e "${RED}Falha ao conectar ao dispositivo. Verifique a conexão e o IP inserido.${NC}"
        exit 3
    fi

    # Verificar se a conexão foi bem-sucedida antes de prosseguir
    if ! "$ADB_DIR/adb" -s "$ip_dispositivo" shell echo "conexão bem-sucedida" &> /dev/null; then
        echo -e "${RED}Falha ao estabelecer uma conexão estável com o dispositivo.${NC}"
        exit 4
    fi

    if [ -z "$nome_dispositivo" ]; then
        nome_dispositivo=$("$ADB_DIR/adb" -s "$ip_dispositivo" shell getprop ro.product.model)
    fi
    echo "$ip_dispositivo $nome_dispositivo" > "$DIR/last_connection.txt"
    echo -e "${GREEN}Conectado com sucesso ao dispositivo '$nome_dispositivo' com IP $ip_dispositivo.${NC}"
}

# Função para listar APKs encontrados
listar_apks_encontrados() {
    if [ $(contar_apks "$APK_DIR") -gt 0 ]; then
        echo -e "${CYAN}Aplicativos encontrados para instalação:${NC}"
        for apk in "$APK_DIR"/*.apk; do
            echo "$(basename "$apk")"
        done
    fi
}

# Função para listar e instalar APKs
listar_e_instalar_apks() {
    INSTALADOS_DIR="$APK_DIR/instalados"
    [ ! -d "$INSTALADOS_DIR" ] && mkdir -p "$INSTALADOS_DIR"

    listar_apks_encontrados

    for apk in "$APK_DIR"/*.apk; do
        apk_nome="$(basename "$apk")"
        echo -e "${YELLOW}Deseja instalar $apk_nome no dispositivo? (y/n):${NC}"
        read -r resp
        if [[ $resp == "y" ]]; then
            "$ADB_DIR/adb" -s "$ip_dispositivo" install -r "$apk" && {
                mv "$apk" "$INSTALADOS_DIR"
                echo -e "${GREEN}$apk_nome instalado com sucesso.${NC}"
            } || {
                echo -e "${RED}Falha ao instalar $apk_nome.${NC}"
            }
        fi
    done

    echo -e "${CYAN}Resumo da instalação:${NC}"
    for apk in "$INSTALADOS_DIR"/*.apk; do
        apk_nome="$(basename "$apk")"
        echo "$apk_nome: Instalado"
    done
    if [ $(contar_apks "$INSTALADOS_DIR") -eq 0 ]; then
        echo "Nenhum APK foi instalado."
    fi
}

desconectar_dispositivo() {
    local ip_dispositivo="$1"

    if [ -z "$ip_dispositivo" ]; then
        echo "Desconectando todos os dispositivos..."
        "$ADB_DIR/adb" disconnect
    else
        echo "Desconectando o dispositivo com IP $ip_dispositivo..."
        "$ADB_DIR/adb" disconnect "$ip_dispositivo"
    fi
}

# Início do script
exibir_termos_e_condicoes
download_adb
conectar_dispositivo
listar_e_instalar_apks
desconectar_dispositivo
