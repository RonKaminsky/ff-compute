#! /usr/bin/julia

using formula
using rpn

n_digits = int(ARGS[1])

formula_arrays = read_formulas(n_digits, "data/formulas_%d")
println("Read all formulas")
flush(STDOUT)

all_profitable = formula.Formula[]

for the_formula_array = formula_arrays
   for the_formula = the_formula_array
      if formula.can_generate_profit(the_formula)
         push!(all_profitable, the_formula)
      end
   end
end

println(string("Length(profitable) = ", length(all_profitable)))
flush(STDOUT)

sort!(all_profitable, by = (x -> x.value))

ofh = open("profitable_formulas", "w")
for the_formula = all_profitable
   @printf(ofh, "%s\n", rpn.to_rpn(the_formula.expression))
end
close(ofh)

println("Finished.")
flush(STDOUT)
