#!/bin/bash

case $1 in
    'start')
        sudo mv /etc/resolv.conf /etc/resolv.conf-orig
        sudo cp /etc/resolv.conf-fdn /etc/resolv.conf
        ;;
    'stop')
        sudo rm /etc/resolv.conf
        sudo mv /etc/resolv.conf-orig /etc/resolv.conf
        ;;
    'status')
        ls -l /etc/resolv.conf
        cat /etc/resolv.conf
        ;;
    *)
        echo 'valid argument : start|stop|status'
        ;;
esac

