#!/bin/sh

# Configuration
TELEGRAM_BOT_TOKEN=" "
CHAT_ID=" "
LEASE_DIR="/var/lib/kea/"
LEASE_FILE="dhcp_leases.txt"
TEMP_FILE="dhcp_leases_tmp.txt"
NOTIFIED_FILE="notified_leases.txt"


cd /custom/dhcp_notifier || { echo "Failed to change directory"; exit 1; }

send_telegram_message() {
    MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$CHAT_ID" \
        -d "text=$MESSAGE"
}

extract_leases() {
    echo "" > "$TEMP_FILE"  # Clear temp file

    # Read all lease files line by line
    for file in $LEASE_DIR/dhcp4.leases*; do
        if [ -f "$file" ]; then  # Skip if file doesn't exist
            tail -n +2 "$file" | while IFS=, read ip mac client_id lifetime expire subnet_id fwd rev hostname state user pool_id; do
                if [ -z "$hostname" ]; then
                    hostname="N/A"
                fi
                echo "$ip,$mac,$hostname" >> "$TEMP_FILE"
            done
        fi
    done

    # Remove duplicates (keep latest) & sort by IP
    awk -F',' '!seen[$1]++' "$TEMP_FILE" | sort -t'.' -k1,1n -k2,2n -k3,3n -k4,4n > "$LEASE_FILE"
}

# Ensure files exist
touch "$LEASE_FILE"

# Parse leases at startup
extract_leases

cp "$LEASE_FILE" "$NOTIFIED_FILE"

# Send all leases at startup
ALL_HOSTS=$(awk -F',' '{print "IP: " $1 "\nMAC: " $2 "\nHostname: " $3 "\n"}' "$LEASE_FILE" | sed ':a;N;$!ba;s/\n\n/\n\n\n/g')
send_telegram_message "📋 Initial DHCP Leases:\n\n$ALL_HOSTS"

# Monitor for new leases
echo "\n \n"
echo "Monitoring DHCP leases..."
while true; do
    extract_leases

    # Identify new leases
    sort "$NOTIFIED_FILE" -o "$NOTIFIED_FILE"
    sort "$LEASE_FILE" -o "$LEASE_FILE"
    NEW_LEASES=`comm -13 "$NOTIFIED_FILE" "$LEASE_FILE"`


    if [ ! -z "$NEW_LEASES" ]; then
        echo "$NEW_LEASES" >> "$NOTIFIED_FILE"  # Update notified leases

        NEW_HOSTS=`echo "$NEW_LEASES" | awk -F',' '{print "IP: " $1 "\nMAC: " $2 "\nHostname: " $3 "\n"}' | sed ':a;N;$!ba;s/\n\n/\n\n\n/g'`

        send_telegram_message "🆕 New DHCP Lease Detected:\n\n$NEW_HOSTS"
    fi

    sleep 10
done
