#!/bin/bash
read -p "Enter your name: " username
cat /home/mueenb/webapp/config/app.conf
echo "Login: $username Date: $(date)" >> /home/mueenb/webapp/logs/app.log
cat /home/mueenb/webapp/logs/app.log
test by devuser1
test by devuser2
