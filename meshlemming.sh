#!/bin/sh
# Matthias Drobny, 2019-10-04, Freifunk Gera-Greiz
# This script changes the mesh channels to ensure that always the best mesh partner is available.
# Be aware of a possible jitter of the channel!

checkHop() {
	for f in `batctl if | grep -e mesh.: | cut -d: -f1`; do
		RADIO=`uci show wireless | grep "${f}" | cut -d. -f2 | cut -d_ -f2`
		CHANGED=0
		CURRENT_CHANNEL=`iwinfo "${RADIO}" info | sed -E 's|^ *|\t|g' | tr -s '\n' | sed ':a;N;$!ba;s|\n|\t|g' | sed -E 's|Cell |\n|g'  | sed -E 's|\t+|\t|g' | sed -E 's|^.*Channel: (\d+).*$|\1|g'`
		logger -t meshlemming "aktueller Kanal: ${CURRENT_CHANNEL}"
		BEST_MESHCHANNEL=`iwinfo "${RADIO}" scan | sed -E 's|^ *|\t|g' | tr -s '\n' | sed ':a;N;$!ba;s|\n|\t|g' | sed -E 's|Cell |\n|g' | grep "Mode: Mesh Point" | sed -E 's|\t+|\t|g' |  sed -E 's|^.*Channel: (\d+).*Signal: -(\d+).*$|\2\t\1|g' | sort | cut -f2 | head -n1`
		logger -t meshlemming "Bester Mesh-Kanal: ${BEST_MESHCHANNEL}"
		if [[ -z "${BEST_MESHCHANNEL}" ]] || [[ "${CURRENT_CHANNEL}" -eq "${BEST_MESHCHANNEL}" ]]; then
			logger -t meshlemming "bereits bester Kanal gewaehlt"
		else
			logger -t meshlemming "neuen Kanal ${BEST_MESHCHANNEL} waehlen"
			logger -t meshlemming "uci set wireless.${RADIO}.channel=${BEST_MESHCHANNEL}"
			if [[ "${DEBUG}" -eq 0 ]]; then
				uci set wireless."${RADIO}".channel="${BEST_MESHCHANNEL}"
			fi
			CHANGED=1
		fi
	done
	if [[ "${CHANGED}" -gt 0 ]]; then
		logger -t meshlemming "uci commit wireless; wifi"
		if [[ "${DEBUG}" -eq 0 ]]; then
			uci commit wireless
			wifi
		fi
	fi
}


VPNIF="mesh-vpn"
DEBUG="${DEBUG:-0}"
VPN=`batctl gwl | grep -e "^*" | grep -e "${VPNIF}" | wc -l`

# Kein Hopping durchfuehren, wenn es eine direkte Verbindung zu den Gateways gibt.
if [[ "${VPN}" -eq 1 ]]; then
	exit 0
else
	logger -t meshlemming "checkHop"
	checkHop
fi
