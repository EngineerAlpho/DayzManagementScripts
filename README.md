# DayZ Linux Server Mod Management Scripts

A collection of bash scripts to automate DayZ server mod management on Linux servers using SteamCMD and LinuxGSM.

**Created with assistance from Claude (Anthropic)**

## Features

- 🔽 **Automated Workshop Downloads** - Download mods directly from Steam Workshop
- 🔄 **Automatic Updates** - Update all installed mods with a single command
- 📝 **Mod List Management** - Clean up duplicate entries and manage your mod list
- 🔀 **Load Order Manager** - Interactive tool to reorder mods for proper loading
- 🔤 **Linux Compatibility** - Automatically handles case-sensitivity requirements
- 🔑 **Key Management** - Automatically copies mod keys to server directory

## Requirements

- Linux server (tested on Ubuntu 24)
- [LinuxGSM](https://linuxgsm.com/) DayZ server installation
- [SteamCMD](https://developer.valvesoftware.com/wiki/SteamCMD) installed
- Steam account (doesn't need to own DayZ)
- Bash shell

## Installation

1. Clone or download the scripts to your server
2. Make scripts executable:
   ```bash
   chmod +x download_workshop_mod.sh
   chmod +x update_all_mods.sh
   chmod +x reorder_mods.sh
   ```

3. Configure your Steam credentials in both `download_workshop_mod.sh` and `update_all_mods.sh`:
   ```bash
   STEAM_USER="your_steam_username"
   STEAM_PASS="your_steam_password"
   ```

4. (Optional) Adjust paths if your setup differs from defaults:
   - `STEAMCMD_PATH` - Path to steamcmd.sh
   - `SERVER_MODS_DIR` - Server mods directory
   - `LGSM_CONFIG` - LinuxGSM config file location
   - `KEYS_DIR` - Server keys directory

## Scripts Overview

### 1. download_workshop_mod.sh

Downloads and installs Workshop mods with full automation.

**Features:**
- Prompts for Workshop ID and mod name
- Downloads from Steam Workshop
- Copies mod to server directory
- Handles key installation
- Converts files/folders to lowercase (Linux requirement)
- Preserves mod directory name case
- Updates LinuxGSM config automatically
- Built-in mod list cleanup
- Option to install multiple mods in one session

**Usage:**
```bash
./download_workshop_mod.sh
```

**Common Workshop IDs:**
- Banov: `2415195639`
- DayZ Expansion Core: `2116151222`
- DayZ Expansion Licensed: `2291785437`
- CF (Community Framework): `1559212036`
- DabsFramework: `1559212036`

### 2. update_all_mods.sh

Automatically updates all installed mods.

**Features:**
- Reads mod mappings from previous installations
- Downloads latest versions from Workshop
- Preserves mod directory names
- Handles lowercase conversion
- Updates keys automatically
- Shows progress for each mod

**Usage:**
```bash
./update_all_mods.sh
```

**First Run:**
If no mapping file exists, the script will scan existing mods and prompt you to enter Workshop IDs.

**Automation:**
Add to cron for automatic updates:
```bash
# Update mods daily at 4 AM
0 4 * * * /home/yourusername/scripts/update_all_mods.sh
```

### 3. reorder_mods.sh

Interactive tool for managing mod load order.

**Features:**
- Display current load order
- Move mods up/down
- Jump mods to specific positions
- Shows load order best practices
- Preview before saving

**Usage:**
```bash
./reorder_mods.sh
```

**Load Order Best Practices:**
1. Map mods (like @Banov) should load FIRST
2. Framework mods (@CF, @DabsFramework) load early
3. @DayZ-Expansion-Core before other Expansion mods
4. Dependency mods before mods that require them

**Example Good Load Order:**
```
@Banov
@CF
@DabsFramework
@DayZ-Expansion-Core
@DayZ-Expansion-Licensed
@VehicleMod
@WeaponMod
@Trader
@VPPAdminTools
```

## File Structure

After installation, your setup will look like:
```
/home/yourusername/
├── serverfiles/
│   ├── mods/
│   │   ├── @Banov/
│   │   ├── @DabsFramework/
│   │   └── ...
│   └── keys/
├── lgsm/
│   └── config-lgsm/
│       └── dayzserver/
│           └── dayzserver.cfg
├── .dayz_mod_mapping (auto-generated)
└── scripts/
    ├── download_workshop_mod.sh
    ├── update_all_mods.sh
    └── reorder_mods.sh
```

## Troubleshooting

### Workshop Downloads Fail
**Problem:** ERROR! Download item XXXXXX failed (Failure)

**Solution:** 
- Ensure Steam credentials are correct
- Many DayZ mods require authenticated login (not anonymous)
- Check if Workshop ID is valid
- If you have Steam Guard, enter 2FA code when prompted

### Mods Show as Red/Broken in Terminal
**Problem:** Mod directories appear red in ls output

**Solution:**
- This was an issue with symbolic links in early versions
- Current scripts use directory copying instead
- If you have old symlinks, delete them and re-download with current script

### Case Sensitivity Issues
**Problem:** Server fails to load mods on Linux

**Solution:**
- Scripts automatically lowercase all files and subdirectories
- Keep mod directory names readable (e.g., `@DabsFramework`)
- Linux requires lowercase file/folder names inside mods

### Mod Not Loading
**Problem:** Mod installed but server doesn't load it

**Solution:**
1. Check load order with `reorder_mods.sh`
2. Verify mod is in LinuxGSM config: `grep "^mods=" ~/lgsm/config-lgsm/dayzserver/dayzserver.cfg`
3. Check keys are copied: `ls ~/serverfiles/keys/`
4. Restart server: `./dayzserver restart`

## Configuration Files

### Mod Mapping File
Location: `~/.dayz_mod_mapping`

Format:
```
workshop_id:@ModDirectoryName
2415195639:@Banov
2116151222:@DayZ-Expansion-Core
```

This file tracks which Workshop IDs correspond to which mod directories for automated updates.

### LinuxGSM Config
Location: `~/lgsm/config-lgsm/dayzserver/dayzserver.cfg`

Mods parameter:
```bash
mods="@Banov;@CF;@DabsFramework;@DayZ-Expansion-Core"
```

## Security Notes

- **Never commit your Steam credentials** to public repositories
- Use a dedicated Steam account for server management
- Set script permissions to prevent unauthorized access:
  ```bash
  chmod 700 download_workshop_mod.sh update_all_mods.sh
  ```
- Consider using Steam Guard for additional security

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Share improvements

## Support

For issues or questions:
- Check the Troubleshooting section
- Review DayZ server logs: `./dayzserver details`
- Check LinuxGSM documentation: https://linuxgsm.com/
- Visit DayZ modding communities

## License

GNU General Public License v3.0 (GPL-3.0)

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

**What this means:**
- ✅ Free to use, modify, and distribute
- ✅ Any modifications must also be open source under GPL
- ✅ Improvements benefit the entire community
- ✅ Source code must be made available to users

## Credits

Created with assistance from Claude (Anthropic)

Scripts developed for the DayZ Linux server administration community.

## Changelog

### Version 1.0
- Initial release
- Workshop mod downloader
- Automatic mod updater
- Load order manager
- Mod list cleanup
- Linux case-sensitivity handling
- Automatic key management

---

**Happy Server Admining! 🎮**
