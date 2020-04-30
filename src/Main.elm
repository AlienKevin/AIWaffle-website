module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html
import Url
import Page.Home as Home
import Page.NotFound as NotFound
import Page.Tutorial as Tutorial
import Url.Parser as Parser exposing (Parser, (</>))


-- MAIN


main : Program () Model Msg
main =
  Browser.application
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    , onUrlChange = UrlChanged
    , onUrlRequest = LinkClicked
    }



-- MODEL


type alias Model =
  { key : Nav.Key
  , page : Page
  }


type Page
  = NotFound
  | Home Home.Model
  | Tutorial Tutorial.Model


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  route url
    { key = key
    , page = Home <| Tuple.first <| Home.init ()
    }



-- UPDATE


type Msg
  = LinkClicked Browser.UrlRequest
  | UrlChanged Url.Url
  | NotFoundMsg NotFound.Msg
  | HomeMsg Home.Msg
  | TutorialMsg Tutorial.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
  case message of
    LinkClicked urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model, Nav.pushUrl model.key (Url.toString url) )

        Browser.External href ->
          ( model, Nav.load href )

    UrlChanged url ->
      route url model

    HomeMsg msg ->
      case model.page of
        Home home -> stepHome model (Home.update msg home)
        _             -> ( model, Cmd.none )

    TutorialMsg msg ->
      case model.page of
        Tutorial tutorial -> stepTutorial model (Tutorial.update msg tutorial)
        _             -> ( model, Cmd.none )

    NotFoundMsg _ ->
      ( model, Cmd.none )


route : Url.Url -> Model -> (Model, Cmd Msg)
route url model =
   let
    parser =
      Parser.oneOf
        [ Parser.map
          ( stepHome model (Home.init ())
          )
          (Parser.s "home")
        , Parser.map
          (\tutorialName ->
            let
              name =
                Maybe.withDefault tutorialName <| Url.percentDecode tutorialName
            in
            stepTutorial model (Tutorial.init name)
          )
          (Parser.s "tutorial" </> tutorialName_)
        , Parser.map
            (stepHome model (Home.init ()))
            Parser.top
        ]
  in
  case Parser.parse parser url of
    Just answer ->
      answer

    Nothing ->
      ( { model | page = NotFound }
      , Cmd.none
      )


tutorialName_ : Parser (String -> a) a
tutorialName_ =
  Parser.custom "TUTORIAL" Just


stepHome : Model -> ( Home.Model, Cmd Home.Msg ) -> ( Model, Cmd Msg )
stepHome model (home, cmds) =
  ( { model | page = Home home }
  , Cmd.map HomeMsg cmds
  )


stepTutorial : Model -> ( Tutorial.Model, Cmd Tutorial.Msg ) -> ( Model, Cmd Msg )
stepTutorial model (tutorial, cmds) =
  ( { model | page = Tutorial tutorial }
  , Cmd.map TutorialMsg cmds
  )


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
  case model.page of
    NotFound ->
      { title = "AIwaffle"
      , body =
        [ Html.map NotFoundMsg <| NotFound.view {}
        ]
      }
    Home home ->
      { title = "AIwaffle"
      , body =
        [ Html.map HomeMsg <| Home.view home
        ]
      }
    Tutorial tutorial ->
      { title = Tutorial.getContentName tutorial.contentIndex
      , body =
        [ Html.map TutorialMsg <| Tutorial.view tutorial
        ]
      }
      
