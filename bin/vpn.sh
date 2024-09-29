#!/bin/bash

case $1 in
    'start')
      fdn.sh stop
      DEV=$(ip route list | grep default | grep wlp8s0 | awk '{print $3}' | uniq)
      sudo ip route del 0.0.0.0/1
      sudo ip route del 0.0.0.0/2
      sudo ip route del 0.0.0.0/3
      sudo ip route del $DEV
      sudo ip route del default via $DEV
      fdn.sh start
      curl ipinfo.io
        ;;
    'stop')
      fdn.sh stop
      sudo dhclient wlp8s0
      fdn.sh start
      curl ipinfo.io
        ;;
    'status')
      ip route list | grep default 
        ;;
    *)
        echo 'valid argument : start|stop|status'
        ;;
esac

