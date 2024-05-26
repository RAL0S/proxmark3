#!/usr/bin/env bash

set -e

show_usage() {
  echo "Usage: $(basename $0) takes exactly 1 argument (install | uninstall)"
}

if [ $# -ne 1 ]; then
  show_usage
  exit 1
fi

check_env() {
  if [[ -z "${RALPM_TMP_DIR}" ]]; then
    echo "RALPM_TMP_DIR is not set"
    exit 1
  elif [[ -z "${RALPM_PKG_INSTALL_DIR}" ]]; then
    echo "RALPM_PKG_INSTALL_DIR is not set"
    exit 1
  elif [[ -z "${RALPM_PKG_BIN_DIR}" ]]; then
    echo "RALPM_PKG_BIN_DIR is not set"
    exit 1
  fi
}

install() {
  sudo apt update
  sudo apt upgrade -y
  sudo apt auto-remove -y

  sudo apt install --no-install-recommends -y git ca-certificates build-essential pkg-config \
  libreadline-dev gcc-arm-none-eabi libnewlib-dev qtbase5-dev \
  libbz2-dev liblz4-dev libbluetooth-dev libpython3-dev libssl-dev libgd-dev

  wget https://github.com/RfidResearchGroup/proxmark3/archive/refs/tags/v4.18341.zip -O $RALPM_TMP_DIR/proxmark3.zip
  unzip $RALPM_TMP_DIR/proxmark3.zip -d $RALPM_PKG_INSTALL_DIR
  mv $RALPM_PKG_INSTALL_DIR/proxmark3-4.18341 $RALPM_PKG_INSTALL_DIR/proxmark3
  cd $RALPM_PKG_INSTALL_DIR/proxmark3

  sudo cp -rf driver/77-pm3-usb-device-blacklist-uucp.rules /etc/udev/rules.d/77-pm3-usb-device-blacklist-uucp.rules
  sudo udevadm control --reload-rules
  sudo adduser $USER dialout

  make clean && make -j

  sudo make install

  sudo ln -s /usr/local/bin/proxmark3 /usr/bin/proxmark3
  sudo ln -s /usr/local/bin/pm3 /usr/bin/pm3
  sudo chmod +x /usr/bin/proxmark3
  sudo chmod +x /usr/bin/pm3
}

uninstall() {
  sudo rm -rf $RALPM_PKG_INSTALL_DIR/proxmark3
  sudo rm /usr/bin/proxmark3
  sudo rm /usr/bin/pm3
  sudo rm -rf /usr/local/bin/proxmark3
  sudo rm -rf /usr/local/share/proxmark3
}

run() {
  if [[ "$1" == "install" ]]; then 
    install
  elif [[ "$1" == "uninstall" ]]; then 
    uninstall
  else
    show_usage
  fi
}

check_env
run $1

