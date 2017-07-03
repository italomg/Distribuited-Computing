#! /bin/bash

set -o xtrace

MEASUREMENTS=10
ITERATIONS_THREAD=2
ITERATIONS_SIZE=2
INITIAL_THREADS=$(nproc)
IMG_SIZE=512

make

#MANDELBROT: Sequential printing only algorithm time
mkdir results

for ((i=1; i<=$ITERATIONS_SIZE; i++)); do
    THREADS=$INITIAL_THREADS
    for ((j=1; j<=$ITERATIONS_THREAD; j++)); do
        for ((k = 1; k<=MEASUREMENTS; k++)); do
            (mpirun -host $@ ./mandelbrot -2.500  1.500 -2.000 2.000 $THREADS $IMG_SIZE) >> full.log 2>&1
            (mpirun -host $@ ./mandelbrot -0.800 -0.700  0.050 0.150 $THREADS $IMG_SIZE) >> seahorse.log 2>&1
            (mpirun -host $@ ./mandelbrot  0.175  0.375 -0.100 0.100 $THREADS $IMG_SIZE) >> elephant.log 2>&1
            (mpirun -host $@ ./mandelbrot -0.188 -0.012  0.554 0.754 $THREADS $IMG_SIZE) >> triplesp.log 2>&1
        done
        THREADS=$(($THREADS * 2))
    done
    IMG_SIZE=$(($IMG_SIZE * 2))
done

mv *.log results
rm output.ppm