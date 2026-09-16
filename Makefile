.PHONY: all build clean install

all: build install

build:
	chmod +x build.sh
	./build.sh

clean:
	rm -rf build

install:
	echo "Installed via build.sh"
