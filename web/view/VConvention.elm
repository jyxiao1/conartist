module VConvention exposing (view, dateRange)
import Html exposing (Html, div, text, span)
import Html.Attributes exposing (class, style)
import Date exposing (Date)
import Date.Extra as Date
import Hex
import Either exposing (Either(..))
import Dict
import Set

import Model exposing (Model)
import Msg exposing (Msg(..))
import Page exposing (ConventionPageState)
import Fancy
import Convention exposing (Convention, MetaConvention, asMeta, asFull)
import Tabs exposing (tabs, TabItem(Tab))
import Table exposing (basicSortableTable, TableHeader(..))
import Card exposing (card)
import Lists exposing (defList)
import List_
import ProductType exposing (ProductType, FullType)
import Product
import Price
import Join exposing (ProductWithType, PriceWithTypeAndProduct, RecordWithTypedProduct)

view : Model -> ConventionPageState -> Html Msg
view model page =
  case List_.find (asMeta >> .code >> (==) page.convention) model.user.conventions of
      Just con ->
        tabs ChangeConventionTab []
          [ Tab "Summary" <| summary model con
          , Tab "Products" <| products model page con
          , Tab "Prices" <| prices model page con
          , Tab "Sales" <| sales model page con
          , Tab "Stats" <| stats model con ]
        page.current_tab
      Nothing ->
        placeholder "Convention loading..."

summary : Model -> Convention -> Html msg
summary _ convention =
  div [ class "convention__summary" ]
    [ conInfo (asMeta convention) ]
    -- TODO: best sellers
    -- TODO: revenue summary

conInfo : MetaConvention -> Html msg
conInfo { name, code, start, end } =
  let dayCount = 1 + Date.diff Date.Day start end
      plural = dayCount > 1
  in
    card name
      [ class "convention__card" ]
      [ defList text
        [ ( "Code", code )
        , ( "Date", dateRange start end ++ " (" ++ toString dayCount ++ " day" ++ (if plural then "s" else "") ++ ")" )
        -- TODO: conventions could have more data associated with them...
        --       maybe there's some API out there somewhere...
        --       maybe I invent such an API...
        -- , ( "Location", "Unknown" )
        -- , ( "Hours", "Unknown" )
        -- , ( "Setup Time", "Unknown" )
        ]
      ]
      []

products : Model -> ConventionPageState -> Convention -> Html Msg
products model page con =
  case asFull con of
    Nothing -> errorPage
    Just fc ->
      basicSortableTable page.product_sort []
        [ Sortable "Type" typesort SortConProductsTable
        , Sortable "Name" namesort SortConProductsTable
        , Sortable "Quantity" quantitysort SortConProductsTable ]
        productRow <|
        Join.productsWithTypes model.user.productTypes
          (if List.isEmpty fc.products then model.user.products else fc.products)

productRow : ProductWithType -> List (Html msg)
productRow p =
  let
    product = Product.normalize p.product
    productType = ProductType.normalize p.productType
  in
    [ productTypeLabel productType
    , text product.name
    , text (toString product.quantity) ]

productTypeLabel : FullType -> Html msg
productTypeLabel { color, name } =
  div [ class "convention__product-type"]
    [ productCircle color name
    , text name ]

productCircle : Int -> String -> Html msg
productCircle color name =
  Fancy.letterCircle
    (String.cons '#' <| String.padLeft 6 '0' <| Hex.toString color)
    (String.left 1 name)

prices : Model -> ConventionPageState -> Convention -> Html Msg
prices model page con =
  case asFull con of
    Nothing -> errorPage
    Just fc ->
      basicSortableTable page.price_sort []
        [ Sortable "Type" maybetypesort SortConPricesTable
        , Sortable "Product" maybeproductsort SortConPricesTable
        , Sortable "Quantity" pquantitysort SortConPricesTable
        , Sortable "Price" pricesort SortConPricesTable ]
        priceRow <|
          List.filterMap (\p -> Maybe.map (always p) p.productType) <|
            Join.pricesWithProductsAndTypes
              model.user.productTypes
              (if List.isEmpty fc.products then model.user.products else fc.products)
              (if List.isEmpty fc.prices then model.user.prices else fc.prices)

priceRow : PriceWithTypeAndProduct -> List (Html msg)
priceRow { product, productType, price } =
  [ productType |> Maybe.map (ProductType.normalize >> productTypeLabel) |> Maybe.withDefault (text "")
  , text <| (product |> Maybe.map (Product.normalize >> .name) |> Maybe.withDefault "")
  , text (price |> Price.normalize >> Maybe.map .quantity |> Maybe.withDefault 0 >> toString)
  , text (Price.priceStr (Left (Maybe.map .price (Price.normalize price) |> Maybe.withDefault 0))) ]

