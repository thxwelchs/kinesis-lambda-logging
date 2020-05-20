const AWS = require('aws-sdk');
const moment = require('moment');
console.log('Loading function');


const s3 = new AWS.S3({
  endpoint: process.env.LAMBDA_ENDPOINT || `lambda.${process.env.AWS_REGION}.amazonaws.com`,
  s3ForcePathStyle: process.env.LAMBDA_ENDPOINT ? true : false,
})

const BUCKET_NAME = process.env.BUCKET_NAME || ''

exports.handler = async (event, context) => {
    /* Process the list of records and transform them */
    const promises = [];
    event.Records.forEach( record => {
      const payload = Buffer.from(record.kinesis.data, 'base64').toString('utf8')
      const parsed = logParser(payload)
      if(parsed && parsed.key && parsed.log) {
        const { key, log } = parsed
        promises.push(upload(key, log))
      }
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
    return {
      endpoint: process.env.LAMBDA_ENDPOINT || `lambda.${process.env.AWS_REGION}.amazonaws.com`,
      s3ForcePathStyle: process.env.LAMBDA_ENDPOINT ? true : false,
    };
};


function logParser(log) {
  try {
    if(!log) return
    const formatted = {}

    const baseSplited = log.split('"');
    const hostSplited = baseSplited[0].split(' ')
    const requestSplited = baseSplited[1].split(' ')

    const time = moment(hostSplited[3].split('[')[1], 'DD/MMM/YYYY:HH:mm:ss')

    formatted.host = hostSplited[0]
    formatted.time = time
    formatted.method = requestSplited[0]
    formatted.path = requestSplited[1]
    formatted.httpVersion = requestSplited[2]
    formatted.status = +(baseSplited[2].split(' ')[1])
    formatted.userAgent = baseSplited[5]

    return { 
      key: `web-log/${time.utc().format('YYYY/MM/DD/HH')}/web-log.log`,
      log: JSON.stringify(formatted) + '\n'
    }
  } catch(err) {
    console.error(err)
    return
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
