# ywt.sh | yw-sh
```shell
  git config --global user.email "raphaelcarlosr@gmail.com"
  git config --global user.name "Raphael C Rego"
```

> **2024.04.30**
```shell

clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir kalilinux/kali-rolling bash -c 'clear; packages/ydk/ydk.cli.sh install'

clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir ubuntu:20.04 bash -c 'clear; packages/ydk/ydk.cli.sh install'

clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir alpine:3.14 sh -c 'apk add --update > /dev/null && apk add --no-cache bash; clear; packages/ydk/ydk.cli.sh install' 

clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir alpine:3.14
clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir kalilinux/kali-rolling
clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir ubuntu:20.04

clear; packages/ydk/ydk.cli.sh install
clear; packages/ydk/ydk.cli.sh secops scanners install cloc
clear; packages/ydk/ydk.cli.sh upm detect
clear; packages/ydk/ydk.cli.sh upm installed
clear; packages/ydk/ydk.cli.sh upm install cloc
clear; packages/ydk/ydk.cli.sh upm uninstall cloc
clear; packages/ydk/ydk.cli.sh upm $(! command -v cloc > /dev/null && echo "install" || echo "uninstall") cloc

```


> **2024.04.29**
```shell
clear; ./packages/ydk/ydk.cli.sh assets location spinners
clear; ./packages/ydk/ydk.cli.sh assets download
clear; ./packages/ydk/ydk.cli.sh assets get spinners emojis

# install on kali
clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir kalilinux/kali-rolling bash -c "packages/ydk/ydk.cli.sh install && packages/ydk/ydk.cli.sh secops scanners install cloc"
# install on ubuntu
# apt-get update > /dev/null && apt-get install -y bash && 
clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir ubuntu:20.04 bash -c "packages/ydk/ydk.cli.sh install && packages/ydk/ydk.cli.sh secops scanners install cloc"
# install on alpine
clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir alpine:3.14  sh -c "apk add --update > /dev/null && apk add --no-cache bash > /dev/null && packages/ydk/ydk.cli.sh install && packages/ydk/ydk.cli.sh secops scanners install cloc"
```


> **2024.04.28**
```shell

clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir alpine:3.14
clear; docker run --rm -it -v $(pwd):/ywt-workdir -w /ywt-workdir alpine:3.14  sh -c "apk add --update > /dev/null && apk add --no-cache bash > /dev/null && packages/ydk/ydk.cli.sh install && packages/ydk/ydk.cli.sh packer defaults"

clear; ./packages/ydk/ydk.cli.sh packer pack ./packages/ydk/ydk.cli.sh
clear; ./packages/ydk/ydk.cli.sh packer defaults
clear; ./packages/ydk/ydk.cli.sh screen expectSize 101 39
clear; ./packages/ydk/ydk.cli.sh screen size 
clear; ./packages/ydk/ydk.cli.sh screen defaults

```

> **2024.04.26**
```shell
clear; ./packages/ydk/ydk.cli.sh builder 
# bundle a package, it's generate ydk.sh file
clear; ./packages/ydk/ydk.cli.sh bundle pack ./packages/ydk/ydk.cli.sh
# compile a bundle 
clear; ./packages/ydk/ydk.cli.sh bundle compile ./packages/ydk/ydk.sh 31/12/2999
# pack and build a bundle
clear; ./packages/ydk/ydk.cli.sh bundle build ./packages/ydk/ydk.cli.sh 31/12/2999




clear; ./packages/ydk/ydk.cli.sh secops plan  /workspace/rapd-shell/assets/assests.json
clear; ./packages/ydk/ydk.cli.sh secops api fetch cloc/version
clear; ./packages/ydk/ydk.cli.sh emojis get "satellite" && echo 
clear; ./packages/ydk/ydk.cli.sh emojis list
clear; ./packages/ydk/ydk.cli.sh emojis substr "Hello from mars :satellite:" && echo 
clear; ./packages/ydk/ydk.cli.sh styles hyperlink "http://www.google.com" "text"
clear; ./packages/ydk/ydk.cli.sh styles list
clear; ./packages/ydk/ydk.cli.sh styles apply bold "bold text" && echo
clear; ./packages/ydk/ydk.cli.sh styles apply dim "dim text" && echo
clear; ./packages/ydk/ydk.cli.sh styles apply italic "italic text" && echo
clear; ./packages/ydk/ydk.cli.sh styles apply underline "underline text" && echo
clear; ./packages/ydk/ydk.cli.sh styles apply blink "blink text" && echo
clear; ./packages/ydk/ydk.cli.sh styles apply inverse "inverse text" && echo
clear; ./packages/ydk/ydk.cli.sh styles apply hidden "hidden text" && echo
clear; ./packages/ydk/ydk.cli.sh styles apply strikethrough "strikethrough text" && echo

echo "test" | ./packages/ydk/ydk.cli.sh logger "info"
echo "test" | ./packages/ydk/ydk.cli.sh logger "info" <&0
clear; ./packages/ydk/ydk.cli.sh logger "info" < <(jq -c . <<<"{\"test\": true, \"emoji\": \":satellite:\"}")
clear; ./packages/ydk/ydk.cli.sh logger -c test "info" "with test context"
clear; ./packages/ydk/ydk.cli.sh logger -f /tmp/custom.log "info" "to specific file"
clear; ./packages/ydk/ydk.cli.sh logger "trace" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger "debug" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger "info" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger "warn" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger "error" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger "success" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger "output" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger "panic" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger "fatal" "Yellow Team :satellite:"
clear; ./packages/ydk/ydk.cli.sh logger levels
clear; ./packages/ydk/ydk.cli.sh logger defaults
```

