#! /usr/bin/julia

include("set_module_path.jl")

using formula
using rpn

n = int(ARGS[1])

previous = Any[]
for i = collect(1 : n)
   the_formulas = formula.Formula[]
   filename = @sprintf("formulas_%d", i)
   ofh = open(filename, "w")
   if i == n
      cb(x) = (@printf(ofh, "%s\n", rpn.to_rpn(x.expression)))
   else
      cb(x) = (@printf(ofh, "%s\n", rpn.to_rpn(x.expression)); push!(the_formulas, x))
   end
   formula.find_formulas(previous, 200, result_callback = cb)
   close(ofh)
   if i == n
      break
   end
   push!(previous, the_formulas)
end
