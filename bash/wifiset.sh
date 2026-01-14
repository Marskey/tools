#!/bin/bash

# 要修改的网络服务名，一般 Wi-Fi 就叫 "Wi-Fi"
SERVICE="Wi-Fi"

if [ "$1" == "gohome" ]; then
    networksetup -setdhcp "$SERVICE"
else
    # 你要指定的静态 IP 地址
    MANUAL_IP="172.16.2.61"
    networksetup -setmanualwithdhcprouter "$SERVICE" "$MANUAL_IP"
fi
