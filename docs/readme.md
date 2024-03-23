# ywt.sh | yw-sh

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
