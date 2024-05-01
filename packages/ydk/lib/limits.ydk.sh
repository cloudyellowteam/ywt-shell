#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:limits() {
    current() {
        # Display Current Limits
        ulimit -a | awk '{print $1 " " $3}' | grep -v "unlimited" | awk '{print $1 " " $2}' | sed -e 's/ /: /' >&4
    }
    set() {
        ulimit -Sn 1024 # Set soft limit
        ulimit -Hn 4096 # Set hard limit
        # Set Limits
        ulimit -c 0
        ulimit -d 0
        ulimit -f 0
        ulimit -l 64
        ulimit -m 0
        ulimit -n 1024
        ulimit -q 0
        ulimit -s 1024
        ulimit -t 20
        ulimit -u 40
        ulimit -v 4000000
        ulimit -x 0
        ulimit -T 0
        ulimit -I 3
        ulimit -l 64
        ulimit -p 20
        ulimit -i 30
        ulimit -o 40
        ulimit -r 0
        ulimit -e 0
        ulimit -k 0
        ulimit -c 0
        ulimit -f 0
        ulimit -t 20
        ulimit -v 4000000
        ulimit -n 1024
        ulimit -m 0
        ulimit -u 40
        ulimit -s 1024
        ulimit -l 64
        ulimit -p 20
        ulimit -i 30
        ulimit -o 40
        ulimit -r 0
        ulimit -q 0
        ulimit -e 0
        ulimit -k 0
        ulimit -x 0
        ulimit -T 0
        ulimit -I 3
    } >&4
    ydk:try "$@" 4>&1
    return $?
}

# Understanding ulimit
# ulimit allows the control of resources available to the shell and to processes started by it, depending on the system limits and user permissions. These resources include:

# Maximum size of the core file.
# Maximum size of a process’s data segment.
# Maximum size of the files created by the shell.
# Maximum size that may be locked into memory.
# Maximum number of open file descriptors.
# And many more...

# ulimit Configuration
# Limits set by ulimit are typically reset on logout or reboot, so if you need to make permanent changes, these would generally be configured in one of your system's startup files:

# Login shell limits: Set in /etc/security/limits.conf or /etc/security/limits.d/*.conf on systems using PAM (Pluggable Authentication Modules). This method sets limits at login, and is often used to configure limits for sessions started by login services like sshd or local terminals.

# Example: /etc/security/limits.conf
# *               soft    nofile          1024
# *               hard    nofile          4096

# System-wide limits for services not using PAM: Set limits in the service configuration for systemd. For example, for a service:

# Example: /etc/systemd/system/myservice.service
# [Service]
# LimitNOFILE=4096

# Common Use Cases and Considerations
# Security and Stability: Setting resource limits can help protect against certain types of denial-of-service attacks (DoS) where processes consume excessive amounts of system resources.
# Application Requirements: Some applications, particularly file-serving applications and databases, might require adjustments to the default resource limits, such as increasing the maximum number of open files.
# Development and Testing: Developers can use ulimit to test software behavior under resource constraints.
# Checking If ulimit is Available
# Since ulimit is built into many shells, you can check its availability by simply typing ulimit or help ulimit in your terminal. If you're using a shell that supports it (like Bash or Dash), you'll see a list of options and current limits.


