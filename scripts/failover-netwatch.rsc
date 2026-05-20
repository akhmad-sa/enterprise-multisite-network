# ==============================================================================
# Enterprise WAN Failover Automation Script via MikroTik Netwatch
# Architect: Akhmad Sholahuddin Arif
# Target Position: IT Operations / Systems Architect / Infrastructure Management
# Framework: Automated Fault Isolation & Session Persistence Recovery
# ==============================================================================
# Description:
# Dynamically monitors Primary ISP gateway health via public DNS validation.
# Implements anti-flapping protection (nested ping validation) to prevent
# erratic route table synchronization during intermittent brownouts.
# ==============================================================================

/tool netwatch
add comment="Enterprise Primary WAN Monitoring & Automated Failover Logic" \
    host=8.8.8.8 \
    interval=1m \
    timeout=1000ms \
    down-script="\
        :delay 5s; \
        :local pingCount [/ping 8.8.8.8 count=3]; \
        :if (\$pingCount = 0) do={ \
            /log warning \"[FAILOVER LOG] Primary Link (ISP-A) verification failed. Isolating fault...\"; \
            /ip route set [find comment=\"ISP-A-PRIMARY\"] distance=10; \
            /ip route set [find comment=\"ISP-B-BACKUP\"] distance=1; \
            /log warning \"[FAILOVER LOG] Successfully rerouted active corporate traffic to Backup Link (ISP-B).\"; \
        } \
    " \
    up-script="\
        :delay 5s; \
        :local pingCount [/ping 8.8.8.8 count=3]; \
        :if (\$pingCount > 0) do={ \
            /log info \"[FAILOVER LOG] Primary Link (ISP-A) heartbeats recovered. Restoring standard topology...\"; \
            /ip route set [find comment=\"ISP-A-PRIMARY\"] distance=1; \
            /ip route set [find comment=\"ISP-B-BACKUP\"] distance=2; \
            /log info \"[FAILOVER LOG] Core routing successfully synchronized back to Primary WAN.\"; \
        } \
    "
