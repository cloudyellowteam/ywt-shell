#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:analytics() {

    ga() {
        collect() {
            # https://developers.google.com/analytics/devguides/collection/protocol/ga4/sending-events?client_type=firebase
            MEASUREMENT_ID="G-9KYCLP5VXR"
            API_SECRET="kwhudb31Q5W7sGQr1SDFFg"
            EVENT_NAME="file_downloaded"
            CLIENT_ID="7947731687"
            BODY='{
                "client_id": "'"$CLIENT_ID"'",
                "user_id": "'"$(whoami | md5sum | awk '{print $1}')"'",
                "non_personalized_ads": false,
                "user_properties":{
                    "group":{
                        "value": "'"$(whoami | md5sum | awk '{print $1}')"'",
                    }
                },
                "events": [{
                    "name": "'"$EVENT_NAME"'",
                    "params": {                        
                        "file_name": "example.zip",
                        "user_category": "premium_user"
                    }
                }]
            }'
            GA4_ENDPOINT="https://www.google-analytics.com/mp/collect?measurement_id=$MEASUREMENT_ID&api_secret=$API_SECRET"
            # debug
            #GA4_ENDPOINT="https://www.google-analytics.com/debug/mp/collect?measurement_id=$MEASUREMENT_ID&api_secret=$API_SECRET"
            curl -X POST "$GA4_ENDPOINT" \
                -H "Content-Type: application/json" \
                -H "User-Agent: $YDK_ANALYTICS_USERAGENT" \
                -H "Accept: application/json" \
                -d "$BODY" &

            ydk:log debug "Event sent to Google Analytics"
        }

        collect:v1() {
            TRACKING_ID="G-9KYCLP5VXR"
            CLIENT_ID="7947731687"
            EVENT_CATEGORY="shell_script"
            EVENT_ACTION="execute"
            EVENT_LABEL="example_script"
            EVENT_VALUE="1" # Optional

            # Endpoint for Google Analytics
            # GA_ENDPOINT="https://www.google-analytics.com/collect"
            GA_ENDPOINT="https://www.google-analytics.com/debug/collect"

            # POST request to Google Analytics
            curl -X POST "$GA_ENDPOINT" \
                -d "v=1" \
                -d "tid=$TRACKING_ID" \
                -d "cid=$CLIENT_ID" \
                -d "t=event" \
                -d "ec=$EVENT_CATEGORY" \
                -d "ea=$EVENT_ACTION" \
                -d "el=$EVENT_LABEL" \
                -d "ev=$EVENT_VALUE"

            echo "Event sent to Google Analytics"
        }
        ydk:try "$@" 4>&1
        return $?
    }
    ydk:try "$@" 4>&1
    return $?
}
{
    [[ -z "$YDK_ANALYTICS_USERAGENT" ]] && export YDK_ANALYTICS_USERAGENT=$({
        echo -n "ydk-shell/0.0.0-local-0"
        echo -n " "
        echo -n "(curl 7.68.0; A; B)" # (Windows NT 10.0; Win64; x64)
        echo -n " "
        echo -n "bash/5.0.17(1)-release" # AppleWebKit/537.36
        echo -n " "
        echo -n "GoogleAnalytics/4.0" # (KHTML, like Gecko)
        echo -n " "
        echo -n "Linux/x86_64" # Chrome/123.0.0.0
        echo -n " "
        echo -n "AppleWebKit/537.36" # Safari/537.36
        echo -n " "
        echo -n "Edg/123.0.0.0" # Edg/123.0.0.0
    }) && readonly YDK_ANALYTICS_USERAGENT
    [[ -z "$YDK_ANALYTICS_EVENTS" ]] && declare -a YDK_ANALYTICS_EVENTS=(
        '{"name": "file_downloaded", "params": {"file_name": "example.zip", "user_category": "premium_user"}}'
    ) && readonly YDK_ANALYTICS_EVENTS
}
