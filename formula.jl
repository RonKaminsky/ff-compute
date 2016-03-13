module formula

using rpn
using big_eval
using ff_digits

export find_formulas, power_of_10
export read_formulas, read_formula_file
export trivial_formulas

# Julia version compatibility fixes               
if (VERSION.major, VERSION.minor) <= (0, 3)
   my_ifloor(x) = ifloor(x)
else
   my_ifloor(x) = floor(Integer, x)
end


type Formula
   expression::Union{Expr, Int64, BigInt}
   value::BigInt
   digits::Array{Int, 1}

   Formula(x) = new(x)
   Formula(x, y) = new(x, y)
   Formula(x, y, z) = new(x, y, z)
end

function default_hash(x)
   return hash(x)
end



# calculate the trivial digit formulas with only concatenation
function trivial_formulas(n::Integer)
   result = Formula[]
   if n == 1
      for i = collect(0 : 9)
         push!(result, Formula(i, big(i)))
      end
   else
      for i = collect(10^(n - 1) : (10^n - 1))
         push!(result, Formula(i, big(i)))
      end
   end
   return result   
end

# find_formulas(...) takes as input a sequence of sequences of formulas,
# ordered on the outermost level by the number of digits used in the formulas
# (starting at 1 digit formulas), and calculates a sequence of formulas which
# have one additional digit whose formula values have not already been attained.
# If result_callback is nothing, the sequence is returned, otherwise
# result_callback should be a function which will be called with every generated
# formula expression as its argument (useful for writing results directly to a file).
#
# Arguments:
#   formulas_by_digits : the sequence of sequence of formulas
#   size cutoff : maximum formula value (in number of decimal digits)
#   hash_fn : hash function used for preventing repeated formula values#
#   result_callback : if set to a function, it is called on every new expression
#                     found before discarding the expression; otherwise, the
#                     new expressions are collected into a sequence and returned.
#                     Useful for writing results directly to a file.
#
function find_formulas(formulas_by_digits,
                       size_cutoff::Integer;
                       hash_fn = default_hash,
                       result_callback = nothing)
   n = length(formulas_by_digits)

   result = Formula[]

   # initialize formula value hash set
   hash_type = typeof(hash_fn(big(17)))
   value_hashes = Set{hash_type}()
   
   if n > 0
      chunk_size = 100000
      for formula_array in formulas_by_digits
         println(string("Pushing into set: ", length(formula_array)))
         for i = collect(1 : chunk_size : length(formula_array))
            chunk_end = min(length(formula_array), i + chunk_size - 1)
            union!(value_hashes, [hash_fn(x.value) for x in formula_array[i : chunk_end]])
            println(string("Pushed ", chunk_end - i + 1))
            gc()
            # run(`ps -Fq $my_pid`)
            flush(STDOUT)
         end
      end
      gc()
      initial_set_length = length(value_hashes)
      println(string("Initial set size: ", initial_set_length, " formulas"))
      flush(STDOUT)
      
      # now calculate the formulas for n + 1 digits
      for i = collect(1 : div(n, 2))
         println(string("Calculating for: ", i, " vs. ", n + 1 - i))
         append!(result, combine_formulas(formulas_by_digits[i],
                                          formulas_by_digits[n + 1 - i],
                                          size_cutoff,
                                          value_hashes,
                                          false,
                                          hash_fn = hash_fn,
                                          result_callback = result_callback))
         println(string(" => ", length(value_hashes) - initial_set_length, " formulas"))
         initial_set_length = length(value_hashes)
      end
      if (n + 1) % 2 == 0
         halfway = div(n + 1, 2)
         println(string("Calculating for: ", halfway, " vs. ", halfway))
         append!(result, combine_formulas(formulas_by_digits[halfway],
                                          formulas_by_digits[halfway],
                                          size_cutoff,
                                          value_hashes,
                                          true,
                                          hash_fn = hash_fn,
                                          result_callback = result_callback))
         println(string(" => ", length(value_hashes) - initial_set_length, " formulas"))
      end
   end

   for new_formula = trivial_formulas(n + 1)
      if ! in(hash_fn(new_formula.value), value_hashes)
         if isa(result_callback, Function)
            result_callback(new_formula)
         else
            push!(result, new_formula)
         end
      end
   end
   return result
