/**
 * nginx access.log 를 읽어 kinesis data stream에 전송 한다.
 */
const AWS = require('aws-sdk');
const fs = require('fs')
const cron = require('node-cron');

const LOCALSTACK_HOST_IP = process.env.LOCALSTACK_HOST || `localhost`
const KINESIS_STREAM_NAME = process.env.KINESIS_STREAM || `web-log-stream`

const kinesis = new AWS.Kinesis({
  endpoint: `http://${LOCALSTACK_HOST_IP}:4568`,
  region: 'us-east-1',
  params: { StreamName: KINESIS_STREAM_NAME }
});

async function logFileRead(path) {
  const readFile = new Promise((resolve, reject) => {
    fs.readFile(path, 'utf-8', (err, data) => {
      if(err) {
        reject(err)
        return
      }
      resolve(data)
    })
  })

  const result = await readFile;
  if(!result) {
    return
  }

  const logs = result.split('\n').map( log => { 
    const hashKey = 'xxxxxxx'.replace(/[xy]/g, function(c) {
        const r = Math.random()*16|0
        const v = c == 'x' ? r : (r&0x3|0x8);
        return v.toString(16);
    });
    return {
      Data: Buffer.from(log.replace(/\r/g, '')),
      PartitionKey: hashKey,
    }
  })

  if(!logs || !logs.length) {
    console.log('log is empty')
    return
  }

  kinesis.putRecords({
    Records: logs,
    StreamName: KINESIS_STREAM_NAME,
  }, (err, data) => {
    if(err) {
      console.log(err, err.stack)
      return
    }
    console.log(data)
    fs.writeFile(path, '', (err) => {
      if(err) {
        return
      }
    })
  })
}

// logFileRead(`C:/Users/LeeTaeHun/project/kakaobank/access.log`);

cron.schedule('* * * * *', () => {
  logFileRead(`C:/Users/LeeTaeHun/project/kakaobank/access.log`)
});
