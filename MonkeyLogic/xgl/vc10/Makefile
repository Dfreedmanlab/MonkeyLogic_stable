# X Graphics Library
#
# Copyright (C) 2006
# Center for Perceptual Systems
# University of Texas at Austin
#
# jsp Tue Aug  1 17:58:05 CDT 2006

PROJECT=vc8.sln

.PHONY: build clean check

build:
	devenv $(PROJECT) /build debug
	devenv $(PROJECT) /build release
	# Run matlab in batch mode
	cd .. && matlab -nojvm -nosplash -r "build;exit;"

clean:
	devenv $(PROJECT) /clean debug
	devenv $(PROJECT) /clean release
	rm -Rf debug release test_xgl/Debug test_xgl/Release

check:
	# These tests can take a long time...
	./debug/test_xgl.exe
	./release/test_xgl.exe
	# Run matlab in batch mode
	# Disable buffered output before calling the test code
	cd .. && matlab -nojvm -nosplash -r "system_dependent(7);xgltest;exit;"
