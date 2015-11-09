#! /usr/bin/julia

profitable_db_filename = "data/profitable_formulas"
target_digits = 800
the_seed = 2718281828

using big_rand
using formula
using ff_digits
using rpsr
using rpn
using cleanup
using absorb
using big_eval

if (VERSION.major, VERSION.minor) <= (0, 3)
   my_int = int
   my_ifloor = ifloor
else
   my_int = (x -> parse(Int, x))
   my_ifloor = (x -> floor(Integer, x))
end

println(string("Seed = ", the_seed))
srand(the_seed)

quiet = false
verbose = false
timing = true
logging = false

logfile_name = "demonstration_output.log"

profitable_db_digits_upper_bound = 200
quotient_size_margin = 5
min_target_digits = 400

# target_digits = my_int(ARGS[1])
# if length(ARGS) > 1
#    profitable_db_filename = ARGS[2]
# end

if target_digits < min_target_digits
   error(string("Size of targets in digits must be at least", min_target_digits))
end

if quiet && verbose
   error("Choose one or none of : quiet, verbose")
end

println("Reading all profitable formulas:")
flush(STDOUT)
if timing
   tic()
end
profit_candidates = formula.read_formula_file(profitable_db_filename)
println(string("Read all profitable formulas."))
if timing
   toc()
end
flush(STDOUT)

# rpsr = "recursive product-sum representation"

attempts = 0
successes = 0
if logging
   logging_fh = open(logfile_name, "w")
end
while true
   target = big_rand.rand_of_n_digits(target_digits)
   let ofh = open("current_target.rpn", "w")
      @printf(ofh, "%s\n", rpn.to_rpn(target))
      close(ofh)
   end
   if logging
      @printf(logging_fh, "%s\n", string(target))
      flush(logging_fh)
   end

   if timing
      tic()
   end
   target_digit_hist = ff_digits.digit_hist(target)

   the_rpsr = target
   number_of_rpsrs = 0

   if ! quiet
      println(target)
      flush(STDOUT)
   end
   
   while true
      if verbose && (number_of_rpsrs > 0)
         show(the_rpsr)
         println()
         println()
         flush(STDOUT)
      end
      if isa(the_rpsr, BigInt)
         the_rpsr = rpsr.represent(the_rpsr, profit_candidates)
      elseif isa(the_rpsr, Expr)
         if (ff_digits.number_of_digits(process_tail_of_rpsr(the_rpsr, x -> x))
             < (profitable_db_digits_upper_bound + quotient_size_margin))
            break
         end
         # for really large RPSRs this algorithm should be improved
         process_tail_of_rpsr(the_rpsr, x -> rpsr.represent(x, profit_candidates))
      else
         error("Unrecognized input")
      end
      number_of_rpsrs += 1
   end
   println(string("Finished RPSR stage : ", number_of_rpsrs, " PSRs"))
   if timing
      toc()
   end
   flush(STDOUT)

   if timing
      tic()
   end

   let ofh = open("current_rpsr.rpn", "w")
      @printf(ofh, "%s\n", rpn.to_rpn(the_rpsr))
      close(ofh)
   end

   # 0.3 is arbitrary guess, could be tuned
   cleanup_via_psr_cutoff = my_ifloor(profitable_db_digits_upper_bound * 0.3)
   the_cleaned_rpsr = cleanup.cleanup_rpsr(target, the_rpsr, profit_candidates, cleanup_via_psr_cutoff)
   the_surplus = ff_digits.digit_hist(target) - ff_digits.digit_hist(the_cleaned_rpsr)
   println(string("Finished initial cleanup stage : surplus = ", the_surplus))
   if timing
      toc()
   end

   if sum(ff_digits.digit_deficit(the_surplus)) > 0
      if timing
         tic()
      end

      the_cleaned_rpsr = cleanup.cleanup_rpsr_via_sum(target, the_cleaned_rpsr, 5)

      the_surplus = ff_digits.digit_hist(target) - ff_digits.digit_hist(the_cleaned_rpsr)
      println(string("Finished secondary cleanup stage : surplus = ", the_surplus))
      
      if timing
         toc()
      end
   end
   
   the_final_formula = ""
   try
      the_final_formula = absorb.absorb_surplus(the_cleaned_rpsr, the_surplus)
   catch the_error
      show(the_error)
      println()
   end
   if ff_digits.total_discrepancy(target_digit_hist, ff_digits.digit_hist(the_final_formula)) > 0
      println("Formula calculation failed!")
      if logging
         @printf(logging_fh, "%s\n", "Failed")
         flush(logging_fh)
      end
   else
      # final check
      if big_eval.eval(the_final_formula) == target
         successes += 1
         if logging
            @printf(logging_fh, "%s\n", string(the_final_formula))
            flush(logging_fh)
         end
      else
         show(target)
         println()
         show(the_final_formula)
         println()
         if logging
            @printf(logging_fh, "%s\n", "Failed")
            flush(logging_fh)
         end
         error("Formula value discrepancy!")
      end
   end
   attempts += 1
   if ! quiet
      show(the_final_formula)
      println()
      println()
      flush(STDOUT)
   end

   println("===========")
   println(string(successes, " successes, ", attempts, " attempts"))
   println("===========")
end
