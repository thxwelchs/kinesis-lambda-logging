# 과제 검증

# **Kinesis lambda logging**

이 저장소는 AWS Kinesis Data Stream, Lambda, S3, Firehose, Terraform 등을 이용하여 웹 로깅 데이터 파이프라인을 구축 하는 것을 목표로 두고 있는 인프라 코드 관련 저장소입니다.

AWS infra mocking tool인 Localstack을 활용하였습니다.
인
## **Localstack 환경 구성**

Data pipeline diagram

![images/undefined_(2).png](Untitled/undefined_(2).png)

Localstack dashboard graph

![images/Untitled.png](Untitled/Untitled.png)

### AWS Resource 생성 절차

1. S3 Bucket 생성
2. Kinesis Data Stream 생성  
3. Lambda 함수 생성 (Runtime: Node.js 12.x)
4. 생성한 Lambda 함수 Kinesis Data Stream에 event-source mapping

### Data pipeline 절차

1. Node.js로 작성된 producer 역할의 애플리케이션이 1분 주기로 웹서버(nginx)의 접근 로그를 polling 하고 Kinesis에 record 저장 
2. Lambda 함수에 맵핑 되어 있는 설정에 따라 Stream에 데이터 저장 시 트리거링 되어 Lambda 함수 실행
3. S3 bucket에 UTC 타임 기준, YYYY/MM/DD/HH 의 key 기준으로 분리하여 log 저장 
(ex  2020/04/17/16/web-access.log, 2020년4월17일16시00분 ~ 2020년4월17일16시59분 까지의 로그 저장)

JSON Format

    { 
    	"host": "192.168.99.1",
    	"time": "2020-04-18T01:42:18.000Z",
    	"method": "GET",
    	"path": "/",
    	"httpVersion": "HTTP/1.1",
    	"status": 200,
    	"userAgent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36"
    }

### 검증

Localstack 실행
```shell
$ git clone https://github.com/thxwelchs/kinesis-lambda-logging
$ cd kinesis-lambda-logging
$ docker-compose up
```

![images/Untitled%201.png](Untitled/Untitled%201.png)

 

LOCALSTACK_HOST 환경 변수 값을 반드시 현재 docker-machine 의 ip로 pass, aws resource 를 생성하는 shell script에서 해당 값을 참조하게 되어 있습니다. (windows 일반적인 기준으로 192.168.99.100, mac, linux localhost일 시 생략 가능)

    $ docker run -d -p 80:80 -e LOCALSTACK_HOST=$(docker-machine ip) [thxwelchs/kinesis-lambda-logging](https://hub.docker.com/r/thxwelchs/kinesis-lambda-logging)

![images/Untitled%202.png](Untitled/Untitled%202.png)

위 컨테이너 실행 시

- S3 bucket 생성
- kinesis data stream 생성
- lambda 실행 role 생성, lambda function 생성, event-source-mapping 등록

```bash
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
```

resource 생성 확인

![images/Untitled%203.png](Untitled/Untitled%203.png)

![images/Untitled%204.png](Untitled/Untitled%204.png)

![images/Untitled%205.png](Untitled/Untitled%205.png)

![images/Untitled%206.png](Untitled/Untitled%206.png)

nginx 접속해서 access.log 발생

![images/Untitled%207.png](Untitled/Untitled%207.png)

access.log 확인 후 producer가 정상적으로 stream에 record로 등록하는지 확인

![images/Untitled%208.png](Untitled/Untitled%208.png)

![images/Untitled%209.png](Untitled/Untitled%209.png)

s3에 업로드 되었는지 확인 후 json화 되어있는지 확인

![images/Untitled%2010.png](Untitled/Untitled%2010.png)

![images/Untitled%2011.png](Untitled/Untitled%2011.png)

## 실제 AWS 환경 구성

![images/aws-kinesis.png](Untitled/aws-kinesis.png)

### AWS Resource 생성 절차

1. S3 Bucket 생성
2. stream data(firehose) transform lambda 함수 생성
3. Kinesis Firehose Stream 생성, Process records에 lambda 함수 등록, 목적지 S3로 설정 

### Data pipeline 절차

1. nginx가 설치된 EC2에서 shell script crontab 작업 설정 Kinesis firehose에 record 저장 
2. Lambda 함수 트리거링 후, S3에 저장
3. S3 bucket에 UTC 타임 기준, YYYY/MM/DD/HH 의 key 기준으로 분리하여 log 저장 
(ex  2020/04/17/16/web-access.log, 2020년4월17일16시00분 ~ 2020년4월17일16시59분 까지의 로그 저장)

위 구성대로 HCL 작성중...

> Link

Docker image: [https://hub.docker.com/r/thxwelchs/kinesis-lambda-logging](https://hub.docker.com/r/thxwelchs/kinesis-lambda-logging)

Dockerfile: [https://github.com/thxwelchs/kinesis-lambda-logging/blob/master/Dockerfile](https://github.com/thxwelchs/kinesis-lambda-logging/blob/master/Dockerfile)

producer code: [https://github.com/thxwelchs/kinesis-lambda-logging/blob/master/producer/index.js](https://github.com/thxwelchs/kinesis-lambda-logging/blob/master/producer/index.js)

lambda function code: [https://github.com/thxwelchs/kinesis-lambda-logging/blob/master/lambda/index.js](https://github.com/thxwelchs/kinesis-lambda-logging/blob/master/lambda/index.js)