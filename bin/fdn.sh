#!/bin/bash

case $1 in
    'start')
        sudo rm -f /etc/resolv.conf 2>/dev/null
        echo "nameserver 80.67.169.12" | sudo tee /etc/resolv.conf
        echo "nameserver 80.67.169.40" | sudo tee -a /etc/resolv.conf
        ;;
    'stop')
        sudo ln -sf /run/resolvconf/resolv.conf /etc/resolv.conf
        ;;
    'status')
        if [ -h /etc/resolv.conf ]
        then
          echo "managed by NetworkManager"
        else
          echo -e "Dedicated file : \c"
          if [ $(grep -c 80.67.169 /etc/resolv.conf) -eq 2 ]
          then
            echo FDN
          else
            echo OTHERS
            cat /etc/resolv.conf
          fi
        fi
        ;;
    *)
        echo 'valid argument : start|stop|status'
        ;;
esac

