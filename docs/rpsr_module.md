# The rpsr module

The "heavy lifting" of the computation is done by the "rpsr" module; more exactly, by rpsr.represent(...). It finds optimal product-sum representations (PSRs). In order to make it reusable for at least one of the cleanup stages, its interface is a bit hard to understand. The arguments of rpsr.represent(...) are:

* target::BigInt

  * This is the number which will be re-represented as a product-sum; the function searches for the representation (quotient * formula + remainder) or (quotient * formula - remainder) which has the best "merit", based on the result of calling a "merit function" with information about the representation (the origin of the merit function will be discussed later).

* profit_candidates

  * This is a sequence (i.e., the function has to be able to iterate over it) which provides the formulas which are tested while finding the best product-sum representation.

* merit_fn_generator

  * This is a function which is called with one argument, the digit histogram of the target. The value that this function returns is itself a function, which we will call merit_fn(...) here. merit_fn(...) is used to compare the various product-sum representations. It should be called with either zero arguments, or three arguments. If merit_fn(...) is called with zero arguments, it should return a value which is guaranteed to be smaller than any possible value it returns when called with three arguments (this value is used for the purpose of initialization). If called with three arguments which define the product-sum representation being classified; the arguments are:

    * quotient

      * This is a number which is the quotient of the PSR under consideration

    * remainder

      * This is a number which is the remainder of the PSR under consideration

    * formula_expression::Expr

      * This is the formula being used as a divisor, in expression form.

  * merit_fn_generator, if not specified, defaults to one supplied by the rpsr module itself; the default merit function generator is designed to give the best return value to the PSR which will best decrease the total number of digits in the formula generated by applying rpsr.represent(...) repeatedly. That is, the default merit generator is designed for use in the first stage of the algorithm (see the [Developer Overview](developer_overview.md)).

* rpsr.represent(...) returns the best PSR found as an Expr; the value of that expression must, of course, be equal numerically to the "target" argument.
