#!/bin/bash

# Define colors
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m" # For "No Change"
NC="\033[0m" # No color

# Log directory and file setup
LOGDIR="$HOME/linux-scripts/script_logs"
LOGFILE="$LOGDIR/$(date +%Y%m%d_%H%M%S)_update.log"
TIMESHIFT_CMD="timeshift"
APT_CMD="apt-get"
SNAP_CMD="snap"
FLATPAK_CMD="flatpak"
FWUPD_CMD="fwupdmgr"

# Ensure log directory exists
mkdir -p "$LOGDIR"

# Trap signals to ensure cleanup
trap 'echo -e "$(date) - ${RED}Script interrupted.${NC}" | tee -a "$LOGFILE"; exit 1' INT TERM

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}" | tee -a "$LOGFILE"
  exit 1
fi

# Check if nala is installed; if so, use it instead of apt-get
if command -v nala &> /dev/null; then
  APT_CMD="nala"
  echo -e "$(date) - ${YELLOW}Using nala for package updates.${NC}" | tee -a "$LOGFILE"
else
  echo -e "$(date) - ${YELLOW}Nala not found, falling back to apt-get.${NC}" | tee -a "$LOGFILE"
fi

# Ensure essential commands are available
for cmd in "$APT_CMD" "$TIMESHIFT_CMD" "$SNAP_CMD" "$FLATPAK_CMD" "$FWUPD_CMD"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "$(date) - ${RED}Command $cmd is not available. Installing...${NC}" | tee -a "$LOGFILE"
    sudo apt-get install "$cmd" -y || { echo -e "${RED}Failed to install $cmd${NC}"; exit 1; }
  fi
done

# Perform a Timeshift backup
echo -e "$(date) - ${YELLOW}Creating a Timeshift backup...${NC}" | tee -a "$LOGFILE"
sudo "$TIMESHIFT_CMD" --create --comments "Backup before system update" | tee -a "$LOGFILE"

# Check for internet connectivity
if ! ping -c 1 google.com &> /dev/null; then
  echo -e "${RED}No internet connection. Please check your network settings.${NC}" | tee -a "$LOGFILE"
  exit 1
fi

# Check for disk space (ensure at least 2GB free space)
FREE_SPACE=$(df / | tail -1 | awk '{print $4}')
if [ "$FREE_SPACE" -lt 2097152 ]; then
  echo -e "${RED}Not enough disk space. At least 2GB free space is required.${NC}" | tee -a "$LOGFILE"
  exit 1
fi

# Update and upgrade APT (or Nala) packages
echo -e "$(date) - ${YELLOW}Updating package list with $APT_CMD...${NC}" | tee -a "$LOGFILE"
if sudo "$APT_CMD" update | tee -a "$LOGFILE" | grep -q "All packages are up to date"; then
  echo -e "${BLUE}No Change: Package list is already up to date.${NC}" | tee -a "$LOGFILE"
else
  echo -e "${GREEN}Package list updated successfully.${NC}" | tee -a "$LOGFILE"
fi

echo -e "$(date) - ${YELLOW}Upgrading packages with $APT_CMD...${NC}" | tee -a "$LOGFILE"
if sudo "$APT_CMD" upgrade -y | tee -a "$LOGFILE" | grep -q "0 upgraded, 0 newly installed"; then
  echo -e "${BLUE}No Change: No packages needed upgrading.${NC}" | tee -a "$LOGFILE"
else
  echo -e "${GREEN}Packages upgraded successfully.${NC}" | tee -a "$LOGFILE"
fi

# Perform full upgrade (includes package removals and new dependencies)
echo -e "$(date) - ${YELLOW}Performing full upgrade...${NC}" | tee -a "$LOGFILE"
sudo "$APT_CMD" full-upgrade -y | tee -a "$LOGFILE"

# Remove unnecessary packages
echo -e "$(date) - ${YELLOW}Removing unnecessary packages...${NC}" | tee -a "$LOGFILE"
sudo "$APT_CMD" autoremove -y | tee -a "$LOGFILE"

# Clean up .deb files of packages that are no longer installed
if [ "$APT_CMD" = "apt-get" ]; then
  echo -e "$(date) - ${YELLOW}Cleaning up .deb files of packages that are no longer installed...${NC}" | tee -a "$LOGFILE"
  sudo "$APT_CMD" autoclean -y | tee -a "$LOGFILE"
fi

# Refresh Snap packages
echo -e "$(date) - ${YELLOW}Refreshing Snap packages...${NC}" | tee -a "$LOGFILE"
if sudo "$SNAP_CMD" refresh | tee -a "$LOGFILE" | grep -q "All snaps up to date"; then
  echo -e "${BLUE}No Change: All Snap packages are up to date.${NC}" | tee -a "$LOGFILE"
else
  echo -e "${GREEN}Snap packages updated successfully.${NC}" | tee -a "$LOGFILE"
fi

# Check and update Flatpak packages if available
if command -v "$FLATPAK_CMD" &> /dev/null; then
  echo -e "$(date) - ${YELLOW}Updating Flatpak packages...${NC}" | tee -a "$LOGFILE"
  if "$FLATPAK_CMD" update -y | tee -a "$LOGFILE" | grep -q "Nothing to do"; then
    echo -e "${BLUE}No Change: All Flatpak packages are up to date.${NC}" | tee -a "$LOGFILE"
  else
    echo -e "${GREEN}Flatpak packages updated successfully.${NC}" | tee -a "$LOGFILE"
  fi
else
  echo -e "$(date) - ${YELLOW}Flatpak is not installed, skipping Flatpak updates.${NC}" | tee -a "$LOGFILE"
fi

# Update system firmware
echo -e "$(date) - ${YELLOW}Updating system firmware...${NC}" | tee -a "$LOGFILE"
sudo "$FWUPD_CMD" refresh | tee -a "$LOGFILE"
if sudo "$FWUPD_CMD" get-updates | tee -a "$LOGFILE" | grep -q "No detected"; then
  echo -e "${BLUE}No Change: No firmware updates available.${NC}" | tee -a "$LOGFILE"
else
  sudo "$FWUPD_CMD" update | tee -a "$LOGFILE"
  echo -e "${GREEN}Firmware updated successfully.${NC}" | tee -a "$LOGFILE"
fi

echo -e "$(date) - ${GREEN}System update completed successfully.${NC}" | tee -a "$LOGFILE"
