// X Graphics Library Test Module
//
// Copyright (C) 2000-2006
// Jeffrey S. Perry
// Wilson S. Geisler
// Center for Perceptual Systems
// University of Texas at Austin
//
// jsp Wed Aug 17 15:31:13 CDT 2005 Updated
// jsp Tue Oct  3 11:37:15 CDT 2006 Updated

#include <cmath>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <fstream>
#include <iostream>
#include <set>
#include <string>
#include <sstream>
#include <vector>
#include "xgl.h"

#ifdef _WIN32
#include <crtdbg.h>
#endif

using namespace std;
using namespace XGL;

static clock_t tic_start;

void tic ()
{
    tic_start = clock ();
}

double toc ()
{
    return static_cast<double> (clock () - tic_start) / CLOCKS_PER_SEC;
}

void Assert (bool f)
{
    if (!f)
        throw "Assertion failed";
}

class LogFile
{
    public:
        LogFile (const string &filename)
        {
            cout << "Opening " << filename << endl;
            ofs.open (filename.c_str ());
            if (!ofs)
                throw "Could not open log file";
            cout << filename << " opened" << endl;
            time_t c;
            struct tm *t;
            time (&c);
            t = localtime (&c);
            ofs << asctime (t) << endl;
        }
        void Log (unsigned line, const string &s)
        {
            cout << "Line " << line << ": " << s << endl;
            ofs << "Line " << line << ": " << s << endl;
        }
    private:
        ofstream ofs;
} lf ("log_test_xgl.txt");

#define Log(e) (lf.Log(__LINE__,e))

template<typename T>
void FillPage (T *p, T c, unsigned n)
{
    for (unsigned i = 0; i < n; ++i)
        p[i] = c;
}

template <class T>
void ForEachDevice (unsigned i, T t, Session *xgl)
{
    Log (typeid (T).name ());
    xgl->Init ();
    stringstream s;
    s << "Device " << i;
    Log (s.str ());
    t.Test (xgl, i);
    xgl->Release ();
};

template <class T>
void ForEachDevice (unsigned i, T t, Session *xgl, const DisplayMode &m)
{
    Log (typeid (T).name ());
    xgl->Init ();
    stringstream s;
    s << "Device " << i << ", " << m.width << "X" << m.height << " @ " << m.freq << "Hz, pixel format " << m.pf << " mode";
    Log (s.str ());
    t.Test (xgl, i, m);
    xgl->Release ();
};

template <class T>
void ForEachSupportedHWConversion (unsigned i, T t, Session *xgl, const DisplayMode &m)
{
    Log (typeid (T).name ());
    xgl->Init ();
    DisplayMode offscreen_buffer_mode = m;
    for (unsigned j = 0; j < PF_OTHER; ++j)
    {
        offscreen_buffer_mode.pf = static_cast<PixelFormat> (j);
        if (xgl->HardwareConversion (i, offscreen_buffer_mode.pf, m.pf))
        {
            stringstream s;
            s << "Device " << i << ", " << m.width << "X" << m.height << " @ " << m.freq << "Hz, pixel format " << m.pf << " mode, "
                << "buffer pixel format " << offscreen_buffer_mode.pf;
            Log (s.str ());
            t.Test (xgl, i, m, offscreen_buffer_mode.pf);
        }
    }
    xgl->Release ();
};

template <class T>
void ForEachMode (unsigned i, T &t, Session *xgl)
{
    Log (typeid (T).name ());
    xgl->Init ();
    for (unsigned j = 0; j < PF_OTHER; ++j)
    {
        const unsigned N = xgl->TotalModes (i, static_cast<PixelFormat> (j));
        for (unsigned k = 0; k < N; ++k)
        {
            stringstream s;
            s << "Device " << i << ", pixel format " << j << ", mode " << k;
            Log (s.str ());
            DisplayMode m;
            xgl->GetMode (i, static_cast<PixelFormat> (j), k, &m);
            t.Test (xgl, i, m);
        }
    }
    xgl->Release ();
};

struct GetDeviceInfoTest
{
    void Test (Session *xgl, unsigned i)
    {
        string s (xgl->GetDeviceInfo (i));
        Log (s);
    }
};

struct GetScreenRectTest
{
    void Test (Session *xgl, unsigned i)
    {
        int x, y, w, h;
        xgl->GetScreenRect (i, &x, &y, &w, &h);
        stringstream s;
        s << "Device " << i << "'s rectangle is " << w << " X " << h << " at " << x << ", " << y;
        Log (s.str ());
    }
};

struct GetCurrentModeTest
{
    void Test (Session *xgl, unsigned i)
    {
        DisplayMode m;
        xgl->GetCurrentMode (i, &m);
        stringstream s;
        s << "Device " << i << "'s current mode is " << m.width << "X" << m.height << " @ " << m.freq << "Hz, pixel format " << m.pf;
        Log (s.str ());
    }
};

struct GetTotalModesTest
{
    void Test (Session *xgl, unsigned i)
    {
        for (unsigned j = 0; j < PF_OTHER; ++j)
        {
            unsigned n = xgl->TotalModes (i, static_cast<PixelFormat> (j));
            stringstream s;
            s << "Device " << i << " has " << n << " total modes in pixel format " << j;
            Log (s.str ());
        }
    }
};

