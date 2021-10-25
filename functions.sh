#!/bin/bash
#
# Title:      PGBlitz (Reference Title File)
# Author(s):  Admin9705
# URL:        https://pgblitz.com - http://github.pgblitz.com
# GNU:        General Public License v3.0
################################################################################
source /opt/plexguide/menu/functions/functions.sh
source /opt/plexguide/menu/functions/start.sh
typed="${typed,,}"
main() {
  local file=$1 val=$2 var=$3
  [[ -e $file ]] || printf '%s\n' "$val" >"$file"
  printf -v "$var" '%s' "$(<"$file")"
}

blockdeploycheck() {
  if [[ $(cat /var/plexguide/traefik.provider) == "NOT-SET" || $(cat /var/plexguide/server.domain) == "NOT-SET" || $(cat /var/plexguide/server.email) == "NOT-SET" ]]; then
    echo
    read -p 'Blocking deployment! Must configure everything! | Press [ENTER]' typed </dev/tty
    traefikstart
  fi
}

delaycheckinterface() {

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Traefik - DNS delay check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOTE: This enables a certain amount of time to be delayed before the
provider validates your Traefik container! Setting it too low may result
in the provider being unable to validate your Traefik container, which may
result in MISSING the opportunity to validate your https:// certificates!

Delay the Traefik DNS check for how many seconds? (Default 90)

EOF

  typed2=999999999
  while [[ "$typed2" -lt "30" || "$typed2" -gt "120" ]]; do
    echo "To quit, type >>> z or exit"
    read -p 'Type a number between 30 through 120 | Press [ENTER]: ' typed2 </dev/tty
    if [[ "$typed2" == "exit" || "$typed2" == "Exit" || "$typed2" == "EXIT" || "$typed2" == "z" || "$typed2" == "Z" ]]; then traefikstart; fi
    echo
  done

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 New DNS delay check value: [$typed2] seconds
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOTE 1: Make all changes first. Traefik must be deployed/redeployed for
this to take affect!

NOTE 2: When deploying Traefik, you will be required to wait at least $typed
seconds as a result of the check.

EOF
  echo "$typed2" >/var/plexguide/server.delaycheck
  read -p 'Acknowledge info | Press [ENTER] ' typed </dev/tty

}

destroytraefik() {
  docker stop traefik 1>/dev/null 2>&1
  docker rm traefik 1>/dev/null 2>&1

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Traefik container has been destroyed!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  read -p 'Acknowledge info | Press [ENTER] ' typed </dev/tty
}

domaininterface() {

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Domain name - current domain: $domain
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To quit, type >>> z or exit
EOF
  read -p 'Input Value | Press [ENTER]: ' typed </dev/tty
  if [[ "${typed}" == "exit" || "${typed}" == "z" ]]; then traefikstart; fi
  if [[ $(echo ${typed} | grep "\.") == "" ]]; then

    tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Domain name is invalid - Missing "." - $typed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
    read -p 'Acknowledge info | Press [ENTER] ' typed </dev/tty
    domaininterface
    bash /opt/traefik/traefik.sh
    exit
  fi

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Domain name - current domain: $typed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOTE: Traefik must be deployed/redeployed for the domain name changes to
take affect!

EOF
  echo $typed >/var/plexguide/server.domain
  read -p 'Acknowledge info | Press [ENTER] ' typed </dev/tty

}

