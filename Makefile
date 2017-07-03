OUTPUT=mandelbrot

IMAGE=.ppm

CC=mpicc
CC_OPT=-std=c11

CC_PTH=-pthread

TIME_UTILS=time_utils.c

.PHONY: all
all: $(OUTPUT)

$(OUTPUT): $(OUTPUT).c
	$(CC) -o $(OUTPUT) $(CC_PTH) $(TIME_UTILS) $(OUTPUT).c

.PHONY: clean
clean:
	rm $(OUTPUT)
	rm *$(IMAGE)
