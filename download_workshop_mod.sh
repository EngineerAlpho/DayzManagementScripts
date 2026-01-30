#!/bin/bash

# DayZ Workshop Mod Downloader with Automation
# This script downloads DayZ workshop mods using SteamCMD and automatically sets them up

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
NC='\033[0m' # No Color

# DayZ App ID
DAYZ_APP_ID=221100

# Default paths (adjust if needed)
STEAMCMD_PATH="$HOME/.steam/steamcmd/steamcmd.sh"
WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/$DAYZ_APP_ID"
SERVER_MODS_DIR="$HOME/serverfiles/mods"
LGSM_CONFIG="$HOME/lgsm/config-lgsm/dayzserver/dayzserver.cfg"
KEYS_DIR="$HOME/serverfiles/keys"
MOD_MAPPING_FILE="$HOME/.dayz_mod_mapping"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  DayZ Workshop Mod Downloader${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if SteamCMD exists
if [ ! -f "$STEAMCMD_PATH" ]; then
    echo -e "${RED}Error: SteamCMD not found at $STEAMCMD_PATH${NC}"
    echo "Please ensure LinuxGSM is installed and SteamCMD is set up."
    exit 1
fi

# Create mods directory if it doesn't exist
mkdir -p "$SERVER_MODS_DIR"

# Show current mods and offer cleanup
if [ -f "$LGSM_CONFIG" ] && grep -q "^mods=" "$LGSM_CONFIG"; then
    CURRENT_MODS=$(grep "^mods=" "$LGSM_CONFIG" | cut -d'"' -f2)
    
    if [ -n "$CURRENT_MODS" ]; then
        echo -e "${BLUE}Current mods in config:${NC}"
        IFS=';' read -ra MOD_ARRAY <<< "$CURRENT_MODS"
        for i in "${!MOD_ARRAY[@]}"; do
            echo -e "  $((i+1)). ${YELLOW}${MOD_ARRAY[$i]}${NC}"
        done
        echo ""
        
        while true; do
            echo -e "${YELLOW}Would you like to manage your mods list? (y/n):${NC}"
            read -p "> " manage_choice
            case "$manage_choice" in
                [Yy]* )
                    echo ""
                    echo -e "${YELLOW}Options:${NC}"
                    echo "  1. Remove a specific mod"
                    echo "  2. Clear all mods"
                    echo "  3. Continue without changes"
                    echo ""
                    read -p "Choose option (1-3): " cleanup_choice
                    
                    case $cleanup_choice in
                        1)
                            echo ""
                            read -p "Enter the number of the mod to remove: " mod_num
                            
                            if ! [[ "$mod_num" =~ ^[0-9]+$ ]] || [ "$mod_num" -lt 1 ] || [ "$mod_num" -gt "${#MOD_ARRAY[@]}" ]; then
                                echo -e "${RED}Invalid selection${NC}"
                                break
                            fi
                            
                            # Remove the selected mod
                            MOD_TO_REMOVE="${MOD_ARRAY[$((mod_num-1))]}"
                            NEW_MODS=""
                            
                            for mod in "${MOD_ARRAY[@]}"; do
                                if [ "$mod" != "$MOD_TO_REMOVE" ]; then
                                    if [ -z "$NEW_MODS" ]; then
                                        NEW_MODS="$mod"
                                    else
                                        NEW_MODS="$NEW_MODS;$mod"
                                    fi
                                fi
                            done
                            
                            sed -i "s|^mods=.*|mods=\"$NEW_MODS\"|" "$LGSM_CONFIG"
                            echo ""
                            echo -e "${GREEN}✓ Removed $MOD_TO_REMOVE${NC}"
                            
                            # Update the array for display
                            CURRENT_MODS="$NEW_MODS"
                            IFS=';' read -ra MOD_ARRAY <<< "$CURRENT_MODS"
                            
                            # Ask if they want to remove more
                            if [ ${#MOD_ARRAY[@]} -gt 0 ]; then
                                echo ""
                                echo -e "${BLUE}Updated mods list:${NC}"
                                for i in "${!MOD_ARRAY[@]}"; do
                                    echo -e "  $((i+1)). ${YELLOW}${MOD_ARRAY[$i]}${NC}"
                                done
                                continue
                            else
                                echo -e "${YELLOW}All mods removed${NC}"
                                break
                            fi
                            ;;
                        2)
                            echo ""
                            read -p "Are you sure you want to remove ALL mods? (y/n): " confirm
                            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                                sed -i "s|^mods=.*|mods=\"\"|" "$LGSM_CONFIG"
                                echo ""
                                echo -e "${GREEN}✓ Cleared all mods from config${NC}"
                            else
                                echo -e "${YELLOW}Cancelled${NC}"
                            fi
                            break
                            ;;
                        3)
                            echo ""
                            break
                            ;;
                        *)
                            echo -e "${RED}Invalid option${NC}"
                            break
                            ;;
                    esac
                    ;;
                [Nn]* )
                    echo ""
                    break
                    ;;
                * )
                    echo -e "${RED}Please answer y or n.${NC}"
                    ;;
            esac
        done
    fi
