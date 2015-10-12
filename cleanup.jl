module cleanup

# cleanup digit frequency disparities using a simple greedy algorithm

using rpn
using ff_digits
using rpsr
using formula

export cleanup_rpsr, cleanup_rpsr_via_sum

export number_list_from_expression

# create a closure which creates a closure...
function create_best_cleanup_function_generator(target_dh, rpsr_dh)
   digit_hist_difference = target_dh - rpsr_dh

   function create_best_cleanup_function(the_initial_dh::ff_digits.DigitHist)
      dh_reference = digit_hist_difference + the_initial_dh
      total_original_digit_surplus = sum(ff_digits.digit_surplus(digit_hist_difference))
      total_original_digit_deficit = sum(ff_digits.digit_deficit(digit_hist_difference))

      function result(the_quotient, the_remainder, the_expression)
         new_dh = (ff_digits.digit_hist(the_quotient)
                   + ff_digits.digit_hist(the_remainder)
                   + ff_digits.digit_hist(the_expression))
         new_total_surplus = sum(ff_digits.digit_surplus(dh_reference, new_dh))
         new_total_deficit = sum(ff_digits.digit_deficit(dh_reference, new_dh))
         if new_total_deficit == 0
            return Inf
         else
            if new_total_surplus > total_original_digit_surplus
               surplus_factor = 0.01
            else
               surplus_factor = total_original_digit_surplus - new_total_surplus + 0.01
            end
            deficit_decrease = total_original_digit_deficit - new_total_deficit
            # return deficit_decrease / (deficit_decrease + surplus_factor)
            return deficit_decrease
         end
      end
   
      function result() # return infinitely bad 
         return -Inf
      end
   
      return result
   end

   return create_best_cleanup_function
end

function number_list_from_expression(the_expression)
   result = Any[]
   # in general, it is assumed the input is a valid FF expression
   if isa(the_expression, Int64) || isa(the_expression, BigInt)
      return Any[] # not indexable
   elseif isa(the_expression, Expr)
      if the_expression.head != :call
         error(string("Cannot parse expression head: ", the_expression.head))
      end
      for (i, argument) = enumerate(the_expression.args)
         if i == 1
            continue
         end
         if isa(argument, Int64) || isa(argument, BigInt)
            push!(result, (argument, the_expression, i))
         elseif isa(argument, Expr)
            append!(result, number_list_from_expression(argument))
         end
      end
   end
   return result
end

function cleanup_rpsr(the_target, the_rpsr, profit_candidates, digit_cutoff)
   the_rpsr = deepcopy(the_rpsr)
   
   target_dh = ff_digits.digit_hist(the_target)
   rpsr_dh = ff_digits.digit_hist(the_rpsr)
   orig_rpsr_dh = rpsr_dh
   orig_deficit = ff_digits.digit_deficit(target_dh, rpsr_dh)
   
   println(string("Target : ", target_dh, " = ", sum(target_dh)))
   println(string("Formula : ", rpsr_dh, " = ", sum(rpsr_dh)))
   println(string("Deficit : ", orig_deficit, " = ", sum(orig_deficit)))

   number_list = [0]
   failed_cleanup_set = Set{Any}()
   while ((length(number_list) > 0)
          && (sum(ff_digits.digit_deficit(target_dh, rpsr_dh)) > 0)
          && (sum(ff_digits.digit_surplus(target_dh, rpsr_dh)) > 0))
      number_list = number_list_from_expression(the_rpsr)
      sort!(number_list, by = (x -> -x[1]))

      cleanup_merit_fn_generator = create_best_cleanup_function_generator(target_dh, rpsr_dh)

      number_to_represent = shift!(number_list)
      while (length(number_list) > 0) && in(number_to_represent[1], failed_cleanup_set)
         number_to_represent = shift!(number_list)
      end
      if in(number_to_represent[1], failed_cleanup_set)
         println(string("No more cleanup candidates"))
         break
      end
      if ff_digits.number_of_digits(number_to_represent[1]) < digit_cutoff
         println(string("Hit digit cutoff: ", ff_digits.number_of_digits(number_to_represent[1])))
         break
      end
      
      best_cleanup = rpsr.represent(number_to_represent[1],
                                    profit_candidates,
                                    merit_fn_generator = cleanup_merit_fn_generator)

      new_dh = rpsr_dh - ff_digits.digit_hist(number_to_represent[1]) + ff_digits.digit_hist(best_cleanup)
      if sum(ff_digits.digit_deficit(target_dh, rpsr_dh)) > sum(ff_digits.digit_deficit(target_dh, new_dh))
         number_to_represent[2].args[number_to_represent[3]] = best_cleanup
   
         rpsr_dh = ff_digits.digit_hist(the_rpsr)
         new_deficit = ff_digits.digit_deficit(target_dh, rpsr_dh)
         new_surplus = ff_digits.digit_surplus(target_dh, rpsr_dh)
         println(string("New Deficit : ", new_deficit, " = ", sum(new_deficit)))
         println(string("New Surplus : ", new_surplus, " = ", sum(new_surplus)))
         flush(STDOUT)
         failed_cleanup_list = Set{Any}()
      else
         push!(failed_cleanup_set, number_to_represent[1])
      end
   end

   return the_rpsr
