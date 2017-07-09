#! /bin/bash

set -o xtrace

MEASUREMENTS=10
SIZE=8192
INSTANCES=localhost
THREADS=$(nproc)

make
mkdir results

#MANDELBROT: Execução com uma instância com 8 cores
#mkdir results/uma_instancia

#for ((k = 1; k<=MEASUREMENTS; k++)); do
#	perf stat -d mpirun -host $INSTANCES ./mandelbrot -2.500  1.500 -2.000 2.000 $THREADS $SIZE >> full.log 2>&1
#	perf stat -d mpirun -host $INSTANCES ./mandelbrot -0.800 -0.700  0.050 0.150 $THREADS $SIZE >> seahorse.log 2>&1
#	perf stat -d mpirun -host $INSTANCES ./mandelbrot  0.175  0.375 -0.100 0.100 $THREADS $SIZE >> elephant.log 2>&1
#	perf stat -d mpirun -host $INSTANCES ./mandelbrot -0.188 -0.012  0.554 0.754 $THREADS $SIZE >> triplesp.log 2>&1
#done

#mv *.log results/uma_instancia
#rm output.ppm

#MANDELBROT: Execução com duas instâncias com 4 cores
mkdir results/uma_instancia

perf stat -r $MEASUREMENTS -d mpirun -host $INSTANCES ./mandelbrot -2.500  1.500 -2.000 2.000 $THREADS $SIZE >> full.log 2>&1
perf stat -r $MEASUREMENTS -d mpirun -host $INSTANCES ./mandelbrot -0.800 -0.700  0.050 0.150 $THREADS $SIZE >> seahorse.log 2>&1
perf stat -r $MEASUREMENTS -d mpirun -host $INSTANCES ./mandelbrot  0.175  0.375 -0.100 0.100 $THREADS $SIZE >> elephant.log 2>&1
perf stat -r $MEASUREMENTS -d mpirun -host $INSTANCES ./mandelbrot -0.188 -0.012  0.554 0.754 $THREADS $SIZE >> triplesp.log 2>&1

mv *.log results/uma_instancia
rm output.ppm



