module rpn

export to_rpn, from_rpn

# eh, trying to do this super-genericly isn't reasonable
# considering that it all depends on the internals of Julia
# and the foibles of Friedman expressions

# what is Julia function for unary minus?
# * same as for regular subtraction
# what does :(a - b - c) and :(a / b / c) give us?
# * expression as binary tree
# what does :(1) give us?
# * Int64
# what does :(-1) give us?
# * Int64

if (VERSION.major, VERSION.minor) <= (0, 3)
   my_int = int
else
   my_int = (x -> parse(Int, x))
end

fn_tag = Dict([(:+, '+'),
               (:-, '-'),
               (:*, '*'),
               (:/, '/'),
               (:^, '^')])

inv_fn_tag = Dict(collect(zip(values(fn_tag), keys(fn_tag))))

function to_rpn(a)
   # in general, it is assumed that a is a valid expression
   if isa(a, Integer) || isa(a, Int64) || isa(a, Int128) || isa(a, BigInt)
      if a >= 0
         return string(a, " ")
      else
         return string(-a, " !")
      end
   elseif isa(a, Expr)
      if a.head != :call
         error(string("Cannot parse expression head: ", a.head))
      end
      if a.args[1] in [:+, :*]
         if length(a.args) == 2
            return to_rpn(a.args[2])
         elseif length(a.args) == 3
            return string(to_rpn(a.args[3]), to_rpn(a.args[2]), fn_tag[a.args[1]])
         else
            # enforce leftwise association
            return to_rpn(Expr(a.head,
                               a.args[1],
                               Expr(a.head, a.args[1 : end-1]...),
                               a.args[end]))
         end
      elseif a.args[1] in [:/, :^]
         if length(a.args) != 3
            error("Illegal number of arguments (/^)")
         else
            return string(to_rpn(a.args[3]), to_rpn(a.args[2]), fn_tag[a.args[1]])
         end
      elseif a.args[1] == :-
         if length(a.args) == 2
            return string(to_rpn(a.args[2]), "!")
         elseif length(a.args) == 3
            return string(to_rpn(a.args[3]), to_rpn(a.args[2]), fn_tag[a.args[1]])
         else
            error("Illegal number of arguments (-)")
         end
      else
         error(string("Unrecognized operation: ", a.args[1]))
      end
   else
      error(string("Unrecognized type: ", typeof(a)))
   end
end

function from_rpn(a::String)
   digits = "0123456789"
   stack = Any[]
   in_integer = false
   for c in a
      if c in digits
         if in_integer
            stack[1] = stack[1] * 10 + my_int(string(c))
         else
            unshift!(stack, big(my_int(string(c))))
            in_integer = true
         end
      elseif c == ' '
         in_integer = false
      elseif haskey(inv_fn_tag, c)
         if length(stack) < 2
            error(string("Not enough arguments on stack: ", c))
         else
            splice!(stack, 1:2, [Expr(:call,
                                      inv_fn_tag[c],
                                      stack[1],
                                      stack[2])])
         end
      elseif c == '!'
         if length(stack) < 1
            error(string("Not enough arguments on stack: ", c))
         else
            stack[1] = Expr(:call, :-, stack[1])
         end
      else
         error(string("Unrecognized character: ", c))
      end
   end
   if length(stack) != 1
      # error("Unbalanced RPN expression")
      error(string("Unbalanced RPN expression", stack))
   end
   return stack[1]
end

end # module rpn
