#!/bin/bash

# ============================================================
#   Fedora Setup Script — ASUS ProArt P16
#   Par Alain | Epitech
# ============================================================

set -e

# Couleurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Progression
TOTAL_STEPS=15
CURRENT_STEP=0

progress_bar() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    FILLED=$((PERCENT / 5))
    EMPTY=$((20 - FILLED))
    BAR=""
    for i in $(seq 1 $FILLED); do BAR="${BAR}█"; done
    for i in $(seq 1 $EMPTY); do BAR="${BAR}░"; done
    echo -e "\n${CYAN}[${BAR}] ${PERCENT}% — Étape ${CURRENT_STEP}/${TOTAL_STEPS}${NC}"
    echo -e "${BOLD}==> $1${NC}"
}

print_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERREUR]${NC} $1"; }

# ============================================================
# VÉRIFICATION FEDORA
# ============================================================
if [ ! -f /etc/fedora-release ]; then
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Ce script est prévu pour Fedora       ║${NC}"
    echo -e "${RED}║  Système détecté : $(uname -s)         ║${NC}"
    echo -e "${RED}║  Installation annulée.                 ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    exit 1
fi

FEDORA_VERSION=$(rpm -E %fedora)
echo -e "${GREEN}Fedora ${FEDORA_VERSION} détecté — OK${NC}"

# ============================================================
# DEMANDE DU NOM D'UTILISATEUR
# ============================================================
echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║     Fedora Setup — ASUS ProArt P16    ║${NC}"
echo -e "${BOLD}║          Par Alain | Epitech           ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Quel est ton nom d'utilisateur Linux ?${NC}"
echo -e "(Appuie sur Entrée pour utiliser : ${CYAN}$USER${NC})"
read -p "> " INPUT_USER
USERNAME=${INPUT_USER:-$USER}
HOME_DIR="/home/$USERNAME"

echo ""
echo -e "Utilisateur   : ${CYAN}$USERNAME${NC}"
echo -e "Dossier home  : ${CYAN}$HOME_DIR${NC}"
echo ""
echo -e "${YELLOW}On commence ? (o/n)${NC}"
read -p "> " CONFIRM
if [ "$CONFIRM" != "o" ]; then
    echo "Installation annulée."
    exit 0
fi

# ============================================================
# 1. Mise à jour système
# ============================================================
progress_bar "Mise à jour du système..."
sudo dnf upgrade --refresh -y
sudo dnf install -y dnf-plugins-core curl wget git
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
echo 'fastestmirror=True' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
print_ok "Système à jour"

# ============================================================
# 2. RPM Fusion
# ============================================================
progress_bar "Activation de RPM Fusion..."
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
print_ok "RPM Fusion activé"

# ============================================================
# 3. Drivers NVIDIA
# ============================================================
progress_bar "Installation des drivers NVIDIA..."
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
sudo tee /etc/modprobe.d/nvidia.conf > /dev/null <<EOF
options nvidia NVreg_DynamicPowerManagement=0x00
options nvidia NVreg_EnableGpuFirmware=0
options nvidia-drm modeset=1
EOF
sudo dracut --force
print_ok "Drivers NVIDIA installés"

# ============================================================
# 4. Flatpak + Flathub
# ============================================================
progress_bar "Configuration de Flatpak..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
print_ok "Flathub ajouté"

# ============================================================
# 5. Paquets DNF
# ============================================================
progress_bar "Installation des paquets principaux..."
sudo dnf install -y \
  tmux zsh steam vlc firefox putty \
  openvpn networkmanager-openvpn \
  java-21-openjdk nodejs npm python3 python3-pip \
  flameshot unrar p7zip p7zip-plugins solaar rclone \
  wireshark nmap netcat traceroute tcpdump mtr \
  bind-utils whois iperf3 wireguard-tools \
  git ansible okular brightnessctl gnome-tweaks bat asusctl
print_ok "Paquets installés"

# ============================================================
# 6. Applications Flatpak
# ============================================================
progress_bar "Installation des applications Flatpak..."
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
progress_bar "Installation de Zsh + Oh My Zsh..."
if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-$HOME_DIR/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 2>/dev/null || true
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
  ${ZSH_CUSTOM:-$HOME_DIR/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 2>/dev/null || true
git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search \
  ${ZSH_CUSTOM:-$HOME_DIR/.oh-my-zsh/custom}/plugins/zsh-history-substring-search 2>/dev/null || true

sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search z sudo)/' $HOME_DIR/.zshrc

cat >> $HOME_DIR/.zshrc <<'EOF'

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

sudo chsh -s $(which zsh) $USERNAME
print_ok "Zsh configuré"

# ============================================================
# 8. Tmux config
# ============================================================
progress_bar "Configuration de tmux..."
cat > $HOME_DIR/.tmux.conf <<'EOF'
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
progress_bar "Configuration du rétroéclairage clavier..."
sudo tee /etc/udev/rules.d/99-kbd-backlight.rules > /dev/null <<EOF
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="asus::kbd_backlight", ATTR{brightness}="3", RUN+="/bin/chmod a+w /sys/class/leds/asus::kbd_backlight/brightness"
EOF
sudo udevadm control --reload-rules
sudo udevadm trigger

