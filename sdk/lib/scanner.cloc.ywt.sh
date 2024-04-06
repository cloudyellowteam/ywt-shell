#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
__scanner:cloc() {
    local DEFAULT_ARGS=(
        "--json"
        "--quiet"
        "--exclude-dir=sys,.git,vendor,node_modules,tests,tests-*,test,tests-*,.git,.github,.vscode,.idea,build,dist,docs,examples,examples-*,samples,spec,specs,spec-*,specs-*,tmp,log,logs,cache,bin,lib,libs,src,assets,resources,static,public,web,webroot,webapp,webapps,webroot,webroots,app,apps,app-*,apps-*,dist,build,builds,deploy,deploys,deployment,deployments,release,releases,backup,backups,backup-*,backups-*,temp,temporary,template,templates,config,configs,configuration,configurations,settings,setting,settings-*,setting-*,conf,confs,conf-*,confs-*,env,envs,env-*,envs-*,log,logs,log-*,logs-*,tmp,temp,tmp-*,temp-*,cache,caches,cache-*,caches-*,data,datas,data-*,datas-*,db,dbs,db-*,dbs-*,database,databases,database-*,databases-*,doc,docs,doc-*,docs-*,document,documents,document-*,documents-*,image,images,image-*,images-*,img,imgs,img-*,imgs-*,media,medias,media-*,medias-*,video,videos,video-*,videos-*,audio,audios,audio-*,audios-*,bin,binaries,binary,binaries-*,binary-*,lib,libs,lib-*,libs-*,libra"
    )
    cloc:install() {
        curl -sSfL https://raw.githubusercontent.com/AlDanial/cloc/master/cloc -o /usr/local/bin/cloc
        chmod +x /usr/local/bin/cloc
    }
    cloc:uninstall() {
        rm -f /usr/local/bin/cloc
    }
    cloc:cli() {
        __scanner:cli "cloc" "${DEFAULT_ARGS[@]}" "$@"
    }
    cloc:version() {
        cloc:cli --version
        return 0
    }
    cloc:metadata() {
        {
            echo -n "{"
            echo -n "\"uuid\":\"cbb46398-a79e-4afe-9672-badabf6075e7\","
            echo -n "\"capabilities\":[\"filesystem\"],"
            echo -n "\"features\":[\"lines-of-code\", \"files\", \"languages\"],"
            echo -n "\"engines\":[\"host\",\"docker\",\"npx\"],"
            echo -n "\"formats\":[\"json\",\"text\"],"
            echo -n "\"priority\":1,"
            echo -n "\"tool\":{"
            echo -n "\"driver\":{"
            echo -n "\"name\":\"cloc\","
            echo -n "\"informationUri\":\"https://github.com/AlDanial/cloc\","
            echo -n "\"version\":\"1.90\""
            echo -n "} }"
            echo -n "}"
        } | jq -c .
        return 0
    }
    cloc:activate() {
        echo "{}"
        return 0
    }
    cloc:result() {
        jq -c . "$1"
    }
    cloc:summary() {
        [ ! -f "$1" ] && echo -n "{}" && return 0
        jq -c '
            . as $root |
            keys[] |
            select(. != "header" and . != "SUM") |
            {
                Language: .,
                Files: $root[.].nFiles,
                Blank: $root[.].blank,
                Comment: $root[.].comment,
                Code: $root[.].code
            }
        ' "$1"
    }
    cloc:asset() {        
        local ASSET="${1//\\\"/\"}" && shift
        if ! __is json "$ASSET"; then
            echo "{\"error\":\"Invalid asset\"}"
            return 1
        fi
        case "$(jq -r '.type' <<<"$ASSET")" in
        filesystem)
            local ASSET_PATH="$(jq -r '.target' <<<"$ASSET")"
            if [ ! -d "$ASSET_PATH" ]; then
                echo "{\"error\":\"Invalid asset path\"}"
                return 1
            fi
            cloc:cli "/ywt-workdir$ASSET_PATH"
            return 0
            ;;
        *)
            echo "{\"error\":\"Invalid asset type\"}"
            return 1
            ;;
        esac
    }
    # cloc:scan() {
    #     shift
    #     cloc:cli "$@"
    # }
    local ACTION="$1" && shift
    __nnf "cloc:$ACTION" "$@"
    return $?
    # case "$ACTION" in
    # activate)
    #     echo "{}"
    #     return 0
    #     ;;
    # *)
    #     __nnf "cloc:$ACTION" "$@"
    #     return $?
    #     ;;
    # esac
    # __nnf "cloc:$ACTION" "$@" || usage "__scanner:cloc" "$?" "$@" && return 1
}
