#!/bin/bash
LOCALSTACK_HOST_IP=${LOCALSTACK_HOST:-localhost}
KINESIS_STREAM_NAME=${KINESIS_STREAM:-web-log-stream}
count=0
successCount=0
failedCount=0

cat /var/log/nginx/access.log | while read line
do
	RAND=`openssl rand -hex 12`
	/usr/bin/aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4568 kinesis put-record --stream-name $KINESIS_STREAM_NAME --partition-key "${RAND}" --data "${line}"
	if [ $? = 0 ];then
		((successCount++))
	else
		((failedCount++))
	fi
	((count++))
done

if [ $count = $successCount ];then
	cat /dev/null > /var/log/nginx/access.log
fi

echo "Total Log=$count, Success=$successCount, Failed=$failedCount"
