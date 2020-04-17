#!/bin/sh

# LOCALSTACK_HOST = docker machine ip이다 (ex: windows = 192.168.99.100, mac, linux = localhost)
LOCALSTACK_HOST_IP=${LOCALSTACK_HOST:-localhost}

LocalstackLive=$(curl -s -o /dev/null -w "%{http_code}" $LOCALSTACK_HOST_IP:4572)
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')

S3_BUCKET_NAME=${S3_BUCKET:-my-bucket}
LAMBDA_ROLE_NAME=${LAMBDA_ROLE:-lambda-ex}
KINESIS_DATA_STREAM_NAME=${KINESIS_DATA_STREAM:-web-log-stream}

if [ $LocalstackLive = 200 ]; then
	echo "[$CURRENT_DATE] LOCALSTACK AWS에 resource 생성..."

	# S3 bucket 생성
	if aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4572 s3 ls "s3://$S3_BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'
	then
		aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4572 s3 mb s3://$S3_BUCKET_NAME
	fi


	# Lambda 실행 Role 생성
	if [ "$(aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4593 iam list-roles --query "Roles[?RoleName == '$LAMBDA_ROLE_NAME']" | head -c 10)" = '[]' ]; then
		 aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4593 iam create-role --role-name $LAMBDA_ROLE_NAME --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
	else
		 aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4593 iam update-assume-role-policy --role-name $LAMBDA_ROLE_NAME --policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
	fi

	aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4593 iam attach-role-policy --role-name $LAMBDA_ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

	# Kinesis Data stream 생성
	if aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4568 kinesis describe-stream --stream-name $KINESIS_DATA_STREAM_NAME 2>&1 | grep -q 'ResourceNotFoundException'
	then
		aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4568 kinesis create-stream --stream-name $KINESIS_DATA_STREAM_NAME --shard-count 1
	fi

	# Lambda Function 생성
	if aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4574 lambda get-function --function-name stream-transformation 2>&1 | grep -q 'ResourceNotFoundException'
	then
		aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4574 lambda create-function --function-name stream-transformation --zip-file fileb:///root/lambda.zip --handler index.handler --runtime nodejs12.x --role $(aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4593 iam get-role --role-name $LAMBDA_ROLE_NAME --query "Role.Arn" --output text --no-paginate)
	fi

	# Lambda Kinesis에 event-source-mapping
	if [ "$(aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4574 lambda list-event-source-mappings --function-name stream-transformation --query "EventSourceMappings")" = '[]' ];
	then
		aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4574 lambda create-event-source-mapping --function-name stream-transformation --event-source-arn $(aws --endpoint-url=http://$LOCALSTACK_HOST_IP:4568 kinesis describe-stream --stream-name $KINESIS_DATA_STREAM_NAME --query "StreamDescription.StreamARN" --output text --no-paginate) --batch-size 100 --starting-position TRIM_HORIZON
	fi

	echo "[$CURRENT_DATE] LOCALSTACK AWS에 resource 생성 완료"

else
	echo "[$CURRENT_DATE][ERROR] LOCALSTACK이 실행된 환경이어야 합니다."
fi

