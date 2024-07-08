#!/bin/sh

THIS_SCRIPT="$(realpath "$0")"
TOP_SUBNET="172.31.0.0/16"
SUB_SUBNET="172.31.0.0/24"

do_default()
{
    # shellcheck disable=SC2154
    if ! [ -s "${XDG_RUNTIME_DIR}/docker.pid" ] ; then
        return 0
    fi
    if [ -z "$(docker network ls --filter 'name=^lan-only$' -q || true)" ] ; then
        docker network create -d bridge --subnet="${TOP_SUBNET}" --gateway=172.31.0.1 \
            --opt "com.docker.network.bridge.enable_icc=true" \
            --opt "com.docker.network.bridge.enable_ip_masquerade=true" \
            --opt "com.docker.network.bridge.host_binding_ipv4=0.0.0.0" \
            --opt "com.docker.network.bridge.name=docker31" \
            --opt "com.docker.network.driver.mtu=1500" \
            lan-only
    fi
    nsenter -U --preserve-credentials -n -m -t "$(cat "${XDG_RUNTIME_DIR}/docker.pid" || true)" \
        "${THIS_SCRIPT}" iptables_add "$@"
}

do_iptables_add()
{
    set -x
    iptables -F DOCKER-USER
    iptables -A DOCKER-USER -s "${SUB_SUBNET}" -d 192.168.0.0/16 -j RETURN
    iptables -A DOCKER-USER -s "${SUB_SUBNET}" -d 172.16.0.0/12 -j RETURN
    iptables -A DOCKER-USER -s "${SUB_SUBNET}" -d 10.0.0.0/8 -j RETURN
    iptables -A DOCKER-USER -s "${SUB_SUBNET}" -j REJECT --reject-with icmp-port-unreachable
    iptables -A DOCKER-USER -j RETURN
    iptables-save >&2
}

case "$1" in
iptables_add)
    shift 1
    do_iptables_add "$@"
    ;;
*)
    do_default "$@"
    ;;
esac

exit $?
