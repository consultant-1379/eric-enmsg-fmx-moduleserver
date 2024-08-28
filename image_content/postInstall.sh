#!/bin/bash
#
# TODO: This permissions setting shall be deprecated whenever the ospackage permissions bug is fixed
chown -R nmxadm:nmx /opt/ericsson/fmx/tools
chown -R nmxadm:nmx /etc/opt/ericsson/fmx/tools
chown -R nmxadm:nmx /opt/ericsson/fmx/configEnmCliCredentials

# add fmxstack to OCF resources
ln -s /opt/ericsson/fmx/tools/bin/fmxstack /usr/lib/ocf/resource.d/fmxstack
echo "copied fmxstack"
# add fmxstack-stop to non-standard pre-shutdown scripts for ConHAr
# see: https://confluence-nam.lmera.ericsson.se/display/TLT/ENM+High+Availability+in+Cloud+Deployment
if [[ ! -d /usr/lib/ocf/pre_shutdown/ ]]; then
    mkdir /usr/lib/ocf/pre_shutdown/
fi
ln -s /opt/ericsson/fmx/tools/bin/fmxstack-stop /usr/lib/ocf/pre_shutdown/
echo "fmxstack-stop executed"
#
# Enable and start fmxstack-pacemaker at boot time
#
echo "before systemctl commands"
/usr/bin/systemctl daemon-reload
echo "before systemctl command-2"
/usr/bin/systemctl enable fmxstack-pacemaker.service
echo "before systemctl command-3"
/usr/bin/systemctl start fmxstack-pacemaker.service
echo "done execution"

