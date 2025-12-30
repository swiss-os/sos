All source code is Public Domain.

## Source code is NO LONGER AVAILABLE here:

    git clone https://git.candlhat.org/xar.git

It is instead incorporated into the PDOS project at https://pdos.org

Also note that xar.exe uses tmpfile() and as such, if you use
the x64 version, you need to run as administrator.

Which is documented here:

https://sourceforge.net/p/mingw-w64/bugs/921/

Also tmpnam() has the same issue, documented here:

https://learn.microsoft.com/en-us/cpp/porting/visual-cpp-change-history-2003-2015?view=msvc-170


## Building

    BSD:
    
        Make sure you have gcc and gmake installed then run gmake -f Makefile.unix.
    
    Linux:
    
        Make sure you have gcc and make installed then run make -f Makefile.unix.
    
    macOS:
    
        Make sure you have xcode command line tools installed then run make -f Makefile.unix.
    
    Windows:
    
        Make sure you have mingw installed and the location within your PATH variable then run mingw32-make.exe -f Makefile.w32.
