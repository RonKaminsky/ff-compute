module rpsr

# code should probably be improved to not generate superfluous " + 0 " in the case of zero remainder;
# in practice this isn't a big problem because of the relative lack of zeros in the profitable formulas

using formula
using ff_digits

export represent, process_tail_of_rpsr

profitable_db_digits_upper_bound = 200
min_target_digits = 1600

function create_best_profit_per_digit_reduction_function(the_initial_dh::ff_digits.DigitHist)
   initial_number_of_digits = sum(the_initial_dh)

   function result(the_quotient, the_remainder, the_expression)
      quotient_digits = ff_digits.number_of_digits(the_quotient)
      digit_reduction = initial_number_of_digits - quotient_digits
      profit = (initial_number_of_digits
                - quotient_digits
                - ff_digits.number_of_digits(the_remainder)
                - ff_digits.number_of_digits(the_expression))
      return (profit / digit_reduction, -digit_reduction)
   end

   function result() # return infinitely bad 
      return (-Inf, 0)
   end

   return result
end
   
# Yes, I know that making the merit function changeable in this way reduces performance.
# The choice was made to sacrifice performance vs. maintainability. Hopefully someone else
# will find a better solution.
function represent(target::BigInt, profit_candidates; merit_fn_generator = create_best_profit_per_digit_reduction_function)
   merit_fn = merit_fn_generator(ff_digits.digit_hist(target))

   initial_number_of_digits = ff_digits.number_of_digits(target)
   println(string("Starting rpsr (", initial_number_of_digits, ")... "))
   flush(STDOUT)

   tic()
   best_merit = merit_fn()
   best_rpsr = nothing
   for (i, the_formula) = enumerate(profit_candidates)
      if i % 200000 == 0
         println(string(" . . . (", i, ")"))
      end
      if the_formula.value > target
         continue
      end
      (quotient, remainder) = divrem(target, the_formula.value)
      merit = merit_fn(quotient, remainder, the_formula.expression)
      if merit > best_merit
         best_merit = merit
         best_rpsr = (quotient, remainder, Expr(:call,
                                                     :+,
                                                     Expr(:call,
                                                          :*,
                                                          quotient,
                                                          the_formula.expression),
                                                     remainder))
      end
      if ff_digits.number_of_digits(remainder) > ff_digits.number_of_digits(the_formula.value - remainder)
         merit = merit_fn(quotient + 1, the_formula.value - remainder, the_formula.expression)
         if merit > best_merit
            best_merit = merit
            best_rpsr = (quotient, remainder, Expr(:call,
                                                        :-,
                                                        Expr(:call,
                                                             :*,
                                                             quotient + 1,
                                                             the_formula.expression),
                                                        the_formula.value - remainder))
         end
      end
   end

   println(string("Finished : (time = ", toc(), ")"))
   flush(STDOUT)

   return best_rpsr[3]
end

function process_tail_of_rpsr(expression, fn)
   if ! isa(expression, Expr)
      return nothing
   end
   
   local father
   while isa(expression, Expr)
      father = expression
      expression = expression.args[2]
      # what about zero remainders???
   end
   result = fn(expression)
   father.args[2] = result
   return result
end

end # module rpsr
