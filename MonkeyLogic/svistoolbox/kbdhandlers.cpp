// kbd library handlers for Mexgen mexfile generator
//
// Copyright (C) 2003 Center for Perceptual Systems
//
// jsp Tue Aug 12 17:51:19 CDT 2003

// The following manifest constant is needed for Low Level KBD Hook
// definitions and comes from <winresrc.h>
#ifdef _WIN32
#define _WIN32_WINNT 0x0500
#include <windows.h>
#include <winuser.h>
#endif

#include "kbd.h"
#include "mex.h"
#include "version.h"

static bool g_debug = false;

#ifdef _WIN32

extern "C" {

// The one and only hook proc
HHOOK g_keyboard_hook;

LRESULT CALLBACK KBDHookProc (int code, WPARAM vkey, LPARAM param)
{
    if (g_debug)
        mexPrintf ("-kbdproc entered with code %d\n", code);

    // Code < 0 is windows telling us 'don't process this message'.
    if (code < 0)
        // NOTE: The first parameter is always ignored
        return CallNextHookEx (0, code, vkey, param);

    int alt = static_cast<int> ((param >> 29) & 1);
    int down = static_cast<int> (!((param >> 30) & 1));
    int scancode = static_cast<int> ((param >> 16) & 0xFF);

    if (g_debug)
        mexPrintf ("-kbdproc down %d alt %d scancode %d\n", down, alt, scancode);

    // If alt-F12 is pressed, release hook
    if (alt && down && (scancode == 88))
    {
        if (g_debug)
            mexPrintf ("-kbdproc release\n");
        UnhookWindowsHookEx (g_keyboard_hook);
        return 1; // Throw away the keystroke
    }

    // If this is any alt-key combination, let it pass through.
    if (alt)
    {
        if (g_debug)
            mexPrintf ("-kbdproc call next\n");
        // NOTE: The first parameter is always ignored
        return CallNextHookEx (0, code, vkey, param);
    }

    // For any non-alt keystroke, do not call next in hook chain,
    // thereby throwing it away.
    if (g_debug)
        mexPrintf ("-kbdproc ignore\n");
    return 1;
}

/*
LRESULT CALLBACK LowLevelKBDHookProc (int code, WPARAM wparam, LPARAM lparam)
{
    if (g_debug)
        mexPrintf ("-llkbdproc entered with code %d\n", code);

    // Code < 0 is windows telling us 'don't process this message'.
    if (code < 0)
        // NOTE: The first parameter is always ignored
        return CallNextHookEx (0, code, wparam, lparam);

    switch (wparam)
    {
        case WM_KEYDOWN:
        case WM_KEYUP:
        case WM_SYSKEYDOWN:
        case WM_SYSKEYUP:
        // Continue
        break;

        default:
        // Unknown: Let it pass through
        return CallNextHookEx (0, code, wparam, lparam);
    }

    PKBDLLHOOKSTRUCT p = (PKBDLLHOOKSTRUCT) lparam;

    int down = static_cast<int> (!(p->flags & LLKHF_UP));
    int alt = static_cast<int> (p->flags & LLKHF_ALTDOWN);
    int scancode = static_cast<int> (p->scanCode);

    if (g_debug)
        mexPrintf ("-llkbdproc down %d alt %d scancode %d\n", down, alt, scancode);

    // If alt-F12 is pressed, release hook
    if (alt && down && (scancode == 88))
    {
        if (g_debug)
            mexPrintf ("-llkbdproc release\n");
        UnhookWindowsHookEx (g_keyboard_hook);
        return 1; // Throw away the keystroke
    }

    // If this is any alt-key combination, let it pass through.
    if (alt)
    {
        if (g_debug)
            mexPrintf ("-llkbdproc call next\n");
        // NOTE: The first parameter is always ignored
        return CallNextHookEx (0, code, wparam, lparam);
    }

    // For any non-alt keystroke, do not call next in hook chain,
    // thereby throwing it away.
    if (g_debug)
        mexPrintf ("-llkbdproc ignore\n");
    return 1;
}
*/

} // extern "C"

#endif // _WIN32

// The one and only KBD instance
KBD::KBD g_kbd;

void kbdinit (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs > 0)
        g_debug = static_cast<bool> (*mxGetPr (prhs[0]) != 0.0);
    else
        g_debug = false;

    if (g_debug)
    {
        mexPrintf ("-kbdinit\n");
        mexPrintf ("KBD library, version %d.%d\n", MAJOR_VERSION, MINOR_VERSION);
        mexPrintf ("Copyright (C) 2003-2006\n");
        mexPrintf ("Center for Perceptual Systems\n");
        mexPrintf ("University of Texas at Austin\n");
    }

    try
    {
        g_kbd.Init ();

        // Release hook proc
        if (g_keyboard_hook)
        {
            UnhookWindowsHookEx (g_keyboard_hook);

            if (g_debug)
                mexPrintf ("-kbd Unhook\n");
        }

        HMODULE hmodule = GetModuleHandle ("kbdmex.mexw32");

        // Set a keyboard hook
        g_keyboard_hook = SetWindowsHookEx (WH_KEYBOARD, KBDHookProc, hmodule, 0);
        // Calling the LowLevel Hook messes up the Matlab command line
        //g_keyboard_hook = SetWindowsHookEx (WH_KEYBOARD_LL, LowLevelKBDHookProc, hmodule, 0);

        if (g_debug)
            mexPrintf ("-kbd Sethook\n");

        if (!g_keyboard_hook)
            throw std::runtime_error ("Could not install hook procedure");
    }
    catch (std::exception &e)
    {
        mexErrMsgTxt (e.what ());
    }
}

void kbdrelease (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (g_debug)
        mexPrintf ("-kbdrelease\n");

    try
    {
        // Release hook proc
        UnhookWindowsHookEx (g_keyboard_hook);
        g_keyboard_hook = 0;

        g_kbd.Release ();
    }
    catch (std::exception &e)
    {
        mexErrMsgTxt (e.what ());
    }
}

void kbdflush (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (g_debug)
        mexPrintf ("-kbdflush\n");

    try
    {
        g_kbd.Flush ();
    }
    catch (std::exception &e)
    {
        mexErrMsgTxt (e.what ());
    }
}

void kbdgetkey (int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int key;

    try
    {
        key = g_kbd.GetKey ();
    }
    catch (std::exception &e)
    {
        mexErrMsgTxt (e.what ());
    }

    if (key != -1)
    {
        // Create a scalar and put the key in it
        const int dims[2] = { 1, 1 };
        plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
        double *destr = mxGetPr (plhs[0]);
        destr[0] = key;

        if (g_debug)
            mexPrintf ("-kbdgetkey %d\n", key);
    }
    else
    {
        // Create an empty scalar
        const int dims[2] = { 0, 0 };
        plhs[0] = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL);
    }
}
