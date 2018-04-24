/* @flow */
import * as React from 'react'
import { Static } from './static'
import { Products } from './products'
import { EditProducts } from './edit-products'
import { EditPrices } from './edit-prices'
import { Prices } from './prices'
import { Conventions } from './conventions'
import { SearchConventions } from './search-conventions'
import { ConventionDetails } from './convention-details'
import { Admin } from './admin'
import type { Props as CardViewProps } from './card-view'
import type { Props as ProductsProps } from './products'
import type { Props as EditProductsProps } from './edit-products'
import type { Props as PricesProps } from './prices'
import type { Props as EditPricesProps } from './edit-prices'
import type { Props as ConventionsProps } from './conventions'
import type { Props as SearchConventionsProps } from './search-conventions'
import type { Props as ConventionDetailsProps } from './convention-details'
import type { Props as StaticProps } from './static'
import type { Props as AdminProps } from './admin'
import S from './index.css'

export type Props
  = { name: 'placeholder' }
  | EditProductsProps
  | ProductsProps
  | PricesProps
  | EditPricesProps
  | ConventionsProps
  | SearchConventionsProps
  | ConventionDetailsProps
  | StaticProps
  | AdminProps

export function Content(props: Props) {
  let content: React.Node
  switch (props.name) {
    case 'placeholder':
      content = <div />
      break
    case 'static':
      content = <Static {...props} />
      break
    case 'products':
      content = <Products {...props} />
      break
    case 'edit-products':
      content = <EditProducts {...props} />
      break
    case 'prices':
      content = <Prices {...props} />
      break
    case 'edit-prices':
      content = <EditPrices {...props} />
      break
    case 'conventions':
      content = <Conventions {...props} />
      break
    case 'search-conventions':
      content = <SearchConventions {...props} />
      break
    case 'convention-details':
      content = <ConventionDetails {...props} />
      break
    case 'admin':
      content = <Admin {...props} />
      break
  }
  return (
    <main className={S.container}>
      { content }
    </main>
  )
}