end

# read formulas from files
function read_formulas(n::Integer, filename_format::String)
   my_sprintf(args...) = eval(:@sprintf($(args...)))
   result = Any[]
   for i = collect(1 : n)
      push!(result, read_formula_file(my_sprintf(filename_format, i)))
   end
   return result      
end

# read formulas from a file
function read_formula_file(filename::String)
   ifh = open(filename)
   return read_formula_file(ifh)
end

function read_formula_file(input_file::IOStream)
   notification_interval = 50000
   # dbg_bailout = 250000
   result = Formula[]
   for (i, line) = enumerate(readlines(input_file))
      new_expression = rpn.from_rpn(chomp(line))
      new_formula = Formula(new_expression,
                            big_eval.eval(new_expression))
      push!(result, new_formula)
      if (i % notification_interval) == 0
         println(string("Read: ", i))
         flush(STDOUT)
      end
      # if i >= dbg_bailout
      #    break
      # end
   end
   return result
end

# provide quick evaluation of powers of 10 via memoization
memoized_powers_of_10 = Dict{Int, BigInt}()
for i = collect(0 : 10)
   memoized_powers_of_10[i] = 10 ^ i;
end

function power_of_10(n::Integer)
   if haskey(memoized_powers_of_10, n)
       return memoized_powers_of_10[n]
   else
      if n % 2 == 0
         memoized_powers_of_10[n] = power_of_10(div(n, 2)) ^ 2
         return memoized_powers_of_10[n]
      else
         memoized_powers_of_10[n] = 10 * power_of_10(n - 1)
         return memoized_powers_of_10[n]
      end
   end
end

