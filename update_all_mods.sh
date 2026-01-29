#!/bin/bash

# DayZ Workshop Mod Auto-Updater
# This script updates all installed mods while preserving directory names

# ============================================
# STEAM CREDENTIALS - UPDATE THESE
# ============================================
STEAM_USER="your_steam_username"
STEAM_PASS="your_steam_password"
# Note: If you have Steam Guard, you'll still need to enter the code manually on first run
# ============================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# DayZ App ID
DAYZ_APP_ID=221100

# Default paths
STEAMCMD_PATH="$HOME/.steam/steamcmd/steamcmd.sh"
WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/$DAYZ_APP_ID"
SERVER_MODS_DIR="$HOME/serverfiles/mods"
KEYS_DIR="$HOME/serverfiles/keys"
MOD_MAPPING_FILE="$HOME/.dayz_mod_mapping"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  DayZ Mod Auto-Updater${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if SteamCMD exists
if [ ! -f "$STEAMCMD_PATH" ]; then
    echo -e "${RED}Error: SteamCMD not found at $STEAMCMD_PATH${NC}"
    exit 1
fi

# Check if mod mapping file exists
if [ ! -f "$MOD_MAPPING_FILE" ]; then
    echo -e "${YELLOW}No mod mapping file found. Creating one now...${NC}"
    echo ""
    echo -e "${CYAN}This file will track which Workshop IDs correspond to which mod directories.${NC}"
    echo ""
    
    # Scan existing mods and try to find their Workshop IDs
    if [ -d "$SERVER_MODS_DIR" ]; then
        for mod_dir in "$SERVER_MODS_DIR"/@*; do
            if [ -d "$mod_dir" ]; then
                mod_name=$(basename "$mod_dir")
                echo -e "${YELLOW}Found mod: $mod_name${NC}"
                echo -e "Enter Workshop ID for $mod_name (or press Enter to skip):"
                read -p "> " workshop_id
                
                if [[ "$workshop_id" =~ ^[0-9]+$ ]]; then
                    echo "$workshop_id:$mod_name" >> "$MOD_MAPPING_FILE"
                    echo -e "${GREEN}✓ Mapped $mod_name to $workshop_id${NC}"
                fi
                echo ""
            fi
        done
    fi
    
    if [ ! -f "$MOD_MAPPING_FILE" ] || [ ! -s "$MOD_MAPPING_FILE" ]; then
        echo -e "${RED}No mods mapped. Run the download script first to install mods.${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}Reading mod mappings...${NC}"
echo ""

# Count mods
mod_count=$(wc -l < "$MOD_MAPPING_FILE")
echo -e "${CYAN}Found $mod_count mod(s) to update${NC}"
echo ""

# Read mappings and update each mod
current=0
while IFS=: read -r workshop_id mod_name; do
    current=$((current + 1))
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}[$current/$mod_count] Updating: $mod_name${NC}"
    echo -e "${GREEN}Workshop ID: $workshop_id${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # Download/update the mod
    echo -e "${BLUE}Downloading from Steam Workshop...${NC}"
    $STEAMCMD_PATH +login "$STEAM_USER" "$STEAM_PASS" \
        +workshop_download_item $DAYZ_APP_ID $workshop_id validate \
        +quit
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to update $mod_name${NC}"
        echo ""
        continue
    fi
    
    MOD_WORKSHOP_PATH="$WORKSHOP_DIR/$workshop_id"
    MOD_DEST_PATH="$SERVER_MODS_DIR/$mod_name"
    
    if [ ! -d "$MOD_WORKSHOP_PATH" ]; then
        echo -e "${RED}✗ Workshop files not found for $mod_name${NC}"
        echo ""
        continue
    fi
    
    # Backup current mod (optional safety measure)
    if [ -d "$MOD_DEST_PATH" ]; then
        echo -e "${BLUE}Removing old version...${NC}"
        rm -rf "$MOD_DEST_PATH"
    fi
    
    # Copy updated mod
    echo -e "${BLUE}Copying updated files...${NC}"
    cp -r "$MOD_WORKSHOP_PATH" "$MOD_DEST_PATH"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to copy files for $mod_name${NC}"
        echo ""
        continue
    fi
    
    echo -e "${GREEN}✓ Files copied${NC}"
    
    # Copy keys
    echo -e "${BLUE}Updating keys...${NC}"
    KEY_SOURCE="$MOD_DEST_PATH/keys"
    KEY_SOURCE_ALT="$MOD_DEST_PATH/Keys"
    
    if [ -d "$KEY_SOURCE" ]; then
        cp -v "$KEY_SOURCE"/*.bikey "$KEYS_DIR/" 2>/dev/null && echo -e "${GREEN}✓ Keys updated${NC}" || echo -e "${YELLOW}No .bikey files found${NC}"
    elif [ -d "$KEY_SOURCE_ALT" ]; then
        cp -v "$KEY_SOURCE_ALT"/*.bikey "$KEYS_DIR/" 2>/dev/null && echo -e "${GREEN}✓ Keys updated${NC}" || echo -e "${YELLOW}No .bikey files found${NC}"
    else
        echo -e "${YELLOW}No keys directory found${NC}"
    fi
    
    # Convert contents to lowercase
    echo -e "${BLUE}Converting contents to lowercase...${NC}"
    
    # Lowercase all files first
    find "$MOD_DEST_PATH" -depth -type f | while read -r file; do
        dir=$(dirname "$file")
        filename=$(basename "$file")
        lowercase_filename=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
        if [ "$filename" != "$lowercase_filename" ]; then
            mv "$file" "$dir/$lowercase_filename" 2>/dev/null
        fi
    done
    
    # Then lowercase all directories (except the root mod directory)
    find "$MOD_DEST_PATH" -mindepth 1 -depth -type d | while read -r dir; do
        parent_dir=$(dirname "$dir")
        dirname_only=$(basename "$dir")
        lowercase_dir=$(echo "$dirname_only" | tr '[:upper:]' '[:lower:]')
        if [ "$dirname_only" != "$lowercase_dir" ]; then
            mv "$dir" "$parent_dir/$lowercase_dir" 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}✓ Contents converted to lowercase${NC}"
    echo -e "${GREEN}✓ $mod_name updated successfully!${NC}"
    echo ""
    
done < "$MOD_MAPPING_FILE"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All Mods Updated!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}Updated $mod_count mod(s)${NC}"
echo ""
echo -e "${YELLOW}Don't forget to restart your server!${NC}"
echo ""
