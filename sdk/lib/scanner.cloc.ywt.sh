#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2120,SC2155,SC2044
__scanner:cloc() {
    # local RESULT_FILE="$(mktemp -u -t XXXXXX --suffix=.cloc -p /tmp)"
    local SCANNER="$({
        echo -n "{"
        echo -n "\"scanner\":\"cloc\","
        echo -n "\"type\":\"code\","
        echo -n "\"format\":\"json\","
        echo -n "\"output\":\"$RESULT_FILE\","
        echo -n "\"start\":\"$(date +%s)\","
        echo -n "\"engines\":["
        echo -n "\"host\","
        echo -n "\"docker\","
        echo -n "\"npx\""
        echo -n "]"
    })"
    local DEFAULT_ARGS=(
        "--json"
        "--quiet"
        "--exclude-dir=.git,vendor,node_modules,tests,tests-*,test,tests-*,.git,.github,.vscode,.idea,build,dist,docs,examples,examples-*,samples,spec,specs,spec-*,specs-*,tmp,log,logs,cache,bin,lib,libs,src,assets,resources,static,public,web,webroot,webapp,webapps,webroot,webroots,app,apps,app-*,apps-*,dist,build,builds,deploy,deploys,deployment,deployments,release,releases,backup,backups,backup-*,backups-*,temp,temporary,template,templates,config,configs,configuration,configurations,settings,setting,settings-*,setting-*,conf,confs,conf-*,confs-*,env,envs,env-*,envs-*,log,logs,log-*,logs-*,tmp,temp,tmp-*,temp-*,cache,caches,cache-*,caches-*,data,datas,data-*,datas-*,db,dbs,db-*,dbs-*,database,databases,database-*,databases-*,doc,docs,doc-*,docs-*,document,documents,document-*,documents-*,image,images,image-*,images-*,img,imgs,img-*,imgs-*,media,medias,media-*,medias-*,video,videos,video-*,videos-*,audio,audios,audio-*,audios-*,bin,binaries,binary,binaries-*,binary-*,lib,libs,lib-*,libs-*,libra"
    )
    if __is command cloc; then
        local VERSION=$(cloc --version)
        SCANNER+="$({
            echo -n ",\"engine\":\"host\""
            echo -n ",\"version\":\"$VERSION\""
        })"
        cloc "${DEFAULT_ARGS[@]}" "$@" >"$RESULT_FILE"
    elif __is command docker; then
        local VERSION=$(docker run "${DOCKER_ARGS[@]}" cloc --version)
        SCANNER+="$({
            echo -n ",\"engine\":\"docker\""
            echo -n ",\"version\":\"cloc@$VERSION\""
        })"
        docker run "${DOCKER_ARGS[@]}" cloc "${DEFAULT_ARGS[@]}" "$@" >"$RESULT_FILE"
    elif __is command npx; then
        SCANNER+=",\"engine\":\"npx\""
        SCANNER+=",\"version\":\"$(npx --yes --quiet cloc --version)\""
        npx cloc "${DEFAULT_ARGS[@]}" "$@" >"$RESULT_FILE"
    else
        SCANNER+=",\"error\":\"cloc not found\""
    fi
    if jq . "$RESULT_FILE" >/dev/null 2>&1; then
        SCANNER+=",\"result\":$(jq . "$RESULT_FILE")"
        local IS_JSON=true
    else
        local CONTENT=$(cat "$RESULT_FILE")
        local IS_JSON=false
        CONTENT=$(
            {
                echo "$CONTENT"
            } | sed 's/"/\\"/g' |
                awk '{ printf "%s\\n", $0 }' |
                awk '{ gsub("\t", "\\t", $0); print $0 }' |
                sed 's/^/  /'
        )
        SCANNER+=",\"text\":\"string\""
    fi
    echo "${SCANNER}, \"end\":\"$(date +%s)\"}" | jq -c .
    [ "$IS_JSON" = false ] && cat "$RESULT_FILE"
    return 0
}
