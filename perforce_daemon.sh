#!/bin/sh

DIR=$(cd $(dirname "$0"); pwd)

mkdir -p perforce_files/root

echo ${DIR}

p4d -r ${DIR}/perforce_files/root -J ${DIR}/perforce_files/journal -L ${DIR}/perforce_files/p4err -p tcp:1666 &
