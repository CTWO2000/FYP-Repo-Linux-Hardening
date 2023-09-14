#!/bin/bash



sed -i.bak 's/root:x:0:0:root:\/root:.*/root:x:0:0:root:\/root:\/sbin\/nologin/' /etc/passwd


