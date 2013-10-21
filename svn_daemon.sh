#!/bin/sh

DIR=$(cd $(dirname "$0"); pwd)

mkdir -p svn_files/

echo ${DIR}

svnadmin create ${DIR}/svn_files

cp ${DIR}/svnserve.conf ${DIR}/svn_files/conf

svnserve -d -r ${DIR}/svn_files
