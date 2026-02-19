#!/bin/bash

# ============================================================
#   Fedora Setup Script — ASUS ProArt P16
#   Par Alain | Epitech
# ============================================================

set -e  # Stop si une commande échoue

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_step() {
    echo -e "\n${CYAN}==>${NC} $1"
}

print_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

# ============================================================
# 1. Mise à jour système
# ============================================================
print_step "Mise à jour du système..."
sudo dnf upgrade --refresh -y
sudo dnf install -y dnf-plugins-core curl wget git
print_ok "Système à jour"

# ============================================================
# 2. RPM Fusion
# ============================================================
print_step "Activation de RPM Fusion..."
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
print_ok "RPM Fusion activé"

# Optimisation DNF
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
echo 'fastestmirror=True' | sudo tee -a /etc/dnf/dnf.conf

# ============================================================
# 3. Drivers NVIDIA
# ============================================================
print_step "Installation des drivers NVIDIA..."
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

# Fix Dynamic Power Management (important pour ASUS)
sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<EOF
options nvidia NVreg_DynamicPowerManagement=0x00
options nvidia NVreg_EnableGpuFirmware=0
options nvidia-drm modeset=1
EOF

sudo dracut --force
print_ok "Drivers NVIDIA installés (un reboot sera nécessaire)"

# ============================================================
# 4. Flatpak + Flathub
# ============================================================
print_step "Configuration de Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
print_ok "Flathub ajouté"

# ============================================================
# 5. Paquets DNF
# ============================================================
print_step "Installation des paquets principaux..."
sudo dnf install -y \
  tmux zsh \
  steam vlc firefox putty \
  openvpn networkmanager-openvpn \
  java-21-openjdk nodejs npm python3 python3-pip \
  flameshot unrar p7zip p7zip-plugins \
  solaar rclone \
  wireshark nmap netcat traceroute tcpdump mtr \
  bind-utils whois iperf3 wireguard-tools \
  git ansible okular \
  brightnessctl \
  gnome-tweaks bat \
  asusctl
print_ok "Paquets installés"

# ============================================================
# 6. Applications Flatpak
# ============================================================
print_step "Installation des applications Flatpak..."
flatpak install -y flathub \
  com.spotify.Client \
  com.discordapp.Discord \
  md.obsidian.Obsidian \
  com.jgraph.drawio \
  so.notion.Notion \
  org.balena.etcher \
  com.microsoft.Teams \
  com.visualstudio.code \
  io.github.jeffshee.Hidamari
print_ok "Applications Flatpak installées"

# ============================================================
# 7. Zsh + Oh My Zsh
# ============================================================
print_step "Installation de Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Plugins
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true

git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true

git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search 2>/dev/null || true

# Config zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search z sudo)/' ~/.zshrc

cat >> ~/.zshrc <<'EOF'

# Historique
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# Navigation historique
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[[C' autosuggest-accept

# Tmux auto-launch
if [ -z "$TMUX" ]; then
    tmux attach-session -t default 2>/dev/null || tmux new-session -s default
fi
EOF

# Zsh par défaut
sudo chsh -s $(which zsh) $USER
print_ok "Zsh configuré"

# ============================================================
# 8. Tmux config
# ============================================================
print_step "Configuration de tmux..."
cat > ~/.tmux.conf <<'EOF'
set -g mouse on
set -g status off
set -g pane-border-style fg=#89b4fa
set -g pane-active-border-style fg=#f38ba8,bold

bind -n C-v split-window -h
bind -n C-h split-window -v
bind -n C-w if-shell "[ $(tmux list-panes | wc -l) -gt 1 ]" "kill-pane" "display-message 'Impossible de fermer le dernier panneau!'"
EOF
print_ok "Tmux configuré"

# ============================================================
# 9. Rétroéclairage clavier
# ============================================================
print_step "Configuration du rétroéclairage clavier..."

# Règle udev
sudo tee /etc/udev/rules.d/99-kbd-backlight.rules > /dev/null <<EOF
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", ATTR{brightness}="3", RUN+="/bin/chmod a+w /sys/class/leds/asus::kbd_backlight/brightness"
EOF

sudo udevadm control --reload-rules
sudo udevadm trigger

# Script toggle F4
cat > ~/toggle-kbd-backlight.sh <<'EOF'
#!/bin/bash
MAX=$(cat /sys/class/leds/asus::kbd_backlight/max_brightness)
CURRENT=$(cat /sys/class/leds/asus::kbd_backlight/brightness)
if [ "$CURRENT" -eq 0 ]; then
    echo $MAX > /sys/class/leds/asus::kbd_backlight/brightness
else
    echo 0 > /sys/class/leds/asus::kbd_backlight/brightness
fi
EOF
chmod +x ~/toggle-kbd-backlight.sh
print_ok "Rétroéclairage configuré"

# ============================================================
# 10. Raccourcis GNOME
# ============================================================
print_step "Configuration des raccourcis GNOME..."

# Super+Entrée pour ouvrir un terminal
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"

dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'Terminal'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'gnome-terminal'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'<Super>Return'"

# Impr écran pour Flameshot
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/name "'Flameshot'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/command "'flameshot gui'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/binding "'Print'"
print_ok "Raccourcis configurés"

# ============================================================
# 11. Autostart
# ============================================================
print_step "Configuration de l'autostart..."
mkdir -p ~/.config/autostart

# Google Drive (rclone)
cat > ~/.config/autostart/rclone-gdrive.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Google Drive
Exec=bash -c "sleep 5 && rclone mount Google-Drive: $HOME/GoogleDrive --daemon --vfs-cache-mode writes"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Luminosité 100%
cat > ~/.config/autostart/brightness.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Brightness
Exec=bash -c "sleep 2 && brightnessctl set 100%"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

mkdir -p ~/GoogleDrive
print_ok "Autostart configuré"

# ============================================================
# 12. Curseur macOS
# ============================================================
print_step "Installation du curseur style macOS..."
sudo dnf copr enable peterwu/rendezvous -y
sudo dnf install -y capitaine-cursors
gsettings set org.gnome.desktop.interface cursor-theme 'capitaine-cursors'
print_ok "Curseur installé"

# ============================================================
# 13. Docker
# ============================================================
print_step "Installation de Docker..."
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
print_ok "Docker installé"

# ============================================================
# 14. Outils DevOps
# ============================================================
print_step "Installation des outils DevOps..."

# Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 755 kubectl /usr/local/bin/
rm kubectl

# Terraform
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf install -y terraform

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

print_ok "Outils DevOps installés"

# ============================================================
# 15. Wireshark sans root
# ============================================================
print_step "Configuration de Wireshark..."
sudo usermod -aG wireshark $USER
print_ok "Wireshark configuré"

# ============================================================
# FIN
# ============================================================
echo -e "\n${GREEN}============================================${NC}"
echo -e "${GREEN}  Installation terminée !${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Choses à faire manuellement après le reboot :"
echo -e "  1. Configurer Google Drive : ${CYAN}rclone config${NC}"
echo -e "  2. Ajouter le raccourci F4 pour le rétroéclairage dans Paramètres → Clavier"
echo -e "  3. Vérifier les drivers NVIDIA : ${CYAN}nvidia-smi${NC}"
echo ""
echo -e "${CYAN}Lance un reboot pour finaliser !${NC}"

echo -e "\nTu veux supprimer le dossier d'installation ? (o/n)"
read response
if [ "$response" = "o" ]; then
    cd .. && rm -rf fedora-setup
    echo "Dossier supprimé !"
fi