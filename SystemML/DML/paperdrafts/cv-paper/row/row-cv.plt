set terminal postscript enhanced color eps
set output "row-cv.eps"
set xlabel "(A) numRows, in millions"
set ylabel "time, s" offset 1.8
set key top left
set size 0.45,0.45
plot 'row-cv.data' u 1:4 w lp lc 1 lt 1 t "Reblock-Based", '' u 1:3 w lp lc 2 lt 2 t "Join-Reblock", '' u 1:2 w lp lc 3 lt 3 t "HashMap"