struct GetHWConversionTest
{
    void Test (Session *xgl, unsigned i)
    {
        for (unsigned j = 0; j < PF_OTHER; ++j)
        {
            for (unsigned k = 0; k < PF_OTHER; ++k)
            {
                stringstream s;
                s << "Device " << i << " HW conversion from mode " << j
                    << " to mode " << k
                    << ": " << (xgl->HardwareConversion (i,
                            static_cast<PixelFormat> (j),
                            static_cast<PixelFormat> (k)) ? "supported" : "unsupported");
                Log (s.str ());
            }
        }
    }
};

struct GetModeTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Device " << i << ", " << m.width << "X" << m.height << " @ " << m.freq << "Hz, pixel format " << m.pf;
        Log (s.str ());
    }
};

// Find a particular mode for a given device
struct FindMode
{
    FindMode (unsigned w, unsigned h): w (w), h (h), found (false) { }
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        if (m.width == w && m.height == h)
        {
            // Find the highest frequency mode
            if (!found || m.freq > mode.freq)
                mode = m;

            found = true;
        }
    }
    unsigned w;
    unsigned h;
    bool found;
    DisplayMode mode;
};

struct InitDeviceTest1
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Testing device " << i << "'s " << m.width << "X" << m.height << " @ " << m.freq << "Hz, pixel format " << m.pf << " mode";
        Log (s.str ());
        // Open and close one device at a time
        xgl->InitDevice (i, m, 2);
        xgl->ReleaseDevice (i);
    }
};

struct InitDeviceTest2
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Testing device " << i << "'s " << m.width << "X" << m.height << " @ " << m.freq << "Hz, pixel format " << m.pf << " mode";
        Log (s.str ());
        // Open and leave it open so that multiple devices are
        // open at once.  xgl->Release() will close all devices.
        xgl->InitDevice (i, m, 2);
    }
};

struct ClearFlipTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Clearing and flipping device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        for (unsigned j = 0; j < 100; ++ j)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Flip (i);
        }
        xgl->ReleaseDevice (i);
    }
};

struct BackBufferTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Writing backbuffer on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        for (unsigned j = 0; j < 6; ++ j)
        {
            void *p = xgl->LockBackBuffer (i, 0);
            stringstream s;
            s << "Backbuffer address is " << p;
            Log (s.str ());
            memset (p, 128, m.width * m.height * 4);
            xgl->UnlockBackBuffer (i, 0);
            xgl->Flip (i);
        }
        xgl->ReleaseDevice (i);

        s.str ("");;
        s << "Preloading pages on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // two backbuffers plus a front buffer

        // Wait a while for initdevice to finish
        tic (); while (toc () < 2);

        // This is how you preload video mode pages:
        //
        // We want to load R, G, and B in pages 0, 1, and 2.  However,
        // we only have access to pages 0 and 1.
        //
        // So, first load page 0 with Red...
        void *p = xgl->LockBackBuffer (i, 0);
        FillPage (static_cast<unsigned int *> (p), MakeRGB8 (255, 0, 0), m.width * m.height);
        xgl->UnlockBackBuffer (i, 0);

        // Now load page 1 with Green
        p = xgl->LockBackBuffer (i, 1);
        FillPage (static_cast<unsigned int *> (p), MakeRGB8 (0, 255, 0), m.width * m.height);
        xgl->UnlockBackBuffer (i, 1);

        // Show page 0.
        xgl->Flip (i);

        // Now page 0 is the front buffer, page 1 is
        // page 0, and page 2 is page 1...

        // Load the final page with Blue...
        p = xgl->LockBackBuffer (i, 1);
        FillPage (static_cast<unsigned int *> (p), MakeRGB8 (0, 0, 255), m.width * m.height);
        xgl->UnlockBackBuffer (i, 1);

        // Now actually show them with pauses between
        // presentations
        tic (); while (toc () < 0.3);
        xgl->Flip (i);
        tic (); while (toc () < 0.3);
        xgl->Flip (i);
        tic (); while (toc () < 0.3);
        xgl->Flip (i);

        s.str ("");;
        s << "Timing device " << i;
        Log (s.str ());

        // Now we are going to see how fast we can page flip
        tic ();
        const unsigned PAGES = 200;
        for (unsigned j = 0; j < PAGES; ++j)
            xgl->Flip (i);
        double elapsed = toc ();

        xgl->ReleaseDevice (i);
        s.str ("");
        s << "Pages were flipped at " << PAGES/elapsed << "Hz";
        Log (s.str ());

        s.str ("");
        s << "Checking raster status routine on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        bool vblank;
        vector<unsigned> scanlines;
        xgl->Flip (i);
        while (1)
        {
            unsigned s;
            xgl->GetRasterStatus (i, &vblank, &s);
            scanlines.push_back (s);
            if (vblank)
                break;
        }
        xgl->ReleaseOffscreenBuffers (i);
        xgl->ReleaseDevice (i);
        s.str ("");
        s << "The raster was checked on the following " << static_cast<unsigned> (scanlines.size ()) << " scanlines: ";
        for (unsigned j = 0; j < scanlines.size (); ++j)
            s << scanlines[j] << " ";
        Log (s.str ());
    }
};

