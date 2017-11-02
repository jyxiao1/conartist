module Model.Convention exposing (..)
import Date exposing (Date)
import Date.Extra as Date exposing (toUtcFormattedString)

import Model.Product exposing (Product)
import Model.Price exposing (Price)
import Model.ProductType exposing (ProductType)
import Model.Record exposing (Record)
import Model.Expense exposing (Expense)

type alias MetaConvention =
  { id: Int
  , name: String
  , code: String
  , start: Date
  , end: Date }

type alias FullConvention =
  { id: Int
  , name: String
  , code: String
  , start: Date
  , end: Date
  , products: List Product
  , productTypes: List ProductType
  , prices: List Price
  , records: List Record
  , expenses: List Expense }

type Convention
  = Full FullConvention
  | Meta MetaConvention

isDirty : Convention -> Bool
isDirty con = case con of
  Meta _ -> False
  Full _ -> False

stringToDate : (String -> Date)
stringToDate = Date.fromString >> Result.toMaybe >> (Maybe.withDefault <| Date.fromTime 0)

asMeta : Convention -> MetaConvention
asMeta con = case con of
  Meta con -> con
  Full con -> MetaConvention con.id con.name con.code con.start con.end

asFull : Convention -> Maybe FullConvention
asFull con = case con of
  Meta con -> Nothing
  Full con -> Just con

formatDate : Date -> String
formatDate = toUtcFormattedString "MMM d, y"
