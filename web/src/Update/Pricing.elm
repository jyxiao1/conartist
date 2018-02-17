module Update.Pricing exposing (update)
import Msg exposing (Msg(..))
import View.Table exposing (updateSort)
import Model.Model exposing (Model)
import Model.Page exposing (Page(..), Selector(..))
import Model.Join as Join
import Model.ProductType as ProductType
import Model.Product as Product
import Model.Price as Price
import Model.Money as Money
import Util.List as List
import Ports.Files as Files


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    user = model.user
    prices = user.prices
  in case model.page of
    Pricing page -> case msg of
      SelectProductType index ->
        { model | page = Pricing { page | open_selector = TypeSelector index } } ! []
      SelectProduct index ->
        { model | page = Pricing { page | open_selector = ProductSelector index } } ! []
      PricingProductType index type_id ->
        case type_id of
          Just type_id ->
            { model
            | page = Pricing { page | open_selector = None }
            , user =
              { user
              | prices = Price.validateAll <| List.flatUpdateAt
                  (Price.index >> (==) index)
                  (\p ->
                    List.filterMap identity
                    [ Just <| Price.setTypeId type_id <| Price.setProduct Nothing p
                    , Price.delete (Price.setIndex (List.length prices + 1) p) ] )
                  prices
              }
            } ! []
          Nothing -> { model | page = Pricing { page | open_selector = None } } ! []
      PricingProduct index product ->
        { model
        | page = Pricing { page | open_selector = None }
        , user =
          { user
          | prices = Price.validateAll <| List.flatUpdateAt
              (Price.index >> (==) index)
              (\p ->
                List.filterMap identity
                  [ Just <| Price.setProduct product p
                  , Price.delete (Price.setIndex (List.length prices + 1) p) ] )
              prices
          }
        } ! []
      PricingPrice index price ->
        { model
        | user =
          { user
          | prices = Price.validateAll <| List.updateAt
              (Price.index >> (==) index)
              (Price.setPrice price)
              prices
          }
        } ! []
      PricingQuantity index quantity ->
        { model
        | user =
          { user
          | prices = Price.validateAll <| List.updateAt
              (Price.index >> (==) index)
              (Price.setQuantity quantity)
              prices
          }
        } ! []
      PricingAdd ->
        { model
        | page = Pricing { page | open_selector = None }
        , user = { user | prices = Price.validateAll <| prices ++ [ Price.new (List.length prices) ] }
        } ! []
      PricingRemove index ->
        { model
        | page = Pricing { page | open_selector = None }
        , user = { user | prices = Price.validateAll <| Price.removeRow index prices }
        } ! []
      SortPricingTable col ->
        { model
        | page = Pricing { page | table_sort = updateSort col page.table_sort }
        } ! []
      ReadPricingCSV -> model ! [ Files.read "pricing" ] -- TODO: implement
      WritePricingCSV ->
        let contents = model.user.prices
          |> List.filter (Price.normalize >> Maybe.map (always True) >> Maybe.withDefault False)
          |> List.sortWith (\wa -> \wb ->
            let
              a = Price.normalize wa
              b = Price.normalize wb
            in
              case compare (Maybe.withDefault 0 <| Maybe.map .type_id a) (Maybe.withDefault 0 <| Maybe.map .type_id b) of
                EQ -> case compare (Maybe.withDefault 0 <| Maybe.andThen .product_id a) (Maybe.withDefault 0 <| Maybe.andThen .product_id b) of
                  EQ -> compare (Maybe.withDefault 0 <| Maybe.map .quantity a) (Maybe.withDefault 0 <| Maybe.map .quantity b)
                  x -> x
                x -> x)
          |> Join.pricesWithProductsAndTypes
              model.user.productTypes
              model.user.products
          |> List.map (\p ->
                 (p.productType |> Maybe.map (ProductType.normalize >> .name) |> Maybe.withDefault "")
              ++ ","
              ++ (p.product |> Maybe.map (Product.normalize >> .name) |> Maybe.withDefault "None")
              ++ ","
              ++ (p.price |> Price.normalize |> Maybe.map .quantity |> Maybe.withDefault 0 |> toString)
              ++ ","
              ++ (p.price |> Price.normalize |> Maybe.map .price |> Maybe.withDefault (Money.money 0) |> Money.resolveAuto model.settings.currency |> toString)
              ++ "\n"
            )
          |> List.foldl (++) ""
        in model ! [ curry Files.write "pricing.csv" contents ]
      _ -> model ! []
    _ -> model ! []