struct OffscreenBufferTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Allocating buffers on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        const unsigned N = 10;
        // Create a bunch of offscreen memory buffers
        vector<OffscreenBufferHandle> buffer_handles (N);
        for (unsigned j = 0; j < N; ++ j)
            xgl->CreateOffscreenBuffer (i, m.width, m.height, m.pf, &buffer_handles[j]);
        // Now release and create in some crazy order.  This only
        // works because I know that the handles are vector indices.
        // Don't try this at home.
#ifdef _WIN32
        xgl->ReleaseOffscreenBuffer (i, 4);
        OffscreenBufferHandle h;
        xgl->CreateOffscreenBuffer (i, m.width, m.height, m.pf, &h);
        Assert (h == 4);
        xgl->ReleaseOffscreenBuffer (i, 3);
        xgl->ReleaseOffscreenBuffer (i, 9);
        xgl->CreateOffscreenBuffer (i, m.width, m.height, m.pf, &h);
        Assert (h == 3);
        xgl->CreateOffscreenBuffer (i, m.width, m.height, m.pf, &h);
        Assert (h == 9);
        xgl->CreateOffscreenBuffer (i, m.width, m.height, m.pf, &h);
        Assert (h == 10);
#endif // _WIN32
        xgl->ReleaseOffscreenBuffers (i);
        xgl->ReleaseDevice (i);

        s.str ("");
        s << "Clearing buffers on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        buffer_handles.clear ();
        buffer_handles.resize (N);
        for (unsigned j = 0; j < N; ++ j)
            xgl->CreateOffscreenBuffer (i, m.width, m.height, m.pf, &buffer_handles[j]);
        // Clear the buffers
        for (unsigned j = 0; j < N; ++j)
            xgl->ClearOffscreenBuffer (i, buffer_handles[j], MakeRGB8 ((j%2)?255:0, (j%3)?255:0, (j%4)?255:0));
        // Blit the buffers
        for (unsigned j = 0; j < N; ++j)
        {
            xgl->Blit (i, buffer_handles[j], 0, 0, m.width, m.height);
            xgl->Flip (i);
        }
        xgl->ReleaseOffscreenBuffers (i);
        xgl->ReleaseDevice (i);

        s.str ("");
        s << "Blitting to device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        buffer_handles.clear ();
        buffer_handles.resize (N);
        for (unsigned j = 0; j < N; ++ j)
            xgl->CreateOffscreenBuffer (i, m.width, m.height, m.pf, &buffer_handles[j]);
        // Fill the buffers
        for (unsigned j = 0; j < N; ++j)
        {
            void *p = xgl->LockOffscreenBuffer (i, buffer_handles[j]);
            FillPage (static_cast<unsigned int *> (p), MakeRGB8 ((j%2)?255:0, (j%3)?255:0, (j%4)?255:0), m.width * m.height);
            xgl->UnlockOffscreenBuffer (i, buffer_handles[j]);
        }
        // Blit the buffers
        for (unsigned j = 0; j < N; ++j)
        {
            xgl->Blit (i, buffer_handles[j], 0, 0, m.width, m.height);
            xgl->Flip (i);
        }
        // See how fast we can blit, without waiting for the vertical
        // retrace...
        tic ();
        const unsigned PAGES = 200;
        for (unsigned j = 0; j < PAGES; ++j)
        {
            xgl->Blit (i, buffer_handles[j%N], 0, 0, m.width, m.height);
        }
        double elapsed = toc ();
        xgl->ReleaseOffscreenBuffers (i);
        xgl->ReleaseDevice (i);
        s.str ("");
        s << "Offscreen memory was blitted at " << PAGES/elapsed << "Hz";
        Log (s.str ());
    }
};

