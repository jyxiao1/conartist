module Msg exposing (Msg(..), TabStatus, chain)
import Html exposing (Html)
import GraphQL.Client.Http exposing (Error)
import Date exposing (Date)
import Navigation exposing (Location)
import Http
import Mouse
import Plot

import Model.ConRequest exposing (ConRequest)
import Model.Pagination exposing (Pagination)
import Model.Product exposing (FullProduct)
import Model.ProductType exposing (FullType)
import Model.Price exposing (CondensedPrice)
import Model.Convention exposing (MetaConvention, FullConvention)
import Model.User exposing (User)

type alias TabStatus =
  { current: Int
  , width: Float }

type Msg
  -- sign in
    -- TODO: user better names for the sign in form messages
  = Email String
  | CEmail String
  | Password String
  | CPassword String
  | Name String
  | Terms Bool
  | ToggleSignIn
  | DoSignIn
  | DoSignOut
  | DidSignIn (Result Http.Error (ConRequest String))
  | DoCreateAccount
  | DidCreateAccount (Result Http.Error (ConRequest ()))
  | DidCheckExistingEmail (Result Http.Error (ConRequest Bool))
  -- dashboard
  | OpenKeyPurchase
  | OpenChooseConvention
  | AddConvention MetaConvention
  -- inventory
  | ChangeInventoryTab TabStatus
  | ColorPickerPage Int
  | ColorPickerOpen
  | ColorPickerClose
  | NewProductType
  | ProductTypeName Int String
  | ProductTypeColor Int Int
  | ProductTypeDiscontinued Int
  | NewProduct
  | ProductName Int Int String
  | ProductQuantity Int Int String
  | ProductDiscontinued Int Int
  | SortInventoryTable Int
  | ReadInventoryCSV
  | WriteInventoryCSV
  -- pricing
  | PricingAdd
  | PricingProductType Int (Maybe Int)
  | PricingProduct Int (Maybe Int)
  | PricingQuantity Int String
  | PricingPrice Int String
  | PricingRemove Int
  | SelectProductType Int
  | SelectProduct Int
  | SortPricingTable Int
  | ReadPricingCSV
  | WritePricingCSV
  -- conventions
  | ChangeConventionTab TabStatus
  | SortConProductsTable Int
  | SortConPricesTable Int
  | SortConRecordsTable Int
  -- charts
  | InventoryChartHover (Maybe Plot.Point)
  | InventoryChartSelectType
  | InventoryChartType (Maybe Int)
  | InventoryChartShowSettings
  | ChartHideSettings
  -- loading
  | DidLoadUser (Result Error User)
  | DidLoadChooseConvention (Result Error (Pagination MetaConvention))
  | DidLoadConvention (Result Error FullConvention)
  -- saving
  | Save
  | SaveTypes
  | SaveProducts
  | SavePrices
  | CreatedPrices (Result Error (List (String, CondensedPrice)))
  | DeletedPrices (Result Error (List (String, Bool)))
  | UpdatedTypes (Result Error (List (String, FullType)))
  | CreatedTypes (Result Error (List (String, FullType)))
  | UpdatedProducts (Result Error (List (String, FullProduct)))
  | CreatedProducts (Result Error (List (String, FullProduct)))
  -- localStorage
  | LSRetrive (String, Maybe String)
  -- files
  | DidFileRead (String, Maybe String)
  | DidFileWrite (String, Maybe String)
  -- navigation
  | DoNav String
  | DidNav Location
  | ToggleSidenav
  | Reauthorized (Result Http.Error (ConRequest String))
  -- dialog
  | CloseDialog
  | EmptyDialog
  | DialogPage Int
  | ShowErrorMessage String
  | ShowErrorMessageComplex (Html Msg) Msg
  | ShowErrorMessageAction String Msg
  -- other
  | MouseMove Mouse.Position
  | SetDate Date
  | Batch (List Msg)
  | Chain (Cmd Msg) Msg
  | Ignore

chain : Cmd Msg -> Cmd Msg -> Cmd Msg
chain second first =
  Cmd.map (Chain second) first
