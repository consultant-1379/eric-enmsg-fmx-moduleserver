#!/bin/bash
umask 002
/sbin/rsyslogd -i /tmp/rsyslogd.pid
/opt/ericsson/fmx/tools/bin/nmx.sh
/var/run/fmx/scripts/fmx_preconfig.sh
/var/run/fmx/scripts/enable_jmx_opts.sh "/opt/ericsson/fmx/moduleserver/bin/fmxms.sh" 9092
/var/run/fmx/scripts/fmx_cpp_block_config.sh &
/opt/ericsson/fmx/moduleserver/bin/fmxms.sh