void FillPage (void *p, PixelFormat pf, unsigned w, unsigned h)
{
    // Make sure scanline length is divisible by 64
    if (pf == PF_L8)
        w = (w + 63) & (~0x3F);
    if (pf ==PF_YV12)
        w = (w + 127) & (~0x7F);
    for (unsigned y = 0; y < h; ++y)
    {
        for (unsigned x = 0; x < w; ++x)
        {
            float dx = static_cast<float> (x - w/2.0f);
            float dy = static_cast<float> (y - h/2.0f);
            float d = 1-sqrt (dx*dx+dy*dy)/(h/2);
            if (d < 0.0f)
                d = 0.0f;
            int yy = static_cast<int> (d * 255.0f);
            int uu = static_cast<int> (x * 255.0f / w);
            int vv = static_cast<int> (y * 255.0f / h);
            if (yy <= 0)
            {
                uu = 128;
                vv = 128;
            }
            unsigned n = y * w + x;
            const unsigned N = w * h;
            int r;
            int g;
            int b;
            unsigned char *puc;
            unsigned int *pui;
            RGBFloat16 *pf64;
            float *pf128;

            switch (pf)
            {
                default:
                throw "Invalid buffer format";
                case PF_L8:
                puc = static_cast<unsigned char *> (p);
                puc[n] = yy; // luminance only
                break;
                case PF_X8R8G8B8:
                r = Clamp<0, 255> (static_cast<int> (YPbPrR (yy, vv - 128, uu - 128)));
                g = Clamp<0, 255> (static_cast<int> (YPbPrG (yy, vv - 128, uu - 128)));
                b = Clamp<0, 255> (static_cast<int> (YPbPrB (yy, vv - 128, uu - 128)));
                pui = static_cast<unsigned int *> (p);
                pui[n] = MakeRGB8 (r, g, b);
                break;
                case PF_YV12:
                puc = static_cast<unsigned char *> (p);
                puc[n] = yy; // luminance
                puc[N + (y / 2) * (w / 2) + (x / 2)] = uu; // u
                puc[N + N/4 + (y / 2) * (w / 2) + (x / 2)] = vv; // v
                break;
                case PF_A2R10G10B10:
                r = Clamp<0, 255> (static_cast<int> (YPbPrR (yy, vv - 128, uu - 128)));
                g = Clamp<0, 255> (static_cast<int> (YPbPrG (yy, vv - 128, uu - 128)));
                b = Clamp<0, 255> (static_cast<int> (YPbPrB (yy, vv - 128, uu - 128)));
                pui = static_cast<unsigned int *> (p);
                pui[n] = MakeRGB10 (r * 4, g * 4, b * 4);
                break;
                case PF_A16B16G16R16F:
                r = Clamp<0, 255> (static_cast<int> (YPbPrR (yy, vv - 128, uu - 128)));
                g = Clamp<0, 255> (static_cast<int> (YPbPrG (yy, vv - 128, uu - 128)));
                b = Clamp<0, 255> (static_cast<int> (YPbPrB (yy, vv - 128, uu - 128)));
                pf64 = static_cast<RGBFloat16 *> (p);
                pf64[n] = MakeRGBFloat16 (r / 255.0f, g / 255.0f, b / 255.0f);
                break;
                case PF_A32B32G32R32F:
                r = Clamp<0, 255> (static_cast<int> (YPbPrR (yy, vv - 128, uu - 128)));
                g = Clamp<0, 255> (static_cast<int> (YPbPrG (yy, vv - 128, uu - 128)));
                b = Clamp<0, 255> (static_cast<int> (YPbPrB (yy, vv - 128, uu - 128)));
                pf128 = static_cast<float *> (p);
                pf128[n * 4 + 0] = b / 255.0f;
                pf128[n * 4 + 1] = g / 255.0f;
                pf128[n * 4 + 2] = r / 255.0f;
                pf128[n * 4 + 3] = 0.0f;
                break;
            }
        }
    }
}

struct BlitTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m, PixelFormat pf)
    {
        stringstream s;
        s << "Allocating a buffer on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        // Create an offscreen memory buffer
        OffscreenBufferHandle buffer_handle;
        const unsigned W = m.width;
        const unsigned H = m.height;
        xgl->CreateOffscreenBuffer (i, W, H, pf, &buffer_handle);

        // Clear the backbuffers
        for (unsigned j = 0; j < 3; ++j)
        {
            xgl->Clear (i, 0, 0);
            xgl->Flip (i);
        }

        tic (); while (toc () < 0.5); // Pause

        // Now we are going to see how fast we can blit
        unsigned passes = 0;
        void *p = xgl->LockOffscreenBuffer (i, buffer_handle);
        FillPage (p, pf, W, H);
        xgl->UnlockOffscreenBuffer (i, buffer_handle);
        tic ();
        double elapsed = toc ();
        while (elapsed < 0.5)
        {
            xgl->Blit (i, buffer_handle);
            xgl->Flip (i);
            elapsed = toc ();
            ++passes;
        }

        xgl->ReleaseOffscreenBuffers (i);
        xgl->ReleaseDevice (i);
        s.str ("");
        s << "Offscreen memory was blitted at " << passes/elapsed << "Hz";
        Log (s.str ());
    }
};

struct StretchRectTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m, PixelFormat pf)
    {
        stringstream s;
        s << "Allocating a buffer on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        // Create an offscreen memory buffer
        OffscreenBufferHandle buffer_handle;
        const unsigned W = 256;
        const unsigned H = 256;
        xgl->CreateOffscreenBuffer (i, W, H, pf, &buffer_handle);
        void *p = xgl->LockOffscreenBuffer (i, buffer_handle);
        FillPage (p, pf, W, H);
        xgl->UnlockOffscreenBuffer (i, buffer_handle);

        // Clear the backbuffers
        for (unsigned j = 0; j < 3; ++j)
        {
            xgl->Clear (i, 0, 0);
            xgl->Flip (i);
        }

        // Blit the buffer
        for (unsigned j = 0; j < 10; ++j)
        {
            xgl->Blit (i, buffer_handle);
            xgl->Flip (i);
        }

        tic (); while (toc () < 0.5); // Pause

        // Clear the backbuffers
        for (unsigned j = 0; j < 3; ++j)
        {
            xgl->Clear (i, 0, 0);
            xgl->Flip (i);
        }

        // Now we are going to see how fast we can stretchrect
        tic ();
        const unsigned MAX = m.height > m.width ? m.width : m.height;
        const unsigned STEP = 10;
        for (unsigned j = 1; j < MAX; j += STEP)
        {
            unsigned x = m.width/2 - j/2 - 1;
            unsigned y = m.height/2 - j/2 - 1;
            xgl->Clear (i, 0, 0);
            xgl->Blit (i, buffer_handle, x, y, j, j);
            xgl->Flip (i);
        }

        double elapsed = toc ();
        xgl->ReleaseOffscreenBuffers (i);
        xgl->ReleaseDevice (i);
        s.str ("");
        s << "Offscreen memory was stretchrected at " << MAX/elapsed/STEP << "Hz";
        Log (s.str ());
    }
};

