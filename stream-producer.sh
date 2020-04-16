#!/bin/bash

cat /var/log/nginx/access.log | while read line
do
	RAND=`openssl rand -hex 12`
	echo `/usr/bin/aws --endpoint-url=http://192.168.99.100:4568 kinesis put-record --stream-name web-log-stream --partition-key "${RAND}" --data "${line}"`
done

cat /dev/null > /var/log/nginx/access.log
