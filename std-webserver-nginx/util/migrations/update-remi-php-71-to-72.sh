#!/bin/bash

# has to be run in /opt
packlist="`yum list installed | grep 'php71-' | perl -pe 's/^php7.-(.*x86_64).*/php72-\1/'`"
yum install $packlist
ln -sfn /opt/remi/php72/root php7

# eof
