module View exposing (view)
import Html exposing (Html, div, main_)
import Html.Attributes exposing (class)

import Model exposing (Model)
import Page exposing (Page(..))
import Msg exposing (Msg)

import VSignIn
import VDashboard
import VSidenav
import VToolbar
import VInventory
import VDialog
import VPricing
import VConventions
import VConvention

view : Model -> Html Msg
view model =
  let content =
    case model.page of
      SignIn state -> [ main_ [ class "ca__content" ] [ VSignIn.view model state ] ]
      _         ->
        [ VToolbar.view model
        , div [ class "ca__container" ]
          [ VSidenav.view model
          , mainView model ]
        , VDialog.view model model.dialog
        , VDialog.backdrop model.dialog ]
  in
    div [ class "ca" ] content

mainView : Model -> Html Msg
mainView model =
  main_
    [ class "ca__content" ]
    [ case model.page of
        Dashboard       -> VDashboard.view model
        Inventory state -> VInventory.view model state
        Pricing state   -> VPricing.view model state
        Conventions     -> VConventions.view model
        Convention con  -> VConvention.view model con
        _               -> div [] [] ]