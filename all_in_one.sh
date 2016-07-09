#!/bin/bash
# all_in_one.sh
#
# Implement all capabilities from auth_code.sh, auth_token.sh, refresh_token.sh

# Usage:
#   AGRV[1]: command
#   ARGV[2]: additional info (if needed)

# Data from amazon developers portal 
DEVICE_TYPE_ID="ertyuio"
CLIENT_ID="amzn1.application-oa2-client.9baf14e91a2c40cb9d925b06b94e6409"
CLIENT_SECRET="4d01be7f0e48ccf2f8bc80edaf3ed6a5c4e1369b85bec9815f3de7340ee2a7a4"
REDIRECT_URI="https://localhost:9745/authresponse"
DEVICE_SERIAL_NUMBER=123
METADATA_FILE=/tmp/$(date +'%m-%d-%Y')-metadata.json


# Create the Metadata in tmp directory with timestamp to avoid any duplication
echo ' { "messageHeader": {}, "messageBody": { "profile": "alexa-close-talk", "locale": "en-us", "format": "audio/L16; rate=16000; channels=1" } } ' > $METADATA_FILE

# Custom settings for the script
DATA_TRANSFER_FILE="/tmp/poorman_alexa.txt"
OUTPUT_AUDIO_FILE="/tmp/outaudio.txt"

# Logging
date

if [ $# -lt 1 ]; then
    echo "Please specify your comamnd"
    echo "  1: initial authenticate"
    echo "  2: get access token"
    echo "  3: refresh access token"
    exit;
fi

#
# Support function - encode the URL for Amazon API to work well
function urlencode() {
  perl -MURI::Escape -ne 'chomp;print uri_escape($_),"\n"'
}

command=$1;
case $command in
1)
    # Get the initial access code - Initial step
    echo "Command 1. Requesting new access code - Will open browser in 1 sec"
    sleep 1
    SCOPE="alexa:all"
    SCOPE_DATA="{\"alexa:all\": {\"productID\": \"$DEVICE_TYPE_ID\", \"productInstanceAttributes\": {\"deviceSerialNumber\": \"${DEVICE_SERIAL_NUMBER}\"}}}"
    RESPONSE_TYPE="code"
    AUTH_URL="https://www.amazon.com/ap/oa?client_id=${CLIENT_ID}&scope=$(echo $SCOPE | urlencode)&scope_data=$(echo $SCOPE_DATA | urlencode)&response_type=${RESPONSE_TYPE}&redirect_uri=$(echo $REDIRECT_URI | urlencode)"
    open ${AUTH_URL}
    echo "  Done"
    ;;
2)
    # Retrieve access token and refresh token from the initial code
    # Supply the code via second parameter
    echo "Command 2. Requesting new access token from the given code"
    if [ $# -lt 2 ]; then
        echo "Error: Initial code missing. Please run command 1 and copy the code here first"
        exit;
    fi
    GRANT_TYPE="authorization_code"
    API_OUTPUT=$(curl -s -X POST --data "grant_type=${GRANT_TYPE}&code=${2}&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&redirect_uri=$(echo $REDIRECT_URI | urlencode)" https://api.amazon.com/auth/o2/token)

    # Check if we encounter any error
    echo "$API_OUTPUT" | jq -e '.error' > /dev/null
    if [ $? -eq 0 ]; then
        # The API_OUTPUT contains error field -> we failed
        echo "  Encountered problem when try to get access token"
        echo " " "$API_OUTPUT"
    else
        echo "  Succeeded, code + related data saved in $DATA_TRANSFER_FILE"
        echo $API_OUTPUT > $DATA_TRANSFER_FILE
    fi
    echo "  Done"
    ;;
3)
    # Refresh the access token saved in DATA_TRANSFER_FILE
    echo "Command 3. refresh the access token in $DATA_TRANSFER_FILE"

    # Check if the file exists
    if [ ! -f $DATA_TRANSFER_FILE ]; then
        echo "  Error. $DATA_TRANSFER_FILE missing"
    else
        # Check if the file is new, if it's too old - chances are token already expire
        if test `find "$DATA_TRANSFER_FILE" -mmin -60`
        then
            # Check if we have "refresh_token" in the file
            REFRESH_TOKEN=$(jq -er '.refresh_token' < $DATA_TRANSFER_FILE)
            if [ $? -ne 0 ]; then
                echo "  Refresh_token missing from $DATA_TRANSFER_FILE"
            else
                # All OK
                GRANT_TYPE="refresh_token"
                API_OUTPUT=$(curl -s -X POST --data "grant_type=${GRANT_TYPE}&refresh_token=${REFRESH_TOKEN}&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}&redirect_uri=$(echo $REDIRECT_URI | urlencode)" https://api.amazon.com/auth/o2/token)

                # Check the output again
                echo "$API_OUTPUT" | jq -e '.error' > /dev/null
                if [ $? -eq 0 ]; then
                    # The API_OUTPUT contains error field -> we failed
                    echo "  Encountered problem when try to get access token"
                    echo " " "$API_OUTPUT"
                else
                    echo "  Succeeded, code + related data saved in $DATA_TRANSFER_FILE"
                    echo $API_OUTPUT > $DATA_TRANSFER_FILE
                fi
            fi
        else
            echo "  $DATA_TRANSFER_FILE is too old, we can't refresh its code"
        fi
    fi
    echo "  Done"
    ;;
4)
    # Send request wav file
    # Check if the file exists
    if [ ! -f $DATA_TRANSFER_FILE ]; then
        echo "  Error. $DATA_TRANSFER_FILE missing"
    else
        # Check if the file is new, if it's too old - chances are token already expire
        if test `find "$DATA_TRANSFER_FILE" -mmin -60`
        then
            # Check if we have "refresh_token" in the file
            ACCESS_TOKEN=$(jq -er '.access_token' < $DATA_TRANSFER_FILE)
            if [ $? -ne 0 ]; then
                echo "  Refresh_token missing from $DATA_TRANSFER_FILE"
            else
                # Record audio
                sox -d -c 1 -r 16000 -e signed -b 16 hello.wav

                curl -i \
                    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
                    -F "metadata=<${METADATA_FILE};type=application/json; charset=UTF-8" \
                    -F "audio=<hello.wav;type=audio/L16; rate=16000; channels=1" \
                    -o response.txt \
                    https://access-alexa-na.amazon.com/v1/avs/speechrecognizer/recognize

                # Read the file and get the audio output
                grep -a -A5000 -m2 -e "Content-Type: audio/mpeg" response.txt | mpg123 -

                rm -f response.txt hello.wav
            fi
        else
            echo "  $DATA_TRANSFER_FILE is too old, no usable token"
        fi
    fi
    echo "  Done"
    ;;
*)
    echo "Unrecognized command"
    ;;
esac

# Clean up that metadata file
rm -f ${METADATA_FILE} 2> /dev/null
