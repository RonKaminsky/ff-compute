baremodule big_eval

eval(x) = Core.eval(big_eval, x)
eval(m, x) = Core.eval(m, x)

using Base

# override arithmetic to do forced promotion to BigInt and result demotion to BigInt (/)

function big_add(a::Integer, b::Integer)
   return Base.(:+)(big(a), b)
end

(+) = big_add

function big_subtract(a::Integer)
   return Base.(:-)(big(a))
end

function big_subtract(a::Integer, b::Integer)
   return Base.(:-)(big(a), b)
end

(-) = big_subtract

function big_multiply(a::Integer, b::Integer)
   return Base.(:*)(big(a), b)
end

(*) = big_multiply

function big_divide(a::Integer, b::Integer)
   return Base.div(big(a), b)
end

(/) = big_divide

function big_exponentiate(a::Integer, b::Integer)
   return Base.(:^)(big(a), b)
end

(^) = big_exponentiate

end # module big_eval
