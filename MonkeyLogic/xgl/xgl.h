// X Graphics Library
//
// Copyright (C) 2000-2006
// Center for Vision and Image Sciences
// Center for Perceptual Systems
// University of Texas at Austin
//
// jsp Tue Aug 15 10:00:00 CDT 2000 Creation
// jsp Fri Oct 11 22:04:14 CST 2002 Updated
// jsp Fri Aug 19 12:42:12 CDT 2005 Updated
// jsp Tue Oct  3 11:37:15 CDT 2006 Updated

#ifndef XGL_H
#define XGL_H

#include <cassert>
#include <cstring>
#include <map>
#include <set>
#include <string>
#include <utility>
#include <vector>

#ifdef _WIN32

#ifndef NDEBUG
#define D3D_DEBUG_INFO
#define D3DX_DEBUG
#endif

#include <d3d9.h>
#include <d3dx9math.h>
typedef D3DXFLOAT16 Float16;
typedef D3DXVECTOR4_16F RGBFloat16;

#else

typedef unsigned short Float16;
typedef
struct D3DXVECTOR4_16F
{
    D3DXVECTOR4_16F (float x, float y, float z, float w) :
        x (x), y (y), z (z), w (w) { }
    float x, y, z, w;
} RGBFloat16;

#endif

namespace XGL
{

enum PixelFormat
{
    PF_L8,
    PF_X8R8G8B8,
    PF_YV12,
    PF_A2R10G10B10,
    PF_A16B16G16R16F,
    PF_A32B32G32R32F,
    PF_OTHER
};

struct DisplayMode
{
    int width;
    int height;
    unsigned freq;
    PixelFormat pf;
};

typedef unsigned OffscreenBufferHandle;

// Clamp an integer to the range [MIN,MAX]
template<int MIN, int MAX>
inline int Clamp (int n) { return n < MIN ? MIN : (n > MAX ? MAX : n); }

// Convert to and from YPbPr colorspace, remember that U=Pr, V=Pb
inline double YPbPrY  (double r, double g, double b) { return  0.2122 * r + 0.7013 * g + 0.0865 * b; }
inline double YPbPrPb (double r, double g, double b) { return -0.1162 * r - 0.3838 * g + 0.5000 * b; }
inline double YPbPrPr (double r, double g, double b) { return  0.5000 * r - 0.4451 * g - 0.0549 * b; }
inline double YPbPrR (double y, double pb, double pr) { return  y + 0.0000 * pb + 1.5756 * pr; }
inline double YPbPrG (double y, double pb, double pr) { return  y - 0.2253 * pb - 0.5000 * pr; }
inline double YPbPrB (double y, double pb, double pr) { return  y + 1.8270 * pb + 0.0000 * pr; }

// Convert three uints to an rgb8
inline unsigned int MakeRGB8 (unsigned r, unsigned g, unsigned b)
{
    return static_cast<unsigned long> ((((r)&0xff)<<16)|(((g)&0xff)<<8)|((b)&0xff));
}

// Convert three uints to an rgb10
inline unsigned int MakeRGB10 (unsigned r, unsigned g, unsigned b)
{
    return static_cast<unsigned long> ((((r)&0x3ff)<<20)|(((g)&0x3ff)<<10)|((b)&0x3ff));
}

// Turn a float into a 16 bit number (s10e5)
inline Float16 MakeFloat16 (float f)
{
    return Float16 (f);
}

// Turn rgb floats into a 64 bit number
inline RGBFloat16 MakeRGBFloat16 (float r, float g, float b)
{
    return RGBFloat16 (MakeFloat16 (r), MakeFloat16 (g), MakeFloat16 (b), MakeFloat16 (0));
}

inline unsigned BitsPerPixel (PixelFormat pf)
{
    switch (pf)
    {
        default:
        throw "Unknown pixel format";
        case PF_L8:
        return 8;
        case PF_X8R8G8B8:
        return 32;
        case PF_YV12:
        return 12;
        case PF_A2R10G10B10:
        return 32;
        case PF_A16B16G16R16F:
        return 64;
        case PF_A32B32G32R32F:
        return 128;
    }
}

#ifdef _WIN32

D3DFORMAT XGL2D3D (PixelFormat pf);
PixelFormat D3D2XGL (D3DFORMAT f);
void ConvertDisplayMode (const D3DDISPLAYMODE &m, DisplayMode *dm);
void ConvertDisplayMode (const DisplayMode &dm, D3DDISPLAYMODE *m);

class Session
{

