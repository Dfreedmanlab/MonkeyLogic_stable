// X Graphics Library
//
// Copyright (C) 2000-2006
// Center for Vision and Image Sciences
// Center for Perceptual Systems
// University of Texas at Austin
//
// jsp Tue Aug 15 10:00:00 CDT 2000 Creation
// jsp Fri Oct 11 22:04:14 CST 2002 Updated
// jsp Wed Aug 17 17:43:46 CDT 2005 Updated
// jsp Tue Oct  3 11:37:15 CDT 2006 Updated

#include "xgl.h"

namespace XGL
{

#ifdef _WIN32

Session::Session ()
{
}

Session::~Session ()
{
    Release ();
}

void Session::Init ()
{
    Release ();
    d3d.Init ();
    focus_window.Init ();

    devices.resize (TotalDevices ());
}

void Session::Release ()
{
    // Release all devices and destroy device windows
    for (unsigned i = 0; i < TotalDevices (); ++i)
        ReleaseDevice (i);
    focus_window.Release ();
    d3d.Release ();
}

unsigned Session::TotalDevices ()
{
    if (d3d.Initialized ())
        return d3d->GetAdapterCount ();
    return 0;
}

std::string Session::GetDeviceInfo (unsigned d)
{
    CheckDeviceNumber (d);
    D3DADAPTER_IDENTIFIER9 id;
    if (d3d->GetAdapterIdentifier (d, 0, &id) != D3D_OK)
        throw "Could not get adapter identifier";
    std::string s;
    s = id.Driver;
    s += ": ";
    s += id.Description;
    return s;
}

void Session::GetScreenRect (unsigned d, unsigned *x, unsigned *y, unsigned *w, unsigned *h)
{
    CheckDeviceNumber (d);
    HMONITOR hm = d3d->GetAdapterMonitor (d);

    MONITORINFO mi;

    memset (&mi, 0, sizeof (mi));
    mi.cbSize = sizeof (mi);

    if (!GetMonitorInfo (hm, &mi))
        throw "Could not get monitor information";

    *x = mi.rcMonitor.left;
    *y = mi.rcMonitor.top;
    *w = mi.rcMonitor.right - mi.rcMonitor.left;
    *h = mi.rcMonitor.bottom - mi.rcMonitor.top;
}

unsigned Session::TotalModes (unsigned d, PixelFormat pf)
{
    CheckDeviceNumber (d);
    unsigned m = d3d->GetAdapterModeCount (d, XGL2D3D (pf));
    return m;
}

bool Session::HardwareConversion (unsigned d, PixelFormat src, PixelFormat dest)
{
    CheckDeviceNumber (d);
    if (d3d->CheckDeviceFormatConversion (d, D3DDEVTYPE_HAL, XGL2D3D (src), XGL2D3D (dest) ) == D3D_OK)
        return true;
    return false;
}

void Session::GetMode (unsigned d, PixelFormat pf, unsigned m, DisplayMode *dm)
{
    CheckDeviceNumber (d);
    D3DDISPLAYMODE mode;
    if (d3d->EnumAdapterModes (d, XGL2D3D (pf), m, &mode) != D3D_OK)
        throw "Could not get specified device mode";
    ConvertDisplayMode (mode, dm);
}

void Session::GetCurrentMode (unsigned d, DisplayMode *dm)
{
    CheckDeviceNumber (d);
    D3DDISPLAYMODE mode;
    if (d3d->GetAdapterDisplayMode (d, &mode) != D3D_OK)
        throw "Could not get device mode";
    ConvertDisplayMode (mode, dm);
}

void Session::InitDevice (unsigned d, const DisplayMode &dm, unsigned backbuffers)
{
    CheckDeviceNumber (d);
    ReleaseDevice (d);
    devices[d].Init (d3d, d, focus_window, dm, backbuffers);
}

void Session::ReleaseDevice (unsigned d)
{
    // Don't throw exceptions if you are called by the destructor
    if (d >= TotalDevices ())
        return;
    devices[d].Release ();
}

void Session::Clear (unsigned d, unsigned backbuffer, unsigned long rgb)
{
    CheckDeviceInitialized (d);
    devices[d].Clear (backbuffer, rgb);
}

void Session::Flip (unsigned d)
{
    CheckDeviceInitialized (d);
    devices[d].Flip ();
}

void Session::GetRasterStatus (unsigned d, bool *vblank, unsigned *scanline)
{
    CheckDeviceInitialized (d);
    devices[d].GetRasterStatus (vblank, scanline);
}

void *Session::LockBackBuffer (unsigned d, unsigned backbuffer)
{
    CheckDeviceInitialized (d);
    return devices[d].LockBackBuffer (backbuffer);
}

void Session::UnlockBackBuffer (unsigned d, unsigned backbuffer)
{
    // Don't throw exceptions if you are called by the destructor
    devices[d].UnlockBackBuffer (backbuffer);
}

void Session::CreateOffscreenBuffer (unsigned d, unsigned w, unsigned h, PixelFormat pf, OffscreenBufferHandle *handle)
{
    CheckDeviceInitialized (d);
    devices[d].CreateOffscreenBuffer (w, h, pf, handle);
}

void Session::ReleaseOffscreenBuffer (unsigned d, OffscreenBufferHandle handle)
{
    // Don't throw exceptions if you are called by the destructor
    devices[d].ReleaseOffscreenBuffer (handle);
}

void Session::OffscreenBufferDimensions (unsigned d, OffscreenBufferHandle handle, unsigned *w, unsigned *h, PixelFormat *pf)
{
    devices[d].OffscreenBufferDimensions (handle, w, h, pf);
}

void Session::ReleaseOffscreenBuffers (unsigned d)
{
    // Don't throw exceptions if you are called by the destructor
    devices[d].ReleaseOffscreenBuffers ();
}

void Session::ClearOffscreenBuffer (unsigned d, OffscreenBufferHandle handle, unsigned long rgb)
{
    CheckDeviceInitialized (d);
    return devices[d].ClearOffscreenBuffer (handle, rgb);
}

void *Session::LockOffscreenBuffer (unsigned d, OffscreenBufferHandle handle)
{
    CheckDeviceInitialized (d);
    return devices[d].LockOffscreenBuffer (handle);
}

void Session::UnlockOffscreenBuffer (unsigned d, OffscreenBufferHandle handle)
{
    // Don't throw exceptions if you are called by the destructor
    devices[d].UnlockOffscreenBuffer (handle);
}

void Session::Blit (unsigned d, OffscreenBufferHandle handle, unsigned dest_x, unsigned dest_y, unsigned dest_width, unsigned dest_height)
{
    CheckDeviceInitialized (d);
    devices[d].Blit (handle, dest_x, dest_y, dest_width, dest_height);
}

void Session::Blit (unsigned d, OffscreenBufferHandle handle)
{
    CheckDeviceInitialized (d);
    devices[d].Blit (handle);
}

void Session::GetGamma (unsigned d, std::vector<unsigned short> &gamma)
{
    if (gamma.size () != 256 * 3)
        gamma.resize (256 * 3);
    CheckDeviceInitialized (d);
    devices[d].GetGamma (gamma);
}

void Session::SetGamma (unsigned d, const std::vector <unsigned short> &gamma)
{
    assert (gamma.size () == 256 * 3);
    CheckDeviceInitialized (d);
    devices[d].SetGamma (gamma);
}

unsigned Session::TotalFonts (unsigned d)
{
    CheckDeviceInitialized (d);
    return devices[d].TotalFonts ();
}

std::string Session::FontName (unsigned d, unsigned font)
{
    CheckDeviceInitialized (d);
    return devices[d].FontName (font);
}

void Session::SetFont (unsigned d, unsigned font)
{
    CheckDeviceInitialized (d);
    devices[d].SetFont (font);
}

void Session::SetTextColor (unsigned d, unsigned long rgb)
{
    CheckDeviceInitialized (d);
    devices[d].SetTextColor (rgb);
}

void Session::SetBGColor (unsigned d, unsigned long rgb)
{
    CheckDeviceInitialized (d);
    devices[d].SetBGColor (rgb);
}

void Session::SetBGTransparency (unsigned d, bool on)
{
    CheckDeviceInitialized (d);
    devices[d].SetBGTransparency (on);
}

unsigned Session::GetTextHeight (unsigned d)
{
    CheckDeviceInitialized (d);
    return devices[d].GetTextHeight ();
}

unsigned Session::GetTextWidth (unsigned d, const char *string)
{
    CheckDeviceInitialized (d);
    return devices[d].GetTextWidth (string);
}

void Session::SetPointSize (unsigned d, unsigned ps)
{
    CheckDeviceInitialized (d);
    devices[d].SetPointSize (ps);
}

void Session::SetEscapement (unsigned d, unsigned degrees)
{
    CheckDeviceInitialized (d);
    devices[d].SetEscapement (degrees);
}

void Session::SetItalic (unsigned d, bool on)
{
    CheckDeviceInitialized (d);
    devices[d].SetItalic (on);
}

void Session::SetUnderline (unsigned d, bool on)
{
    CheckDeviceInitialized (d);
    devices[d].SetUnderline (on);
}

void Session::SetStrikeOut (unsigned d, bool on)
{
    CheckDeviceInitialized (d);
    devices[d].SetStrikeOut (on);
}

void Session::Text (unsigned d, int x, int y, const char *t)
{
    CheckDeviceInitialized (d);
    devices[d].Text (x, y, t);
}

void Session::ShowCursor (unsigned d, bool flag)
{
    CheckDeviceNumber (d);
    devices[d].ShowCursor (flag);
}

void Session::CheckDeviceNumber (unsigned d)
{
    if (d >= TotalDevices ())
        throw "Invalid device number";
}

void Session::CheckDeviceInitialized (unsigned d)
{
    CheckDeviceNumber (d);
    if (!devices[d].Initialized ())
        throw "The device has not been initialized";
}

void Session::GetCaps (unsigned d, D3DCAPS9 *caps)
{
    CheckDeviceNumber (d);
    if (d3d->GetDeviceCaps (d, D3DDEVTYPE_HAL, caps) != D3D_OK)
        throw "Could not get device capabilities";
}

D3DFORMAT XGL2D3D (PixelFormat pf)
{
    switch (pf)
    {
        default:
        return D3DFMT_UNKNOWN;
        case PF_L8:
        return D3DFMT_L8;
        case PF_X8R8G8B8:
        return D3DFMT_X8R8G8B8;
        case PF_YV12:
        return static_cast<D3DFORMAT> (MAKEFOURCC ('Y', 'V', '1', '2'));
        case PF_A2R10G10B10:
        return D3DFMT_A2R10G10B10;
        case PF_A16B16G16R16F:
        return D3DFMT_A16B16G16R16F;
        case PF_A32B32G32R32F:
        return D3DFMT_A32B32G32R32F;
    }
}

#pragma warning (disable: 4063) // YV12 is not a valid value for D3DFORMAT

PixelFormat D3D2XGL (D3DFORMAT f)
{
    switch (f)
    {
        default:
        return PF_OTHER;
        case D3DFMT_L8:
        return PF_L8;
        case D3DFMT_X8R8G8B8:
        return PF_X8R8G8B8;
        case static_cast<D3DFORMAT> (MAKEFOURCC ('Y', 'V', '1', '2')):
        return PF_YV12;
        case D3DFMT_A2R10G10B10:
        return PF_A2R10G10B10;
        case D3DFMT_A16B16G16R16F:
        return PF_A16B16G16R16F;
        case D3DFMT_A32B32G32R32F:
        return PF_A32B32G32R32F;
    }
}

void ConvertDisplayMode (const D3DDISPLAYMODE &m, DisplayMode *dm)
{
    dm->width = m.Width;
    dm->height = m.Height;
    dm->freq = m.RefreshRate;
    dm->pf = D3D2XGL (m.Format);
}

void ConvertDisplayMode (const DisplayMode &dm, D3DDISPLAYMODE *m)
{
    m->Width = dm.width;
    m->Height = dm.height;
    m->RefreshRate = dm.freq;
    m->Format = XGL2D3D (dm.pf);
}

Session::D3D::D3D () : p (0)
{
}

Session::D3D::~D3D ()
{
    Release ();
}

void Session::D3D::Init ()
{
    Release ();
    p = Direct3DCreate9 (D3D_SDK_VERSION);
    if (!p)
        throw "Could not initialize Direct3D";
}

void Session::D3D::Release ()
{
    if (p)
    {
        p->Release ();
        p = 0;
    }
}

bool Session::D3D::Initialized ()
{
    return p != 0;
}

LPDIRECT3D9 Session::D3D::operator-> ()
{
    return p;
}

Session::FocusWindow::FocusWindow () : hwnd (0)
{
}

Session::FocusWindow::~FocusWindow ()
{
    Release ();
}

void Session::FocusWindow::Init ()
{
    Release ();
    std::string title ("XGLToolbox Focus Window");
    WNDCLASSEX wc =
    {
        sizeof (WNDCLASSEX),
        CS_CLASSDC,
        DefWindowProc,
        0L,
        0L,
        GetModuleHandle (NULL),
        NULL,
        NULL,
        NULL,
        NULL,
        title.c_str (),
        NULL
    };
    RegisterClassEx (&wc);
    hwnd = CreateWindow (title.c_str (), title.c_str (),
        WS_OVERLAPPEDWINDOW, 0, 0, 100, 100,
        GetDesktopWindow (), NULL, wc.hInstance, NULL);
    if (hwnd == NULL)
        throw "Could not create application focus window";
}

void Session::FocusWindow::Release ()
{
    if (hwnd)
    {
        DestroyWindow (hwnd);
        hwnd = 0;
    }
}

HWND Session::FocusWindow::Hwnd ()
{
    return hwnd;
}

Session::Device::Device () :
    initialized (0),
    hwnd (0),
    device_interface (0)
{
}

Session::Device::~Device ()
{
    Release ();
}

void Session::Device::Init (D3D &d3d, unsigned d, FocusWindow &focus_window, const DisplayMode &dm, unsigned bb)
{
    Release ();
    // Create a device window
    std::string title ("XGL Toolbox Device Window");
    WNDCLASSEX wc =
    {
        sizeof (WNDCLASSEX),
        CS_CLASSDC,
        DefWindowProc,
        0L,
        0L,
        GetModuleHandle (NULL),
        NULL,
        NULL,
        NULL,
        NULL,
        title.c_str (),
        NULL
    };
    RegisterClassEx (&wc);
    // Create the window.
    hwnd = CreateWindow (title.c_str (), title.c_str (),
        WS_OVERLAPPEDWINDOW, 0, 0, dm.width, dm.height,
        GetDesktopWindow (), NULL, wc.hInstance, NULL);
    if (hwnd == NULL)
        throw "Could not create application device window";
    // Check if HW vertext processing is supported
    D3DCAPS9 caps;
    if (d3d->GetDeviceCaps (d, D3DDEVTYPE_HAL, &caps) != D3D_OK)
        throw "Could not get device capabilities";
    DWORD bf = 0;
    if (caps.VertexProcessingCaps != 0 )
        bf |= D3DCREATE_HARDWARE_VERTEXPROCESSING;
    else
        bf |= D3DCREATE_SOFTWARE_VERTEXPROCESSING;
    // Create the device
    D3DPRESENT_PARAMETERS pp;
    pp.BackBufferWidth = dm.width;
    pp.BackBufferHeight = dm.height;
    pp.BackBufferFormat = XGL2D3D (dm.pf);
    // You need at least one backbuffer
    if (bb < 0)
        bb = 1;
    pp.BackBufferCount = bb;
    pp.MultiSampleType = D3DMULTISAMPLE_NONE;
    pp.MultiSampleQuality = 0;
    pp.SwapEffect = D3DSWAPEFFECT_FLIP; // Back buffer 0 is the least recently used back buffer
    pp.hDeviceWindow = hwnd;
    pp.Windowed = false;
    pp.EnableAutoDepthStencil = false;
    pp.AutoDepthStencilFormat = D3DFMT_D16_LOCKABLE;
    pp.Flags = D3DPRESENTFLAG_LOCKABLE_BACKBUFFER;
    pp.FullScreen_RefreshRateInHz = dm.freq;
    pp.PresentationInterval = D3DPRESENT_INTERVAL_DEFAULT;
    IDirect3DDevice9 *di = 0;
    if (d3d->CreateDevice (d,
        D3DDEVTYPE_HAL,
        focus_window.Hwnd (),
        bf,
        &pp,
        &di) != D3D_OK)
        throw "Could not create device";
    device_interface = di;
    backbuffers.resize (bb);
    initialized = true;
    // Enumerate the fonts
    TotalFonts ();
}

void Session::Device::Release ()
{
    initialized = false;
    // Unlock and release all backbuffers
    for (unsigned i = 0; i < backbuffers.size (); ++i)
        backbuffers[i].Release ();
    // Unlock and release all offscreen buffers
    ReleaseOffscreenBuffers ();

    if (device_interface)
    {
        device_interface->Release ();
        device_interface = 0;
    }

    if (hwnd)
    {
        DestroyWindow (hwnd);
        hwnd = 0;
    }
}

bool Session::Device::Initialized ()
{
    return initialized;
}

HWND Session::Device::Hwnd ()
{
    if (!hwnd)
        throw "A device window for this device has not been allocated";
    return hwnd;
}

IDirect3DDevice9 *Session::Device::Interface ()
{
    if (!device_interface)
        throw "A device interface for this device has not been allocated";
    return device_interface;
}

void Session::Device::InitBackBuffer (unsigned b)
{
    CheckBackBuffer (b);
    if (!backbuffers[b].Initialized ())
    {
        IDirect3DSurface9 *surface_interface;
        if (Interface ()->GetBackBuffer (0, b, D3DBACKBUFFER_TYPE_MONO, &surface_interface) != D3D_OK)
            throw "Could not get the device's backbuffer";
        backbuffers[b].Init (surface_interface);
    }
}

void *Session::Device::LockBackBuffer (unsigned b)
{
    InitBackBuffer (b);
    return backbuffers[b].Lock ();
}

void Session::Device::UnlockBackBuffer (unsigned b)
{
    if (b >= backbuffers.size ())
        return;
    backbuffers[b].Unlock ();
}

void Session::Device::Clear (unsigned b, unsigned long rgb)
{
    InitBackBuffer (b);
    UnlockBackBuffer (b);
    if (Interface ()->ColorFill (backbuffers[b].Interface (), 0, rgb) != D3D_OK)
        throw "Could not colorfill the device's backbuffer";
}

void Session::Device::Flip ()
{
    // Flipping invalidates all backbuffers
    for (unsigned b = 0; b < backbuffers.size (); ++b)
        backbuffers[b].Release ();
    HRESULT hr = Interface ()->Present (NULL, NULL, NULL, NULL);
    switch (hr)
    {
        case D3D_OK:
        // OK!
        break;
        case D3DERR_DEVICELOST:
        throw "The fullscreen device has lost focus and may not be presented";
        break;
        case D3DERR_DRIVERINTERNALERROR:
        throw "Could not present device's backbuffer";
        break;
        case D3DERR_INVALIDCALL:
        throw "Could not present device's backbuffer";
        break;
    }
}

void Session::Device::GetRasterStatus (bool *vblank, unsigned *scanline)
{
    D3DRASTER_STATUS rs;
    if (Interface ()->GetRasterStatus (0, &rs) != D3D_OK)
        throw "Could not get raster status";
    *vblank = static_cast<bool> (rs.InVBlank != 0);
    *scanline = rs.ScanLine;
}

void Session::Device::CreateOffscreenBuffer (unsigned w, unsigned h, PixelFormat pf, OffscreenBufferHandle *handle)
{
    unsigned i;
    // First see if we can reuse a free handle
    if (!released_buffer_handles.empty ())
    {
        // Use the first one and remove it from the list
        i = *released_buffer_handles.begin ();
        size_t nremoved = released_buffer_handles.erase (i);
        assert (nremoved == 1);
        nremoved = 0; // get rid of compiler warning
    }
    else
    {
        // Grow the vector of buffers
        i = static_cast<unsigned> (offscreen_buffers.size ());
        offscreen_buffers.resize (i + 1);
    }
    IDirect3DSurface9 *si;
    if (Interface ()->CreateOffscreenPlainSurface (w, h,
        XGL2D3D (pf),
        D3DPOOL_DEFAULT, &si, 0) != D3D_OK)
        throw "Could not create offscreen surface";
    offscreen_buffers[i] = new Surface;
    offscreen_buffers[i]->Init (si);
    *handle = i;
}

void Session::Device::ReleaseOffscreenBuffer (OffscreenBufferHandle handle)
{
    if (handle >= offscreen_buffers.size ())
        return;
    if (!offscreen_buffers[handle])
        return;
    offscreen_buffers[handle]->Release ();
    delete offscreen_buffers[handle];
    offscreen_buffers[handle] = 0;
    // Put the handle back into the pool of handles
    released_buffer_handles.insert (handle).second;
}

void Session::Device::ReleaseOffscreenBuffers ()
{
    // If it has not been released, release it
    for (unsigned i = 0; i < offscreen_buffers.size (); ++i)
        if (released_buffer_handles.find (i) == released_buffer_handles.end ())
            ReleaseOffscreenBuffer (i);
    offscreen_buffers.clear ();
    released_buffer_handles.clear ();
}

void Session::Device::OffscreenBufferDimensions (OffscreenBufferHandle handle, unsigned *w, unsigned *h, PixelFormat *pf)
{
    CheckOffscreenBuffer (handle);
    offscreen_buffers[handle]->Dimensions (w, h, pf);
}

void Session::Device::ClearOffscreenBuffer (OffscreenBufferHandle handle, unsigned long rgb)
{
    CheckOffscreenBuffer (handle);
    UnlockOffscreenBuffer (handle);
    if (Interface ()->ColorFill (offscreen_buffers[handle]->Interface (), 0, rgb) != D3D_OK)
        throw "Could not colorfill the device's offscreen buffer";
}

void *Session::Device::LockOffscreenBuffer (OffscreenBufferHandle handle)
{
    CheckOffscreenBuffer (handle);
    return offscreen_buffers[handle]->Lock ();
}

void Session::Device::UnlockOffscreenBuffer (OffscreenBufferHandle handle)
{
    if (handle >= offscreen_buffers.size ())
        return;
    offscreen_buffers[handle]->Unlock ();
}

void Session::Device::Blit (OffscreenBufferHandle handle, unsigned x, unsigned y, unsigned w, unsigned h)
{
    CheckOffscreenBuffer (handle);
    UnlockOffscreenBuffer (handle);
    InitBackBuffer (0);
    UnlockBackBuffer (0);
    RECT r = { x, y, x + w, y + h };
    if (Interface ()->StretchRect (offscreen_buffers[handle]->Interface (),
        0,
        backbuffers[0].Interface (),
        &r,
        D3DTEXF_NONE) != D3D_OK)
        throw "Could not stretchrect the device's offscreen buffer";
}

void Session::Device::Blit (OffscreenBufferHandle handle)
{
    CheckOffscreenBuffer (handle);
    UnlockOffscreenBuffer (handle);
    InitBackBuffer (0);
    UnlockBackBuffer (0);
    if (Interface ()->StretchRect (offscreen_buffers[handle]->Interface (),
        0,
        backbuffers[0].Interface (),
        0,
        D3DTEXF_NONE) != D3D_OK)
        throw "Could not stretchrect the device's offscreen buffer";
}

void Session::Device::GetGamma (std::vector<unsigned short> &gamma)
{
    if (gamma.size () != 256 * 3)
        gamma.resize (256 * 3);
    D3DGAMMARAMP g;
    Interface ()->GetGammaRamp (0, &g);
    for (unsigned i = 0; i < 256; ++i)
    {
        gamma[i * 3 + 0] = g.red[i];
        gamma[i * 3 + 1] = g.green[i];
        gamma[i * 3 + 2] = g.blue[i];
    }
}

void Session::Device::SetGamma (const std::vector<unsigned short> &gamma)
{
    assert (gamma.size () == 256 * 3);
    D3DGAMMARAMP g;
    for (unsigned i = 0; i < 256; ++i)
    {
        g.red[i]   = gamma[i * 3 + 0];
        g.green[i] = gamma[i * 3 + 1];
        g.blue[i]  = gamma[i * 3 + 2];
    }
    Interface ()->SetGammaRamp (0, D3DSGR_NO_CALIBRATION, &g);
}

unsigned Session::Device::TotalFonts ()
{
    if (fonts.empty ())
    {
        InitBackBuffer (0);
        DeviceContext dc (backbuffers[0].Interface ());
        EnumFontFamilies (dc, 0, &Session::Device::EnumFontFamProc, (LPARAM) this);
        // The default is the first font
        current_font = fonts[0];
    }
    return static_cast<unsigned> (fonts.size ());
}

std::string Session::Device::FontName (unsigned font)
{
    CheckFont (font);
    return fonts[font].lfFaceName;
}

void Session::Device::SetFont (unsigned font)
{
    CheckFont (font);
    current_font = fonts[font];
    current_font.lfWidth = 0; // Determine width from height
}

void Session::Device::SetTextColor (unsigned long rgb)
{
    // In Windows, colors are specified as 0x00bbggrr.
    rgb = (rgb >> 16) + (rgb & 0x0000FF00) + ((rgb << 16) & 0x00FF0000);
    text_color.SetColor (rgb);
}

void Session::Device::SetBGColor (unsigned long rgb)
{
    // In Windows, colors are specified as 0x00bbggrr.
    rgb = (rgb >> 16) + (rgb & 0x0000FF00) + ((rgb << 16) & 0x00FF0000);
    text_color.SetBG (rgb);
}

void Session::Device::SetBGTransparency (bool on)
{
    text_color.SetTransparency (on);
}

unsigned Session::Device::GetTextHeight ()
{
    return current_font.lfHeight;
}

unsigned Session::Device::GetTextWidth (const char *string)
{
    if (!string)
        throw "Invalid string";
    const size_t N = strlen (string);
    float width = 0.0f;
    InitBackBuffer (0);
    FontCreator hf (current_font);
    DeviceContext dc (backbuffers[0].Interface ());
    HGDIOBJ hg = SelectObject (dc, hf);
    if (!hg)
        throw "Could not select the specified font";
    for (size_t i = 0; i < N; ++i)
    {
        unsigned ch = string[i];
        ABCFLOAT abc;
        int success = GetCharABCWidthsFloat (dc, ch, ch, &abc);
        if (!success)
            throw "Could not get width of specified string";
        width += abc.abcfA // white space on left
            + abc.abcfB // glyph space
            + abc.abcfC; // white space on right
    }
    // Round to the nearest int
    return static_cast<unsigned> (width + 0.5);
}

void Session::Device::SetPointSize (unsigned ps)
{
    InitBackBuffer (0);
    DeviceContext dc (backbuffers[0].Interface ());
    current_font.lfHeight = ps;
}

void Session::Device::SetEscapement (unsigned degrees)
{
    // Escapement is measured in tenths of degrees
    current_font.lfEscapement = 10 * degrees;
}

void Session::Device::SetItalic (bool on)
{
    current_font.lfItalic = on;
}

void Session::Device::SetUnderline (bool on)
{
    current_font.lfUnderline = on;
}

void Session::Device::SetStrikeOut (bool on)
{
    current_font.lfStrikeOut = on;
}

void Session::Device::Text (int x, int y, const char *t)
{
    InitBackBuffer (0);
    FontCreator hf (current_font);
    DeviceContext dc (backbuffers[0].Interface ());
    HGDIOBJ hg = SelectObject (dc, hf);
    if (!hg)
        throw "Could not select the specified font";
    text_color.Set (dc);
    if (!TextOut (dc, x, y, t, static_cast<int> (strlen (t))))
        throw "Could not write text to device";
}

void Session::Device::ShowCursor (bool flag)
{
    //Interface ()->ShowCursor (static_cast<BOOL> (flag));
    // The DirectX ShowCursor call does not work...
    ::ShowCursor (flag);
}

void Session::Device::CheckBackBuffer (unsigned i)
{
    if (i >= backbuffers.size ())
        throw "Invalid backbuffer index";
}

void Session::Device::CheckOffscreenBuffer (OffscreenBufferHandle h)
{
    if (h >= offscreen_buffers.size () ||
        released_buffer_handles.find (h) != released_buffer_handles.end ())
        throw "Invalid offscreen buffer handle";
}

void Session::Device::CheckFont (unsigned font)
{
    if (font >= fonts.size ())
        throw "Invalid font index";
}

Session::Device::Surface::Surface () :
    surface_interface (0),
    lock (0)
{
}

Session::Device::Surface::~Surface ()
{
    Release ();
}

IDirect3DSurface9 *Session::Device::Surface::Interface ()
{
    if (!surface_interface)
        throw "A surface interface for this surface has not been allocated";
    return surface_interface;
}

bool Session::Device::Surface::Initialized ()
{
    return surface_interface != 0;
}

void Session::Device::Surface::Init (IDirect3DSurface9 *si)
{
    if (!si)
        throw "Invalid surface interface";
    if (surface_interface == si) // already inited
        return;
    Release ();
    surface_interface = si;
}

void Session::Device::Surface::Release ()
{
    if (!surface_interface) // not inited
        return;
    Unlock ();
    surface_interface->Release ();
    surface_interface = 0;
}

void *Session::Device::Surface::Lock ()
{
    if (!surface_interface)
        throw "The surface has not been initialized";
    if (lock) // already locked
        return lock;
    D3DLOCKED_RECT lr;
    if (surface_interface->LockRect (&lr, 0, 0) != D3D_OK)
        throw "Could not lock device's surface";
    lock = lr.pBits;
    return lock;
}

void Session::Device::Surface::Unlock ()
{
    if (!lock)
        return;
    surface_interface->UnlockRect ();
    lock = 0;
}

void Session::Device::Surface::Dimensions (unsigned *w, unsigned *h, PixelFormat *pf)
{
    if (!surface_interface)
        throw "The surface has not been initialized";
    D3DSURFACE_DESC d;
    if (surface_interface->GetDesc (&d) != D3D_OK)
        throw "Could not get the surface descriptor for the specified surface";
    *w = d.Width;
    *h = d.Height;
    *pf =  D3D2XGL (d.Format);
}

Session::Device::DeviceContext::DeviceContext (IDirect3DSurface9 *i) :
    surface_interface (i)
{
    if (surface_interface->GetDC (&dc) != D3D_OK)
        throw "Could not get device context for the specified device";
}

Session::Device::DeviceContext::~DeviceContext ()
{
    surface_interface->ReleaseDC (dc);
}

Session::Device::DeviceContext::operator HDC ()
{
    return dc;
}

Session::Device::FontCreator::FontCreator (const LOGFONT &font)
{
    hf = CreateFontIndirect (&font);
    if (!hf)
        throw "Could not create the specified font";
}

Session::Device::FontCreator::~FontCreator ()
{
    DeleteObject (hf);
}

Session::Device::FontCreator::operator HFONT ()
{
    return hf;
}

Session::Device::TextColor::TextColor () :
    foreground (MakeRGB8 (0, 0, 0)),
    background (MakeRGB8 (255,255,255)),
    transparent (false),
    dirty (true)
{
}

void Session::Device::TextColor::Set (HDC dc)
{
    if (dirty)
    {
        if (::SetTextColor (dc, foreground) == CLR_INVALID)
            throw "Could not set text color";
        if (::SetBkColor (dc, background) == CLR_INVALID)
            throw "Could not set background color";
        if (!::SetBkMode (dc, transparent ? TRANSPARENT : OPAQUE))
            throw "Could not set background transparency";
    }
}

void Session::Device::TextColor::SetColor (unsigned long rgb)
{
    dirty = true;
    foreground = rgb;
}

void Session::Device::TextColor::SetBG (unsigned long rgb)
{
    dirty = true;
    background = rgb;
}

void Session::Device::TextColor::SetTransparency (bool on)
{
    dirty = true;
    transparent = on;
}

#else

// Linux

Session::Session ()
{
}

Session::~Session ()
{
    Release ();
}

void Session::Init ()
{
    back_buffer_mode.width = 1024;
    back_buffer_mode.height = 768;
    back_buffer_mode.freq = 60;
    back_buffer_mode.pf = PF_X8R8G8B8;
}

void Session::Release ()
{
}

unsigned Session::TotalDevices ()
{
    return 1;
}

std::string Session::GetDeviceInfo (unsigned d)
{
    CheckDeviceNumber (d);
    std::string s ("Linux text device");
    return s;
}

void Session::GetScreenRect (unsigned d, unsigned *x, unsigned *y, unsigned *w, unsigned *h)
{
    CheckDeviceNumber (d);
    *x = 0;
    *y = 0;
    *w = back_buffer_mode.width;
    *h = back_buffer_mode.height;
}

unsigned Session::TotalModes (unsigned d, PixelFormat pf)
{
    CheckDeviceNumber (d);
    return 1;
}

bool Session::HardwareConversion (unsigned d, PixelFormat src, PixelFormat dest)
{
    CheckDeviceNumber (d);
    if (dest == PF_X8R8G8B8)
    {
        if (src == PF_X8R8G8B8)
            return true;
        if (src == PF_L8)
            return true;
    }
    return false;
}

void Session::GetMode (unsigned d, PixelFormat pf, unsigned m, DisplayMode *dm)
{
    CheckDeviceNumber (d);
    if (m != 0)
        throw "Invalid mode number";
    dm->width = back_buffer_mode.width;
    dm->height = back_buffer_mode.height;
    dm->freq = back_buffer_mode.freq;
    dm->pf = back_buffer_mode.pf;
}

void Session::GetCurrentMode (unsigned d, DisplayMode *dm)
{
    CheckDeviceNumber (d);
    dm->width = back_buffer_mode.width;
    dm->height = back_buffer_mode.height;
    dm->freq = back_buffer_mode.freq;
    dm->pf = back_buffer_mode.pf;
}

void Session::InitDevice (unsigned d, const DisplayMode &dm, unsigned backbuffers)
{
    CheckDeviceNumber (d);
    back_buffer_mode = dm;
}

void Session::ReleaseDevice (unsigned d)
{
}

void Session::Clear (unsigned d, unsigned backbuffer, unsigned long rgb)
{
    CheckDeviceNumber (d);
}

void Session::Flip (unsigned d)
{
    CheckDeviceNumber (d);
}

void Session::GetRasterStatus (unsigned d, bool *vblank, unsigned *scanline)
{
    CheckDeviceNumber (d);
    *vblank = true;
    *scanline = 0;
}

void *Session::LockBackBuffer (unsigned d, unsigned backbuffer)
{
    CheckDeviceNumber (d);
    back_buffer.resize (back_buffer_mode.width * back_buffer_mode.height * 4);
    return &back_buffer[0];
}

void Session::UnlockBackBuffer (unsigned d, unsigned backbuffer)
{
    CheckDeviceNumber (d);
}

void Session::CreateOffscreenBuffer (unsigned d, unsigned w, unsigned h, PixelFormat pf, OffscreenBufferHandle *handle)
{
    CheckDeviceNumber (d);
    offscreen_buffer_mode.width = w;
    offscreen_buffer_mode.height = h;
    offscreen_buffer_mode.pf = pf;
    offscreen_buffer.resize (offscreen_buffer_mode.width * offscreen_buffer_mode.height * 4);
}

void Session::ReleaseOffscreenBuffer (unsigned d, OffscreenBufferHandle handle)
{
    CheckDeviceNumber (d);
}

void Session::OffscreenBufferDimensions (unsigned d, OffscreenBufferHandle handle, unsigned *w, unsigned *h, PixelFormat *pf)
{
    CheckDeviceNumber (d);
    *w = offscreen_buffer_mode.width;
    *h = offscreen_buffer_mode.height;
    *pf = offscreen_buffer_mode.pf;
}

void Session::ReleaseOffscreenBuffers (unsigned d)
{
    CheckDeviceNumber (d);
}

void Session::ClearOffscreenBuffer (unsigned d, OffscreenBufferHandle handle, unsigned long rgb)
{
    CheckDeviceNumber (d);
}

void *Session::LockOffscreenBuffer (unsigned d, OffscreenBufferHandle handle)
{
    CheckDeviceNumber (d);
    return &offscreen_buffer[0];
}

void Session::UnlockOffscreenBuffer (unsigned d, OffscreenBufferHandle handle)
{
    CheckDeviceNumber (d);
}

void Session::Blit (unsigned d, OffscreenBufferHandle handle, unsigned dest_x, unsigned dest_y, unsigned dest_width, unsigned dest_height)
{
    CheckDeviceNumber (d);
}

void Session::Blit (unsigned d, OffscreenBufferHandle handle)
{
    CheckDeviceNumber (d);
}

void Session::GetGamma (unsigned d, std::vector<unsigned short> &gamma)
{
    CheckDeviceNumber (d);
}

void Session::SetGamma (unsigned d, const std::vector <unsigned short> &gamma)
{
    CheckDeviceNumber (d);
}

unsigned Session::TotalFonts (unsigned d)
{
    CheckDeviceNumber (d);
    return 1;
}

std::string Session::FontName (unsigned d, unsigned font)
{
    CheckDeviceNumber (d);
    return std::string ("Arial");
}

void Session::SetFont (unsigned d, unsigned font)
{
    CheckDeviceNumber (d);
}

void Session::SetTextColor (unsigned d, unsigned long rgb)
{
    CheckDeviceNumber (d);
}

void Session::SetBGColor (unsigned d, unsigned long rgb)
{
    CheckDeviceNumber (d);
}

void Session::SetBGTransparency (unsigned d, bool on)
{
    CheckDeviceNumber (d);
}

unsigned Session::GetTextHeight (unsigned d)
{
    CheckDeviceNumber (d);
    return 1;
}

unsigned Session::GetTextWidth (unsigned d, const char *string)
{
    CheckDeviceNumber (d);
    return 1;
}

void Session::SetPointSize (unsigned d, unsigned ps)
{
    CheckDeviceNumber (d);
}

void Session::SetEscapement (unsigned d, unsigned degrees)
{
    CheckDeviceNumber (d);
}

void Session::SetItalic (unsigned d, bool on)
{
    CheckDeviceNumber (d);
}

void Session::SetUnderline (unsigned d, bool on)
{
    CheckDeviceNumber (d);
}

void Session::SetStrikeOut (unsigned d, bool on)
{
    CheckDeviceNumber (d);
}

void Session::Text (unsigned d, int x, int y, const char *t)
{
    CheckDeviceNumber (d);
}

void Session::ShowCursor (unsigned d, bool flag)
{
    CheckDeviceNumber (d);
}

void Session::CheckDeviceNumber (unsigned d)
{
    if (d >= TotalDevices ())
        throw "Invalid device number";
}

#endif // ifdef _WIN32

} // namespace XGL
