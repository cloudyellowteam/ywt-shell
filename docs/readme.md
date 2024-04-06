# ywt.sh | yw-sh
> **2024.04.06**
```shell
docker run --rm -it \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd):/ywt-workdir \
    -w /ywt-workdir \
    alpine:3.14

```
> **2024.04.05**
```shell
curl -sO https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/src/ydk.sh \
    && chmod +x ./ydk.sh \
    && ./ydk.sh inspect

clear; chmod +x ./src/sdk.sh; ./src/sdk.sh scan apply ./assests-to-scan.json
clear; ./ywt.sh scan apply ./assests-to-scan.json
clear; ./ywt.sh async \
    "scanner cloc asset '{\"type\":\"filesystem\",\"target\":\"/\"}' " \
    "scanner trivy asset '{\"type\":\"filesystem\",\"target\":\"/\"}' " \
    "scanner trufflehog asset '{\"type\":\"filesystem\",\"target\":\"/\"}' " \
    "scanner trufflehog asset '{\"type\":\"repository\",\"target\":\"https://github.com/DefectDojo/django-DefectDojo.git\",\"local\":\"django-DefectDojo\",\"clone\":{\"branch\":\"main\",\"args\":[\"--depth=1\"]},\"branches\":[\"main\"]}' " \
    "scanner trufflehog asset '{\"type\":\"docker:image\",\"target\":\"defectdojo/django-DefectDojo\",\"tags\":[\"latest\"]}'"


clear; ./ywt.sh async \
    "scanner cloc asset '{\"type\":\"filesystem\",\"target\":\"/\"}'" \
    "scanner trivy asset '{\"type\":\"filesystem\",\"target\":\"/\"}'" \
    "scanner trufflehog asset '{\"type\":\"filesystem\",\"target\":\"/\"}'"
clear; ./ywt.sh scan apply ./assests-to-scan.json
clear; ./ywt.sh scanner cloc asset "{\"type\":\"filesystem\",\"target\":\"/\"}" & \
    ./ywt.sh scanner trivy asset "{\"type\":\"filesystem\",\"target\":\"/\"}" & \
    ./ywt.sh scanner trufflehog asset "{\"type\":\"filesystem\",\"target\":\"/\"}" & \
    wait
```
> **2004.04.04**
```shell
clear; ./ywt.sh spinner examples
clear; ./ywt.sh spinner spin $$ "dd" 
clear; ./ywt.sh spinner random
clear; ./ywt.sh spinner names
# run from bundle
clear; chmod +x ./src/sdk.sh; ./src/sdk.sh async "sleep 1; echo Task 1 completed" "sleep 2; echo Task 2 completed; exit 1"  "sleep 1; echo Task 3 completed"
clear; ./ywt.sh builder bundle ./sdk/sdk.sh
# ydk included in the async command, you can use any command from the ywt.sh
clear; ./ywt.sh async "sleep 1; ywt inspect"
```
> **2024.04.03**
```shell
clear; ./ywt.sh async "sleep 1; ./ywt.sh inspect" "sleep 15; ./ywt.sh inspect"
clear; ./ywt.sh async "sleep 2; echo Task 1 completed" "sleep 4; echo Task 2 completed; exit 1"  "sleep 6; echo Task 3 completed"
clear; ./ywt.sh builder bundle ./sdk/sdk.sh
```
> **2024.04.02**
```shell
clear; ./ywt.sh scan apply ./assests-to-scan.json
clear; ./ywt.sh scan summary ./assests-to-scan.json
clear; ./ywt.sh scan plan ./assests-to-scan.json
clear; ./ywt.sh scanner inspect cloc
clear; ./ywt.sh scanner list
```
> **2024.04.01**
```shell
clear; ./ywt.sh scanner inspect trufflehog
clear; ./ywt.sh scanner list
clear; ./ywt.sh scanner cloc /ywt-workdir
clear; ./ywt.sh scanner trufflehog filesystem /ywt-workdir
clear; ./ywt.sh scanner trufflehog docker --image=ywt-shell:latest
clear; ./ywt.sh scanner trivy fs /ywt-workdir
clear; ./ywt.sh scanner trivy image ywt-shell:latest
```

> **2024.03.22**
```shell
clear; ./ywt.sh scanner cloc /ywt-workdir
clear; ./ywt.sh scanner trivy fs /ywt-workdir
clear; ./ywt.sh scanner trivy image ywt-shell:latest
clear; ./ywt.sh scanner trufflehog docker --image=ywt-shell:latest
clear; ./ywt.sh scanner trufflehog filesystem /ywt-workdir
clear; ./ywt.sh scanner trufflehog syslog
```


> **2024.03.22**
```shell
# parse without validade
clear; ./ywt.sh param kv --default value --required --name key3 -- --default value --required --name key4

# parse with validade
clear; ./ywt.sh param kv --validate --required --name key2
```


> **Caption:** This is the caption for the code block
```bash
# build
clear; ./ywt.sh builder _build_sdk
# test src
chmod +x ./src/ywt.sh; clear; ./src/ywt.sh  inspect
# test dist
chmod +x ./dist/ywt.sh; clear; ./dist/ywt.sh  inspect
# test bin
clear; ./bin/ywt inspect
clear; ./ywt.sh tests unit sdk:require
clear; ./ywt.sh debugger watch #tail -f /tmp/ywt-debug
clear; ./ywt.sh --trace --debug --logger inspect --param=key:value --paramkey3:value -p=key1:value -pkey2:value 
docker build --no-cache -f docker/ywt-shell/Dockerfile.alpine .
docker image prune -af  && docker compose -f docker/compose.yaml build && docker images -a
docker run --rm -ti ywt-shell /bin/bash -c "source /usr/local/bin/ywt-shell/ywt.sh && ywt inspect"
```

```shell
clear; ./ywt.sh inspect --flag --flag-value=value kv=key:value kv=key2:value


docker image prune -af  && docker compose  build && docker images -a
clear; docker run --rm -ti ywt-shell /bin/bash -c "source /usr/local/bin/ywt-shell/ywt.sh && ywt tests unit fetch get"

clear; ./ywt.sh fetch get https://jsonplaceholder.typicode.com/todos/1
clear; ./ywt.sh tests unit fetch get
```

```shell
local PARAMS=$({
    param json -r -n key -- \
        --required --name key2 -- \
        --required --name key3 -- \
        --default value --required --name key4 -- \
        --type number --default value --required --name key5 -- \
        --message "custom message" --type number --default value --required --name key6
})
if ! param validate "$PARAMS"; then return 1; fi
echo "$PARAMS" | jq -C .

[YWT] [958564] [2024-03-22 23:15:20] [ERROR] [INSPECT] 🚨 3 Invalid parameters [0003]
[YWT] [958564] [2024-03-22 23:15:21] [ERROR] [INSPECT] 🚨 (--kv=key3: ) is required to inspect [0003]
[YWT] [958564] [2024-03-22 23:15:21] [ERROR] [INSPECT] 🚨 (--kv=key5: value) must be a number [0003]
[YWT] [958564] [2024-03-22 23:15:21] [ERROR] [INSPECT] 🚨 (--kv=key6: value) must be a number [0003]
 ```


# return array of resources
# resources packages
# resources tools
# resources scripts
# resources extensions
