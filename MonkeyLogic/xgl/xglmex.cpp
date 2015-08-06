// Mexgen generated this file on Mon Feb 18 08:10:33 2013
// DO NOT EDIT!

#include "mex.h"

void xglpfgs (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglpfgs_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    xglpfgs (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglpfrgb8 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglpfrgb8_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    xglpfrgb8 (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglpfyv12 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglpfyv12_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    xglpfyv12 (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglpfrgb10 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglpfrgb10_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    xglpfrgb10 (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglpfrgbf32 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglpfrgbf32_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    xglpfrgbf32 (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglrgb8 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglrgb8_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    if (!mxIsDouble (prhs[2]))
        mexErrMsgTxt ("Input 3 must be double.");
    if (mxIsComplex (prhs[2]))
        mexErrMsgTxt ("Input 3 may not be complex.");

    xglrgb8 (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglrgb10 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglrgb10_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    if (!mxIsDouble (prhs[2]))
        mexErrMsgTxt ("Input 3 must be double.");
    if (mxIsComplex (prhs[2]))
        mexErrMsgTxt ("Input 3 may not be complex.");

    xglrgb10 (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglinit (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglinit_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs < 0)
        mexErrMsgTxt ("This function requires at least 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types

    xglinit (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglrelease (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglrelease_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    xglrelease (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xgldevices (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xgldevices_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    xgldevices (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglinfo (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglinfo_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xglinfo (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsChar (plhs[0]))
        mexErrMsgTxt ("Output 1 must be char.");

}

void xglrect (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglrect_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xglrect (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xgltotalmodes (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xgltotalmodes_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xgltotalmodes (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglcurrentmode (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglcurrentmode_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xglcurrentmode (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglgetmode (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglgetmode_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    if (!mxIsDouble (prhs[2]))
        mexErrMsgTxt ("Input 3 must be double.");
    if (mxIsComplex (prhs[2]))
        mexErrMsgTxt ("Input 3 may not be complex.");

    xglgetmode (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglhwconversion (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglhwconversion_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    if (!mxIsDouble (prhs[2]))
        mexErrMsgTxt ("Input 3 must be double.");
    if (mxIsComplex (prhs[2]))
        mexErrMsgTxt ("Input 3 may not be complex.");

    xglhwconversion (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsLogical (plhs[0]))
        mexErrMsgTxt ("Output 1 must be logical.");

}

void xglinitdevice (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglinitdevice_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    if (!mxIsDouble (prhs[2]))
        mexErrMsgTxt ("Input 3 must be double.");
    if (mxIsComplex (prhs[2]))
        mexErrMsgTxt ("Input 3 may not be complex.");

    xglinitdevice (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglreleasedevice (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglreleasedevice_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xglreleasedevice (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglclear (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglclear_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    if (!mxIsDouble (prhs[2]))
        mexErrMsgTxt ("Input 3 must be double.");
    if (mxIsComplex (prhs[2]))
        mexErrMsgTxt ("Input 3 may not be complex.");

    xglclear (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglflip (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglflip_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xglflip (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglgetrasterstatus (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglgetrasterstatus_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs != 2)
        mexErrMsgTxt ("This function requires 2 return values.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xglgetrasterstatus (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsLogical (plhs[0]))
        mexErrMsgTxt ("Output 1 must be logical.");

    if (!plhs[1])
        mexErrMsgTxt ("Output 2 was not allocated.");
    if (!mxIsDouble (plhs[1]))
        mexErrMsgTxt ("Output 2 must be double.");
    if (mxIsComplex (plhs[1]))
        mexErrMsgTxt ("Output 2 may not be complex.");

}

void xglcreatebuffer (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglcreatebuffer_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglcreatebuffer (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglreleasebuffer (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglreleasebuffer_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglreleasebuffer (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglreleasebuffers (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglreleasebuffers_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xglreleasebuffers (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglclearbuffer (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglclearbuffer_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    if (!mxIsDouble (prhs[2]))
        mexErrMsgTxt ("Input 3 must be double.");
    if (mxIsComplex (prhs[2]))
        mexErrMsgTxt ("Input 3 may not be complex.");

    xglclearbuffer (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglcopybuffer (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglcopybuffer_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");


    xglcopybuffer (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglblit (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglblit_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs < 2)
        mexErrMsgTxt ("This function requires at least 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");


    xglblit (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglgetcursor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglgetcursor_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 0)
        mexErrMsgTxt ("This function requires 0 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    xglgetcursor (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglsetcursor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetcursor_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xglsetcursor (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglshowcursor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglshowcursor_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglshowcursor (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsetlut (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetlut_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetlut (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xgltotalfonts (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xgltotalfonts_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xgltotalfonts (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xglfontname (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglfontname_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglfontname (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsChar (plhs[0]))
        mexErrMsgTxt ("Output 1 must be char.");

}

void xglsetfont (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetfont_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetfont (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsetpointsize (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetpointsize_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetpointsize (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsetescapement (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetescapement_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetescapement (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsettextcolor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsettextcolor_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsettextcolor (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsetbgcolor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetbgcolor_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetbgcolor (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsetbgtrans (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetbgtrans_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetbgtrans (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsetitalic (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetitalic_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetitalic (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsetunderline (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetunderline_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetunderline (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglsetstrikeout (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglsetstrikeout_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    xglsetstrikeout (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xgltextwidth (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xgltextwidth_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 2)
        mexErrMsgTxt ("This function requires 2 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsChar (prhs[1]))
        mexErrMsgTxt ("Input 2 must be char.");

    xgltextwidth (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xgltextheight (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xgltextheight_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 1)
        mexErrMsgTxt ("This function requires 1 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    xgltextheight (nlhs, plhs, nrhs, prhs);

    // Check output types
    if (!plhs[0])
        mexErrMsgTxt ("Output 1 was not allocated.");
    if (!mxIsDouble (plhs[0]))
        mexErrMsgTxt ("Output 1 must be double.");
    if (mxIsComplex (plhs[0]))
        mexErrMsgTxt ("Output 1 may not be complex.");

}

void xgltext (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xgltext_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Check inputs
    if (nrhs != 3)
        mexErrMsgTxt ("This function requires 3 arguments.");

    // Check outputs
    if (nlhs > 1)
        mexErrMsgTxt ("Too many return values were specified.");

    // Check input types
    if (!mxIsDouble (prhs[0]))
        mexErrMsgTxt ("Input 1 must be double.");
    if (mxIsComplex (prhs[0]))
        mexErrMsgTxt ("Input 1 may not be complex.");

    if (!mxIsDouble (prhs[1]))
        mexErrMsgTxt ("Input 2 must be double.");
    if (mxIsComplex (prhs[1]))
        mexErrMsgTxt ("Input 2 may not be complex.");

    if (!mxIsChar (prhs[2]))
        mexErrMsgTxt ("Input 3 must be char.");

    xgltext (nlhs, plhs, nrhs, prhs);

    // Check output types
}

void xglgetcursor_buttonstate (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

void xglgetcursor_buttonstate_mexgen (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    xglgetcursor_buttonstate (nlhs, plhs, nrhs, prhs);

	// Check output types
}

typedef void (*MEXFUNCTION) (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]);

MEXFUNCTION functions[] =
{
    xglpfgs_mexgen,
    xglpfrgb8_mexgen,
    xglpfyv12_mexgen,
    xglpfrgb10_mexgen,
    xglpfrgbf32_mexgen,
    xglrgb8_mexgen,
    xglrgb10_mexgen,
    xglinit_mexgen,
    xglrelease_mexgen,
    xgldevices_mexgen,
    xglinfo_mexgen,
    xglrect_mexgen,
    xgltotalmodes_mexgen,
    xglcurrentmode_mexgen,
    xglgetmode_mexgen,
    xglhwconversion_mexgen,
    xglinitdevice_mexgen,
    xglreleasedevice_mexgen,
    xglclear_mexgen,
    xglflip_mexgen,
    xglgetrasterstatus_mexgen,
    xglcreatebuffer_mexgen,
    xglreleasebuffer_mexgen,
    xglreleasebuffers_mexgen,
    xglclearbuffer_mexgen,
    xglcopybuffer_mexgen,
    xglblit_mexgen,
    xglgetcursor_mexgen,
    xglsetcursor_mexgen,
    xglshowcursor_mexgen,
    xglsetlut_mexgen,
    xgltotalfonts_mexgen,
    xglfontname_mexgen,
    xglsetfont_mexgen,
    xglsetpointsize_mexgen,
    xglsetescapement_mexgen,
    xglsettextcolor_mexgen,
    xglsetbgcolor_mexgen,
    xglsetbgtrans_mexgen,
    xglsetitalic_mexgen,
    xglsetunderline_mexgen,
    xglsetstrikeout_mexgen,
    xgltextwidth_mexgen,
    xgltextheight_mexgen,
    xgltext_mexgen,
	xglgetcursor_buttonstate_mexgen,
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
