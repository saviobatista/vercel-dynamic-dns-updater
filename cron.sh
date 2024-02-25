#!/bin/bash

# Configuration
ENV_FILE=".env"
LAST_IP_FILE=".last"
RESPONSE_FILE="response.json"
TEMP_FILE="temp.http_response"

# Check for jq installation
if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install jq to continue."
    exit 1
fi

# Function to get the current external IP address
getCurrentIP() {
    curl -s https://checkip.amazonaws.com
}

# Function to read the last known IP address
getPreviousIP() {
    cat "$LAST_IP_FILE" 2>/dev/null
}

# Function to update the DNS record on Vercel
updateDNSRecord() {
    local ip="$1"

    # Ensure variables are loaded from the environment file
    if ! source "$ENV_FILE"; then
        echo "Error: Failed to load environment variables from $ENV_FILE"
        exit 1
    fi

    # Update DNS record
    curl -s -o "$RESPONSE_FILE" -w "%{http_code}" -X PATCH "https://api.vercel.com/v1/domains/records/$RECORD" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "comment": "Dynamic DNS update",
            "name": "'"$SUBDOMAIN"'",
            "ttl": 60,
            "type": "A",
            "value": "'"$ip"'"
        }' > "$TEMP_FILE"

    local http_status=$(cat "$TEMP_FILE")
    local response_body=$(cat "$RESPONSE_FILE")

    handleResponse "$http_status" "$response_body"
}

# Function to handle the API response and update the .env file if successful
handleResponse() {
    local http_status="$1"
    local response_body="$2"

    if [ "$http_status" -eq 200 ]; then
        echo "DNS record updated successfully."

        # Extract the new record ID from the response
        local new_record_id=$(echo "$response_body" | jq -r '.id')
        if [ -n "$new_record_id" ] && [ "$new_record_id" != "null" ]; then
            echo "Updating .env file with the new record ID: $new_record_id"
            updateEnvFile "$new_record_id"
        else
            echo "Could not extract the new record ID from the response."
	    cleanUp
	    return
        fi
    else
        echo "Failed to update DNS record. HTTP status: $http_status"
        echo "Response: $response_body"

	cleanUp
	return
    fi

    cleanUp

    # Update the last IP file
    echo "$ip" > "$LAST_IP_FILE"  
}

# Function to clean up temporary files
cleanUp() {
    rm -f "$RESPONSE_FILE" "$TEMP_FILE"
}

# Function to update the .env file with the new record ID
updateEnvFile() {
    local new_record_id="$1"
    # Detect OS and adjust sed command accordingly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^RECORD=.*/RECORD=$new_record_id/" "$ENV_FILE"
    else
        sed -i "s/^RECORD=.*/RECORD=$new_record_id/" "$ENV_FILE"
    fi
}

# Main logic
main() {
    local currentIP=$(getCurrentIP)
    local previousIP=$(getPreviousIP)

    echo $(date)
    echo "Current external IP is: $currentIP"
    if [ -z "$previousIP" ]; then
        echo "No previous record of the IP found. Is this the first run?"
    else
        echo "Previous IP was: $previousIP"
    fi

    if [[ -n "$currentIP" && "$currentIP" != "$previousIP" ]]; then
        echo "IP has changed or is being set for the first time. Updating DNS record..."
        updateDNSRecord "$currentIP"
    else
        echo "IP has not changed. No update necessary."
    fi
}

main

