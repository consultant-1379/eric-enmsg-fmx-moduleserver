#!/bin/bash

CPP_BLOCK_MODULE_GIT="/ericsson/tor/data/fmx/moduleserver/repos/cpp-block-module.git"
LOADED_CPP_BLOCK_MODULE="/ericsson/tor/data/fmx/modules/cpp-block-module"
CONSTANT_PERL_MODULE="/lib/perl5/vendor_perl/IO/Tty"
PTY_PERL_MODULE="/lib/perl5/vendor_perl/IO"
TTY_PERL_MODULE="/lib/perl5/vendor_perl/IO"
TTY_SHARED_OBJECT="/lib/perl5/vendor_perl/auto/IO/Tty"
RIJNDAEL_PERL_MODULE="/lib/perl5/vendor_perl/Crypt"
RIJNDAEL_SHARED_OBJECT="/lib/perl5/vendor_perl/auto/Crypt/Rijndael"
CPP_BLOCK_CONFIG="/cpp-block-module.cfg"
REMOTE_CPP_COMMAND="/remoteCppCmd.pl"

is_module_cpp_block_module_extracted() {
    if [ -f "${CPP_BLOCK_MODULE_GIT}${CONSTANT_PERL_MODULE}/Constant.pm" ] && \
   [ -f "${CPP_BLOCK_MODULE_GIT}${PTY_PERL_MODULE}/Pty.pm" ] && \
   [ -f "${CPP_BLOCK_MODULE_GIT}${TTY_PERL_MODULE}/Tty.pm" ] && \
   [ -f "${CPP_BLOCK_MODULE_GIT}${TTY_SHARED_OBJECT}/Tty.so" ] && \
   [ -f "${CPP_BLOCK_MODULE_GIT}${RIJNDAEL_PERL_MODULE}/Rijndael.pm" ] && \
   [ -f "${CPP_BLOCK_MODULE_GIT}${RIJNDAEL_SHARED_OBJECT}/Rijndael.so" ]; then
        return 0
    else
        return 1
    fi
}

update_config() {
    sed -i "s/AMOS_SERVERS=.*/AMOS_SERVERS=amos-0,amos-1/g" "$1"
}

update_script_from_tmpnam_to_tempfile() {
    sed -i "s/use POSIX qw(tmpnam);/use File::Temp qw\/tempfile\/;/g" "$1"
    sed -i "s/my \$tmpname =\"\"\;/my (\$fh, \$tmpname) = tempfile()\;/g" "$1"
    sed -i '/do { $tmpname = tmpnam() }/d' "$1"
    sed -i '/until \$fh = IO::File->new(\$tmpname, O_RDWR\|O_CREAT\|O_EXCL)\;/d' "$1"
}

overwrite_perl_modules_with_sles_compatible_versions() {
    cp /var/tmp/Constant.pm "$1${CONSTANT_PERL_MODULE}"
    cp /var/tmp/Pty.pm "$1${PTY_PERL_MODULE}"
    cp /var/tmp/Tty.pm "$1${TTY_PERL_MODULE}"
    cp /var/tmp/Tty.so "$1${TTY_SHARED_OBJECT}"
    cp /var/tmp/Rijndael.pm "$1${RIJNDAEL_PERL_MODULE}"
    cp /var/tmp/Rijndael.so "$1${RIJNDAEL_SHARED_OBJECT}"
}

update_cpp_block_files(){
    logger "Updating cpp-block-module Perl modules and the config file ($1 Module)"
    overwrite_perl_modules_with_sles_compatible_versions $2
    update_config "$3"
    update_script_from_tmpnam_to_tempfile "$4"
    logger "cpp-block-module module successfully updated. ($1 Module)"
}

retry=1
while [ $retry -le 60 ]; do
    if is_module_cpp_block_module_extracted; then
        # Update cpp-block-module if the module is already loaded.
        if [ -d "$LOADED_CPP_BLOCK_MODULE" ]; then
            update_cpp_block_files "Loaded" "${LOADED_CPP_BLOCK_MODULE}" "${LOADED_CPP_BLOCK_MODULE}${CPP_BLOCK_CONFIG}" "${LOADED_CPP_BLOCK_MODULE}${REMOTE_CPP_COMMAND}"
        fi

        # Update the cpp-block-module in cpp-block-module.git
        update_cpp_block_files "Non-Loaded" "${CPP_BLOCK_MODULE_GIT}" "${CPP_BLOCK_MODULE_GIT}${CPP_BLOCK_CONFIG}" "${CPP_BLOCK_MODULE_GIT}${REMOTE_CPP_COMMAND}"
        exit 0
    else
        logger "cpp-block-module modules have not been extracted yet. Will retry in 30 seconds"
        ((retry++))
        sleep 30
    fi
done

logger "The cpp-block-module was not extracted after 30 minutes."
exit 1