cat > $HOME_DIR/toggle-kbd-backlight.sh <<'EOF'
#!/bin/bash
MAX=$(cat /sys/class/leds/asus::kbd_backlight/max_brightness)
CURRENT=$(cat /sys/class/leds/asus::kbd_backlight/brightness)
if [ "$CURRENT" -eq 0 ]; then
    echo $MAX > /sys/class/leds/asus::kbd_backlight/brightness
else
    echo 0 > /sys/class/leds/asus::kbd_backlight/brightness
fi
EOF
chmod +x $HOME_DIR/toggle-kbd-backlight.sh
print_ok "Rétroéclairage configuré"

# ============================================================
# 10. Raccourcis GNOME
# ============================================================
progress_bar "Configuration des raccourcis GNOME..."
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/','/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/name "'Terminal'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/command "'gnome-terminal'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/binding "'<Super>Return'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/name "'Flameshot'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/command "'flameshot gui'"
dconf write /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/binding "'Print'"
print_ok "Raccourcis configurés"

# ============================================================
# 11. Autostart
# ============================================================
progress_bar "Configuration de l'autostart..."
mkdir -p $HOME_DIR/.config/autostart

cat > $HOME_DIR/.config/autostart/rclone-gdrive.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Google Drive
Exec=bash -c "sleep 5 && rclone mount Google-Drive: $HOME_DIR/GoogleDrive --daemon --vfs-cache-mode writes"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

cat > $HOME_DIR/.config/autostart/brightness.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Brightness
Exec=bash -c "sleep 2 && brightnessctl set 100%"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

mkdir -p $HOME_DIR/GoogleDrive
print_ok "Autostart configuré"

# ============================================================
# 12. Curseur macOS
# ============================================================
progress_bar "Installation du curseur style macOS..."
sudo dnf copr enable peterwu/rendezvous -y
sudo dnf install -y capitaine-cursors
gsettings set org.gnome.desktop.interface cursor-theme 'capitaine-cursors'
print_ok "Curseur installé"

# ============================================================
# 13. Docker
# ============================================================
progress_bar "Installation de Docker..."
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USERNAME
print_ok "Docker installé"

# ============================================================
# 14. Outils DevOps
# ============================================================
progress_bar "Installation des outils DevOps..."
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 755 kubectl /usr/local/bin/
rm kubectl
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
sudo dnf install -y terraform
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
print_ok "Outils DevOps installés"

# ============================================================
# 15. Wireshark sans root
# ============================================================
progress_bar "Configuration de Wireshark..."
sudo usermod -aG wireshark $USERNAME
print_ok "Wireshark configuré"

# ============================================================
# BONUS. Reconnaissance faciale — Howdy
# ============================================================
echo ""
echo -e "${YELLOW}Installer la reconnaissance faciale (Howdy) ? (o/n)${NC}"
read -p "> " INSTALL_HOWDY
if [ "$INSTALL_HOWDY" = "o" ]; then
    echo -e "\n${BOLD}==> Installation de Howdy (Face ID)...${NC}"

    # Dépendances
    sudo dnf install -y cmake gcc gcc-c++ python3-devel meson ninja-build \
      python3-opencv python3-numpy inih-devel libevdev-devel pam-devel
    pip3 install dlib --break-system-packages

    # Cloner et compiler
    git clone https://github.com/boltgolt/howdy $HOME_DIR/howdy
    cd $HOME_DIR/howdy
    sudo meson setup build
    sudo ninja -C build install

    # Modèles dlib
    sudo mkdir -p /usr/local/share/dlib-data
    cd /usr/local/share/dlib-data
    sudo curl -LO http://dlib.net/files/shape_predictor_5_face_landmarks.dat.bz2
    sudo bzip2 -d shape_predictor_5_face_landmarks.dat.bz2
    sudo curl -LO http://dlib.net/files/mmod_human_face_detector.dat.bz2
    sudo bzip2 -d mmod_human_face_detector.dat.bz2
    sudo curl -LO http://dlib.net/files/dlib_face_recognition_resnet_model_v1.dat.bz2
    sudo bzip2 -d dlib_face_recognition_resnet_model_v1.dat.bz2

    # Lien symbolique PAM
    sudo ln -s /usr/local/lib64/security/pam_howdy.so /lib64/security/pam_howdy.so

    # SELinux
    sudo semanage permissive -a xdm_t

    # PAM gdm-password
    sudo sed -i '1s/^/auth        sufficient    pam_howdy.so\n/' /etc/pam.d/gdm-password

    # Nettoyage
    rm -rf $HOME_DIR/howdy

    print_ok "Howdy installé — Lance 'sudo howdy add' pour enregistrer ton visage !"
fi

# ============================================================
# FIN
# ============================================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation terminée à 100% !    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}À faire manuellement après le reboot :${NC}"
echo -e "  ${CYAN}1.${NC} Configurer Google Drive     →  rclone config"
echo -e "  ${CYAN}2.${NC} Raccourci F4 rétroéclairage →  Paramètres → Clavier → Raccourcis personnalisés"
echo -e "  ${CYAN}3.${NC} Vérifier les drivers NVIDIA →  nvidia-smi"
echo ""
echo -e "${YELLOW}Supprimer le dossier d'installation ? (o/n)${NC}"
read -p "> " CLEANUP
if [ "$CLEANUP" = "o" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cd $HOME_DIR
    rm -rf "$SCRIPT_DIR"
    echo -e "${GREEN}[OK]${NC} Dossier supprimé !"
fi
echo ""
echo -e "${CYAN}Lance un reboot pour finaliser :${NC} sudo reboot"
echo ""