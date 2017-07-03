#include <stdlib.h>
#include <math.h>
#include <pthread.h>
#include "time_utils.h"
#include "mpi.h"

double c_x_min = 0.0f;
double c_x_max = 0.0f;
double c_y_min = 0.0f;
double c_y_max = 0.0f;

double pixel_width = 0.0f;
double pixel_height = 0.0f;

int iteration_max = 200;

int image_size;
int rgb_size = 3;
char* image_buffer = NULL;
char* total_image_buffer = NULL;

int i_x_max = 0;
int i_y_max = 0;

// int i_x_min = 0;
int i_y_min = 0;

int image_buffer_size = 0;

int gradient_size = 16;
int colors[17][3] = {
                        {66, 30, 15},
                        {25, 7, 26},
                        {9, 1, 47},
                        {4, 4, 73},
                        {0, 7, 100},
                        {12, 44, 138},
                        {24, 82, 177},
                        {57, 125, 209},
                        {134, 181, 229},
                        {211, 236, 248},
                        {241, 233, 191},
                        {248, 201, 95},
                        {255, 170, 0},
                        {204, 128, 0},
                        {153, 87, 0},
                        {106, 52, 3},
                        {16, 16, 16},
                    };

int nthreads = 0;
pthread_t * thread_pool = NULL;

#define STEPS_SIZE 3


void init(int argc, char *argv[], int num_tasks, int rank){
    if (argc < 7) {

        printf("usage: ./mandelbrot_pth cx_min cx_max cy_min cy_max nthreads image_size\n");
        printf("examples with image_size = 11500:\n");
        printf("    Full Picture:         ./mandelbrot_pth -2.5 1.5 -2.0 2.0 8 11500\n");
        printf("    Seahorse Valley:      ./mandelbrot_pth -0.8 -0.7 0.05 0.15 8 11500\n");
        printf("    Elephant Valley:      ./mandelbrot_pth 0.175 0.375 -0.1 0.1 8 11500\n");
        printf("    Triple Spiral Valley: ./mandelbrot_pth -0.188 -0.012 0.554 0.754 8 11500\n");
        exit(0);

    } else {

        sscanf(argv[1], "%lf", &c_x_min);
        sscanf(argv[2], "%lf", &c_x_max);
        sscanf(argv[3], "%lf", &c_y_min);
        sscanf(argv[4], "%lf", &c_y_max);
        sscanf(argv[5], "%d", &nthreads);
        sscanf(argv[6], "%d", &image_size);

        thread_pool = (pthread_t *) malloc(sizeof(pthread_t) * nthreads);

        i_x_max           = image_size;
        i_y_max           = (image_size / num_tasks) * (rank + 1);

        i_y_min           = (image_size / num_tasks) * rank;

        image_buffer_size = i_x_max * (image_size / num_tasks);

        pixel_width       = (c_x_max - c_x_min) / image_size;
        pixel_height      = (c_y_max - c_y_min) / image_size;
    };
};


void update_rgb_buffer(int iteration, int x, int y){

    char* tmp_pointer = NULL;
    int color = gradient_size;

    if(iteration != iteration_max){
        color = iteration % gradient_size;
    };

    y = y - i_y_min;
    tmp_pointer  = image_buffer + (((y * image_size) + x) * rgb_size);
    *tmp_pointer = (char)colors[color][0];

    tmp_pointer  += 1;
    *tmp_pointer = (char)colors[color][1];

    tmp_pointer  += 1;
    *tmp_pointer = (char)colors[color][2];
};


void write_to_file(){
    FILE * file = NULL;
    char * filename = "output.ppm";
    char * comment  = "# ";

    int max_color_component_value = 255;

    file = fopen(filename,"wb");

    fprintf(file, "P6\n %s\n %d\n %d\n %d\n", comment,
            image_size, image_size, max_color_component_value);

    fwrite(total_image_buffer, 1, image_size * image_size * 3, file);

    fclose(file);
};


