'use strict';
import * as express from 'express';
import * as fs from 'fs';
import * as path from 'path';
import * as Papa from 'papaparse';
import * as bodyParser from 'body-parser';
import { ProductTypes, Products, Prices, Record } from './src/types';

function readdir(dir: string): Promise<string[]> {
  return new Promise((resolve, reject) => fs.readdir(dir, (err, files) => err ? reject(err) : resolve(files)));
}

function readFile(file: string): Promise<string> {
  return new Promise((resolve, reject) => fs.readFile(file, (err, data) => err ? reject(err) : resolve(data.toString())));
}

function writeFile(file: string, data: string): Promise<{}> {
  return new Promise((resolve, reject) => fs.writeFile(file, data, (err) => err ? reject(err) : resolve()));
}

const app = express();
app.listen(process.env.PORT || 8000, () => {
  console.log('Server is listening on port 8000');
});

app.use(bodyParser.urlencoded({ extended: true }));

app.get('/products', async (_, res) => {
  const files = (await readdir('./data')).map(file => path.resolve('data', file));
  const response = {
    products: {} as Products,
    prices: {} as Prices,
    records: [] as Record[]
  };
  await Promise.all(files.map(async file => {
    const { data }: { data: String[] } = Papa.parse((await readFile(file)).trim());
    switch(path.basename(file, '.csv')) {
      case 'records':
        response.records.push(...data.map(([type,quantity,names,price,time]) => ({
            type,
            quantity: +quantity,
            products: names.split(';'),
            price: +price,
            time: +time
          } as Record)).sort((a, b) => a.time - b.time));
        break;
      case 'prices':
        data.forEach(([type, quantity, price]) => {
          response.prices[type as keyof ProductTypes] = response.prices[type as keyof ProductTypes] || [];
          response.prices[type as keyof ProductTypes].push([+quantity, +price]);
        });
        break;
      default:
        data.forEach(([name,quantity]) => {
          const type = path.basename(file, '.csv') as keyof ProductTypes;
          response.products[type] = response.products[type] || [];
          response.products[type].push([name, +quantity]);
        });
    }
  }));
  res.header('Content-Type: application/json');
  res.send(JSON.stringify(response));
});
app.put('/purchase', async (req, res) => {
  const record = {
    type: req.body.type,
    quantity: +req.body.quantity,
    products: req.body.products.split(','),
    price: +req.body.price,
    time: +req.body.time
  } as Record;
  await queueSave(record);
  res.header('Content-Type: text/plain');
  res.send('Success');
});
app.put('/sync', async (req, res) => {
  const records: Record[] = JSON.parse(req.body.records)
    .sort((a: Record, b: Record) => a.time - b.time);;
  await queueMerge(records);
  res.header('Content-Type: text/plain');
  res.send('Success');
});
app.use('/', express.static('public_html'));

const recordFile = path.resolve('data', 'records.csv');
let queue: Promise<void> = Promise.resolve();
function queueSave(record: Record): Promise<void> {
  return queue = queue.then(async () => {
    let records = await readFile(recordFile);
    records += `${record.type},${record.quantity},${record.products.join(';')},${record.price},${record.time}\n`;
    await writeFile(recordFile, records);
  });
}

function queueMerge(records: Record[]): Promise<void> {
  return queue = queue.then(async() => {
    const previous: Record[] =
      Papa.parse((await readFile(path.resolve('data', 'records.csv'))).trim())
        .data.slice(1).map(([type, quantity, products, price, time]): Record => ({
          type: type as keyof ProductTypes,
          quantity: +quantity,
          products: products.split(';'),
          price: +price,
          time: +time
        })).sort((a, b) => a.time - b.time);
    const equal = (a: Record, b: Record) =>
      a.type === b.type &&
      a.quantity === b.quantity &&
      a.price === b.price &&
      a.time === b.time &&
      a.products.join(';') === b.products.join(';');
    let r = 0, p = 0;
    while(p !== previous.length && r !== records.length) {
      const [n, o] = [records[r], previous[p]];
      if(equal(n, o)) {
        ++r;
        ++p;
      } else if(n.time < o.time) {
        previous.splice(p, 0, records[r]);
        ++r;
      } else {
        ++p;
      }
    }
    previous.push(...records.slice(r));
    await writeFile(
      recordFile,
      'Type,Quantity,Names,Price,Time\n' +
      previous.map(({type, quantity, products, price, time}) => `${type},${quantity},${products.join(';')},${price},${time}`
    ).join('\n') + '\n');
  })
}
