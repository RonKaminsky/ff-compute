module absorb

using ff_digits
using rpn
using cleanup

export absorb_surplus

function digits_to_number(dh::ff_digits.DigitHist)
   if any(dh.freq .< 0)
      error("digits_to_number: negative repetitions")
   end
   if sum(dh.freq[2 : end]) == 0
      if dh_freq[1] == 1
         return 0
      else
         error("digits_to_number: only multiple zero digits")
      end
   end
   return rpn.from_rpn(string(reduce((*), [repeat(string(i - 1), x) for (i, x) in reverse(collect(enumerate(dh.freq)))]), " "))
end

# the function, as is, works for any surplus of more than 4 digits
function absorb_surplus(the_friedman_formula::Expr, the_surplus::ff_digits.DigitHist)
   if all(the_surplus.freq .== 0)
      # nothing to do
      return the_friedman_formula
   end
   
   the_friedman_formula = deepcopy(the_friedman_formula)
   the_surplus = deepcopy(the_surplus)
   
   if the_surplus.freq[1] > 0
      the_surplus.freq[1] -= 1
      zero_expression = Expr(:call, :*, 0, digits_to_number(the_surplus))
      return Expr(:call, :+, the_friedman_formula, zero_expression)
   end
   if the_surplus.freq[2] > 0
      the_surplus.freq[2] -= 1
      one_expression = Expr(:call, :^, 1, digits_to_number(the_surplus))
      return Expr(:call, :*, the_friedman_formula, one_expression)
   end
   for i = collect(2 : 9)
      if the_surplus.freq[i + 1] > 1
         the_surplus.freq[i + 1] -= 2
         zero_expression = Expr(:call,
                                :*,
                                Expr(:call, :-, i, i),
                                digits_to_number(the_surplus))
         return Expr(:call, :+, the_friedman_formula, zero_expression)
      end
   end
   for i = collect(2 : 8)
      if (the_surplus.freq[i + 1] > 0) && (the_surplus.freq[i + 2] > 0)
         the_surplus.freq[i + 1] -= 1
         the_surplus.freq[i + 2] -= 1
         one_expression = Expr(:call,
                               :^,
                               Expr(:call, :-, i + 2, i + 1),
                               digits_to_number(the_surplus))
         return Expr(:call, :*, the_friedman_formula, one_expression)
      end
   end

   # OK, let's try to find a 1 or 0 (number) in the expression to use it to absorb
   number_list = cleanup.number_list_from_expression(the_friedman_formula)
   sort!(number_list, by = (x -> x[1]))
   if number_list[1][1] == 1
      number_list[1][2].args[number_list[1][3]] = Expr(:call, :^, 1, digits_to_number(the_surplus))
      return the_friedman_formula
   end
   if number_list[1][1] == 0
      number_list[1][2].args[number_list[1][3]] = Expr(:call, :*, 0, digits_to_number(the_surplus))
      return the_friedman_formula
   end

   # People more pedantic than I will add the corner cases like {4, 6, 9}, etc...
   error("Didn't manage to absorb surplus")
end

end # module absorb
