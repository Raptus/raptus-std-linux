#!/bin/bash

# has to be run in /opt
packlist="`yum list installed | grep 'php72-' | perl -pe 's/^php7.-(.*x86_64).*/php73-\1/'`"
yum install $packlist
ln -sfn /opt/remi/php73/root php7

# eof
