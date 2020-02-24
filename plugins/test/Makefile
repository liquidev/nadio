CC := gcc
COMPILE_FLAGS := \
	-Wall -Werror \
	-fPIC \
	-I../../src/nadio/plugins

COMPILE := $(CC) $(COMPILE_FLAGS)

build: clean out/test.so

install: build
	cp out/test.so ~/.local/share/Nadio/plugins

clean:
	rm -rf build out
	mkdir build out

build/main.o: main.c
	$(COMPILE) -c main.c -o build/main.o

out/test.so: build/main.o
	$(CC) -shared build/main.o -o out/test.so
