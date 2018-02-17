module View.SignIn exposing (view)
import Html exposing (Html, div, input, button, text, label)
import Html.Attributes exposing (type_, placeholder, class, disabled)
import Html.Events exposing (onInput, onClick)
import Html.Keyed as K

import Msg exposing (Msg(..))
import Model.Page exposing (SignInPageState)
import Model.Status as Status exposing (Status)
import View.Card exposing (card)
import View.Fancy as Fancy exposing (ButtonStyle(..))

view : a -> SignInPageState -> Html Msg
view _ page =
  div [ class "sign-in" ]
   [ card "Sign in" [ class "sign-in__form"]
      [ K.node "div" [ class "sign-in__fields"] <| signInForm page
      , div [ class "sign-in__info" ] <| signInInfo page.is_sign_in page.status ]
      (signInButtons page.is_sign_in page.status) ]

signInForm : SignInPageState -> List (String, Html Msg)
signInForm page = if page.is_sign_in
  then
    [ ("username", Fancy.validatedInput "Email" page.email [ class "sign-in__field" ] [type_ "text", onInput Email] )
    , ("password", Fancy.validatedInput "Password" page.password [ class "sign-in__field" ] [type_ "password", onInput Password]) ]
  else
    [ ("username", Fancy.validatedInput "Email" page.email [ class "sign-in__field" ] [type_ "text", onInput Email] )
    , ("confirm_email", Fancy.validatedInput "Confirm email" page.c_email [ class "sign-in__field" ] [type_ "text", onInput CEmail])
    , ("password", Fancy.validatedInput "Password" page.password [ class "sign-in__field" ] [type_ "password", onInput Password])
    , ("confirm_password", Fancy.validatedInput "Confirm password" page.c_password [ class "sign-in__field" ] [type_ "password", onInput CPassword])
    , ("name", Fancy.validatedInput "Name" page.name [ class "sign-in__field" ] [type_ "text", onInput Name])
    , ("terms", Fancy.checkbox Terms "I accept the terms and conditions") ]

signInButtons : Bool -> Status -> List (Html Msg)
signInButtons sign_in status =
  [ Fancy.button Primary
    ( if sign_in
      then "Sign in"
      else "Create account")
    [ class "sign-in__button"
    , onClick <| if sign_in then DoSignIn else DoCreateAccount
    , disabled <| case status of
      Status.Progress _ -> True
      _                 -> False ]
  , Fancy.button Flat
    ( if sign_in
      then "Create an account"
      else "I already have an account")
    [ class "sign-in__link" , onClick ToggleSignIn ] ]

signInInfo : Bool -> Status -> List (Html msg)
signInInfo sign_in status =
  [ case status of
      Status.Success str -> div [ class "sign-in__notification sign-in__notification--neutral" ] [text str]
      Status.Progress _ -> div [ class "sign-in__notification sign-in__notification--neutral" ]
        [ text <| if sign_in then "Signing in..." else "Creating account..." ]
      Status.Failure error -> div [ class "sign-in__notification sign-in__notification--error" ] [text error] ]
