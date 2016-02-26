# ff-compute

This software is a proof-of-concept to demonstrate a practical algorithm for proving that large random numbers are [Friedman numbers](https://en.wikipedia.org/wiki/Friedman_number). It is written in Julia, and has been lightly tested for Julia versions 0.3.x and 0.4.x . You probably shouldn't run it with anything less than version 0.4, however; it runs roughly an order of magnitude faster with my personally compiled (MARCH=native) version 0.4 vs. the version 0.3 binaries provided by most Linux distros. Additionally, in order to run it using the following instructions, you will need a computer with at least 3 GiB of RAM, and a lot of patience. This code is my first attempt to code in Julia, so it is currently not very well optimized.

After cloning or downloading a copy of the repository, the following steps are necessary in order to run the demonstration program, "demonstration.jl".

1. Uncompress the file "profitable_formulas.xz" from the "data" directory.
2. Edit the top of "demonstration.jl" so that the variable "profitable_db_filename" is initialized to where the uncompressed file from (1) is located.
3. In the same place, if you want, change the value of "target_digits": larger values will require longer calculation times, but will have greater probabilities of success.
4. If you want a separate log file to be written with the random targets and any successfully generated formulas, set the value of "logging" to true.
5. If you want to be _really_ adventuresome and have a _fully customized_ Friedman formula calculation experience, you should also change the value of the "seed" variable.
6. Run the file "demonstration.jl" using your Julia installation. The program is currently rather verbose even on the default settings, since it, like Julia, is still in alpha.

There is a PDF file in the repository which explains the mathematical basis for the algorithm. (If anyone can help me find an endorser for the math-NT section of arXiv, please let me know.)

If you have a computer which is fast enough and has enough memory, you could calculate a much larger database of profitable formulas with up to 6 digits (see the "write_to_N.jl" and "profitable.jl" scripts). Of course, using such a database would be much more time consuming, but would probably enable calculating formulas for smaller targets.