deploytraefik() {
clear
  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Confirm the details below and deploy Traefik
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Domain provider                               : $provider
Domain name                                   : $domain
Email address                                 : $email

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

  pnum=0
  mkdir -p /var/plexguide/prolist
  rm -rf /var/plexguide/prolist/* 1>/dev/null 2>&1

  ls -la "/opt/traefik/providers/$provider" | awk '{print $9}' | tail -n +4 >/var/plexguide/prolist/prolist.sh

  while read p; do
    let "pnum++"
    echo -n "${p} - "
    echo -n $(cat "/var/plexguide/traefik/$provider/$p")
    echo
  done </var/plexguide/prolist/prolist.sh
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo

  while true; do
    echo "Deploy Traefik?"
    read -p 'y or n? | Press [ENTER]: ' typed2 </dev/tty
    if [[ "$typed2" == "n" || "$typed2" == "N" || "$typed2" == "No" || "$typed2" == "NO" ]]; then traefikstart; fi
    if [[ "$typed2" == "y" || "$typed2" == "Y" || "$typed2" == "Yes" || "$typed2" == "YES" ]]; then
      traefikbuilder
      traefikstart
    fi
    echo
  done

}

emailinterface() {

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Current Email address: $email
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To quit, type >>> z or exit
EOF
  read -p 'Input value | Press [ENTER]: ' typed </dev/tty
  if [[ "$typed" == "exit" || "$typed" == "Exit" || "$typed" == "EXIT" || "$typed" == "z" || "$typed" == "Z" ]]; then traefikstart; fi

  ### fix bug if user doesn't type .
  if [[ $(echo $typed | grep "\.") == "" ]]; then

    tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Email invalid - Missing "." - $typed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
    read -p 'Acknowledge info | Press [ENTER] ' typed </dev/tty
    emailinterface
    bash /opt/traefik/traefik.sh
    exit
  fi

  if [[ $(echo $typed | grep "\@") == "" ]]; then

    tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Email invalid - Missing "@" - $typed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
    read -p 'Acknowledge info | Press [ENTER] ' typed </dev/tty
    emailinterface
    bash /opt/traefik/traefik.sh
    exit

  fi

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 New Email address: $typed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOTE: Make all changes first.  Traefik must be deployed/redeployed for
the email name changes to take affect!

EOF
  echo $typed >/var/plexguide/server.email
  read -p 'Acknowledge info | Press [ENTER] ' typed </dev/tty

}
layoutbuilder() {
top_menu "Traefik"
  if [[ "$provider" == "NOT-SET" ]]; then layout=" "; fi
  tee <<-EOF

[1] Top Level Domain App: [$tld]
[2] Domain provider     : [$provider]
[3] Domain Name         : [$domain]
[4] Email address       : [$email]
[5] DNS delay check     : [$delaycheck] Seconds
EOF

  # skips if no provider is set
  if [[ $(cat /var/plexguide/traefik.provider) != "NOT-SET" ]]; then
    # Generates Rest of Inbetween Interface

    pnum=5
    mkdir -p /var/plexguide/prolist
    rm -rf /var/plexguide/prolist/* 1>/dev/null 2>&1

    ls -la "/opt/traefik/providers/$provider" | awk '{print $9}' | tail -n +4 >/var/plexguide/prolist/prolist.sh

    # Set Provider for the Process
    provider7=$(cat /var/plexguide/traefik.provider)
    mkdir -p "/var/plexguide/traefik/$provider7"

    while read p; do
      let "pnum++"
      echo "$p" >"/var/plexguide/prolist/$pnum"
      echo "[$pnum] $p" >>/var/plexguide/prolist/final.sh

      # Generates a Not-Set for the Echo Below
      file="/var/plexguide/traefik/$provider7/$p"
      if [ ! -e "$file" ]; then
        filler="** NOT SET - "
        touch /var/plexguide/traefik/block.deploy
      else filler=""; fi

      echo "[$pnum] ${filler}${p}"
    done </var/plexguide/prolist/prolist.sh
  fi

  # If message.c exists due to incorrect working traefik, this will show
  if [ -e "/opt/appdata/plexguide/emergency/message.c" ]; then
    deployed="DEPLOYED - INCORRECTLY"
  fi

  # Last Piece of the Interface
  tee <<-EOF

-------------------------------------------------------------------------
[A] Deploy Traefik      : [$deployed]
[B] Destroy Traefik
EOF
end_menu_back
  # Standby
  read -p 'Type a number | Press [ENTER]: ' typed </dev/tty

  # Prompt User To Input Information Based on Greater > 4 & Less Than pnum++
  if [[ "$typed" -ge "6" && "$typed" -le "$pnum" ]]; then layoutprompt; fi

}

layoutprompt() {
  process5=$(cat /var/plexguide/prolist/final.sh | grep "$typed" | cut -c 5-)

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Input value - $process5
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

To quit, type >>> z or exit
EOF
  read -p 'Input value | Press [ENTER]: ' typed </dev/tty
  if [[ "$typed" == "exit" || "$typed" == "Exit" || "$typed" == "EXIT" || "$typed" == "z" || "$typed" == "Z" ]]; then traefikstart; fi

  echo "$typed" >"/var/plexguide/traefik/$provider7/$process5"
  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  read -p 'Information stored | Press [ENTER] ' typed </dev/tty

}

postdeploy() {
  tempseconds=$(cat /var/plexguide/server.delaycheck)
  delseconds=$((${tempseconds} + 10))
  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Standby for repulling Core Apps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
ansible-playbook /opt/traefik/repulls/clone.yml
sleep 2
  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Core Apps pulled ✔️ 
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
 sleep 3

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Standby for Traefik deployment validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOTE 1: Do NOT EXIT this interface. Please standby for validation checks!

NOTE 2: Standing by for [$tempseconds] + 10 seconds per the set DNS delay
check! When complete, Portainer will be rebuilt! If that passes,
then we will rebuild the rest of the containers!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

  while [[ "$delseconds" -ge "1" ]]; do
    delseconds=$((${delseconds} - 1))
    echo -ne "StandBy - Traefik validatiuon process: $delseconds Seconds  "'\r'
    sleep 1
  done

  tee <<-EOF


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Rebuilding Portainer
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
 
  ansible-playbook /opt/coreapps/apps/portainer.yml

  delseconds=10
  domain=$(cat /var/plexguide/server.domain)

  cname="portainer"
  if [[ -f "/var/plexguide/portainer.cname" ]]; then
    cname=$(cat "/var/plexguide/portainer.cname")
  fi

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Portainer check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOTE 1: Do NOT EXIT this interface. Please standby for validation checks!

NOTE 2: Checking on https://${cname}.${domain}'s existance.
Please allow 10 seconds for portainer to boot up.

NOTE 3: Be aware that simple mistakes such as bad input, bad domain, or
not knowing what your doing counts for 75% of the problems.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

  while [[ "$delseconds" -ge "1" ]]; do
    delseconds=$((${delseconds} - 1))
    echo -ne "StandBy - Portainer Validation Checks: $delseconds Seconds  "'\r'
    sleep 1
  done

  cname="portainer"
  if [[ -f "/var/plexguide/portainer.cname" ]]; then
    cname=$(cat /var/plexguide/portainer.cname)
  fi

  touch /opt/appdata/plexguide/traefikportainer.check
  wget -q "https://${cname}.${domain}" -O "/opt/appdata/plexguide/traefikportainer.check"

  # If Portainer Detection Failed
  if [[ $(cat /opt/appdata/plexguide/traefikportainer.check) == "" ]]; then
    rm -rf /opt/appdata/plexguide/traefikportainer.check

    tee <<-EOF


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Portainer check: FAILED!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SMART TIP: Check Portainer now! View the Traefik logs!

Portainer  : https://${cname}.${domain}

REASON 1 - Cloudflare  : portainer is not set in the CNAME or A Records
REASON 2 - Delay value : Set too low - CF users reported using 90 to work
REASON 3 - DuckDNS     : Forgot to create a portainer or * - A Record
REASON 4 - Firewall    : Everything is blocked
REASON 5 - LetsEncrypt : LE HitLimit : check https://crt.sh/?q=${domain}
REASON 6 - LetsEncrypt : Planned Maintenance In Progress or service down (https://letsencrypt.status.io)
REASON 7 - User        : PTS Locally; Route is not enable to reach server
REASON 8 - User        : Did not point DOMAIN to correct IP address

There are multiple reason for failure! Visit our wiki or discord!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

    read -p 'Acknowledge info | Press [ENTER] ' name </dev/tty

    tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Traefik process failed!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TIP: When fixed, rerun this process again

NOTE 1: Possibly unable to reach subdomains
NOTE 2: Subdomains will provide insecure warnings

EOF

    read -p 'Try again! Acknowledge info | Press [ENTER] ' name </dev/tty
    traefikstart
  fi

  tee <<-EOF


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Portainer - https://${cname}.${domain} detected!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

  delseconds=4
  while [[ "$delseconds" -ge "1" ]]; do
    delseconds=$((${delseconds} - 1))
    echo -ne "StandBy - Rebuilding containers in: $delseconds seconds  "'\r'
    sleep 1
  done

  docker ps -a --format "{{.Names}}" >/var/plexguide/container.running

  # Containers to Exempt
  sed -i -e "/traefik/d" /var/plexguide/container.running
  sed -i -e "/watchtower/d" /var/plexguide/container.running
  sed -i -e "/wp-*/d" /var/plexguide/container.running # Exempt WP DataBases
  sed -i -e "/x2go*/d" /var/plexguide/container.running
  sed -i -e "/authclient/d" /var/plexguide/container.running
  sed -i -e "/dockergc/d" /var/plexguide/container.running
  sed -i -e "/oauth/d" /var/plexguide/container.running
 
  sed -i -e "/portainer/d" /var/plexguide/container.running # Already Rebuilt

  count=$(wc -l </var/plexguide/container.running)
  ((count++))
  ((count--))
clear
  tee <<-EOF


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈  Traefik - Rebuilding containers!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  sleep 1
  for ((i = 1; i < $count + 1; i++)); do
    app=$(sed "${i}q;d" /var/plexguide/container.running)
    tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈  Traefik - Rebuilding [$app]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
    echo "$app" >/tmp/program_var
    sleep 1.5

    #Rebuild Depending on Location
    if [ -e "/opt/coreapps/apps/$app.yml" ]; then ansible-playbook /opt/coreapps/apps/$app.yml && clear; fi
    if [ -e "/opt/communityapps/$app.yml" ]; then ansible-playbook /opt/communityapps/apps/$app.yml && clear; fi

  done
clear
  read -p 'Traefik - Containers rebuilt ✔️ Acknowledge info | Press [ENTER] ' name </dev/tty
clear
}

