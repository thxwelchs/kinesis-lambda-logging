const AWS = require('aws-sdk');
const moment = require('moment');
console.log('Loading function');


const s3 = new AWS.S3({
  endpoint: 'http://192.168.99.100:4572',
  s3ForcePathStyle: true,
})

const BUCKET_NAME = 'my-bucket'

exports.handler = async (event, context) => {
    /* Process the list of records and transform them */
    const promises = [];
    event.Records.forEach( record => {
      const payload = Buffer.from(record.kinesis.data, 'base64').toString('ascii')

      promises.push(upload('asdfasdfasdfasdf', payload))
    })

    await Promise.all(promises)


    /* FireHose Lambda Trigger Code */
    // const output = event.records.map((record) => {
    //     /* This transformation is the "identity" transformation, the data is left intact */
    //     const entry = (new Buffer(record.data, 'base64')).toString('utf8');
    //     const formattedData = (new Buffer(logParser(entry), 'utf8')).toString('base64');
        
    //     return {
    //         recordId: record.recordId,
    //         result: 'Ok',
    //         data: formattedData,
    //     }
    // });
    // console.log(`Processing completed.  Successful records ${output.length}.`);
    // return { records: output };
};


function logParser(log) {
  try {
    const formatted = {}

    const baseSplited = log.split('"');
    const hostSplited = baseSplited[0].split(' ')
    const requestSplited = baseSplited[1].split(' ')

    formatted.host = hostSplited[0]
    formatted.time = hostSplited[3].split('[')[1]
    formatted.method = requestSplited[0]
    formatted.path = requestSplited[1]
    formatted.httpVersion = requestSplited[2]
    formatted.status = +(baseSplited[2].split(' ')[1])
    formatted.userAgent = baseSplited[5]

    return JSON.stringify(formatted)

  } catch(err) {
    console.error(err)
    return ''
  }
}

async function isExistObject(key) {
  try {
    const result = await s3.headObject({
      Bucket: BUCKET_NAME,
      Key: key,
    }).promise()

    return true;

  } catch(err) {
    return false;
  }
}

async function findObject(key) {
  try {

    const result = await s3.getObject({
      Bucket: BUCKET_NAME,
      Key: key
    }).promise()

    if(!result && !result.Body) {
      return ''
    }

    // console.log(result.Body.toString('utf-8'))

    return result.Body.toString('utf-8')

  } catch(err) {
    console.log(err)
    return ''
  }
}

async function upload(key, data) {
  try {
    const isExist = await isExistObject(key)

    if(isExist) {
      const _data = await findObject(key)
      data = _data + '\n' + data
    }

    const result = await s3.putObject({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: data
    }).promise()

    // console.log(result);

  } catch (err) {
    console.log(err);
  }
}
