# ywt.sh | yw-sh


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



# return array of resources
# resources packages
# resources tools
# resources scripts
# resources extensions
