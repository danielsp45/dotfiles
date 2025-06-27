#!/usr/bin/env bash
# A basic rofi/dmenu power menu

options=" Shutdown
 Reboot
 Suspend
 Logout"
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power:")

case "$chosen" in
  " Shutdown")  systemctl poweroff ;;
  " Reboot")    systemctl reboot  ;;
  " Suspend")   systemctl suspend ;;
  " Logout")    bspc quit        ;;
esac