sales : Model -> ConventionPageState -> Convention -> Html Msg
sales model page con =
  case asFull con of
    Nothing -> errorPage
    Just fc ->
      case fc.records of
        [] -> placeholder "You haven't sold anything yet!"
        _  ->
          basicSortableTable page.record_sort []
            [ Standard "Type"
            , Standard "Products"
            , Sortable "Quantity" rquantitysort SortConRecordsTable
            , Sortable "Price" rpricesort SortConRecordsTable
            , Sortable "Time" timesort SortConRecordsTable ]
            recordRow <|
            Join.recordsWithTypedProducts
              model.user.productTypes
              (if List.isEmpty fc.products then model.user.products else fc.products)
              fc.records

recordRow : RecordWithTypedProduct -> List (Html msg)
recordRow record =
  [ div [ class "convention__product-type" ] <| typeSet record.products
  , text <| productString record.products
  , text <| toString (List.length record.products)
  , text <| Price.priceStr (Left record.price)
  , text <| Date.toFormattedString "EEE, h:mm a" record.time ]

typeSet : List ProductWithType -> List (Html msg)
typeSet =
  List.map (.productType >> ProductType.normalize >> (\p -> (p.color, p.name)))
    >> Set.fromList
    >> Set.foldl (uncurry productCircle >> (::)) []

productString : List ProductWithType -> String
productString products =
  let
    reducer c p =
      Dict.update c.name (\v -> case v of
          Nothing -> Just 1
          Just o -> Just (o + 1)) p
    expander k v p =
      p ++ case v of
        1 -> k ++ ", "
        _ -> k ++ " (" ++ toString v ++ "), "
  in products
    |> List.map (.product >> Product.normalize)
    |> List.foldl reducer Dict.empty
    |> Dict.foldl expander ""
    |> String.dropRight 2

stats : Model -> Convention -> Html msg
stats _ _ = placeholder "This page has not yet been created!"

dateRange : Date -> Date -> String
dateRange start end = (Convention.formatDate start) ++ "–" ++ (Convention.formatDate end)

errorPage : Html msg
errorPage = placeholder "It seems something has gone wrong. Maybe you should reload."

placeholder : String -> Html msg
placeholder str = div [ class "convention__placeholder" ] [ text str ]

-- Lots of dumb sort functions
-- Many are repeated in the other view files
-- TODO: make these standardized somewhere, or improve the syntax of sort tables

typesort : ProductWithType -> ProductWithType -> Order
typesort a b = compare (ProductType.normalize a.productType).name (ProductType.normalize b.productType).name

namesort : ProductWithType -> ProductWithType -> Order
namesort a b = compare (Product.normalize a.product).name (Product.normalize a.product).name

maybetypesort : PriceWithTypeAndProduct -> PriceWithTypeAndProduct -> Order
maybetypesort a b =
  let extract = Maybe.map (ProductType.normalize >> .name) >> Maybe.withDefault "" in
    compare
      (extract a.productType)
      (extract b.productType)

maybeproductsort : PriceWithTypeAndProduct -> PriceWithTypeAndProduct -> Order
maybeproductsort a b =
  let extract = Maybe.map (Product.normalize >> .name) >> Maybe.withDefault "" in
    compare
      (extract a.product)
      (extract b.product)

quantitysort : ProductWithType -> ProductWithType -> Order
quantitysort a b = compare (Product.normalize a.product).quantity (Product.normalize a.product).quantity

pquantitysort : PriceWithTypeAndProduct -> PriceWithTypeAndProduct -> Order
pquantitysort a b =
  let extract = Price.normalize >> Maybe.map .quantity >> Maybe.withDefault 0 in
    compare (extract a.price) (extract b.price)

rquantitysort : RecordWithTypedProduct -> RecordWithTypedProduct -> Order
rquantitysort a b = compare (List.length a.products) (List.length b.products)

pricesort : PriceWithTypeAndProduct -> PriceWithTypeAndProduct -> Order
pricesort a b =
  let extract = Price.normalize >> Maybe.map .price >> Maybe.withDefault 0 in
    compare (extract a.price) (extract b.price)

rpricesort : RecordWithTypedProduct -> RecordWithTypedProduct -> Order
rpricesort a b = compare (Price.priceFloat (Left a.price)) (Price.priceFloat (Left b.price))

timesort : RecordWithTypedProduct -> RecordWithTypedProduct -> Order
timesort a b = Date.compare a.time b.time