    public:
    Session ();
    ~Session ();
    void Init ();
    void Release ();
    unsigned TotalDevices ();
    std::string GetDeviceInfo (unsigned device);
    void GetScreenRect (unsigned device, int *x, int *y, int *w, int *h);
    unsigned TotalModes (unsigned device, PixelFormat pf);
    void GetMode (unsigned device, PixelFormat pf, unsigned m, DisplayMode *dm);
    void GetCurrentMode (unsigned device, DisplayMode *dm);
    bool HardwareConversion (unsigned device, PixelFormat src, PixelFormat dest);
    // When you initialize a device, it will enter the display mode
    // that you pass to this routine.
    //
    // You must have at least one backbuffer.  The total number of
    // pages of video memory used will be 'backbuffers'+1 since a
    // frontbuffer is also allocated.
    void InitDevice (unsigned device, const DisplayMode &dm, unsigned backbuffers);
    void ReleaseDevice (unsigned device);
    void Clear (unsigned device, unsigned backbuffer, unsigned long rgb);
    void Flip (unsigned device);
    void GetRasterStatus (unsigned device, bool *vblank, unsigned *scanline);
    void *LockBackBuffer (unsigned device, unsigned backbuffer);
    void UnlockBackBuffer (unsigned device, unsigned backbuffer);
    void CreateOffscreenBuffer (unsigned device, unsigned w, unsigned h, PixelFormat pf, unsigned *handle);
    void ReleaseOffscreenBuffer (unsigned device, OffscreenBufferHandle handle);
    void ReleaseOffscreenBuffers (unsigned device);
    void OffscreenBufferDimensions (unsigned device, OffscreenBufferHandle handle, unsigned *w, unsigned *h, PixelFormat *pf);
    void ClearOffscreenBuffer (unsigned device, OffscreenBufferHandle handle, unsigned long rgb);
    void *LockOffscreenBuffer (unsigned device, OffscreenBufferHandle handle);
    void UnlockOffscreenBuffer (unsigned device, OffscreenBufferHandle handle);
    void Blit (unsigned device, OffscreenBufferHandle handle, unsigned dest_x, unsigned dest_y, unsigned dest_width, unsigned dest_height);
    void Blit (unsigned device, OffscreenBufferHandle handle);
    // Gamma effects are immediate: there is no wait for vsync
    //
    // Gamma ramp values should be in the range [0,2**16-1]
    void GetGamma (unsigned device, std::vector<unsigned short> &gamma);
    void SetGamma (unsigned device, const std::vector<unsigned short> &gamma);
    // Text functions
    unsigned TotalFonts (unsigned device);
    std::string FontName (unsigned device, unsigned font);
    void SetFont (unsigned device, unsigned font);
    void SetTextColor (unsigned device, unsigned long rgb);
    void SetBGColor (unsigned device, unsigned long rgb);
    void SetBGTransparency (unsigned device, bool on);
    unsigned GetTextHeight (unsigned device);
    unsigned GetTextWidth (unsigned device, const char *string);
    void SetPointSize (unsigned device, unsigned ps);
    void SetEscapement (unsigned device, unsigned degrees);
    void SetItalic (unsigned device, bool on);
    void SetUnderline (unsigned device, bool on);
    void SetStrikeOut (unsigned device, bool on);
    void Text (unsigned device, int x, int y, const char *t);
    // Cursor Functions
    void ShowCursor (unsigned device, bool flag);

    private:
    void CheckDeviceNumber (unsigned d);
    void CheckDeviceInitialized (unsigned d);
    void GetCaps (unsigned d, D3DCAPS9 *caps);

    // Helper class for initializing and releasing Direct3D
    class D3D
    {
        public:
        D3D ();
        ~D3D ();
        void Init ();
        void Release ();
        bool Initialized ();
        LPDIRECT3D9 operator-> ();
        private:
        LPDIRECT3D9 p;
    } d3d;

