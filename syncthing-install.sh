#!/bin/bash

cat <<EOF
#
# syncthing-install.sh
# Support OS: Debian / Ubuntu / CentOS
#       arch: amd64 / arm64
#
# This shell scipts will install Syncthing as a service.
#
EOF

no_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        if [ -z "$3" ]; then
            $2 install -y $1
        else
            $2 install -y $3
        fi
    fi
}

read -p "Please press \"y\" to continue: " answer

case $answer in
Y | y)
    echo "continue..."

    cd ~

    #check OS
    source /etc/os-release

    case $ID in
    debian | ubuntu)
        echo System OS is $PRETTY_NAME
        apt update
        no_command curl apt

        # Add the release PGP keys:
        curl -s https://syncthing.net/release-key.txt | apt-key add -

        # Add the "stable" channel to your APT sources:
        echo "deb https://apt.syncthing.net/ syncthing stable" | tee /etc/apt/sources.list.d/syncthing.list

        # Update and install syncthing:
        apt install -y apt-transport-https
        apt update && apt install -y syncthing
        ;;

    centos | fedora | rhel | sangoma)
        echo System OS is $PRETTY_NAME
        no_command bc yum
        yumdnf="yum"
        if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0; then
            yumdnf="dnf"
        fi
        no_command wget $yumdnf
        no_command curl $yumdnf
        no_command tar $yumdnf

        # check architecture
        case $(uname -m) in
        x86_64)
            arch=linux-amd64
            ;;
        aarch64)
            arch=linux-arm64
            ;;
        *)
            echo "uname -m"
            uname -m
            echo "Unknown architecture."
            echo "Exit..."
            exit 2
            ;;
        esac

        rm syncthing-$arch-*.tar.gz*
        curl -s https://api.github.com/repos/syncthing/syncthing/releases/latest |
            grep browser_download_url |
            grep $arch |
            cut -d '"' -f 4 |
            wget -qi -

        tar xvf syncthing-$arch-*.tar.gz
        rm syncthing-$arch-*.tar.gz*

        rm /usr/bin/syncthing -f
        mv syncthing-$arch-*/syncthing /usr/bin/
        chmod +x /usr/bin/syncthing

        # create syncthing.service
        cat >/lib/systemd/system/syncthing@.service <<EOF
[Unit]
Description=Syncthing - Open Source Continuous File Synchronization for %I
Documentation=man:syncthing(1)
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=4

[Service]
User=%i
ExecStart=/usr/bin/syncthing --no-browser --no-restart --logflags=0
Restart=on-failure
RestartSec=1
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

# Hardening
ProtectSystem=full
PrivateTmp=true
SystemCallArchitectures=native
MemoryDenyWriteExecute=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

        cat >/lib/systemd/system/syncthing-resume.service <<EOF
[Unit]
Description=Restart Syncthing after resume
Documentation=man:syncthing(1)
After=sleep.target

[Service]
Type=oneshot
ExecStart=-/usr/bin/pkill -HUP -x syncthing

[Install]
WantedBy=sleep.target
EOF

        systemctl daemon-reload
        ;;

    *)
        echo System OS is $PRETTY_NAME
        echo Unsupported system OS.
        exit 2
        ;;
    esac

    # create syncthing user
    useradd -m syncthing

    systemctl enable syncthing@syncthing.service
    systemctl restart syncthing@syncthing.service

    echo "Please wait for Syncthing service starting..."
    sleep 5s

    systemctl status syncthing@syncthing.service --no-pager

    ## go exit
    ;;

*)
    echo "exit"
    ;;

esac

exit 0
