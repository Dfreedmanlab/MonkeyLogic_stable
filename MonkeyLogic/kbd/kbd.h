// Keyboard Control
//
// Copyright (C) 2006
// Center for Perceptual Systems
// University of Texas at Austin
//
// jsp Sun Oct 27 21:38:49 CST 2002
// jsp Fri Jun 16 16:09:16 CDT 2006

#ifndef KBD_H
#define KBD_H

#include <cassert>
#include <iostream>
#include <stdexcept>

#ifdef _WIN32
#define DIRECTINPUT_VERSION 0x0700
#include <dinput.h>
#endif

namespace KBD
{

#ifdef _WIN32

#define KBD_ESC_KEY 1
#define KBD_KEYPAD_ENTER_KEY 156
#define KBD_KEYPAD_ENTER_KEY_EXT 28 // External USB Keypad

class KBD
{
    public:
    KBD () :
        init (false),
        di (0),
        kbd (0)
    {
    }
    ~KBD ()
    {
        Release ();
    }
    void Init ()
    {
        // Free everything, if needed
        Release ();

        // Setup DirectInput to allow us to talk directly to the
        // keyboard drivers.  This does not prevent other applications
        // from getting data from the keyboard, but it does allow us
        // to get keyboard input regardless of which application has
        // focus.
        HINSTANCE instance = GetModuleHandle (0);
        if (DirectInputCreate (instance, DIRECTINPUT_VERSION, &di, 0) != DI_OK)
            throw std::runtime_error ("Could not initialize DirectInput");

        if (di->CreateDevice (GUID_SysKeyboard, &kbd, NULL) != DI_OK)
            throw std::runtime_error ("Could not create keyboard device");

        // Set the data format to "keyboard format"
        if (kbd->SetDataFormat (&c_dfDIKeyboard) != DI_OK)
            throw std::runtime_error ("Could not set keyboard data format");

        // Get all keys from any application instance
        kbd->SetCooperativeLevel (0, DISCL_EXCLUSIVE | DISCL_BACKGROUND);

        // Setup DirectInput to do buffered input.
        DIPROPDWORD dipdw;
        dipdw.diph.dwSize = sizeof(DIPROPDWORD);
        dipdw.diph.dwHeaderSize = sizeof(DIPROPHEADER);
        dipdw.diph.dwObj = 0;
        dipdw.diph.dwHow = DIPH_DEVICE;
        const unsigned BUFFER_SIZE = 256;
        dipdw.dwData = BUFFER_SIZE;

        kbd->SetProperty (DIPROP_BUFFERSIZE, &dipdw.diph);

        init = true;
    }
    void Release ()
    {
        if (init)
        {
            // Release keyboard
            if (kbd)
            {
                kbd->Unacquire ();
                kbd->Release ();
                kbd = 0;
            }
            // Release DirectInput
            if (di)
            {
                di->Release ();
                di = 0;
            }

            init = false;
        }
    }
    int GetKey ()
    {
        if (!init)
            throw std::runtime_error ("The library has not been initialized");

        assert (di);
        assert (kbd);

        HRESULT hr;
        DIDEVICEOBJECTDATA data[1];
        DWORD elements;

        elements = 1;

        if (kbd->GetDeviceData (sizeof (DIDEVICEOBJECTDATA), data, &elements, 0) != DI_OK)
        {
            // Make sure we have aquired the keyboard.
            hr = kbd->Acquire ();

            if (hr != DI_OK && hr != S_FALSE)
                throw std::runtime_error ("Could not acquire keyboard");

            if (kbd->GetDeviceData (sizeof (DIDEVICEOBJECTDATA), data, &elements, 0) != DI_OK)
                throw std::runtime_error ("Could not get keyboard device data");
        }

        int key;

        // If no key is in the buffer...
        if (elements == 0)
            key = -1;
        // If there is a key, but it was a key release (not a key down), don't count it.
        else if (!(data[0].dwData & 0x80))
            key = -1;
        // Get the key from the buffer
        else
            key = data[0].dwOfs;

        return key;
    }
    void Flush ()
    {
        if (!init)
            throw std::runtime_error ("The library has not been initialized");

        assert (di);
        assert (kbd);

        DWORD elements = INFINITE;
        HRESULT hr = kbd->GetDeviceData (sizeof (DIDEVICEOBJECTDATA), NULL, &elements, 0);

        if (hr != DI_OK && hr != DI_BUFFEROVERFLOW)
        {
            // Make sure we have aquired the keyboard.
            hr = kbd->Acquire ();

            if (hr != DI_OK && hr != S_FALSE)
                throw std::runtime_error ("Could not acquire keyboard");

            hr = kbd->GetDeviceData (sizeof (DIDEVICEOBJECTDATA), NULL, &elements, 0);

            if (hr != DI_OK && hr != DI_BUFFEROVERFLOW)
                throw std::runtime_error ("Could not get keyboard device data");
        }
    }

    private:
    bool init;
    LPDIRECTINPUT di;
    LPDIRECTINPUTDEVICE kbd;
};

#else

#ifdef __linux__

#define KBD_ESC_KEY 27
#define KBD_KEYPAD_ENTER_KEY 10
#define KBD_KEYPAD_ENTER_KEY_EXT KBD_KEYPAD_ENTER_KEY

#include "tty.h"

class KBD
{
    public:
    KBD () { }
    ~KBD () { }
    void Init () { }
    void Release () { }
    int GetKey ()
    {
        if (tty.KBHit ())
        {
            int c = fgetc (stdin);
            fflush (stdin);
            return c;
        }
        return -1;
    }
    void Flush ()
    {
        fflush (stdin);
    }
    private:
    jsp::TTY tty;
};

#else

#error ("Unknown OS");

#endif // __linux__

#endif // _win32

} // namespace KBD

#endif // KBD_H
