// xgl library handlers for Mexgen mexfile generator
//
// Copyright (C) 2003 Center for Perceptual Systems
//
// jsp created Mon Aug 25 14:51:18 CDT 2003

#include "mex.h"
#include "version.h"
#include "xgl.h"
#include <windows.h>
#include <algorithm>
#include <utility>
#include <string>

using namespace std;
using namespace XGL;

static LRESULT CALLBACK KeyboardHookProc (int code, WPARAM vkey, LPARAM param);
static LRESULT CALLBACK MouseHookProc (int code, WPARAM vkey, LPARAM param);

void ReportErrorAndExit (const char *e);

// The global instance is responsible for keeping track of what has
// been inited and released.
class Instance
{
    public:
    Instance () :
        xgl (0),
        keyboard_hook (0),
        mouse_hook (0)
    {
    }
    ~Instance ()
    {
        Release ();
    }
    void Init ()
    {
        if (xgl) // Already initted
            return;

#if defined(MEXW32)
        HMODULE hmodule = GetModuleHandle ("xglmex.mexw32");
#elif defined(MEXW64)
        HMODULE hmodule = GetModuleHandle ("xglmex.mexw64");
#else
#error "No MATLAB Extension Specified"
#endif

        if (!hmodule)
            ReportErrorAndExit ("Could not get module handle for xglmex.mexw32.");

        keyboard_hook = SetWindowsHookEx (WH_KEYBOARD, KeyboardHookProc, hmodule, 0);

        if (!keyboard_hook)
            ReportErrorAndExit ("Could not install keyboard hook procedure.");

        //mouse_hook = SetWindowsHookEx (WH_MOUSE, MouseHookProc, hmodule, 0);

        //if (!mouse_hook)
        //    ReportErrorAndExit ("Could not install mouse hook procedure.");

        xgl = new Session;

        try
        {
            xgl->Init ();
        }
        catch (const char *e)
        {
            ReportErrorAndExit (e);
        }
    }
    void Release ()
    {
        // Release is called by the destructor and therefore should
        // not throw exceptions or terminate the application.
        if (xgl)
        {
            delete xgl;
            xgl = 0;
        }

        if (keyboard_hook)
        {
            if (!UnhookWindowsHookEx (keyboard_hook))
                mexPrintf ("Warning: Could not release keyboard hook procedure.\n");
            keyboard_hook = 0;
        }

        if (mouse_hook)
        {
            if (!UnhookWindowsHookEx (mouse_hook))
                mexPrintf ("Warning: Could not release mouse hook procedure.\n");
            mouse_hook = 0;
        }
    }
    Session *operator-> ()
    {
        if (!xgl)
            throw "XGL has not been initialized";
        return xgl;
    }
    HHOOK KeyboardHook () { return keyboard_hook; }
    HHOOK MouseHook () { return mouse_hook; }

    private:
    Session *xgl;
    HHOOK keyboard_hook;
    HHOOK mouse_hook;
} instance;

void ReportErrorAndExit (const char *e)
{
    instance.Release ();
    mexErrMsgTxt (e);
}

static LRESULT CALLBACK KeyboardHookProc (int code, WPARAM vkey, LPARAM param)
{
    if (code < 0) // Do not process this message
        return CallNextHookEx (instance.KeyboardHook (), code, vkey, param);

    //mexPrintf ("xgl vkey: %d, scancode: %d\n", vkey, (param >> 16) & 0xFF);
    int scan = (param >> 16) & 0xFF;
    int alt = (param >> 29) & 1;

    // If alt-F12 is pressed, release everything
    if (alt && (scan == 88))
        instance.Release ();

    // Let it pass through.
    return CallNextHookEx (instance.KeyboardHook (), code, vkey, param);
}

static LRESULT CALLBACK MouseHookProc (int code, WPARAM vkey, LPARAM param)
{
    if (code < 0) // Do not process this message
        return CallNextHookEx (instance.MouseHook (), code, vkey, param);

    // Throw away this mouse event...
    return 1;
}

void xglpfgs (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Create a scalar and put the rgb value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *r = mxGetPr (plhs[0]);
    r[0] = static_cast<double> (PF_L8 + 1);
}

void xglpfrgb8 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Create a scalar and put the rgb value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *r = mxGetPr (plhs[0]);
    r[0] = static_cast<double> (PF_X8R8G8B8 + 1);
}

void xglpfyv12 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Create a scalar and put the rgb value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *r = mxGetPr (plhs[0]);
    r[0] = static_cast<double> (PF_YV12 + 1);
}

