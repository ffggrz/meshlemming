#!/bin/sh
# Matthias Drobny, 2019-10-04, Freifunk Gera-Greiz
# This script changes the mesh channels to secure that always the best mesh partner is available.
# Beware of possible channel flapping!

checkHop() {
	for f in `batctl if | grep -e mesh.: | cut -d: -f1` ; do
		RADIO=`uci show | grep "${f}" | cut -d. -f2 | cut -d_ -f2`
		CHANGED=0
		CURRENT_CHANNEL=`iwinfo "${RADIO}" info | sed -E 's|^ *|\t|g' | tr -s '\n' | sed ':a;N;$!ba;s|\n|\t|g' | sed -E 's|Cell |\n|g'  | sed -E 's|\t+|\t|g' | sed -E 's|^.*Channel: (\d+).*$|\1|g'`
		logger "Meshlemming: aktueller Kanal: ""${CURRENT_CHANNEL}"
		BEST_MESHCHANNEL=`iwinfo "${RADIO}" scan | sed -E 's|^ *|\t|g' | tr -s '\n' | sed ':a;N;$!ba;s|\n|\t|g' | sed -E 's|Cell |\n|g' | grep "Mode: Mesh Point" | sed -E 's|\t+|\t|g' |  sed -E 's|^.*Channel: (\d+).*Signal: -(\d+).*$|\2\t\1|g' | sort | cut -f2 | head -n1`
		logger "Meshlemming: Bester Mesh-Kanal: ""${BEST_MESHCHANNEL}"
		if [[ "${CURRENT_CHANNEL}" -eq "${BEST_MESHCHANNEL}" ]] 
			then logger "Meshlemming: bereits bester Kanal gewaehlt"; 
		else
			logger "Meshlemming: neuen Kanal " "${BEST_MESHCHANNEL}" " waehlen";
			logger "Meshlemming: uci set wireless."${RADIO}".channel=""${BEST_MESHCHANNEL}";
			if [[ "${DEBUG}" -eq 0 ]]
				then uci set wireless."${RADIO}".channel="${BEST_MESHCHANNEL}"
			fi
			CHANGED=1
		fi
	done
	if [[ "${CHANGED}" -gt 0 ]]
		then logger "Meshlemming: uci commit wireless; wifi";
		if [[ "${DEBUG}" -eq 0 ]]
			then uci commit
			wifi
		fi
	fi
}


VPNIF="mesh-vpn"
DEBUG=0
VPN=`batctl gwl | grep -e "^*" | grep -e "${VPNIF}" | wc -l`;

# Kein Hopping durchfuehren, wenn es eine direkte Verbindung zu den Gateways gibt.
if [[ "${VPN}" -eq 1 ]]
	then exit 0;
else 
	logger "Meshlemming: checkHop";
	checkHop
fi
