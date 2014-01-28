// Keyboard Control
//
// Copyright (C) 2006
// Center for Perceptual Systems
// University of Texas at Austin
//
// jsp Fri Jun 16 16:09:16 CDT 2006

#include "kbd.h"
#include "verify.h"
#include <iostream>
#include <stdexcept>

using namespace std;

void test1 ()
{
    KBD::KBD kbd;
    kbd.Init ();
    VERIFY (kbd.GetKey () == -1);
    cout << "Press a key..." << endl;
    int ch = -1;
    while (ch == -1)
        ch = kbd.GetKey ();
    while (ch != -1)
    {
        cout << "Key code: " << ch << endl;
        ch = kbd.GetKey ();
    }
    kbd.Flush ();
    kbd.Release ();
}

int main (int argc, char *argv[])
{
    try
    {
        test1 ();

        return 0;
    }
    catch (const exception &e)
    {
        cerr << e.what () << endl;
        return -1;
    }
}
