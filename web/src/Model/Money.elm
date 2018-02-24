module Model.Money exposing
  ( currency
  , currencyString
  , allCurrencies
  , toString
  , fromString
  , prettyprint
  , parse
  , numeric
  , money
  , add
  , resolveAuto
  , Money(..)
  , Currency(..)
  )
{-| Elm implementation of the Money data type defined by the ConArtist server. See the server
documentation for the Money specification.

# Definition
@docs Money, Currency

# Money formatting
@docs toString, prettyprint, fromString, parse

# Currency formatting
@docs currency, currencyString

# Helpers
@docs allCurrencies, money, resolveAuto, numeric, add
-}
import Util.Util as Util
import FormatNumber exposing (format)
import FormatNumber.Locales as Locales

-- TODO: can this file be auto-generated from a list?
{-| The currency being represented by a `Money` value.
-}
type Currency
  = CAD
  | USD
  | AUTO
{-| Extracts a `Currnency` from a `String`, returning `Nothing` when it is not a valid currency
code.

    currency "CAD" == CAD
-}
currency : String -> Maybe Currency
currency str = case str of
  "CAD" -> Just CAD
  "USD" -> Just USD
  _ -> Nothing

{-| Turns a `Currency` code into its `String` representation for serialization.

    currencyString CAD == "CAD"
-}
currencyString : Currency -> String
currencyString c = case c of
  CAD -> "CAD"
  USD -> "USD"
  AUTO -> Debug.crash "Trying to print AUTO currencyString"

{-| A list of all the currencies that are available
-}
allCurrencies : List Currency
allCurrencies = [CAD, USD]

{-| The actual `Money` data type, containing a `Currency` code and a number corresponding to how
many of the currency's minimum denomination is held.

    Money CAD 1500 -- 15 Canadian dollars
-}
type Money = Money Currency Int

{-| Converts a `Money` value into its JSON serialization as a `String`

    toString (Money CAD 1500) == "CAD1500"
-}
toString : Money -> String
toString (Money c i) = currencyString c ++ Basics.toString i

{-| Extracts a `Money` value from its JSON `String` serialization

    fromString "CAD1500" = Money CAD 1500
-}
fromString : String -> Result String Money
fromString moneyString =
  case (currency <| String.left 3 moneyString, Util.toInt <| String.dropLeft 3 moneyString) of
    (Just cur, Ok int) -> Ok <| Money cur int
    (_, Err msg)       -> Err <| msg
    (Nothing, _)       -> Err <| (String.left 3 moneyString ++ " is not a valid currency code")

{-| Prints a `Money` value in its localized format, based on the `Currency` code

    prettyprint (Money CAD 1500) == "$15.00"
-}
prettyprint : Money -> String
prettyprint (Money cur val) = case cur of
  USD -> (++) "$" <| format Locales.usLocale <| flip (/) 100 <| toFloat val
  CAD -> (++) "$" <| format Locales.usLocale <| flip (/) 100 <| toFloat val
  AUTO -> Debug.crash "Trying to prettyprint Money AUTO"

{-| Attempts to parse a `Money` value from its human readable localized representation. Returns an
`Err` on failure.

    parse "$15" == Ok (Money CAD 1500)
-}
parse : String -> Result String Money
parse money =
  case String.uncons money of
    Just ('$', rest) -> parse rest
    _ -> String.toFloat money
      |> Result.map ((*) 100 >> floor >> Money CAD)

{-| Extracts the numeric value of `Money`, disregarding the `Currency` code

    numeric (Money CAD 1500) == 1500
-}
numeric : Money -> Int
numeric (Money _ i) = i

{-| Creates a `Money` value from the AUTO currency. This value will need to be resolved with
`resolveAuto` before it is of any use.

    money 1500 == Money CAD 1500
-}
money : Int -> Money
money = Money AUTO

{-| Adds two `Money` values together, producing their sum if the curreny is the same, or Nothing
otherwise (as two different currencies cannot be meaningfully added together)

    add (Money CAD 1500) (Money CAD 3000) == Just (Money CAD 4500)
    add (Money CAD 1500) (Money USD 3000) == Nothing
-}
add : Money -> Money -> Maybe Money
add (Money ca va) (Money cb vb) =
  if ca == cb then Just <| Money ca (va + vb) else Nothing

{-| Turns the AUTO Currency code to the provided one.

    resolveAuto CAD (Money AUTO 1500) == Money CAD 1500
    resolveAuto CAD (Money USD 1500) == Money USD 1500
-}
resolveAuto : Currency -> Money -> Money
resolveAuto currency money = case money of
  Money AUTO val -> Money currency val
  _ -> money