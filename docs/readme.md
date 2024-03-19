# ywt.sh | yw-sh


```bash
# build
clear; ./sdk/sdk.sh builder _build_sdk
# test src
chmod +x ./src/ywt.sh; clear; ./src/ywt.sh  inspect
# test dist
chmod +x ./dist/ywt.sh; clear; ./dist/ywt.sh  inspect
# test bin
clear; ./bin/ywt inspect
clear; ./sdk/sdk.sh tests unit sdk:require
clear; ./sdk/sdk.sh debugger watch #tail -f /tmp/ywt-debug
clear; ./sdk/sdk.sh --trace --debug --logger inspect --param=key:value --paramkey3:value -p=key1:value -pkey2:value 

```


# return array of resources
# resources packages
# resources tools
# resources scripts
# resources extensions