> **2024.04.25**
```shell
clear; ./packages/ydk/ydk.cli.sh logger levels
clear; ./packages/ydk/ydk.cli.sh secops api fetch cloc/version
clear; ./packages/ydk/ydk.cli.sh secops scanners list
clear; ./packages/ydk/ydk.cli.sh secops scanners get cloc
clear; ./packages/ydk/ydk.cli.sh secops scanners available
clear; ./packages/ydk/ydk.cli.sh secops scanners unavailable
clear; ./packages/ydk/ydk.cli.sh secops scanners install cloc ...
clear; ./packages/ydk/ydk.cli.sh secops scanners uninstall cloc ...
```


> **2024.04.24**
```shell
clear; ./packages/ydk/ydk.cli.sh secops api fetch cloc/version
clear; ./packages/ydk/ydk.cli.sh secops api fetch cloc/asset/filesystem/count-by-lang --target=.
clear; ./packages/ydk/ydk.cli.sh secops api fetch cloc/version
clear; ./packages/ydk/ydk.cli.sh secops api fetch cloc/asset/filesystem/count --target=.
clear; ./packages/ydk/ydk.cli.sh secops api endpoints cloc 
clear; ./packages/ydk/ydk.cli.sh secops cli cloc .
clear; ./packages/ydk/ydk.cli.sh secops cli cloc --version

```




> **2024.04.23**
```shell
clear; ./packages/ydk/ydk.cli.sh secops cli cloc --version
clear; ./packages/ydk/ydk.cli.sh secops api cloc/asset/filesystem/count --target=.
clear; ./packages/ydk/ydk.cli.sh secops api cloc/version 
clear; sleep 10 & SPID=$! && ./packages/ydk/ydk.cli.sh await spin $SPID "waiting for $SPID"
clear; ./packages/ydk/ydk.cli.sh await examples
clear; ./packages/ydk/ydk.cli.sh async "sleep 6 && echo 'task 1 completed'" "sleep 10; echo 'task 2 completed'" "sleep 30; echo 'task 3 completed'"
```
> **2024.04.22**
```shell
clear; ./packages/ydk/ydk.cli.sh async "sleep 60 && echo 'task 1 completed'" "sleep 60; echo 'task 65 completed'" "sleep 30; echo 'task 3 completed'"
clear; sleep 10 & SPID=$! && ./packages/ydk/ydk.cli.sh await spin $SPID "waiting for $SPID"
clear; ./packages/ydk/ydk.cli.sh await examples
clear; ./packages/ydk/ydk.cli.sh await spin PID MESSAGE
clear; ./packages/ydk/ydk.cli.sh await spinners random
clear; ./packages/ydk/ydk.cli.sh await spinners names
clear; ./packages/ydk/ydk.cli.sh await spinners list
clear; ./packages/ydk/ydk.cli.sh secops scanners install cloc
clear; ./packages/ydk/ydk.cli.sh upm install cloc
clear; ./packages/ydk/ydk.cli.sh upm upgrade cloc
clear; ./packages/ydk/ydk.cli.sh upm search cloc
clear; ./packages/ydk/ydk.cli.sh upm info cloc
clear; ./packages/ydk/ydk.cli.sh upm update
clear; ./packages/ydk/ydk.cli.sh upm upgrade_all
clear; ./packages/ydk/ydk.cli.sh upm installed
clear; ./packages/ydk/ydk.cli.sh upm uninstall cloc
```

> **2024.04.21**
```shell
clear; ./packages/ydk/ydk.cli.sh secops scanners manager install cloc trivy trufflehog 
clear; ./packages/ydk/ydk.cli.sh secops scanners manager uninstall cloc trivy trufflehog
clear; ./packages/ydk/ydk.cli.sh secops scanners install cloc trivy trufflehog 
clear; ./packages/ydk/ydk.cli.sh secops scanners uninstall cloc trivy trufflehog
clear; ./packages/ydk/ydk.cli.sh secops scanners unavailable
clear; ./packages/ydk/ydk.cli.sh secops scanners available
clear; ./packages/ydk/ydk.cli.sh secops scanners get cloc
clear; ./packages/ydk/ydk.cli.sh secops scanners list

clear; ./packages/ydk/ydk.cli.sh css scanner cloc
clear; ./packages/ydk/ydk.cli.sh analytics ga collect
```

