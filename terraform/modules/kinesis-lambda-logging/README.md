# AWS resource for the Nginx access.log collecting 

## This module will create next resources
- S3 Bucket
- Kinesis Data Stream
- Lambda function

## You must set next variables (See variables.tf for details.)
- lambda-endpoint (optional, If you want to use localstack you can set)
- stream-name (required)
- bucket-name (required)
- stream-shard-count (required)
- lambda-configurations (required)

## Lambda Event
The event will occur from a kinesis data stream. So, you must write code from the next event.
```json
{
    "Records": [
        {
            "kinesis": {
                "kinesisSchemaVersion": "1.0",
                "partitionKey": "1",
                "sequenceNumber": "49590338271490256608559692538361571095921575989136588898",
                "data": "MTkyLjE2OC45OS4xIC0gLSBbMTcvQXByLzIwMjA6MTQ6NTQ6MzYgKzAwMDBdICJHRVQgLyBIVFRQLzEuMSIgMzA0IDAgIi0iICJNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvODAuMC4zOTg3LjE2MyBTYWZhcmkvNTM3LjM2Ig==",
                "approximateArrivalTimestamp": 1545084650.987
            },
            "eventSource": "aws:kinesis",
            "eventVersion": "1.0",
            "eventID": "shardId-000000000006:49590338271490256608559692538361571095921575989136588898",
            "eventName": "aws:kinesis:record",
            "invokeIdentityArn": "arn:aws:iam::123456789012:role/lambda-kinesis-role",
            "awsRegion": "us-east-2",
            "eventSourceARN": "arn:aws:kinesis:us-east-2:123456789012:stream/lambda-stream"
        }
    ]
}
```

Record data is base64 encoded.
```
// encode example
MTkyLjE2OC45OS4xIC0gLSBbMTcvQXByLzIwMjA6MTQ6NTQ6MzYgKzAwMDBdICJHRVQgLyBIVFRQLzEuMSIgMzA0IDAgIi0iICJNb3ppbGxhLzUuMCAoV2luZG93cyBOVCAxMC4wOyBXaW42NDsgeDY0KSBBcHBsZVdlYktpdC81MzcuMzYgKEtIVE1MLCBsaWtlIEdlY2tvKSBDaHJvbWUvODAuMC4zOTg3LjE2MyBTYWZhcmkvNTM3LjM2Ig

//decode example
192.168.99.1 - - [17/Apr/2020:14:54:36 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.163 Safari/537.36"
```





