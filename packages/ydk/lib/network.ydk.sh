# #!/usr/bin/env bash
# # shellcheck disable=SC2044,SC2155,SC2317
# network() {
#     info() {
#         local IP=$(hostname -I | awk '{print $1}')
#         local MAC=""
#         local GATEWAY=""
#         if command -v ip >/dev/null 2>&1; then
#             GATEWAY=$(ip route | awk '/default/ {print $3}')
#             MAC=$(ip link show | awk '/link\/ether/ {print $2}')
#         fi
#         local DNS=$(awk '/nameserver/ {print $2}' </etc/resolv.conf)
#         local PUBLIC_IP=$(curl -s ifconfig.me)
#         echo "{
#             \"ip\": \"$IP\",
#             \"mac\": \"$MAC\",
#             \"gateway\": \"$GATEWAY\",
#             \"dns\": \"$DNS\",
#             \"public_ip\": \"$PUBLIC_IP\"
#         }"
#     }
#     ioc nnf "$@" || usage "network" "$?" "$@" && return 1
# }
# (
#     export -f network
# )