providerinterface() {

  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Traefik - Please select a provider
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
  pnum=0
  mkdir -p /var/plexguide/prolist
  rm -rf /var/plexguide/prolist/* 1>/dev/null 2>&1

  ls -la "/opt/traefik/providers" | awk '{print $9}' | tail -n +4 >/var/plexguide/prolist/prolist.sh

  while read p; do
    let "pnum++"
    echo "$p" >"/var/plexguide/prolist/$pnum"
    echo "[$pnum] $p" >>/var/plexguide/prolist/final.sh
  done </var/plexguide/prolist/prolist.sh

  cat /var/plexguide/prolist/final.sh
  echo
  typed2=999999999
  while [[ "$typed2" -lt "1" || "$typed2" -gt "$pnum" ]]; do
    echo "[Z] Exit"
    echo ""
    read -p 'Type number | Press [ENTER]: ' typed2 </dev/tty
    if [[ "$typed2" == "exit" || "$typed2" == "Exit" || "$typed2" == "EXIT" || "$typed2" == "z" || "$typed2" == "Z" ]]; then traefikstart; fi
    echo
  done
  echo $(cat /var/plexguide/prolist/final.sh | grep "$typed2" | cut -c 5- | awk '{print $1}' | head -n 1) >/var/plexguide/traefik.provider
clear
  tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛈 Provider has been set
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOTE: Make all changes first. Traefik must be deployed/redeployed for
this to take affect.

EOF
  read -p 'Acknowledge info | Press [ENTER] ' typed </dev/tty
  clear
}

traefikbuilder() {

  provider=$(cat /var/plexguide/traefik.provider)

  echo "

- name: 'Setting Traefik ENV'
  set_fact:
    pg_env:
      PUID: '1000'
      PGID: '1000'
      PROVIDER: $provider" | tee /opt/traefik/provider.yml 1>/dev/null 2>&1

  mkdir -p /var/plexguide/prolist
  rm -rf /var/plexguide/prolist/* 1>/dev/null 2>&1

  ls -la "/opt/traefik/providers/$provider" | awk '{print $9}' | tail -n +4 >/var/plexguide/prolist/prolist.sh

  while read p; do
    echo -n "      ${p}: " >>/opt/traefik/provider.yml
    echo $(cat "/var/plexguide/traefik/$provider/$p") >>/opt/traefik/provider.yml
  done </var/plexguide/prolist/prolist.sh

  if [[ $(docker ps --format '{{.Names}}' | grep traefik) == "traefik" ]]; then
    docker stop traefik 1>/dev/null 2>&1
    docker rm traefik 1>/dev/null 2>&1
  fi

  file="/opt/appdata/traefik"
  if [ -e "$file" ]; then rm -rf /opt/appdata/traefik; fi

  ansible-playbook /opt/traefik/traefik.yml

  postdeploy
}

traefikpaths() {
  mkdir -p /var/plexguide/traefik
}

traefikstatus() {
  if [ "$(docker ps --format '{{.Names}}' | grep traefik)" == "traefik" ]; then
    deployed="DEPLOYED"
  else deployed="NOT DEPLOYED"; fi
}
