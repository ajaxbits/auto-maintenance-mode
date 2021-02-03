#!/bin/bash

# ╔═╗┌─┐┬  ┬┌─┐┬ ┬
# ╠═╝│ ││  ││  └┬┘
# ╩  └─┘┴─┘┴└─┘ ┴
# ╔╦╗┌─┐┬┌┐┌┬┐┌─┐┌┐┌┌─┐┌┐┌┌─┐┌─┐
# ║║║├─┤│││││ ├┤ │││├─┤││││  ├┤
# ╩ ╩┴ ┴┴┘└┘┴ └─┘┘└┘┴ ┴┘└┘└─┘└─┘
# ╔╦╗┌─┐┌┬┐┌─┐
# ║║║│ │ ││├┤
# ╩ ╩└─┘─┴┘└─┘

# by Alex Jackson
# email bugs to alex_jackson@trendmicro.com

# you can run the command only using flags...
while getopts i:a:p:t: flag
do
    case "${flag}" in
        i) address=${OPTARG};; # in MINUTES
        a) api_key=${OPTARG};;
        p) policy=${OPTARG};; # exact names only
        t) time=${OPTARG};; # in MINUTES
    esac
done

# or you can run it interactively
if [ -z "$address" ]
then
        echo 'Please enter the DSM IP address and port (<DSM ip>:<port>)'
        echo '(leave blank for Cloud One Workload Security)'
        read address
        [ -z "$address" ] && address=https://cloudone.trendmicro.com || address="-k https://$address"
fi
if [ -z "$api_key" ]
then
        echo 'Please enter a valid, "Full Access" api key'
        read api_key
fi
if [ -z "$policy" ]
then
        echo 'Which policy to enable maintenance mode on?'
        read policy
fi
if [ -z "$time" ]
then
        echo 'How long should maintenance mode run (in minutes)?'
        read time
fi

# find policy id
policy_id=$(curl $address/api/policies -H "api-secret-key:$api_key" -H "api-version:v1" -s | jq -r ".policies[] | select(.name == \"$policy\") | .ID")
computers_list=$(curl $address/api/computers -H "api-secret-key:$api_key" -H "api-version:v1" -s | jq -r ".computers[] | select(.policyID == $policy_id) | .ID")

for computerID in $computers_list; do
        curl -X POST $address/api/computers/$computerID \
                -H "api-secret-key:$api_key" \
                -H "api-version:v1" \
                -H "content-type: application/json" \
                -d "{\"applicationControl\":{\"maintenanceModeStatus\":\"on\", \"maintenanceModeDuration\":$time}}" \
                -s
done