struct DoHWConversionTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m, PixelFormat pf)
    {
        stringstream s;
        s << "Converting from pixel format " << pf << " to pixel format " << m.pf;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        const unsigned N = 10;
        // Create a bunch of offscreen memory buffers
        vector<OffscreenBufferHandle> buffer_handles (N);
        for (unsigned h = 0; h < N; ++h)
            xgl->CreateOffscreenBuffer (i, m.width, m.height, m.pf, &buffer_handles[h]);
        // Fill the buffers
        for (unsigned j = 0; j < N; ++j)
        {
            void *p = xgl->LockOffscreenBuffer (i, buffer_handles[j]);
            switch (pf)
            {
                default:
                throw "Invalid buffer format";
                case PF_L8:
                FillPage (static_cast<unsigned char *> (p), static_cast<unsigned char> ((j*311)%255), m.width * m.height);
                break;
                case PF_X8R8G8B8:
                FillPage (static_cast<unsigned int *> (p), MakeRGB8 ((j%2)?255:0, (j%3)?255:0, (j%4)?255:0), m.width * m.height);
                break;
                case PF_YV12:
                {
                unsigned n = m.width * m.height;
                FillPage (static_cast<unsigned char *> (p), static_cast<unsigned char> (183), m.width * m.height);
                FillPage (static_cast<unsigned char *> (p) + n, static_cast<unsigned char> (47), n/4);
                FillPage (static_cast<unsigned char *> (p) + n + n/4, static_cast<unsigned char> (203), n/4);
                }
                break;
                case PF_A2R10G10B10:
                FillPage (static_cast<unsigned int *> (p), MakeRGB10 ((j%2)?1023:0, (j%3)?1023:0, (j%4)?1023:0), m.width * m.height);
                break;
                case PF_A16B16G16R16F:
                FillPage (static_cast<Float16 *> (p), MakeFloat16 (j*1.0f/N), m.width * m.height * 4);
                break;
                case PF_A32B32G32R32F:
                FillPage (static_cast<float *> (p), j*1.0f, m.width * m.height * 4);
                break;
            }
            xgl->UnlockOffscreenBuffer (i, buffer_handles[j]);
        }

        // Do the blits
        tic ();
        const unsigned PAGES = 50;
        for (unsigned j = 0; j < PAGES; ++j)
        {
            xgl->Blit (i, buffer_handles[j%N], 0, 0, m.width, m.height);
            xgl->Flip (i);
        }
        double elapsed = toc ();
        xgl->ReleaseOffscreenBuffers (i);
        xgl->ReleaseDevice (i);
        s.str ("");
        s << "Offscreen memory was converted at ";
        if (elapsed)
            s << PAGES/elapsed;
        else
            s << "Infinity";
        s << " Hz";
        Log (s.str ());
    }
};

struct CopyFromBackBufferTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Reading backbuffer on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        const unsigned N = m.width * m.height;
        vector<unsigned char> b(N*4);
        tic ();
        const unsigned PAGES = 5;
        for (unsigned j = 0; j < PAGES; ++j)
        {
            unsigned char *p = static_cast<unsigned char *> (xgl->LockBackBuffer (i, 0));
            memcpy (&b[0], p, N*4);
            for (unsigned k = 0; k < N; ++k)
            {
                unsigned char r = p[1];
                unsigned char g = p[2];
                unsigned char b = p[3];
                unsigned char y = static_cast<unsigned char> (YPbPrY (r, g, b));
                unsigned char u = static_cast<unsigned char> (YPbPrPr (r, g, b) + 128);
                unsigned char v = static_cast<unsigned char> (YPbPrPb (r, g, b) + 128);
                y = 0;
                u = 0;
                v = 0;
                p += 4;
            }
            xgl->UnlockBackBuffer (i, 0);
        }
        double elapsed = toc ();
        xgl->ReleaseDevice (i);

        s.str ("");
        s << "Backbuffers were read and converted to YUV at " << PAGES/elapsed << "Hz";
        Log (s.str ());
    }
};

