The program makes use of [Reverse Polish notation](https://en.wikipedia.org/wiki/Reverse_Polish_notation) (RPN) as an easily parsed format for formula I/O. The module "rpn" in "rpn.jl" provides two functions "to_rpn(...)" and "from_rpn(...)" which translate Julia Expr objects to and from RPN notation.

Space characters are used to terminate numbers. The character "!" represents unary minus. The other usual mathematical binary operators which are legal in Friedman formulas are represented by the same characters used in Julia syntax.