# combine_formulas(...) combines two sequences of formulas, producing all possible
# expressions using one binary operation between elements.
#
#    formulas_1 : the first sequence
#    formulas_2 : the second sequence
#    size_cutoff : upper bound on number of digits of resulting formula value
#    value_hashes : Set of hashes of already attained values
#    identical_inputs : Bool, true if the two input sequences are identical
#    hash_fn : the hash function to use on the values
#    result_callback : if set to a function, it is called on every new expression
#                      found before discarding the expression; otherwise, the
#                      new expressions are collected into a sequence and returned.
#                      Useful for writing results directly to a file.
#    memory_cache_cutoff : currently unused.
#
function combine_formulas(formulas_1::Array{Formula, 1},
                          formulas_2::Array{Formula, 1},
                          size_cutoff::Int64,
                          value_hashes::Set,
                          identical_inputs::Bool;
                          hash_fn = default_hash,
                          result_callback = nothing,
                          memory_cache_cutoff = Inf)
   result = Formula[]
   initial_set_size = length(value_hashes)
   notification_increment = 10000
   gc_counter = 0
   gc_frequency = 100000
   for (formula_1_idx, formula_1) = enumerate(formulas_1)
      for (formula_2_idx, formula_2) = enumerate(formulas_2)
         if identical_inputs && (formula_2_idx > formula_1_idx)
            break
         end

         gc_counter += 1
         if (gc_counter % gc_frequency) == 0
            gc()
            println(string("GC call"))
            flush(STDOUT)
            gc_counter = 0
         end
         
         # :+
         new_value = formula_1.value + formula_2.value
         new_value_hash = hash_fn(new_value)
         if ff_digits.number_of_digits(new_value) <= size_cutoff
            if ! in(new_value_hash, value_hashes)
               new_formula = Formula(Expr(:call,
                                          :+,
                                          formula_1.expression,
                                          formula_2.expression),
                                     new_value)
               if isa(result_callback, Function)
                  result_callback(new_formula)
               else
                  push!(result, new_formula)
               end
               push!(value_hashes, new_value_hash)
               if (length(value_hashes) - initial_set_size) % notification_increment == 0
                  println(string("Calculated ", length(value_hashes) - initial_set_size, " formulas (+)"))
               end
            end
         end
         # :-
         if formula_1.value > formula_2.value
            larger = formula_1
            smaller = formula_2
         else
            larger = formula_2
            smaller = formula_1
         end
         new_value = larger.value - smaller.value
         new_value_hash = hash_fn(new_value)
         if ! in(new_value_hash, value_hashes)
            new_formula = Formula(Expr(:call,
                                       :-,
                                       larger.expression,
                                       smaller.expression),
                                  new_value)
            if isa(result_callback, Function)
               result_callback(new_formula)
            else
               push!(result, new_formula)
            end
            push!(value_hashes, new_value_hash)
            if (length(value_hashes) - initial_set_size) % notification_increment == 0
               println(string("Calculated ", length(value_hashes) - initial_set_size, " formulas (-)"))
            end
         end
         # :*
         approx_number_of_digits = ff_digits.number_of_digits(formula_1.value) + ff_digits.number_of_digits(formula_2.value)
         if approx_number_of_digits < size_cutoff + 1
            new_value = formula_1.value * formula_2.value
            if ff_digits.number_of_digits(new_value) <= size_cutoff
               new_value_hash = hash_fn(new_value)
               if ! in(new_value_hash, value_hashes)
                  new_formula = Formula(Expr(:call,
                                             :*,
                                             formula_1.expression,
                                             formula_2.expression),
                                        new_value)
                  if isa(result_callback, Function)
                     result_callback(new_formula)
                  else
                     push!(result, new_formula)
                  end
                  
                  push!(value_hashes, new_value_hash)

                  if (length(value_hashes) - initial_set_size) % notification_increment == 0
                     println(string("Calculated ", length(value_hashes) - initial_set_size, " formulas (*)"))
                  end
               end
            end
         end
         # :/
         if smaller.value != zero(smaller.value)
            (new_value, remainder) = divrem(larger.value, smaller.value)
            if remainder == zero(remainder)
               new_value_hash = hash_fn(new_value)
               if ! in(new_value_hash, value_hashes)
                  new_formula = Formula(Expr(:call,
                                             :/,
                                             larger.expression,
                                             smaller.expression),
                                        new_value)
                  if isa(result_callback, Function)
                     result_callback(new_formula)
                  else
                     push!(result, new_formula)
                  end
                  push!(value_hashes, new_value_hash)
                  if (length(value_hashes) - initial_set_size) % notification_increment == 0
                     println(string("Calculated ", length(value_hashes) - initial_set_size, " formulas (/)"))
                  end
               end
            end
         end
         # :^
         for (first_formula, second_formula) = [(formula_1, formula_2), (formula_2, formula_1)]
            # need to check both orders, here
            if first_formula.value != zero(first_formula.value)
               approx_number_of_digits = my_ifloor(log10(first_formula.value) * second_formula.value) + 1
               if approx_number_of_digits < size_cutoff + 1
                  new_value = first_formula.value ^ second_formula.value
                  if ff_digits.number_of_digits(new_value) <= size_cutoff
                     new_value_hash = hash_fn(new_value)
                     if ! in(new_value_hash, value_hashes)
                        new_formula = Formula(Expr(:call,
                                                   :^,
                                                   first_formula.expression,
                                                   second_formula.expression),
                                              new_value)
                        if isa(result_callback, Function)
                           result_callback(new_formula)
                        else
                           push!(result, new_formula)
                        end
                        push!(value_hashes, new_value_hash)
                        if (length(value_hashes) - initial_set_size) % notification_increment == 0
                           println(string("Calculated ", length(value_hashes) - initial_set_size, " formulas (^)"))
                        end
                     end
                  end
               end
            end
         end
      end
   end
   if isa(result_callback, Function)
      return Formula[]
   else
      return result
   end
end

function can_generate_profit(f::Formula; profit_margin = 1)
   if isdefined(f, :value)
      value = f.value
   else
      value = big_eval.eval(f.expression)
   end
   return ((value != zero(value))
           && (ff_digits.number_of_digits(value)
               >= (profit_margin + ff_digits.number_of_digits(f.expression))))
end

function canonize_expression(the_expression)
   # get rid of @bigint_str (and other) macro calls
   if isa(the_expression, Int64) || isa(the_expression, BigInt) || isa(the_expression, Symbol)
      return the_expression
   elseif isa(the_expression, Expr)
      if the_expression.head == :call
         return Expr(:call,
                     map(canonize_expression, the_expression.args)...)
      elseif the_expression.head == :macrocall
         return eval(the_expression)
      else
         error(strint("Unrecognized expression head: ", the_expression.head))
      end
   end
end

end # module formula
