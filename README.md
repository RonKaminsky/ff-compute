# ff-compute

This software is a proof-of-concept to demonstrate a practical algorithm for proving that large random numbers are Friedman numbers. It is written in Julia.

After cloning or downloading a copy of the repository, the following steps are necessary in order to run the demonstration program, "demonstration.jl".

1. Uncompress the file "profitable_formulas.xz" .
2. Edit the top of "demonstration.jl" so that the variable "profitable_db_filename" is initialized to where the uncompressed file from (1) is located.
3. In the same place, if you want, change the value of "target_digits": larger values will require longer calculation times, but will have greater probabilities of success.
4. If you want to be _really_ adventuresome and have a _fully customized_ Friedman formula calculation experience, you should also change the value of the "seed" variable.
5. Run the file "demonstration.jl" using your Julia installation. The program is currently rather verbose even on the default settings, since it, like Julia, is still in alpha.

There is a PDF file in the repository which explains the mathematical basis for the algorithm. (If anyone can help me find an endorser for the math-NT section of arXiv, please let me know.)

If you have a computer which is fast enough and has enough memory, you could calculate a much larger database of profitable formulas with up to 6 digits. Of course, using such a database would be much more time consuming, but would probably enable calculating formulas for smaller targets.
