module Main exposing (main)

import DomainList
import Html exposing (Html)


main : Html msg
main =
    DomainList.new [ "one word", "bad word", "other word" ]
        |> DomainList.sort
        |> DomainList.sanitize
        |> DomainList.render