> **2024.04.19**
```shell
clear; ./packages/ydk/ydk.cli.sh css scanner cloc
```

> **2024.04.18**
```shell
clear; ./packages/ydk/ydk.cli.sh css scanners
clear; ./packages/ydk/ydk.cli.sh installer install
clear; ./packages/ydk/ydk.cli.sh install
clear; ./packages/ydk/ydk.cli.sh upm detect | jq -s .

```

> **2024.04.17**
```shell
clear; ./packages/ydk/ydk.cli.sh logger watch
clear; ./packages/ydk/ydk.cli.sh logger --c=testing info test
clear; ./packages/ydk/ydk.cli.sh logger --c=test levels | jq -s '. | flatten' 
clear; ./packages/ydk/ydk.cli.sh upm detect | jq -s .
clear; ./packages/ydk/ydk.cli.sh upm cli | jq -s .
```

> **2024.04.16**
```shell
clear; ./packages/ydk/ydk.cli.sh logger --c=test levels | jq -s '. | flatten' 
```

> **2024.04.15**
```shell
clear; ./packages/ydk/ydk.cli.sh bundle pack ./packages/scanners/scanners.cli.sh
clear; ./packages/ydk/ydk.cli.sh bundle compile ./packages/scanners/scanners.sh 31/12/2999
clear; ./packages/ydk/ydk.cli.sh bundle build ./packages/scanners/scanners.cli.sh 31/12/2999
# run from binary
clear; /workspace/rapd-shell/packages/ydk/ydk.bin process inspect | jq .
# run from bundle
clear; /workspace/rapd-shell/packages/ydk/ydk.sh process inspect | jq .
# pack and build a bundle
clear; ./packages/ydk/ydk.cli.sh bundle build ./packages/ydk/ydk.cli.sh 31/12/2999
# compile a bundle 
clear; ./packages/ydk/ydk.cli.sh bundle compile ./packages/ydk/ydk.sh 31/12/2999
# bundle a package, it's generate ydk.sh file
clear; ./packages/ydk/ydk.cli.sh bundle pack ./packages/ydk/ydk.cli.sh
# load latest version
curl -sIX HEAD https://github.com/cloudyellowteam/ywt-shell/releases/latest | grep -i ^location: | grep -Eo '[0-9]+.[0-9]+.[0-9]+?-[a-z]+-[0-9]+'
```
> **2024.04.08**
```shell
clear; docker run --rm -it -w /ywt-workdir kalilinux/kali-rolling bash -c "apt-get update > /dev/null && apt-get install -y bash curl jq util-linux coreutils openssl bsdmainutils > /dev/null && curl -sO https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/packages/ydk/ydk.cli.sh && chmod +x ./ydk.cli.sh && ./ydk.cli.sh install"

clear; docker run --rm -it -w /ywt-workdir ubuntu:20.04 bash -c "apt-get update > /dev/null && apt-get install -y bash curl jq util-linux coreutils openssl bsdmainutils > /dev/null && curl -sO https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/packages/ydk/ydk.cli.sh && chmod +x ./ydk.cli.sh && ./ydk.cli.sh install"

clear; docker run --rm -it -w /ywt-workdir alpine:3.14 sh -c "apk add --update > /dev/null && apk add --no-cache bash curl jq util-linux coreutils openssl > /dev/null && curl -sO https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/packages/ydk/ydk.cli.sh && chmod +x ./ydk.cli.sh && ./ydk.cli.sh install"
```
> **2024.04.06**
```shell
clear; ./ydk.sh scan plan ./assets.json
clear; ./ydk.sh scan summary ./assets.json
clear; ./ydk.sh scan apply ./assets.json
# -v /var/run/docker.sock:/var/run/docker.sock \
# -v $(pwd):/ywt-workdir \
docker run --rm -it -w /ywt-workdir alpine:3.14

clear; docker run --rm -it -w /ywt-workdir alpine:3.14 sh -c "apk add --update > /dev/null && apk add --no-cache bash curl jq util-linux coreutils openssl > /dev/null && curl -sO https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/packages/ydk/ydk.cli.sh && chmod +x ./ydk.cli.sh && ./ydk.cli.sh install"

clear && \
apk add --update > /dev/null && \
apk add --no-cache bash curl jq util-linux coreutils openssl > /dev/null && \
curl -sO https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/packages/ydk/ydk.cli.sh &&
chmod +x ./ydk.cli.sh &&
./ydk.cli.sh install &&
./ydk.sh inspect


```
> **2024.04.05**
```shell
    apk add --update > /dev/null && \
    apk add --no-cache bash curl jq > /dev/null && \
    curl -sO https://raw.githubusercontent.com/cloudyellowteam/ywt-shell/main/src/ydk.sh &&
    chmod +x ./ydk.sh &&
    ./ydk.sh inspect

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