    // Helper class for initializing and releasing a focus window
    class FocusWindow
    {
        public:
        FocusWindow ();
        ~FocusWindow ();
        void Init ();
        void Release ();
        HWND Hwnd ();
        private:
        HWND hwnd;
    } focus_window;

    // Helper class for keeping track of devices
    class Device
    {
        public:
        Device ();
        ~Device ();
        void Init (D3D &d3d, unsigned d, FocusWindow &focus_window, const DisplayMode &dm, unsigned bb);
        void Release ();
        bool Initialized ();
        HWND Hwnd ();
        IDirect3DDevice9 *Interface ();
        void InitBackBuffer (unsigned b);
        void *LockBackBuffer (unsigned b);
        void UnlockBackBuffer (unsigned b);
        void Clear (unsigned b, unsigned long rgb);
        void Flip ();
        void GetRasterStatus (bool *vblank, unsigned *scanline);
        void CreateOffscreenBuffer (unsigned w, unsigned h, PixelFormat pf, OffscreenBufferHandle *handle);
        void ReleaseOffscreenBuffer (OffscreenBufferHandle handle);
        void ReleaseOffscreenBuffers ();
        void OffscreenBufferDimensions (OffscreenBufferHandle handle, unsigned *w, unsigned *h, PixelFormat *pf);
        void ClearOffscreenBuffer (OffscreenBufferHandle handle, unsigned long rgb);
        void *LockOffscreenBuffer (OffscreenBufferHandle handle);
        void UnlockOffscreenBuffer (OffscreenBufferHandle handle);
        void Blit (OffscreenBufferHandle handle, unsigned x, unsigned y, unsigned w, unsigned h);
        void Blit (OffscreenBufferHandle handle);
        void GetGamma (std::vector<unsigned short> &gamma);
        void SetGamma (const std::vector<unsigned short> &gamma);
        unsigned TotalFonts ();
        std::string FontName (unsigned font);
        void SetFont (unsigned font);
        void SetTextColor (unsigned long rgb);
        void SetBGColor (unsigned long rgb);
        void SetBGTransparency (bool on);
        unsigned GetTextHeight ();
        unsigned GetTextWidth (const char *string);
        void SetPointSize (unsigned ps);
        void SetEscapement (unsigned degrees);
        void SetItalic (bool on);
        void SetUnderline (bool on);
        void SetStrikeOut (bool on);
        void Text (int x, int y, const char *t);
        void ShowCursor (bool flag);

        private:
        void CheckBackBuffer (unsigned i);
        void CheckOffscreenBuffer (OffscreenBufferHandle h);
        void CheckFont (unsigned font);
        static int __stdcall EnumFontFamProc (const LOGFONT *lf, const TEXTMETRIC *tm, unsigned long font, LPARAM p)
        {
            // The object gets passed as side data
            Session::Device *dp = (Session::Device *) p;
            dp->fonts.push_back (*lf);
            dp->font_types.push_back (font); // DEVICE_FONTTYPE, RASTER_FONTTYPE, or TRUETYPE_FONTTYPE
            tm = 0; // turn on unreferenced formal parameter warning
            return true; // Continue enumerating
        }

        // Helper class for D3D Surfaces
        class Surface
        {
            public:
            Surface ();
            ~Surface ();
            IDirect3DSurface9 *Interface ();
            bool Initialized ();
            void Init (IDirect3DSurface9 *si);
            void Release ();
            void *Lock ();
            void Unlock ();
            void Dimensions (unsigned *w, unsigned *h, PixelFormat *pf);
            private:
            IDirect3DSurface9 *surface_interface;
            void *lock;
        };

        // Helper class for device contexts
        class DeviceContext
        {
            public:
            DeviceContext (IDirect3DSurface9 *i);
            ~DeviceContext ();
            operator HDC ();
            private:
            IDirect3DSurface9 *surface_interface;
            HDC dc;
        };

        // Helper class for creating fonts
        class FontCreator
        {
            public:
            FontCreator (const LOGFONT &font);
            ~FontCreator ();
            operator HFONT ();
            private:
            HFONT hf;
        };

