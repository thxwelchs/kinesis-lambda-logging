console.log('Loading function');

exports.handler = async (event, context) => {
    /* Process the list of records and transform them */
    const output = event.records.map((record) => {
        /* This transformation is the "identity" transformation, the data is left intact */
        const entry = (new Buffer(record.data, 'base64')).toString('utf8');
        const formattedData = (new Buffer(logParser(entry), 'utf8')).toString('base64');
        
        return {
            recordId: record.recordId,
            result: 'Ok',
            data: formattedData,
        }
    });
    console.log(`Processing completed.  Successful records ${output.length}.`);
    return { records: output };
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
