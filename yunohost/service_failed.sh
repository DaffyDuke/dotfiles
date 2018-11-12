#!/bin/bash

yunohost tools diagnosis --output-as json | jq '.services' | grep -v running | awk -F'"' '{print $2}' 
# yunohost service status | grep -E -v 'service_file_path|active_at|human|loaded|description|timestamp|active' | sed -e "s+^+_+g" | tr -d '\012' | sed -e "s+ _ ++g" -e "s+_+\n+g" -e "s+: status:+ +g" | grep -v running