end

function cleanup_rpsr_via_sum(the_target, the_rpsr, candidate_cutoff)
   the_rpsr = deepcopy(the_rpsr)
   
   target_dh = ff_digits.digit_hist(the_target)
   rpsr_dh = ff_digits.digit_hist(the_rpsr)
   orig_rpsr_dh = rpsr_dh
   orig_digit_discrepancy = target_dh - rpsr_dh
   orig_deficit = ff_digits.digit_deficit(orig_digit_discrepancy)
   total_deficit = sum(orig_deficit)
   
   println(string("Target : ", target_dh, " = ", sum(target_dh)))
   println(string("Formula : ", rpsr_dh, " = ", sum(rpsr_dh)))
   println(string("Deficit : ", orig_deficit, " = ", total_deficit))

   number_list = number_list_from_expression(the_rpsr)
   sort!(number_list, by = (x -> -x[1]))

   # find good starting point in number_list according to total_deficit
   the_starting_index = nothing
   for (the_index, x) = enumerate(number_list)
      if ff_digits.number_of_digits(x[1]) <= total_deficit
         the_starting_index = the_index
         break
      end
   end

   if (total_deficit + 1) < candidate_cutoff
      candidate_cutoff = total_deficit + 1
   end
   profit_candidates = formula.trivial_formulas(1)
   shift!(profit_candidates) # 0 is useless
   for i = collect(2 : candidate_cutoff)
      append!(profit_candidates, trivial_formulas(i))
   end

   # notification_interval = div(length(profit_candidates), 10)
   notification_interval = length(profit_candidates) + 10
   
   # small_number_list = splice!(number_list, the_starting_index : end)
   small_number_list = number_list
   
   failed_cleanup_set = Set{Any}()
   best_sr = nothing
   best_merit = nothing
   while ((length(small_number_list) > 0)
          && (sum(ff_digits.digit_deficit(target_dh, rpsr_dh)) > 0)
          && (sum(ff_digits.digit_surplus(target_dh, rpsr_dh)) > 0))
      number_to_represent = shift!(small_number_list)
      current_target = number_to_represent[1]
      
      cleanup_merit_fn_generator = create_best_cleanup_function_generator(target_dh, rpsr_dh)
      merit_fn = cleanup_merit_fn_generator(ff_digits.digit_hist(current_target))

      best_merit = merit_fn()

      # TBC
      for (i, the_formula) = enumerate(profit_candidates)
         if i % notification_interval == 0
            println(string(" .. . . (", i, ")"))
         end
         # case 1
         other_value = the_formula.value + current_target
         merit = merit_fn(nothing, other_value, the_formula.expression)

         if merit > best_merit
            best_merit = merit
            best_sr = Expr(:call,
                           :-,
                           other_value,
                           the_formula.expression)
         end
         if the_formula.value < current_target
            # case 2
            other_value = the_formula.value - current_target
            merit = merit_fn(nothing, other_value, the_formula.expression)
            if merit > best_merit
               best_merit = merit
               best_sr = Expr(:call,
                              :-,
                              the_formula.expression,
                              other_value)
            end
         elseif the_formula.value < current_target
            # case 3
            other_value = current_target - the_formula.value
            merit = merit_fn(nothing, other_value, the_formula.expression)
            if merit > best_merit
               best_merit = merit
               best_sr = Expr(:call,
                              :+,
                              the_formula.expression,
                              other_value)
            end
         end
      end
      
      best_cleanup = best_sr

      new_dh = rpsr_dh - ff_digits.digit_hist(current_target) + ff_digits.digit_hist(best_cleanup)
      if sum(ff_digits.digit_deficit(target_dh, rpsr_dh)) > sum(ff_digits.digit_deficit(target_dh, new_dh))
         number_to_represent[2].args[number_to_represent[3]] = best_cleanup
   
         rpsr_dh = ff_digits.digit_hist(the_rpsr)
         # println(string("New Deficit : ", ff_digits.digit_deficit(target_dh, rpsr_dh)))
         new_deficit = ff_digits.digit_deficit(target_dh, rpsr_dh)
         new_surplus = ff_digits.digit_surplus(target_dh, rpsr_dh)
         println(string("New Deficit : ", new_deficit, " = ", sum(new_deficit)))
         println(string("New Surplus : ", new_surplus, " = ", sum(new_surplus)))
         flush(STDOUT)
      else
         # println(string("Nothing found? : best_merit = ", best_merit))
         0;
      end
   end

   return the_rpsr
end

end # module cleanup
