import * as React from 'react'
import { Basic } from '../basic'
import { Input } from '../../common/input'
import { Link } from '../../common/link'
import { Textarea } from '../../common/textarea'
import { Tooltip } from '../../common/tooltip'
import { Icon } from '../../common/icon'
import { AutoList as List } from '../../common/list/auto'
import { Item } from '../../common/list/item'
import { l } from '../../localization'
import { closeDialog as closeDialogButton } from '../action'
import { closeDialog } from '../../update/dialog'
import { loadConvention } from '../../update/helpers'
import { SaveRecord } from '../../api/save-record'
import { Money } from '../../model/money'
import { INVALID, VALID } from '../../model/validation'
import DefaultMap from '../../util/default-map'
import { by, Asc } from '../../util/sort'
import * as toast from '../../toast'
import type { Product } from '../../model/product'
import type { ProductType } from '../../model/product-type'
import type { FullConvention } from '../../model/full-convention'
import type { Validation } from '../../common/input'
import S from './index.css'

export type Props = {
  name: 'new-sale',
  convention: FullConvention,
  record?: ?Record
}

type State = {
  products: Product[],
  amount: Money,
  note: string,
  processing: boolean,
  productType: ProductType,
  moneyValidation: Validation,
}

export class NewSale extends React.Component<Props, State> {
  constructor(props) {
    super(props)

    const { products } = this.props.convention

    this.state = {
      products: props.record ? props.record.products.map(id => products.find(product => product.id === id)).filter(x => x) : [],
      amount: props.record ? props.record.price.toString() : Money.zero.toString(),
      note: props.record ? props.record.info : '',
      processing: false,
      productType: null,
      manualPrice: false,
      moneyValidation: { state: VALID },
    }
  }

  setAmount(amount: string) {
    let moneyValidation = { state: VALID };
    if (!amount) {
      amount = this.calculatePrice().toString()
      this.setState({ amount, moneyValidation, manualPrice: false })
    } else {
      try {
        Money.parse(amount);
      } catch (error) {
        moneyValidation = { state: INVALID, error: l`The price is invalid` }
      }
      this.setState({ amount, moneyValidation, manualPrice: true })
    }
  }

  removeProduct({ id }: Product) {
    const { products } = this.state
    this.setState({
      products: products.filter(product => product.id !== id)
    }, () => {
      if (!this.state.manualPrice) {
        this.setState({ amount: this.calculatePrice().toString() })
      }
    })
  }

  addProduct(product: Product) {
    const { products } = this.state
    this.setState({
      products: [...products, product],
    }, () => {
      if (!this.state.manualPrice) {
        this.setState({ amount: this.calculatePrice().toString() })
      }
    })
  }

  calculatePrice() {
    const { convention: { prices } } = this.props
    const { products, amount } = this.state
    if (prices.count === 0) { return Money.zero } // can't calculate anything
    const matters = new Set(prices.map(price => price.productId).filter(product => !!product))
    const items = products.reduce((counts, product) => {
      if (matters.has(product.id)) {
        const key = `p${product.id}`
        counts.set(key, counts.get(key) + 1)
      } else {
        const key = `t${product.typeId}`
        counts.set(key, counts.get(key) + 1)
      }
      return counts
    }, new DefaultMap([], 0))
    const newPrice = [...items.entries()]
      .reduce((price, [key, count]) => {
        const relevantPrices = prices
          .filter(price => (price.productId && key === `p${price.productId}`) || (!price.productId && key === `t${price.typeId}`))
          .sort(by(['quantity', Asc]))
        var newPrice = price
        while (count) {
          const price = relevantPrices
            .reduce((best, price) => {
              if (price.quantity <= count && (!best || price.quantity > best.quantity)) {
                return price
              } else {
                return best
              }
            }, null)
          if (!price) { return newPrice }
          count -= price.quantity
          newPrice = newPrice.add(price.price)
        }
        return newPrice
      }, Money.zero)
    return newPrice
  }

  async saveChanges() {
    const { record, convention: { id: conId } } = this.props
    const { products, amount, note } = this.state
    this.setState({ processing: true })
    const productIds = products.map(product => product.id)
    let action
    if (record) {
      action = { action: 'update', recordId: record.id, products: productIds, amount: Money.parse(amount), info: note }
    } else {
      action = { action: 'create', conId, products: productIds, amount: Money.parse(amount), info: note }
    }
    const response = await new SaveRecord()
      .send(action)
      .toPromise()
    try {
      await loadConvention(conId)
    } catch (_) { /* ignore */ }
    this.setState({ processing: false })
    if (response.state === 'failed') {
      toast.show(<span>{l`It seems something went wrong.`} <Icon name='warning'/></span>)
    } else {
      toast.show(<span>{l`Sale saved`} <Icon name='check'/></span>)
      closeDialog()
    }
  }

  render() {
    const { convention, record: editing } = this.props
    const { products, productType, amount, note, moneyValidation, processing } = this.state
    const save = {
      enabled: products.length > 0 && moneyValidation.state === VALID && !processing,
      title: 'Save',
      action: () => this.saveChanges(),
    }
    let title = editing ? l`Editing Sale` : l`New Sale`

    let content

    if (productType) {
      title = (
        <>
          <span className={S.title}>
            <Link className={S.backButton} onClick={() => this.setState({ productType: null })}>
              <Icon name='keyboard_arrow_left' /> {l`Back`}
            </Link>
            {productType.name}
          </span>
        </>
      )
      content = (
        <List className={S.full} dataSource={convention.products.filter(product => product.typeId === productType.id)}>
          {product => {
            const selected = products
              .filter(({ id }) => product.id === id)
              .length
            const totalSold = []
              .concat(...convention.records.map(record => record.products))
              .filter(id => id === product.id)
              .length

            return (
              <Item className={S.row} onClick={() => this.addProduct(product)} key={product.id}>
                <span className={S.name}>{product.name}</span>
                { selected
                  ? (
                    <Tooltip title={l`Remove`} className={S.tooltipContainer}>
                      <span onClick={e => { e.stopPropagation(); this.removeProduct(product) }} className={`${S.selectedCount} ${S.removable}`}>{selected}</span>
                    </Tooltip>
                  )
                  : null }
                <span className={S.detail}>{product.quantity - totalSold}</span>
              </Item>
            )
          }}
        </List>
      )
    } else {
      const calculatedPrice = this.calculatePrice()
      content = (
        <>
          <List className={S.full} dataSource={convention.productTypes}>
            {productType => {
              const selected = products
                .filter(product => product.typeId === productType.id)
                .length
              return (
                <Item className={S.row} onClick={() => this.setState({ productType })} key={productType.id}>
                  <span className={S.name}>{productType.name}</span>
                  { selected ? <span className={S.selectedCount}>{selected}</span> : null }
                  <Icon className={S.detail} name='keyboard_arrow_right' />
                </Item>
              )
            }}
          </List>
          <div className={S.form}>
            <Input
              className={S.formItem}
              defaultValue={amount}
              value={amount}
              placeholder={l`Price`}
              title={l`Price`}
              onChange={amount => this.setAmount(amount)}
              validation={moneyValidation}
              />
            <Textarea
              className={S.full}
              defaultValue={note}
              placeholder={l`Note`}
              onChange={note => this.setState({ note })}
              />
          </div>
        </>
      )
    }

    return (
      <Basic title={title} onClose={closeDialogButton} onContinue={productType ? null : save}>
        <div className={S.body}>
          {content}
        </div>
      </Basic>
    )
  }
}

export default NewSale;
