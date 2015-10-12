module big_rand

export rand_of_n_digits

function rand_of_n_digits(n::Integer)
   # calling GMP directly is a bit tricky because of the random state object
   # so we just generate it in chunks and join them
   chunk_size = 18
   n_chunks = div(n - 1, chunk_size)
   header_size = n - chunk_size * n_chunks
   header = rand(10 ^ (header_size - 1) : 10 ^ header_size - 1)
   chunks = rand(0 : 10 ^ chunk_size - 1, n_chunks)
   result = big(header)
   for chunk = chunks
      result = (10 ^ chunk_size) * result + chunk
   end
   return result
end

end
