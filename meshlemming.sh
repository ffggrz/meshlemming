#!/bin/sh
# Matthias Drobny, 2019-10-04, Freifunk Gera-Greiz
# This script changes the mesh channels to secure that always the best mesh partner is available.
# Beware of possible channel flapping!

checkHop() {
	for f in `batctl if | grep -e mesh.: | cut -d: -f1` ; do
		echo "Mesh-Interface: ""${f}"
		RADIO=`uci show | grep "${f}" | cut -d. -f2 | cut -d_ -f2`
		CHANGED=0
		echo "zugehoeriges Radio-Interface: ""${RADIO}"
		CURRENT_CHANNEL=`iwinfo "${RADIO}" info | sed -E 's|^ *|\t|g' | tr -s '\n' | sed ':a;N;$!ba;s|\n|\t|g' | sed -E 's|Cell |\n|g'  | sed -E 's|\t+|\t|g' | sed -E 's|^.*Channel: (\d+).*$|\1|g'`
		echo "aktueller Kanal: ""${CURRENT_CHANNEL}"
		BEST_MESHCHANNEL=`iwinfo "${RADIO}" scan | sed -E 's|^ *|\t|g' | tr -s '\n' | sed ':a;N;$!ba;s|\n|\t|g' | sed -E 's|Cell |\n|g' | grep "Mode: Mesh Point" | sed -E 's|\t+|\t|g' |  sed -E 's|^.*Channel: (\d+).*Signal: -(\d+).*$|\2\t\1|g' | sort | cut -f2 | head -n1`
		echo "Bester Mesh-Kanal: ""${BEST_MESHCHANNEL}"
		if [[ "${CURRENT_CHANNEL}" -eq "${BEST_MESHCHANNEL}" ]] 
			then echo "bereits bester Kanal gewaehlt"; 
		else
			echo "neuen Kanal " "${BEST_MESHCHANNEL}" " waehlen";
			echo "uci set wireless."${RADIO}".channel=""${BEST_MESHCHANNEL}";
			if [[ "${DEBUG}" -eq 0 ]]
				then uci set wireless."${RADIO}".channel="${BEST_MESHCHANNEL}"
			fi
			CHANGED=1
		fi
	done
	if [[ "${CHANGED}" -gt 0 ]]
		then echo "uci commit"; echo "wifi";
		if [[ "${DEBUG}" -eq 0 ]]
			then uci commit
			wifi
		fi
	fi
}


VPNIF="mesh-vpn"
DEBUG=0
VPN=`batctl gwl | grep -e "^*" | grep -e "${VPNIF}" | wc -l`;

while true; do
	# Kein Hopping durchfuehren, wenn es eine direkte Verbindung zu den Gateways gibt.
	if [[ "${VPN}" -eq 1 ]]
		then exit 0;
	else 
		echo "#### checkHop ####";
		checkHop
	fi
	sleep 1m
done
