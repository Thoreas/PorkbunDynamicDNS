#!/bin/bash

# Required
API_KEY=""
API_SECRET=""
DOMAIN=""
#Optional
SUBDOMAIN=""

# Check if API_KEY and API_SECRET have been populated
if [ -z "$API_KEY" ] || [ -z "$API_SECRET" ]; then
	echo "Required data missing! Populate API_KEY and API_SECRET values." | tee >(cat >&2) | systemd-cat -t $0
	exit
fi
# Check if DOMAIN has been populated
if [ -z "$DOMAIN" ]; then
	echo "Required data missing! Populate DOMAIN value." | tee >(cat >&2) | systemd-cat -t $0
	exit
fi

# Get current IP using Porkbun's API
CURRENT_IP=$(curl -s -X POST "https://porkbun.com/api/json/v3/ping" -H "Content-Type: application/json" --data "{ \"apikey\": \"$API_KEY\", \"secretapikey\": \"$API_SECRET\" }" | grep -Po '(?<="yourIp":")[^"]+')
if [ -z "$CURRENT_IP" ]; then
	echo "Could not get current external IP address!" | tee >(cat >&2) | systemd-cat -t $0
	exit
fi

# Get current DNS record
CURRENT_DNS_RECORD=$(curl -s -X POST "https://porkbun.com/api/json/v3/dns/retrieveByNameType/$DOMAIN/A/$SUBDOMAIN" -H "Content-Type: application/json" --data "{ \"apikey\": \"$API_KEY\", \"secretapikey\": \"$API_SECRET\" }" | grep -Po '(?<="content":")[^"]+')

# Check if DNS record needs updating
if [[ $CURRENT_DNS_RECORD != $CURRENT_IP ]]; then
	RESPONSE=$(curl -s -X POST "https://porkbun.com/api/json/v3/dns/editByNameType/$DOMAIN/A/$SUBDOMAIN" -H "Content-Type: application/json" --data "{ \"apikey\": \"$API_KEY\", \"secretapikey\": \"$API_SECRET\", \"content\": \"$CURRENT_IP\", \"ttl\": \"300\" }")
	if [[ $RESPONSE =~ "SUCCESS" ]]; then
		echo "DNS record for $SUBDOMAIN.$DOMAIN updated with IP $CURRENT_IP" | systemd-cat -t $0
	else
		echo "$RESPONSE" | systemd-cat -t $0
	fi
fi
