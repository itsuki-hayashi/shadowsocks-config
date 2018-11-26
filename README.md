# shadowsocks-config
A script to help you to setup `shadowsocks-libev` + `simple-obfs` on Ubuntu 18.04.
It tries to provide a best practice for common shadowsocks config & optimization.

# Usage
```bash
    sudo setup.sh
    # Client configuration will be generated in ~/client.json, ss:// config in ~/ss-uri.txt
```
# What It Does
1. Install packages.
2. Tune kernel parameters for better performance & security.
3. Generate password & setup shadowsocks-libev + simple-obfs server.
4. Generate client config.

# Packages Installed
 1. shadowsocks-libev: Provides PSK-encrypted SOCKSv5 proxy.
 2. simple-obfs: Obfuscation to protect against DPI. TLS mode is used.
 3. haveged: Provide more entropy in cloud environment for safe password generation.
 4. curl: Used for discover the public IP address of the server to generate client config.