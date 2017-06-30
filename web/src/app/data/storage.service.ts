import { Injectable, Inject } from '@angular/core';
import { BehaviorSubject } from 'rxjs/BehaviorSubject';
import { Observable } from 'rxjs/Observable';
import 'rxjs/add/operator/mergeMap';
import 'rxjs/add/operator/toPromise';
import 'rxjs/add/operator/take';
import 'rxjs/add/operator/skip';
import 'rxjs/add/operator/distinctUntilChanged';

import APIService from '../api/api.service';
import { UserInfo, ProductType, Convention } from '../../../../conartist';

type ObservableUserInfo = {
  [K in keyof UserInfo]: BehaviorSubject<UserInfo[K]>;
}

@Injectable()
export default class StorageService implements ObservableUserInfo {
  private _email: BehaviorSubject<UserInfo['email']>;
  private _keys: BehaviorSubject<UserInfo['keys']>;
  private _products: BehaviorSubject<UserInfo['products']>;
  private _prices: BehaviorSubject<UserInfo['prices']>;
  private _types: BehaviorSubject<UserInfo['types']>;
  private _conventions: BehaviorSubject<UserInfo['conventions']>;

  constructor(@Inject(APIService) private api: APIService) {
    this._email = new BehaviorSubject('');
    this._keys = new BehaviorSubject(0);
    this._products = new BehaviorSubject([]);
    this._prices = new BehaviorSubject([]);
    this._types = new BehaviorSubject([]);
    this._conventions = new BehaviorSubject([]);
    this.api.getUserInfo().subscribe(_ => {
      this._email.next(_.email);
      this._keys.next(_.keys);
      this._products.next(_.products);
      this._prices.next(_.prices);
      this._types.next(_.types);
      this._conventions.next(_.conventions);
    });
  }

  get email() { return this._email; }
  get keys() { return this._keys; }
  get products() { return this._products; }
  get prices() { return this._prices; }
  get types() { return this._types; }
  get conventions() { return this._conventions; }

  fillConvention(code: string) {
    this._conventions
      // flatMap doing what I want would be nice... but I guess typescript is too weak for rxjs
      .take(1)
      .map(_ => _.find(_ => _.code === code)!).filter(_ => !!_)
      .flatMap(_ => _.type === 'full' ? Observable.of(_) : this.api.loadConvention(_.code))
      .subscribe(full => this._conventions.next(this._conventions.getValue().map(_ => _.code === code ? full : _)));
  }

  convention(code: string) {
    return this._conventions
      .map(_ => _.find(_ => _.code === code)!).filter(_ => !!_)
      .distinctUntilChanged();
  }

  updateConvention(con: Convention) {
    this._conventions.next(this._conventions.getValue().map(_ => _.code === con.code ? con : _));
  }

  createProduct(type: ProductType, index: number) {
    // TODO: check that new name is unique
    this._products.next([
      ...this._products.getValue(),
      {
        name: `${type.name} ${index}`,
        quantity: 0,
        type: type.id,
        id: -index,
        discontinued: false
      }
    ]);
  }

  setProductName(product: number, name: string) {
    this._products.next(this._products.getValue().map(_ => _.id === product ? { ..._, name, dirty: true } : _));
  }

  setProductQuantity(product: number, quantity: number) {
    this._products.next(this._products.getValue().map(_ => _.id === product ? { ..._, quantity, dirty: true } : _));
  }

  setProductDiscontinued(product: number, discontinued: boolean) {
    const before = this._products.getValue().length;
    let type: number;
    this._products.next(
      this._products.getValue()
        .map(_ => {
          if(_.id === product) {
            type = _.type;
            return { ..._, discontinued, dirty: true };
          }
          return _;
        })
        .filter(_ => _.id >= 0 || !_.discontinued)
    );

    if(before > this._products.getValue().length) {
      this._prices.next(
        this._prices.getValue().filter(
          _ => _.type !== type || _.product !== product
        )
      )
    }
  }

  addPriceRow(type: number, product: number | null = null) {
    const prices = this._prices.getValue();
    const existing = prices.find(_ => _.type === type && _.product === product);
    if(existing) {
      const extended = existing.prices.sort((a, b) => a[0] - b[0]);
      extended.push([ (extended[extended.length - 1] || [0])[0] + 1, 0 ]);
      this._prices.next(prices.map(_ => _ === existing ? { ...existing, prices: extended, dirty: true } : _))
    } else {
      this._prices.next([
        ...prices,
        { type, product, prices: [ [1, 0] ], dirty: true },
      ]);
    }
  }

  createType(index: number) {
    this._types.next([
      ...this._types.getValue(),
      {
        name: `Type ${index}`,
        color: 0xFFFFFF,
        id: -index,
        discontinued: false,
        dirty: true,
      }
    ]);
  }

  setTypeName(type: number, name: string) {
    this._types.next(this._types.getValue().map(_ => _.id === type ? { ..._, name, dirty: true } : _));
  }

  setTypeDiscontinued(type: number, discontinued: boolean) {
    this._types.next(this._types.getValue().map(_ => _.id === type ? { ..._, discontinued, dirty: true } : _));
  }

  setTypeColor(type: number, color: number) {
    this._types.next(this._types.getValue().map(_ => _.id === type ? { ..._, color, dirty: true } : _));
  }

  setPriceQuantity(type: number, product: number | null, index: number, quantity: number) {
    this._prices.next(
      this._prices
        .getValue()
        .map(
          _ => _.type === type && _.product === product
            ? {
              ..._,
              prices: _.prices.map(([q, p], i) => [index === i ? quantity : q, p]),
              dirty: true,
            } : _
        ));
  }

  setPricePrice(type: number, product: number | null, index: number, price: number) {
    this._prices.next(
      this._prices
        .getValue()
        .map(
          _ => _.type === type && _.product === product
            ? {
              ..._,
              prices: _.prices.map(([q, p], i) => [q, index === i ? Math.round(100 * price) / 100 : p]),
              dirty: true,
            } : _
        ));
  }

  removePriceRow(type: number, product: number | null, index: number) {
    this._prices.next(
      this._prices.getValue()
        .map(_ => _.type === type && _.product === product ? { ..._, prices: _.prices.filter((_, i) => i !== index), dirty: true } : _)
        .filter(_ => ((_.product === null || _.product >= 0) && _.type >= 0) || _.prices.length > 0)
    );
  }

  async commit() {
    const oldTypes = this._types.getValue();
    let oldProducts = this._products.getValue();
    let oldPrices = this._prices.getValue();
    const newTypes = await this.api.saveTypes(oldTypes).toPromise();;
    const nextTypes = oldTypes.map(type => {
      if(type.id >= 0) { return { ...type, dirty: false }; };
      const next = newTypes.find(_ => _.name === type.name)!;
      oldProducts = oldProducts.map(_ => _.type === type.id ? { ..._, type: next.id } : _);
      oldPrices = oldPrices.map(_ => _.type === type.id ? { ..._, type: next.id } : _);
      return next;
    });

    const newProducts = await this.api.saveProducts(oldProducts).toPromise();
    const nextProducts = oldProducts.map(product => {
      if(product.id >= 0) { return { ...product, dirty: false }; }
      const next = newProducts.find(_ => _.type === product.type && _.name === product.name)!;
      oldPrices = oldPrices.map(_ => _.product === product.id ? { ..._, product: next.id } : _);
      return next;
    });

    await this.api.savePrices(oldPrices).toPromise();

    this._types.next(nextTypes);
    this._products.next(nextProducts);
    this._prices.next(oldPrices);
  }
}