void xglpfrgb10 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Create a scalar and put the rgb value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *r = mxGetPr (plhs[0]);
    r[0] = static_cast<double> (PF_A2R10G10B10 + 1);
}

void xglpfrgbf32 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Create a scalar and put the rgb value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *r = mxGetPr (plhs[0]);
    r[0] = static_cast<double> (PF_A32B32G32R32F + 1);
}

void xglrgb8 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned n =  mxGetNumberOfElements (prhs[0]);
    if (mxGetNumberOfElements (prhs[1]) != n || mxGetNumberOfElements (prhs[2]) != n)
        ReportErrorAndExit ("The R, G, and B vectors must all contain the same number of elements");

    double *p0 = mxGetPr (prhs[0]);
    double *p1 = mxGetPr (prhs[1]);
    double *p2 = mxGetPr (prhs[2]);

    // Create a scalar and put the rgb value into it
    const int dims[2] = { 1, n };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *r = mxGetPr (plhs[0]);

    for (unsigned i =0; i < n; ++i)
        r[i] = MakeRGB8 (static_cast<unsigned> (p0[i]), static_cast<unsigned> (p1[i]), static_cast<unsigned> (p2[i]));
}

void xglrgb10 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned n =  mxGetNumberOfElements (prhs[0]);
    if (mxGetNumberOfElements (prhs[1]) != n || mxGetNumberOfElements (prhs[2]) != n)
        ReportErrorAndExit ("The R, G, and B vectors must all contain the same number of elements");

    double *p0 = mxGetPr (prhs[0]);
    double *p1 = mxGetPr (prhs[1]);
    double *p2 = mxGetPr (prhs[2]);

    // Create a scalar and put the rgb value into it
    const int dims[2] = { 1, n };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *r = mxGetPr (plhs[0]);

    for (unsigned i =0; i < n; ++i)
        r[i] = MakeRGB10 (static_cast<unsigned> (p0[i]), static_cast<unsigned> (p1[i]), static_cast<unsigned> (p2[i]));
}

/*
void xglrgbf16 (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (mxGetNumberOfElements (prhs[0]) != 3)
        ReportErrorAndExit ("Incorrect number of elements in the rgb vector");

    double *p = mxGetPr (prhs[0]);

    // Create a scalar and put the rgb value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxUINT64_CLASS, mxREAL);
    RGBFloat16 *r = static_cast<RGBFloat16 *> (mxGetData (plhs[0]));
    r[0] = MakeRGBFloat16 (static_cast<float> (p[0]), static_cast<float> (p[1]), static_cast<float> (p[2]));
}
*/

static bool g_debug = false;

void xglinit (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs > 0)
        g_debug = static_cast<bool> (*mxGetPr (prhs[0]) != 0.0);
    else
        g_debug = false;

    if (g_debug)
    {
        mexPrintf ("-xglinit\n");
        mexPrintf ("XGL library, version %d.%d\n", MAJOR_VERSION, MINOR_VERSION);
        mexPrintf ("Copyright (C) 2013\n");
        mexPrintf ("Center for Perceptual Systems\n");
        mexPrintf ("University of Texas at Austin\n");
    }

    instance.Init ();
}

void xglrelease (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    instance.Release ();
}

