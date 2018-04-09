#!/bin/bash

packlist="`yum list installed | grep 'php71-' | perl -pe 's/^php7.-(.*x86_64).*/php72-\1/'`"
yum install $packlist

# eof
