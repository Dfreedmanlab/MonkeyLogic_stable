// Mexgen generated this file on Wed Nov  6 12:05:44 2013
// DO NOT EDIT!

#include "mex.h"

void kbdinit (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void kbdinit_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs < 0)
        mexErrMsgTxt ("This function requires at least 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types

    kbdinit (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void kbdrelease (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void kbdrelease_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    kbdrelease (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void kbdflush (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void kbdflush_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    kbdflush (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void kbdgetkey (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void kbdgetkey_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    kbdgetkey (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

typedef void (*MEXFUNCTION) (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

MEXFUNCTION functions[] =
{
    kbdinit_mexgen,
    kbdrelease_mexgen,
    kbdflush_mexgen,
    kbdgetkey_mexgen,
};

static const int MAX_FUNCTIONS = sizeof (functions) / sizeof (void (*) ());

void mexFunction (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs < 1)
        mexErrMsgTxt ("Incorrect number of arguments.\n");

    int mrows = mxGetM (prhs[0]);
    int ncols = mxGetN (prhs[0]);

    if (!mxIsDouble (prhs[0]) || mxIsComplex (prhs[0]) || !(mrows == 1 && ncols == 1))
        mexErrMsgTxt ("Input must be a noncomplex scalar double.\n");

    int findex = (int) (*mxGetPr (prhs[0]));

    if (findex < 0 || findex >= MAX_FUNCTIONS)
        mexErrMsgTxt ("Invalid function index.\n");

    functions[findex] (nlhs, plhs, nrhs - 1, prhs + 1);
}