void* compute_mandelbrot(void* args){

    double z_x = 0.0f;
    double z_y = 0.0f;
    double z_x_squared = 0.0f;
    double z_y_squared = 0.0f;
    double escape_radius_squared = 4.0;

    int iteration = 0;
    int i_x = 0;
    int i_y = 0;

    double c_x = 0.0f;
    double c_y = 0.0f;

    int* args_arr = (int *) args;
    int init = args_arr[0];
    int end = args_arr[1];    

    for(i_y = init; i_y < end; i_y++){
        c_y = c_y_min + i_y * pixel_height;

        if(fabs(c_y) < pixel_height / 2){
            c_y = 0.0;
        };

        for(i_x = 0; i_x < i_x_max; i_x++){
            c_x         = c_x_min + i_x * pixel_width;

            z_x         = 0.0;
            z_y         = 0.0;

            z_x_squared = 0.0;
            z_y_squared = 0.0;

            for(iteration = 0;
                iteration < iteration_max && \
                ((z_x_squared + z_y_squared) < escape_radius_squared);
                iteration++){
                z_y         = 2 * z_x * z_y + c_y;
                z_x         = z_x_squared - z_y_squared + c_x;

                z_x_squared = z_x * z_x;
                z_y_squared = z_y * z_y;
            };

            update_rgb_buffer(iteration, i_x, i_y);
        };
    };

    return NULL;
};

void call_mandelbrot(){

    int chunk = i_y_max/nthreads;
    int init = 0, end = 0, i = 0;
    for(i = 0, init = i_y_min, end = init + chunk; i < nthreads; end += chunk, init += chunk, i++){

        if(end > i_y_max)
            end = i_y_max;

        int * args = (int *) malloc(sizeof(int) * 2);
        args[0] = init;
        args[1] = end;
        pthread_create(&thread_pool[i], NULL, compute_mandelbrot, (void *) args);
    };
}


int main(int argc, char *argv[]){

    /* Initialize MPI and get:
     * 1 - Total number of processes
     * 2 - Rank of current process
    */
    MPI_Init(&argc, &argv);

    int num_tasks = 0;
    MPI_Comm_size(MPI_COMM_WORLD, &num_tasks);

    int rank = 0;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    /*************************/

    init(argc, argv, num_tasks, rank);

    /* Initialize Time Utils */
    struct timespec wc_start[STEPS_SIZE], wc_end[STEPS_SIZE];
    double cpu_start[STEPS_SIZE], cpu_end[STEPS_SIZE];
    /*************************/

    /* Allocate Memory */
    start_timers(cpu_start, wc_start, alloc);
    image_buffer = (char *) malloc(sizeof(char) * 3 * image_buffer_size);
    if (rank == 0) {
        total_image_buffer = (char *) malloc(sizeof(char) * image_size * 3 * image_size);
    }
    end_timers(cpu_end, wc_end, alloc);
    /*************************/

    /* Execute Algorithm */
    start_timers(cpu_start, wc_start, calc);
    call_mandelbrot();
    int i = 0;
    for(i = 0; i < nthreads; i++)
        pthread_join(thread_pool[i], NULL);

    MPI_Gather(image_buffer, 3 * image_buffer_size, MPI_CHAR, total_image_buffer, 3 * image_buffer_size, MPI_CHAR, 0, MPI_COMM_WORLD);
    end_timers(cpu_end, wc_end, calc);
    /*************************/

    /* Write to File */
    start_timers(cpu_start, wc_start, ioops);
    if (rank == 0)
        write_to_file();
    end_timers(cpu_end, wc_end, ioops);
    /*************************/

    MPI_Finalize();
    printf("Processing an image of size %d with %d threads\n", image_size,nthreads);
    print_elapsed(cpu_start, wc_start, cpu_end, wc_end);

    return 0;
};
