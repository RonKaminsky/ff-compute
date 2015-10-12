module ff_digits

using rpn
using formula

if (VERSION.major, VERSION.minor) <= (0, 3)
   my_int = int
   my_ifloor = ifloor
else
   my_int = (x -> parse(Int, x))
   my_ifloor = (x -> floor(Integer, x))
end

export number_of_digits, digit_hist
export digit_surplus, digit_deficit

type DigitHist
   freq::Array{Int, 1}
end

function digit_hist(n::Integer)
   return digit_hist(string(n))
end

function digit_hist(exp::Expr)
   return digit_hist(rpn.to_rpn(exp))
end

function digit_hist(the_string::String)
   result = DigitHist(zeros(10))
   for c in the_string
      if isdigit(c)
         result.freq[my_int(string(c)) + 1] += 1
      end
   end
   return result
end

function digit_hist(dummy::Nothing)
   return DigitHist(zeros(10))
end

function Base.start(dh::DigitHist)
   return start(dh.freq)
end

function Base.done(dh::DigitHist, state)
   return done(dh.freq, state)
end

function Base.next(dh::DigitHist, state)
   return next(dh.freq, state)
end

function Base.eltype(::Type{DigitHist})
   return Int
end

function Base.(:-)(dh1::DigitHist)
   return DigitHist(-dh1.freq)
end

function Base.(:-)(dh1::DigitHist, dh2::DigitHist)
   return DigitHist(dh1.freq - dh2.freq)
end

function Base.(:+)(dh1::DigitHist, dh2::DigitHist)
   return DigitHist(dh1.freq + dh2.freq)
end

function digit_surplus(hist::Array{Int, 1})
   return [x * (x > 0) for x = hist]
end

function digit_deficit(hist::Array{Int, 1})
   return [(-x) * (x < 0) for x = hist]
end

function digit_surplus(dh::DigitHist)
   return [x * (x > 0) for x = dh.freq]
end

function digit_deficit(dh::DigitHist)
   return [(-x) * (x < 0) for x = dh.freq]
end

function digit_deficit(target::DigitHist, candidate::DigitHist)
   return digit_deficit(target - candidate)
end

function digit_surplus(target::DigitHist, candidate::DigitHist)
   return digit_surplus(target - candidate)
end

function total_discrepancy(target::DigitHist, candidate::DigitHist)
   return sum(abs(target.freq - candidate.freq))
end

# this should be isolated since it depends on Julia internals to work
function number_of_digits(n::BigInt)
   if (VERSION.major, VERSION.minor) <= (0, 3)
      my_int = int
   else
      my_int = Int
   end
   approx_digits = my_int(ccall((:__gmpz_sizeinbase, :libgmp),
                                Culong, (Ptr{BigInt}, Int64), &n, 10))
   if n >= formula.power_of_10(approx_digits - 1)
      return approx_digits
   else
      return approx_digits - 1
   end
end

function number_of_digits(n::Integer)
   if n == zero(n)
      return 1
   end
   return my_ifloor(log10(abs(n))) + 1
end

function number_of_digits(exp::Expr)
   return number_of_digits(rpn.to_rpn(exp))
end

function number_of_digits(the_string::String)
   # more concise, but is it faster?:
   #   sum([isdigit(c) for c = the_string])
   result = 0
   for c in the_string
      if isdigit(c)
         result += 1
      end
   end
   return result
end

end # module digits
