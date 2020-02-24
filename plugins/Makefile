# Linux-specific makefile, this might be ported over to Windows at some point.

NIM := nim c --app:lib

build-all: _out/test.so

clean:
	rm -rf _out

install: build-all
	cp _out/* ~/.local/share/Nadio/plugins

_out:
	mkdir _out

_out/test.so: _out test/test.nim
	$(NIM) -o:_out/test.so test/test.nim
