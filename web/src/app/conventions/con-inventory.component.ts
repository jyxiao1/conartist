import { Component, Input, Inject } from '@angular/core';
import { BehaviorSubject } from 'rxjs/BehaviorSubject';

import StorageService from '../data/storage.service';
import TypePipe from '../data/type.pipe';
import ConDataSource from '../data/data-source';

import template from './con-inventory.component.html';
import styles from './con-inventory.component.scss';
import { FullConvention, Product, Products } from '../../../../conartist';

@Component({
  selector: 'con-con-inventory',
  template: template,
  styles: [ styles ],
})
export default class ConInventoryComponent {
  @Input() con: FullConvention;
  private _products: BehaviorSubject<Products>;
  private _dataSource: ConDataSource<Product>;

  constructor(
    @Inject(StorageService) private storage: StorageService,
    @Inject(TypePipe) private type: TypePipe,
  ) {
    this._products = storage.products;
    this._dataSource = new ConDataSource(this._products);
    this._dataSource.filter = _ => (!_.discontinued && !this.type.transform(_.type, 'discontinued')) || this.included(_);
  }

  included({ id }: Product): boolean {
    return !!this.con.data.products.find(_ => _.id === id && !_.discontinued);
  }

  toggleIncluded(product: Product) {
    if(this.included(product)) {
      this.storage.removeConventionProduct(this.con, product);
    } else {
      this.storage.addConventionProduct(this.con, product);
    }
  }

  get dataSource() {
    return this._dataSource;
  }

  get displayedColumns() {
    return ['selected', 'name', 'type', 'quantity'];
  }
}