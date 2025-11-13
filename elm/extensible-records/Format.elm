module Format exposing (SomethingWithAge, SomethingWithSize)


type alias HasScrollPosition a =
    { a
        | scrollPosition : Int
    }


type alias SomethingWithSize a =
    { a
        | height : Int
        , width : Int
    }


type alias HasLanguage a =
    { a
        | language : Language.Language
    }


type alias HasName a =
    { a
        | firstName : String
        , lastName : String
    }


prettyPrintName : Settings -> Model -> Html msg
prettyPrintName { language } { firstName, lastName} =
  Html.span [] [
    Html.text case language of
      Language.Formal ->
        lastName ++ ", " ++ firstName
      Language.Casual ->
        firstName ++ " " ++ lastName
    ]
