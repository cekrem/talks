module DomainList exposing (DomainList, new, render, sanitize, sort)

import Html exposing (Html)
import List


type DomainList a
    = DomainList (List String)


type alias Sorted a =
    { a
        | sorted : ()
    }


type alias Sanitized a =
    { a
        | validated : ()
    }


type alias SafeForRender a =
    { a
        | sorted : ()
        , validated : ()
    }


new : List String -> DomainList {}
new list =
    DomainList list


sort : DomainList a -> DomainList (Sorted a)
sort (DomainList list) =
    DomainList (List.sort list)


sanitize : DomainList a -> DomainList (Sanitized a)
sanitize (DomainList list) =
    DomainList (list |> List.filter (\entry -> entry /= "bad word"))


render : DomainList (SafeForRender a) -> Html msg
render (DomainList list) =
    Html.div []
        [ Html.h1 []
            [ Html.text "The following is oh-so-safe, both sorted and Sanitized. The Compiler guarantees it!" ]
        , Html.ul []
            (list |> List.map (\entry -> Html.li [] [ Html.text entry ]))
        ]