struct CheckInterpolationTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Reading backbuffer on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        const unsigned W = m.width;
        const unsigned H = m.height;
        // Create an offscreen memory buffer
        OffscreenBufferHandle buffer_handle;
        xgl->CreateOffscreenBuffer (i, W/2, H/2, m.pf, &buffer_handle);
        void *p = xgl->LockOffscreenBuffer (i, buffer_handle);
        // Make sharp horizontal edges
        for (unsigned j = 0; j < H/4; ++j)
        {
            memset (static_cast<unsigned char *> (p) + (j * 2 + 0) * (W/2)*4,   0, (W/2)*4);
            memset (static_cast<unsigned char *> (p) + (j * 2 + 1) * (W/2)*4, 255, (W/2)*4);
        }
        //// Make a ramp
        //for (unsigned j = 0; j < H/2; ++j)
        //    memset (static_cast<unsigned char *> (p) + j * (W/2)*4, j % 256, (W/2)*4);
        xgl->UnlockOffscreenBuffer (i, buffer_handle);
        // Blit the buffer to all backbuffers
        xgl->Blit (i, buffer_handle);
        xgl->Flip (i);
        xgl->Blit (i, buffer_handle);
        xgl->Flip (i);
        xgl->Blit (i, buffer_handle);
        xgl->Flip (i);
        // Read the back buffer
        set<unsigned char> vals;
        unsigned char *bb = static_cast<unsigned char *> (xgl->LockBackBuffer (i, 0));
        for (unsigned j = 0; j < W * H * 4; ++j)
            vals.insert (bb[j]);
        s.str ("");
        for (unsigned y = 0; y < 16; ++y)
        {
            for (unsigned x = 0; x < 16; ++x)
            {
                s << static_cast<unsigned> (bb[y * W * 4 + x * 4]) << " ";
            }
            s << endl;
        }
        s << endl;
        Log (s.str ());

        xgl->UnlockBackBuffer (i, 0);

        s.str ("");
        s << "Unique values in the backbuffer are:" << endl;
        for (set<unsigned char>::iterator si = vals.begin (); si != vals.end (); ++si)
            s << static_cast<unsigned int> (*si) << " ";
        s << endl;
        Log (s.str ());
    }
};

struct GammaRampTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        stringstream s;
        s << "Getting/Setting gamma ramp on device " << i;
        Log (s.str ());
        xgl->InitDevice (i, m, 2); // triple buffer
        vector<unsigned short> g (3 * 256);
        xgl->GetGamma (i, g);
        s.str ("");
        s << "Current gamma ramp: ";
        Log (s.str ());
        for (unsigned j = 0; j < 256; ++j)
        {
            s.str ("");
            s << g[j * 3 + 0] << ", "
              << g[j * 3 + 1] << ", "
              << g[j * 3 + 2];
            Log (s.str ());
        }
        unsigned char *p = static_cast<unsigned char *> (xgl->LockBackBuffer (i, 0));
        // Create a vertical ramp on the display
        for (unsigned j = 0; j < m.height; ++j)
            memset (&p[j*m.width*4], j*256/m.height, m.width*4);
        xgl->UnlockBackBuffer (i, 0);
        xgl->Flip (i);
        tic (); while (toc () < 0.5); // Pause
        for (float j = 0.5f; j < 3.1f; j+=0.1f)
        {
            s.str ("");
            s << "Setting gamma to " << 1/j;
            Log (s.str ());
            for (unsigned k = 0; k < 256; ++k)
            {
                g[k * 3 + 0] = static_cast<unsigned> (powf (static_cast<float> (k * 1.0 / 255), 1/j) * 0xFFFF);
                g[k * 3 + 1] = static_cast<unsigned> (powf (static_cast<float> (k * 1.0 / 255), 1/j) * 0xFFFF);
                g[k * 3 + 2] = static_cast<unsigned> (powf (static_cast<float> (k * 1.0 / 255), 1/j) * 0xFFFF);
            }
            xgl->SetGamma (i, g);
        }
        tic (); while (toc () < 0.5); // Pause
        xgl->ReleaseDevice (i);
    }
};