void xgldevices (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned n;

    try
    {
        n = instance->TotalDevices ();
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a scalar and put the # in it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *destr = mxGetPr (plhs[0]);
    destr[0] = n;
}

void xglinfo (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);

    string s;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        s = instance->GetDeviceInfo (n - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a vector and put the text into it
    const char *c_str = s.c_str ();
    plhs[0] = mxCreateCharMatrixFromStrings (1, &c_str);
}

void xglrect (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);

    int x, y, w, h;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        instance->GetScreenRect (n - 1, &x, &y, &w, &h);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a vector and put the coordinates into it
    const int dims[2] = { 1, 4 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    p = mxGetPr (plhs[0]);
    p[0] = x;
    p[1] = y;
    p[2] = w;
    p[3] = h;
}

void xgltotalmodes (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p0 = mxGetPr (prhs[0]);
    double *p1 = mxGetPr (prhs[1]);

    unsigned m;

    try
    {
        unsigned n = static_cast<unsigned> (p0[0]);
        unsigned pf = static_cast<unsigned> (p1[0]);
        m = instance->TotalModes (n - 1, static_cast<PixelFormat> (pf - 1));
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a scalar and put the modes into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *p = mxGetPr (plhs[0]);
    p[0] = m;
}

void xglcurrentmode (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    DisplayMode m;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        instance->GetCurrentMode (n - 1, &m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a mode array and fill it
    const int dims[2] = { 1, 4 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    p = mxGetPr (plhs[0]);
    p[0] = m.width;
    p[1] = m.height;
    p[2] = m.pf + 1;
    p[3] = m.freq;
}

void xglgetmode (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p0 = mxGetPr (prhs[0]);
    double *p1 = mxGetPr (prhs[1]);
    double *p2 = mxGetPr (prhs[2]);
    DisplayMode m;

    try
    {
        unsigned i = static_cast<unsigned> (p0[0]);
        unsigned j = static_cast<unsigned> (p1[0]);
        unsigned k = static_cast<unsigned> (p2[0]);
        instance->GetMode (i - 1, static_cast<PixelFormat> (j - 1), k - 1, &m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a mode array and fill it
    const int dims[2] = { 1, 4 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *p = mxGetPr (plhs[0]);
    p[0] = m.width;
    p[1] = m.height;
    p[2] = m.pf + 1;
    p[3] = m.freq;
}

void xglhwconversion (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p0 = mxGetPr (prhs[0]);
    double *p1 = mxGetPr (prhs[1]);
    double *p2 = mxGetPr (prhs[2]);

    bool f;

    try
    {
        unsigned n = static_cast<unsigned> (p0[0]);
        unsigned pf1 = static_cast<unsigned> (p1[0]);
        unsigned pf2 = static_cast<unsigned> (p2[0]);
        f = instance->HardwareConversion (n - 1, static_cast<PixelFormat> (pf1 - 1), static_cast<PixelFormat> (pf2 - 1));
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a scalar and put the flag into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxLOGICAL_CLASS, mxREAL);
    mxLogical *p = mxGetLogicals (plhs[0]);
    p[0] = f;
}

void xglinitdevice (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    if (mxGetNumberOfElements (prhs[1]) != 4)
        ReportErrorAndExit ("Incorrect number of elements in the mode vector");
    double *m = mxGetPr (prhs[1]);
    double *b = mxGetPr (prhs[2]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        DisplayMode dm;
        dm.width = static_cast<unsigned> (m[0]);
        dm.height = static_cast<unsigned> (m[1]);
        unsigned pf = static_cast<unsigned> (m[2]);
        dm.pf = static_cast<PixelFormat> (pf - 1);
        dm.freq = static_cast<unsigned> (m[3]);
        unsigned bb = static_cast<unsigned> (b[0]);
        instance->InitDevice (n - 1, dm, bb);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglreleasedevice (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        instance->ReleaseDevice (n - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglclear (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p0 = mxGetPr (prhs[0]);
    double *p1 = mxGetPr (prhs[1]);
    double *p2 = mxGetPr (prhs[2]);

    try
    {
        unsigned d = static_cast<unsigned> (p0[0]);
        unsigned b = static_cast<unsigned> (p1[0]);
        unsigned c = static_cast<unsigned> (p2[0]);
        instance->Clear (d - 1, b - 1, c);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglflip (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        instance->Flip (n - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglgetrasterstatus (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);

    bool f;
    unsigned sl;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        instance->GetRasterStatus (n - 1, &f, &sl);
        //mexPrintf ("Raster Status: %d %d\n", f, sl);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a scalar and put the flag into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxLOGICAL_CLASS, mxREAL);
    mxLogical *fp = mxGetLogicals (plhs[0]);
    fp[0] = f;

    // Create a scalar and put the scanline into it
    plhs[1] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *sp = mxGetPr (plhs[1]);
    sp[0] = sl;
}

void xglcreatebuffer (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    if (mxGetNumberOfElements (prhs[1]) != 3 &&
        mxGetNumberOfElements (prhs[1]) != 4)
        ReportErrorAndExit ("Incorrect number of elements in the mode vector");
    double *m = mxGetPr (prhs[1]);

    OffscreenBufferHandle h;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned pf = static_cast<unsigned> (m[2]);
        instance->CreateOffscreenBuffer (n - 1,
            static_cast<unsigned> (m[0]),
            static_cast<unsigned> (m[1]),
            static_cast<PixelFormat> (pf - 1),
            &h);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a scalar and put the handle into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    p = mxGetPr (plhs[0]);
    p[0] = static_cast<double> (h);
}

void xglreleasebuffer (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *b = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        OffscreenBufferHandle h = static_cast<OffscreenBufferHandle> (b[0]);
        instance->ReleaseOffscreenBuffer (n - 1, h);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglreleasebuffers (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        instance->ReleaseOffscreenBuffers (n - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglclearbuffer (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *b = mxGetPr (prhs[1]);
    double *c = mxGetPr (prhs[2]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        OffscreenBufferHandle h = static_cast<OffscreenBufferHandle> (b[0]);
        unsigned rgb = static_cast<unsigned> (c[0]);
        instance->ClearOffscreenBuffer (n - 1, h, rgb);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglcopybuffer (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

    // Check input types
    if (!mxIsSingle (prhs[2]) && !mxIsUint8 (prhs[2]) && !mxIsUint32 (prhs[2]))
        ReportErrorAndExit ("Input 3 must be either uint8, uint32, or single-precision floating point.");
    if (mxIsComplex (prhs[2]))
        ReportErrorAndExit ("Input 3 may not be complex.");

    // bytes per pixel
    unsigned bpp = mxIsUint8 (prhs[2]) ? 1 : 4;

    double *p = mxGetPr (prhs[0]);
    double *b = mxGetPr (prhs[1]);
    void *buffer = mxGetData (prhs[2]);
    unsigned bb = mxGetNumberOfElements (prhs[2]) * bpp;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        OffscreenBufferHandle h = static_cast<OffscreenBufferHandle> (b[0]);
        unsigned width, height;
        PixelFormat pf;
        instance->OffscreenBufferDimensions (n - 1, h, &width, &height, &pf);
        unsigned ob = width * height * BitsPerPixel (pf) / 8;
        if (ob != bb)
        {
            mexPrintf ("Input buffer total bytes: %d\n", bb);
            mexPrintf ("Offscreen buffer total bytes: %d\n", ob);
            ReportErrorAndExit ("The input buffer and offscreen buffer must contain the same number of bytes");
        }
        void *vidmem = instance->LockOffscreenBuffer (n - 1, h); // throws on failure
        memcpy (vidmem, buffer, bb);
        instance->UnlockOffscreenBuffer (n - 1, h);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglblit (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *b = mxGetPr (prhs[1]);
    double *r = 0;

    switch (nrhs)
    {
        case 2:
        // Do nothing
        break;
        case 3:
        if (mxGetNumberOfElements (prhs[2]) != 4)
            ReportErrorAndExit ("Incorrect number of elements in the destination vector");
        r = mxGetPr (prhs[2]);
        break;
        default:
        ReportErrorAndExit ("This function requires either 3 or 4 arguments.");
    }

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        OffscreenBufferHandle h = static_cast<OffscreenBufferHandle> (b[0]);
        if (r != 0)
        {
            int rx = static_cast<int> (r[0]);
            int ry = static_cast<int> (r[1]);
            int rw = static_cast<int> (r[2]);
            int rh = static_cast<int> (r[3]);
            instance->Blit (n - 1, h, rx, ry, rw, rh);
        }
        else
        {
            instance->Blit (n - 1, h);
        }
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglgetcursor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    // Create a vector and put the position in it
    const int dims[2] = { 1, 2 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);

    double *p = mxGetPr (plhs[0]);

    POINT xy;

    if (!GetCursorPos (&xy))
        ReportErrorAndExit ("Could not get the cursor position");

    p[0] = xy.x;
    p[1] = xy.y;
}

void xglsetcursor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    unsigned n = mxGetNumberOfElements (prhs[0]);

    if (n != 2)
        ReportErrorAndExit ("Input 1 must contain an x, y coordinate pair.");

    double *p = mxGetPr (prhs[0]);

    SetCursorPos (static_cast<int> (p[0]), static_cast<int> (p[1]));
}

void xglshowcursor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *b = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        if (b[0] == 0.0)
        {
            //mexPrintf ("Device %d, cursor off\n", n-1);
            instance->ShowCursor (n - 1, false);
        }
        else
        {
            //mexPrintf ("Device %d, cursor on\n", n-1);
            instance->ShowCursor (n - 1, true);
        }
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsetlut (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    if (mxGetM (prhs[1]) != 256)
        ReportErrorAndExit ("Incorrect number of rows in the lookup table.");
    if (mxGetN (prhs[1]) != 3)
        ReportErrorAndExit ("Incorrect number of columns in the lookup table.");
    double *g = mxGetPr (prhs[1]);
    vector<unsigned short> lut (3 * 256);

    for (int n = 0; n < 256; ++n)
    {
        // Transpose g
        lut[n * 3 + 0] = static_cast<unsigned short> (g[0 * 256 + n] * ((1<<16)-1));
        lut[n * 3 + 1] = static_cast<unsigned short> (g[1 * 256 + n] * ((1<<16)-1));
        lut[n * 3 + 2] = static_cast<unsigned short> (g[2 * 256 + n] * ((1<<16)-1));
    }

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        instance->SetGamma (n - 1, lut);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xgltotalfonts (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double fonts;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        fonts = instance->TotalFonts (n - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
    // Create a scalar and put the value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    p = mxGetPr (plhs[0]);
    p[0] = static_cast<double> (fonts);
}

void xglfontname (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *f = mxGetPr (prhs[1]);

    string s;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (f[0]);
        s = instance->FontName (n - 1, m - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a vector and put the text into it
    const char *c_str = s.c_str ();
    plhs[0] = mxCreateCharMatrixFromStrings (1, &c_str);
}

void xglsetfont (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *f = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (f[0]);
        instance->SetFont (n - 1, m - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsetpointsize (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *s = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (s[0]);
        instance->SetPointSize (n - 1, m - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsetescapement (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *s = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (s[0]);
        instance->SetEscapement (n - 1, m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsettextcolor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *c = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (c[0]);
        instance->SetTextColor (n - 1, m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsetbgcolor (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *c = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (c[0]);
        instance->SetBGColor (n - 1, m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsetbgtrans (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *f = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (f[0]);
        instance->SetBGTransparency (n - 1, m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsetitalic (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *f = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (f[0]);
        instance->SetItalic (n - 1, m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsetunderline (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *f = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (f[0]);
        instance->SetUnderline (n - 1, m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglsetstrikeout (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *f = mxGetPr (prhs[1]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned m = static_cast<unsigned> (f[0]);
        instance->SetStrikeOut (n - 1, m);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xgltextwidth (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    mxChar *c = mxGetChars (prhs[1]);
    unsigned nc = mxGetNumberOfElements (prhs[1]);
    string s (nc, ' ');

    // Transform from short to char
    for (unsigned i = 0; i < nc; ++i)
        s[i] = static_cast<char> (c[i]);

    double w;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        w = instance->GetTextWidth (n - 1, s.c_str ());
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a scalar and put the value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    p = mxGetPr (plhs[0]);
    p[0] = static_cast<double> (w);
}

void xgltextheight (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double h;

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        h = instance->GetTextHeight (n - 1);
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }

    // Create a scalar and put the value into it
    const int dims[2] = { 1, 1 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    p = mxGetPr (plhs[0]);
    p[0] = static_cast<double> (h);
}

void xgltext (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *p = mxGetPr (prhs[0]);
    double *xy = mxGetPr (prhs[1]);
    mxChar *c = mxGetChars (prhs[2]);
    unsigned nc = mxGetNumberOfElements (prhs[2]);
    string s (nc, ' ');

    // Transform from short to char
    for (unsigned i = 0; i < nc; ++i)
        s[i] = static_cast<char> (c[i]);

    try
    {
        unsigned n = static_cast<unsigned> (p[0]);
        unsigned x = static_cast<unsigned> (xy[0]);
        unsigned y = static_cast<unsigned> (xy[1]);
        //mexPrintf ("Device %d, x = %d, y = %d, text = %s\n", n-1, x-1, y-1, s.c_str ());
        instance->Text (n - 1, x - 1, y - 1, s.c_str ());
    }
    catch (const char *e)
    {
        ReportErrorAndExit (e);
    }
}

void xglgetcursor_buttonstate (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int returnStateLeft = 0;
	int returnStateRight = 0;

	if (!(GetAsyncKeyState (VK_LBUTTON) & 0x8000))
	{
		//cout << "Line " << line++ << ": " << "Left Mouse Up " << endl;
		returnStateLeft = 0;
	} else {
		//cout << "Line " << line++ << ": " << "Left Mouse Down " << endl;;
		returnStateLeft = 1;
	}

	if (!(GetAsyncKeyState (VK_RBUTTON) & 0x8000))
	{
		//cout << "Line " << line++ << ": " << "Right Mouse Up " << endl;;
		returnStateRight = 0;
	} else {
		//cout << "Line " << line++ << ": " << "Right Mouse Down " << endl;;
		returnStateRight = 1;
	}

    const int dims[2] = { 1, 4 };
    plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    double *p = mxGetPr (plhs[0]);
    p[0] = returnStateLeft;
    p[1] = returnStateRight;
    p[2] = 0; // reserved for future use
    p[3] = 0; // reserved for future use
    
}
