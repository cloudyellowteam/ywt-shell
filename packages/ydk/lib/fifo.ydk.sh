#!/usr/bin/env bash
# shellcheck disable=SC2044,SC2155,SC2317
ydk:fifo() {
    stdin() {
        [ ! -p /dev/stdin ] && [ ! -t 0 ] && return "$1"
        while IFS= read -r INPUT; do
            echo "$INPUT" >&0
        done
        unset INPUT
    }
    stdout() {
        [ ! -p /dev/stdout ] && [ ! -t 1 ] && return "$1"
        while IFS= read -r OUTPUT; do
            echo "$OUTPUT" >&1
        done
        unset OUTPUT
    }
    stderr() {
        [ ! -p /dev/stderr ] && [ ! -t 2 ] && return "$1"
        while IFS= read -r ERROR; do
            echo "$ERROR" >&2
        done
        unset ERROR
    }
    stdvalue() {
        local STD="${1:-4}"
        [ -e /proc/$$/fd/"$STD" ] && echo "$@" >&"$STD" && return 0
        return 1
    }
    stdio() {
        stdin "$1" && stdout "$1" && stderr "$1"
    }
    descriptor() {
        exists() {
            [ -z "$1" ] && return 1
            [ -e /proc/$$/fd/"$1" ] && return 0 || return 1
            # { >&"$1"; } 2>/dev/null && return 0 || return 1
        }
        writable() {
            [ -z "$1" ] && return 1
            [ -w /proc/$$/fd/"$1" ] && return 0 || return 1
            { true >&"$1"; } 2>/dev/null && return 0 || return 1
        }
        readable() {
            [ -z "$1" ] && return 1
            [ -r /proc/$$/fd/"$1" ] && return 0 || return 1
            { true <&"$1"; } 2>/dev/null && return 0 || return 1
            read -t 0 <&"$1" && return 0 || return 1
        }
        opened() {
            [ -z "$1" ] && return 1
            [ -e /proc/$$/fd/"$1" ] && return 0 || return 1
            lsof -p $$ | grep " $1" && return 0 || return 1
        }
        ydk:try "$@"
        return $?
    }
    exists() {
        [ -p "$1" ] && return 0 || return 1
    }
    create() {
        [ -z "$1" ] && return 1
        mkfifo "$1" && return 0 || return 1
    }
    delete() {
        [ -z "$1" ] && return 1
        rm -f "$1" && return 0 || return 1
    }
    read() {
        [ -z "$1" ] && return 1
        [ -p "$1" ] && cat "$1" && return 0 || return 1
    }
    write() {
        [ -z "$1" ] && return 1
        [ -p "$1" ] && echo "$2" >"$1" && return 0 || return 1
    }
    writable() {
        [ -z "$1" ] && return 1
        [ -w "$1" ] && return 0 || return 1
    }
    readable() {
        [ -z "$1" ] && return 1
        [ -r "$1" ] && return 0 || return 1
    }
    opened() {
        [ -z "$1" ] && return 1
        lsof "$1" && return 0 || return 1
    }
    ydk:try "$@"
    return $?
}

# When working with mkfifo, also known as named pipes, it's essential to understand their purpose, usage, and best practices for storage and management. Named pipes are used to facilitate inter-process communication (IPC); data written to a named pipe by one process can be read by another process. The data is transient, meaning it doesn’t persist in the pipe after it has been read.

# Understanding mkfifo and Named Pipes
# 1. What is mkfifo?

# mkfifo creates named pipes, which are special types of files that act as FIFO (First In, First Out) queues. Unlike regular files, they are not stored on disk. Data written to a named pipe is buffered by the kernel until it is read by some process.

# 2. Usage of Named Pipes

# Named pipes are particularly useful for simple inter-process communication when you want to avoid more complex mechanisms like sockets or shared memory. For example, you can use a named pipe to pass output from one program directly into another program.

# bash
# Copy code
# mkfifo my_pipe
# command1 > my_pipe &  # Command1's output goes to named pipe
# command2 < my_pipe    # Command2 takes input from named pipe
# Best Practices for Storing mkfifo Pipes
# Where to Store:

# Temporary Files Directory (/tmp): This is a common location for named pipes when they are needed temporarily. The /tmp directory is cleaned up at boot or through a scheduled service, so pipes placed here should be used for short-lived tasks.
# Application-Specific Directories: If your application routinely uses named pipes for IPC, it’s better to create them in a directory dedicated to your application, preferably under /var/run (for system processes) or a user-specific runtime directory. Ensure that the directory permissions are set correctly to prevent unauthorized access.
# Home Directory: For user-specific scripts and processes, storing named pipes in a subdirectory within the user’s home directory can be practical. This isolates user processes from system processes.
# Permissions and Security:

# Permissions: Set appropriate permissions using chmod to restrict who can write to or read from the pipe. This is crucial for preventing unauthorized processes from injecting data or eavesdropping.
# bash
# Copy code
# mkfifo my_pipe
# chmod 600 my_pipe  # Only the owner can read and write
# Security Concerns: Consider security implications in multi-user environments. Named pipes are subject to various IPC security risks, including but not limited to squatting attacks (where an unauthorized process creates a pipe with the same name before the legitimate one does) and sniffing/interference by other processes.
# Descriptors and Their Management
# File Descriptors for Pipes:

# When a process opens a named pipe, it gets file descriptors for reading and/or writing:

# Read Descriptor (0 or STDIN for readers): Allows a process to read data sent to the pipe.
# Write Descriptor (1 or STDOUT for writers): Allows a process to send data to the pipe.
# Managing these descriptors correctly is essential, especially when dealing with daemon processes or scripts that run as services. Ensure that descriptors are not unnecessarily left open as they can lead to deadlocks or resource leaks.

# Example with Descriptors:

# bash
# Copy code
# exec 3<>my_pipe  # Open file descriptor 3 for reading and writing
# echo "Data" >&3  # Write to the pipe
# cat <&3          # Read from the pipe
# exec 3>&-        # Close the descriptor
# This script demonstrates opening a named pipe with an additional file descriptor (3), using it for both reading and writing, and then closing it properly.

# Conclusion:

# Named pipes (mkfifo) are a straightforward method for performing IPC that can be used effectively with proper understanding and management. Store them in locations that reflect their purpose—temporary for short-lived processes and dedicated directories for persistent usage. Always be aware of the security implications and manage permissions and file descriptors with care.
