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
