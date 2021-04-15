all : mod64.dll mod32.dll

mod64.dll : mod.c
	x86_64-w64-mingw32-gcc -shared -o $@ $<

mod32.dll : mod.c
	i686-w64-mingw32-gcc -shared -o $@ $<

clean:
	-rm *.dll
