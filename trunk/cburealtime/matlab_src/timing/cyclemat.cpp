// High performance timing in Matlab
// Rhodri Cusack, Berlin 2011

#include "math.h"
#include "mex.h"
#include "cycle.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{ 
 ticks t1;
 t1=getticks();
 ticks t2;
 t2=getticks();
 printf("Elapsed time is %f\n",elapsed(t2,t1));
 return;
}