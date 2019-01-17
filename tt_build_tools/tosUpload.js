const {
    TosClient,
} = require('byted-tos-client');
const fs = require('fs');

process.env.CONSUL_HTTP_HOST = '10.6.131.79';
let args = process.argv.splice(2);
let filepath = args[0];
let name = args[1];

const client = new TosClient({
    bucket: 'toutiao.ios.arch', // must have
    accessKey: 'MJMETJODXZF7FZLFY3VT', // must have
    timeout: 10, // optional, 10 is default
    cluster: 'default', // optinal, 'default' is default
    service: 'toutiao.tos.tosapi', // optional, 'toutiao.tos.tosapi' is default
});

// upload file

const fileBuffer1 = fs.readFileSync(filepath);
client.uploadFileBuf(name, fileBuffer1)
    .then(Promise.resolve())
    .catch(err => console.log(err));