struct TextTest
{
    void Test (Session *xgl, unsigned i, const DisplayMode &m)
    {
        xgl->InitDevice (i, m, 2); // triple buffer
        const unsigned N = xgl->TotalFonts (i);
        stringstream s;
        s << "Total system fonts: " << N;
        Log (s.str ());
        for (unsigned j = 0; j < N; ++j)
        {
            s.str ("");
            s << "Font #" << j << ": " << xgl->FontName (i, j);
            Log (s.str ());
        }
        int x = m.width / 2;
        int y = m.height / 2;
        unsigned arial_font_number = N;
        for (unsigned j = 0; j < N; ++j)
        {
            if (!strcmp (xgl->FontName (i, j).c_str (), "Arial"))
            {
                arial_font_number = j;
                break;
            }
        }

        if (arial_font_number == N)
            throw "Could not find the font named 'Arial'";

        xgl->SetFont (i, arial_font_number);
        xgl->SetPointSize (i, 50);

        s.str ("Testing text colors");
        Log (s.str ());
        s.str ("Red");
        Log (s.str ());
        int dx = xgl->GetTextWidth (i, s.str ().c_str ());
        int dy = xgl->GetTextHeight (i);
        xgl->SetTextColor (i, MakeRGB8 (255, 0, 0));
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("Green");
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        xgl->SetTextColor (i, MakeRGB8(0, 255, 0));
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("Blue");
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        xgl->SetTextColor (i, MakeRGB8(0, 0, 255));
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("Red on Blue/green");
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        xgl->SetTextColor (i, MakeRGB8(255, 0, 0));
        xgl->SetBGColor (i, MakeRGB8(0, 255, 255));
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("Green on Purple");
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        xgl->SetTextColor (i, MakeRGB8(0, 255, 0));
        xgl->SetBGColor (i, MakeRGB8(255, 0, 255));
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("Blue on Yellow");
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        xgl->SetTextColor (i, MakeRGB8(0, 0, 255));
        xgl->SetBGColor (i, MakeRGB8 (255, 255, 0));
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("Black on Transparent");
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        xgl->SetTextColor (i, MakeRGB8 (0, 0, 0));
        xgl->SetBGColor (i, MakeRGB8 (255, 255, 255));
        xgl->SetBGTransparency (i, true);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (128, 128, 128));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }
        xgl->SetTextColor (i, MakeRGB8 (0, 0, 0));
        xgl->SetBGColor (i, MakeRGB8 (255, 255, 255));
        xgl->SetBGTransparency (i, false);

        s.str ("Testing font attributes");
        Log (s.str ());
        s.str ("Italic");
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        xgl->SetItalic (i, 1);
        xgl->SetUnderline (i, 0);
        xgl->SetStrikeOut (i, 0);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }

        s.str ("Underline");
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        Log (s.str ());
        xgl->SetItalic (i, 0);
        xgl->SetUnderline (i, 1);
        xgl->SetStrikeOut (i, 0);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }

        s.str ("StrikeOut");
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        Log (s.str ());
        xgl->SetItalic (i, 0);
        xgl->SetUnderline (i, 0);
        xgl->SetStrikeOut (i, 1);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }

        s.str ("Everything");
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        Log (s.str ());
        xgl->SetItalic (i, 1);
        xgl->SetUnderline (i, 1);
        xgl->SetStrikeOut (i, 1);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }

        s.str ("Nothing");
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        Log (s.str ());
        xgl->SetItalic (i, 0);
        xgl->SetUnderline (i, 0);
        xgl->SetStrikeOut (i, 0);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
            xgl->Flip (i);
        }

        s.str ("Testing text positions");
        Log (s.str ());
        s.str ("");
        s << "Top Left";
        Log (s.str ());
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, 0, 0, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("");
        s << "Top Right";
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, m.width - dx, 0, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("");
        s << "Bottom Left";
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, 0, m.height - dy, s.str ().c_str ());
            xgl->Flip (i);
        }
        s.str ("");
        s << "Bottom Right";
        Log (s.str ());
        dx = xgl->GetTextWidth (i, s.str ().c_str ());
        dy = xgl->GetTextHeight (i);
        tic ();
        while (toc () < 0.5)
        {
            xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
            xgl->Text (i, m.width - dx, m.height - dy, s.str ().c_str ());
            xgl->Flip (i);
        }

        s.str ("Testing font sizes");
        Log (s.str ());
        for (unsigned j = 0; j < N; j+=10)
        {
            s.str ("");
            s << "Font #" << j << ": " << xgl->FontName (i, j);
            Log (s.str ());

            xgl->SetFont (i, j);
            tic ();
            for (unsigned k = 1; toc () < 0.5; k = static_cast<unsigned> (toc () * 100))
            {
                xgl->SetPointSize (i, k);
                xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
                int dx = xgl->GetTextWidth (i, s.str ().c_str ());
                int dy = xgl->GetTextHeight (i);
                xgl->Text (i, x - dx/2, y - dy/2, s.str ().c_str ());
                xgl->Flip (i);
            }
        }
        s.str ("Testing font escapements");
        Log (s.str ());
        for (unsigned j = 0; j < N; j+=10)
        {
            s.str ("");
            s << "Font #" << j << ": " << xgl->FontName (i, j);
            Log (s.str ());

            xgl->SetFont (i, j);
            xgl->SetPointSize (i, 30);
            tic ();
            const float SECS = 0.5;
            for (unsigned k = 0; toc () < SECS; k = static_cast<unsigned> (toc () * 360 / SECS))
            {
                xgl->SetEscapement (i, k);
                xgl->Clear (i, 0, MakeRGB8 (255, 255, 255));
                xgl->Text (i, x, y, s.str ().c_str ());
                xgl->Flip (i);
            }
        }

        xgl->ReleaseDevice (i);
    }
};