fi

# Prompt for Workshop ID
echo -e "${YELLOW}Enter the Workshop ID:${NC}"
read -p "> " WORKSHOP_ID

# Validate input
if ! [[ "$WORKSHOP_ID" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid Workshop ID. Must be numeric.${NC}"
    exit 1
fi

# Prompt for mod folder name (for better organization)
echo ""
echo -e "${YELLOW}Enter a name for this mod (e.g., @Banov, @CF, @DayZ-Expansion-Core):${NC}"
read -p "> " MOD_NAME

# Ensure mod name starts with @
if [[ ! "$MOD_NAME" =~ ^@ ]]; then
    MOD_NAME="@$MOD_NAME"
fi

echo ""
echo -e "${GREEN}Downloading Workshop ID: $WORKSHOP_ID${NC}"
echo -e "${YELLOW}This may take a while depending on the mod size...${NC}"
echo -e "${YELLOW}Logging in as: $STEAM_USER${NC}"
echo ""

# Run SteamCMD to download the workshop item
$STEAMCMD_PATH +login "$STEAM_USER" "$STEAM_PASS" \
    +workshop_download_item $DAYZ_APP_ID $WORKSHOP_ID \
    +quit

# Check if download was successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Download complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    MOD_WORKSHOP_PATH="$WORKSHOP_DIR/$WORKSHOP_ID"
    MOD_DEST_PATH="$SERVER_MODS_DIR/$MOD_NAME"
    
    # Copy mod directory
    echo -e "${BLUE}Copying mod files...${NC}"
    if [ -d "$MOD_DEST_PATH" ]; then
        echo -e "${YELLOW}Warning: $MOD_NAME already exists. Removing old directory...${NC}"
        rm -rf "$MOD_DEST_PATH"
    fi
    
    cp -r "$MOD_WORKSHOP_PATH" "$MOD_DEST_PATH"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Mod copied to: $MOD_DEST_PATH${NC}"
    else
        echo -e "${RED}✗ Failed to copy mod files${NC}"
        exit 1
    fi
    
    # Copy keys to server keys directory
    echo ""
    echo -e "${BLUE}Copying mod keys...${NC}"
    KEY_SOURCE="$MOD_DEST_PATH/keys"
    KEY_SOURCE_ALT="$MOD_DEST_PATH/Keys"
    
    if [ -d "$KEY_SOURCE" ]; then
        cp -v "$KEY_SOURCE"/*.bikey "$KEYS_DIR/" 2>/dev/null && echo -e "${GREEN}✓ Keys copied${NC}" || echo -e "${YELLOW}No .bikey files found${NC}"
    elif [ -d "$KEY_SOURCE_ALT" ]; then
        cp -v "$KEY_SOURCE_ALT"/*.bikey "$KEYS_DIR/" 2>/dev/null && echo -e "${GREEN}✓ Keys copied${NC}" || echo -e "${YELLOW}No .bikey files found${NC}"
    else
        echo -e "${YELLOW}No keys directory found (some mods don't require keys)${NC}"
    fi
    
    # Convert folder names and files to lowercase (DayZ Linux requirement)
    echo ""
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
    
    # Save mod mapping for future updates
    echo -e "${BLUE}Saving mod mapping for updates...${NC}"
    
    # Remove old entry if exists
    if [ -f "$MOD_MAPPING_FILE" ]; then
        sed -i "/^$WORKSHOP_ID:/d" "$MOD_MAPPING_FILE"
    fi
    
    # Add new entry
    echo "$WORKSHOP_ID:$MOD_NAME" >> "$MOD_MAPPING_FILE"
    echo -e "${GREEN}✓ Mod mapping saved${NC}"
    
    # Update LinuxGSM config
    echo ""
    echo -e "${BLUE}Updating server configuration...${NC}"
    
    if [ -f "$LGSM_CONFIG" ]; then
        # Check if mods parameter exists
        if grep -q "^mods=" "$LGSM_CONFIG"; then
            # Get current mods and convert from LinuxGSM format to simple format for comparison
            CURRENT_MODS=$(grep "^mods=" "$LGSM_CONFIG" | sed 's/^mods=//' | sed 's/mods\///g' | sed 's/\\;//g' | tr -d '"')
            
            # Convert to array and check for exact match
            IFS=';' read -ra MOD_ARRAY <<< "$CURRENT_MODS"
            MOD_EXISTS=false
            
            for mod in "${MOD_ARRAY[@]}"; do
                if [ "$mod" = "$MOD_NAME" ]; then
                    MOD_EXISTS=true
                    break
                fi
            done
            
            if [ "$MOD_EXISTS" = true ]; then
                echo -e "${YELLOW}$MOD_NAME already in configuration${NC}"
            else
                # Add mod to list in LinuxGSM format
                if [ -z "$CURRENT_MODS" ]; then
                    NEW_MODS="mods/$MOD_NAME"
                else
                    # Reconstruct with proper format
                    NEW_MODS=""
                    for mod in "${MOD_ARRAY[@]}"; do
                        if [ -n "$mod" ]; then
                            if [ -z "$NEW_MODS" ]; then
                                NEW_MODS="mods/$mod"
                            else
                                NEW_MODS="$NEW_MODS\\\\;mods/$mod"
                            fi
                        fi
                    done
                    NEW_MODS="$NEW_MODS\\\\;mods/$MOD_NAME"
                fi
                
                sed -i "s|^mods=.*|mods=$NEW_MODS|" "$LGSM_CONFIG"
                echo -e "${GREEN}✓ Added $MOD_NAME to server mods${NC}"
            fi
        else
            # Add mods parameter in LinuxGSM format
            echo "mods=mods/$MOD_NAME" >> "$LGSM_CONFIG"
            echo -e "${GREEN}✓ Added mods parameter with $MOD_NAME${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: LinuxGSM config not found at $LGSM_CONFIG${NC}"
        echo -e "${YELLOW}You'll need to manually add the mod to your startup parameters${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Setup Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Mod Details:${NC}"
    echo -e "  Workshop ID: ${YELLOW}$WORKSHOP_ID${NC}"
    echo -e "  Mod Name: ${YELLOW}$MOD_NAME${NC}"
    echo -e "  Location: ${YELLOW}$MOD_DEST_PATH${NC}"
    echo ""
    echo -e "${YELLOW}Current mods in config:${NC}"
    if [ -f "$LGSM_CONFIG" ]; then
        grep "^mods=" "$LGSM_CONFIG" | sed 's/^mods=//' | sed 's/\\;/\n/g' | sed 's/mods\//  @/g'
    fi
    echo ""
    
    # Prompt to install another mod or exit
    while true; do
        echo -e "${YELLOW}Would you like to install another mod? (y/n):${NC}"
        read -p "> " choice
        case "$choice" in
            [Yy]* )
                echo ""
                echo -e "${GREEN}========================================${NC}"
                exec "$0"
                ;;
            [Nn]* )
                echo ""
                echo -e "${GREEN}All done! Don't forget to restart your server.${NC}"
                exit 0
                ;;
            * )
                echo -e "${RED}Please answer y or n.${NC}"
                ;;
        esac
    done
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Download failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo ""
    echo "Please check:"
    echo "- Workshop ID is correct"
    echo "- Internet connection is stable"
    echo "- SteamCMD has proper permissions"
    exit 1
fi