        // Helper class for setting the text colors
        class TextColor
        {
            public:
            TextColor ();
            void Set (HDC dc);
            void SetColor (unsigned long rgb);
            void SetBG (unsigned long rgb);
            void SetTransparency (bool on);
            private:
            unsigned long foreground, background;
            bool transparent, dirty;
        };

        bool initialized;
        HWND hwnd;
        IDirect3DDevice9 *device_interface;
        std::vector<Surface> backbuffers;
        std::vector<Surface *> offscreen_buffers;
        std::set<OffscreenBufferHandle> released_buffer_handles;
        std::vector<LOGFONT> fonts;
        std::vector<unsigned long> font_types;
        TextColor text_color;

        LOGFONT current_font;
    };
    std::vector<Device> devices;
};

#else

class Session
{

    public:
    Session ();
    ~Session ();
    void Init ();
    void Release ();
    unsigned TotalDevices ();
    std::string GetDeviceInfo (unsigned device);
    void GetScreenRect (unsigned device, int *x, int *y, int *w, int *h);
    unsigned TotalModes (unsigned device, PixelFormat pf);
    void GetMode (unsigned device, PixelFormat pf, unsigned m, DisplayMode *dm);
    void GetCurrentMode (unsigned device, DisplayMode *dm);
    bool HardwareConversion (unsigned device, PixelFormat src, PixelFormat dest);
    void InitDevice (unsigned device, const DisplayMode &dm, unsigned backbuffers);
    void ReleaseDevice (unsigned device);
    void Clear (unsigned device, unsigned backbuffer, unsigned long rgb);
    void Flip (unsigned device);
    void GetRasterStatus (unsigned device, bool *vblank, unsigned *scanline);
    void *LockBackBuffer (unsigned device, unsigned backbuffer);
    void UnlockBackBuffer (unsigned device, unsigned backbuffer);
    void CreateOffscreenBuffer (unsigned device, unsigned w, unsigned h, PixelFormat pf, unsigned *handle);
    void ReleaseOffscreenBuffer (unsigned device, OffscreenBufferHandle handle);
    void ReleaseOffscreenBuffers (unsigned device);
    void OffscreenBufferDimensions (unsigned device, OffscreenBufferHandle handle, unsigned *w, unsigned *h, PixelFormat *pf);
    void ClearOffscreenBuffer (unsigned device, OffscreenBufferHandle handle, unsigned long rgb);
    void *LockOffscreenBuffer (unsigned device, OffscreenBufferHandle handle);
    void UnlockOffscreenBuffer (unsigned device, OffscreenBufferHandle handle);
    void Blit (unsigned device, OffscreenBufferHandle handle, unsigned dest_x, unsigned dest_y, unsigned dest_width, unsigned dest_height);
    void Blit (unsigned device, OffscreenBufferHandle handle);
    void GetGamma (unsigned device, std::vector<unsigned short> &gamma);
    void SetGamma (unsigned device, const std::vector<unsigned short> &gamma);
    unsigned TotalFonts (unsigned device);
    std::string FontName (unsigned device, unsigned font);
    void SetFont (unsigned device, unsigned font);
    void SetTextColor (unsigned device, unsigned long rgb);
    void SetBGColor (unsigned device, unsigned long rgb);
    void SetBGTransparency (unsigned device, bool on);
    unsigned GetTextHeight (unsigned device);
    unsigned GetTextWidth (unsigned device, const char *string);
    void SetPointSize (unsigned device, unsigned ps);
    void SetEscapement (unsigned device, unsigned degrees);
    void SetItalic (unsigned device, bool on);
    void SetUnderline (unsigned device, bool on);
    void SetStrikeOut (unsigned device, bool on);
    void Text (unsigned device, int x, int y, const char *t);
    void ShowCursor (unsigned device, bool flag);
    private:
    void CheckDeviceNumber (unsigned d);
    std::vector<unsigned char> back_buffer;
    DisplayMode back_buffer_mode;
    std::vector<unsigned char> offscreen_buffer;
    DisplayMode offscreen_buffer_mode;
};

#endif

} // namespace XGL

#endif // XGL_H