int main()
{
   Session *xgl;

    try
    {
        assert (sizeof (unsigned int) == 4);

#ifdef _WIN32
        // Record the state of the debug heap if we are using MSVC in
        // _DEBUG mode.
        _CrtSetReportMode (_CRT_WARN, _CRTDBG_MODE_FILE);
        _CrtSetReportFile (_CRT_WARN, _CRTDBG_FILE_STDOUT);
        _CrtSetReportMode (_CRT_ERROR, _CRTDBG_MODE_FILE);
        _CrtSetReportFile (_CRT_ERROR, _CRTDBG_FILE_STDOUT);
        _CrtSetReportMode (_CRT_ASSERT, _CRTDBG_MODE_FILE);
        _CrtSetReportFile (_CRT_ASSERT, _CRTDBG_FILE_STDOUT);
#ifndef NDEBUG
        _CrtMemState ms1;
        _CrtMemCheckpoint (&ms1);
#endif
        {
#endif

        xgl = new Session;

        Log ("Testing Init/Release");
        xgl->Init ();
        xgl->Release ();

        Log ("Testing Init/Release with an error");
        xgl->Init ();
        bool failed = false;
        try { xgl->TotalModes (~0, PF_X8R8G8B8); }
        catch (const char *e) {
            Log (e);
            failed = true;
        }
        Assert (failed);
        xgl->Release ();

        Log ("Testing TotalDevices");
        xgl->Init ();
        unsigned devices = xgl->TotalDevices ();
        stringstream s;
        s << devices << " devices found";
        Log (s.str ());
        xgl->Release ();

        xgl->Init ();
        cout << "There are " << xgl->TotalDevices () << " total devices" << endl;
        xgl->Release ();
        cout << "Enter the device number (0-based):" << endl;
        unsigned device_number;
        cin >> device_number;

        ForEachDevice (device_number, GetDeviceInfoTest (), xgl);
        ForEachDevice (device_number, GetScreenRectTest (), xgl);
        ForEachDevice (device_number, GetCurrentModeTest (), xgl);
        ForEachDevice (device_number, GetTotalModesTest (), xgl);
        ForEachDevice (device_number, GetHWConversionTest (), xgl);
        GetModeTest gmt;
        ForEachMode (device_number, gmt, xgl);

        unsigned width = 1024;
        unsigned height = 768;

        //cout << "Enter the mode width:" << endl;
        //cin >> width;
        //cout << "Enter the mode height:" << endl;
        //cin >> height;

        s.str ("");
        s << "Looking for a " << width << "x" << height << " mode";
        Log (s.str ());
        FindMode fm (width, height);
        ForEachMode (device_number, fm, xgl);

        if (!fm.found)
            throw "Could not find a mode for the device with these dimensions";

        cout << "1 InitDeviceTest1" << endl;
        cout << "2 InitDeviceTest2" << endl;
        cout << "3 ClearFlipTest" << endl;
        cout << "4 BackBufferTest" << endl;
        cout << "5 OffscreenBufferTest" << endl;
        cout << "6 BlitTest" << endl;
        cout << "7 StretchRectTest" << endl;
        cout << "8 DoHWConversionTest" << endl;
        cout << "9 CopyFromBackBufferTest" << endl;
        cout << "10 CheckInterpolationTest" << endl;
        cout << "11 GammaRampTest" << endl;
        cout << "12 TextTest" << endl;
        cout << "13 Quit" << endl;
        cout << "Enter a test number (0 for all): " << endl;
        unsigned n;
        cin >> n;

        switch (n)
        {
            default: throw "Invalid test number";
            case 0:
                ForEachDevice (device_number, InitDeviceTest1 (), xgl, fm.mode);
                ForEachDevice (device_number, InitDeviceTest2 (), xgl, fm.mode);
                ForEachDevice (device_number, ClearFlipTest (), xgl, fm.mode);
                ForEachDevice (device_number, BackBufferTest (), xgl, fm.mode);
                ForEachDevice (device_number, OffscreenBufferTest (), xgl, fm.mode);
                ForEachSupportedHWConversion (device_number, BlitTest (), xgl, fm.mode);
                ForEachSupportedHWConversion (device_number, StretchRectTest (), xgl, fm.mode);
                ForEachSupportedHWConversion (device_number, DoHWConversionTest (), xgl, fm.mode);
                ForEachDevice (device_number, CopyFromBackBufferTest (), xgl, fm.mode);
                ForEachDevice (device_number, CheckInterpolationTest (), xgl, fm.mode);
                ForEachDevice (device_number, GammaRampTest (), xgl, fm.mode);
                ForEachDevice (device_number, TextTest (), xgl, fm.mode);
            break;
            case 1:  ForEachDevice (device_number, InitDeviceTest1 (), xgl, fm.mode); break;
            case 2:  ForEachDevice (device_number, InitDeviceTest2 (), xgl, fm.mode); break;
            case 3:  ForEachDevice (device_number, ClearFlipTest (), xgl, fm.mode); break;
            case 4:  ForEachDevice (device_number, BackBufferTest (), xgl, fm.mode); break;
            case 5:  ForEachDevice (device_number, OffscreenBufferTest (), xgl, fm.mode); break;
            case 6:  ForEachSupportedHWConversion (device_number, BlitTest (), xgl, fm.mode); break;
            case 7:  ForEachSupportedHWConversion (device_number, StretchRectTest (), xgl, fm.mode); break;
            case 8:  ForEachSupportedHWConversion (device_number, DoHWConversionTest (), xgl, fm.mode); break;
            case 9:  ForEachDevice (device_number, CopyFromBackBufferTest (), xgl, fm.mode); break;
            case 10: ForEachDevice (device_number, CheckInterpolationTest (), xgl, fm.mode); break;
            case 11: ForEachDevice (device_number, GammaRampTest (), xgl, fm.mode); break;
            case 12: ForEachDevice (device_number, TextTest (), xgl, fm.mode); break;
            case 13: break;
        }

        delete xgl;
#ifdef _WIN32
        // Now compare the heap saved off to the current one to make
        // sure we haven't leaked any memory resources.
        }
#ifndef NDEBUG
        _CrtMemState ms2, diff;
#endif
        _CrtMemCheckpoint (&ms2);

        if (_CrtMemDifference (&diff, &ms1, &ms2))
        {
            _CrtMemDumpStatistics (&diff);
            _CrtMemDumpAllObjectsSince (&ms1);
            throw "Memory leaks detected";
        }
#endif
        Log ("Success");
        return 0;
    }
    catch (const char *e)
    {
        cerr << e << endl;
        Log (e);
        delete xgl;
        return -1;
    }
}
