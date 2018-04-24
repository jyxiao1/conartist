/* @flow */
import type { Convention } from '../convention'

export type Page = Splash
                 | Dashboard
                 | Products
                 | EditProducts
                 | Prices
                 | EditPrices
                 | Conventions
                 | SearchConventions
                 | ConventionDetails
                 | Settings
                 | TermsOfService
                 | PrivacyPolicy
                 | Admin

export type Splash = {| name: 'splash' |}
export type Dashboard = {| name: 'dashboard' |}
export type Products = {| name: 'products' |}
export type EditProducts = {| name: 'edit-products' |}
export type Prices = {| name: 'prices' |}
export type EditPrices = {| name: 'edit-prices' |}
export type Conventions = {| name: 'conventions' |}
export type SearchConventions = {| name: 'search-conventions' |}
export type ConventionDetails = {| name: 'convention-details', convention: Convention |}
export type Settings = {| name: 'settings' |}
export type TermsOfService = {| name: 'terms-of-service' |}
export type PrivacyPolicy = {| name: 'privacy-policy' |}
export type Admin = {| name: 'admin' |}

export type Name = $PropertyType<Page, 'name'>

export const splash: Splash = { name: 'splash' }
export const dashboard: Dashboard = { name: 'dashboard' }
export const products: Products = { name: 'products' }
export const editProducts: EditProducts = { name: 'edit-products' }
export const prices: Prices = { name: 'prices' }
export const editPrices: EditPrices = { name: 'edit-prices' }
export const conventions: Conventions = { name: 'conventions' }
export const searchConventions: SearchConventions = { name: 'search-conventions' }
export const conventionDetails = (convention: Convention): ConventionDetails => ({ name: 'convention-details', convention })
export const settings: Settings = { name: 'settings' }
export const termsOfService: TermsOfService = { name: 'terms-of-service' }
export const privacyPolicy: PrivacyPolicy = { name: 'privacy-policy' }
export const admin: Admin = { name: 'admin' }