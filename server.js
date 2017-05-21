'use strict';
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const express = require("express");
const fs = require("fs");
const path = require("path");
const Papa = require("papaparse");
const bodyParser = require("body-parser");
function readdir(dir) {
    return new Promise((resolve, reject) => fs.readdir(dir, (err, files) => err ? reject(err) : resolve(files)));
}
function readFile(file) {
    return new Promise((resolve, reject) => fs.readFile(file, (err, data) => err ? reject(err) : resolve(data.toString())));
}
function writeFile(file, data) {
    return new Promise((resolve, reject) => fs.writeFile(file, data, (err) => err ? reject(err) : resolve()));
}
const app = express();
app.listen(process.env.PORT || 8000, () => {
    console.log('Server is listening on port 8000');
});
app.use(bodyParser.urlencoded({ extended: true }));
app.get('/products', (_, res) => __awaiter(this, void 0, void 0, function* () {
    const data = (yield Promise.all((yield readdir('./data')).map(file => readFile(path.resolve('data', file)))))
        .map(file => file.trim())
        .map(file => Papa.parse(file))
        .map(_ => _.data);
    const response = {
        products: {},
        prices: {},
        records: []
    };
    for (let set of data) {
        switch (set[0].length) {
            case 2:
                const type = set[0][0];
                response.products[type] = set.slice(1).map(([a, b]) => [a, +b]);
                break;
            case 3:
                for (let [type, qty, price] of set.slice(1)) {
                    response.prices[type] = response.prices[type] || [];
                    response.prices[type].push([+qty, +price]);
                }
                break;
            case 5:
                response.records = set.slice(1).map(([type, quantity, products, price, time]) => ({
                    type: type,
                    quantity: +quantity,
                    products: products.split(';'),
                    price: +price,
                    time: +time
                }));
                break;
        }
    }
    res.header('Content-Type: application/json');
    res.send(JSON.stringify(response));
}));
app.put('/purchase', (req, res) => __awaiter(this, void 0, void 0, function* () {
    const record = {
        type: req.body.type,
        quantity: +req.body.quantity,
        products: req.body.products.split(','),
        price: +req.body.price,
        time: +req.body.time
    };
    yield queueSave(record);
    res.header('Content-Type: text/plain');
    res.send('Success');
}));
app.put('/sync', (req, res) => __awaiter(this, void 0, void 0, function* () {
    const records = JSON.parse(req.body.records)
        .sort((a, b) => a.time - b.time);
    ;
    yield queueMerge(records);
    res.header('Content-Type: text/plain');
    res.send('Success');
}));
app.use('/', express.static('public_html'));
const recordFile = path.resolve('data', 'records.csv');
let queue = Promise.resolve();
function queueSave(record) {
    return queue = queue.then(() => __awaiter(this, void 0, void 0, function* () {
        let records = yield readFile(recordFile);
        records += `${record.type},${record.quantity},${record.products.join(';')},${record.price},${record.time}\n`;
        yield writeFile(recordFile, records);
    }));
}
function queueMerge(records) {
    return queue = queue.then(() => __awaiter(this, void 0, void 0, function* () {
        const previous = Papa.parse((yield readFile(path.resolve('data', 'records.csv'))).trim())
            .data.slice(1).map(([type, quantity, products, price, time]) => ({
            type: type,
            quantity: +quantity,
            products: products.split(';'),
            price: +price,
            time: +time
        })).sort((a, b) => a.time - b.time);
        const equal = (a, b) => a.type === b.type &&
            a.quantity === b.quantity &&
            a.price === b.price &&
            a.time === b.time &&
            a.products.join(';') === b.products.join(';');
        let r = 0, p = 0;
        while (p !== previous.length && r !== records.length) {
            const [n, o] = [records[r], previous[p]];
            if (equal(n, o)) {
                ++r;
                ++p;
            }
            else if (n.time < o.time) {
                previous.splice(p, 0, records[r]);
                ++r;
            }
            else {
                ++p;
            }
        }
        previous.push(...records.slice(r));
        yield writeFile(recordFile, 'Type,Quantity,Names,Price,Time\n' +
            previous.map(({ type, quantity, products, price, time }) => `${type},${quantity},${products.join(';')},${price},${time}`).join('\n') + '\n');
    }));
}
