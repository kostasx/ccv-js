ifneq ($(notdir $(CXX)), em++)
$(error You need to install/source emscripten and run with "emmake make")
endif

CXXFLAGS = -std=c++1z \
	--bind \
	--memory-init-file 0 \
	--pre-js ccv_pre.js \
	-s EXPORTED_RUNTIME_METHODS=[\"FS_createDataFile\"] \
	-s EXPORT_NAME=\"'CCVLib'\" \
	-s MODULARIZE=1 \
	-s NO_EXIT_RUNTIME=1 \
	-s TOTAL_MEMORY=$$((2 << 29))
	# TODO: see if we need -s PRECISE_F32=1

CXXFLAGS += -O3 --llvm-lto 1 -s AGGRESSIVE_VARIABLE_ELIMINATION=1 -s OUTLINING_LIMIT=10000 # TODO --closure 1
#CXXFLAGS += -v -g4 -s ASSERTIONS=1 -s DEMANGLE_SUPPORT=1 -s SAFE_HEAP=1 -s STACK_OVERFLOW_CHECK=1 -Weverything -Wall -Wextra

CPPFLAGS = -I"./external/ccv/lib"

LDFLAGS = -L"./external/ccv/lib"

LDLIBS = -lccv


all: build/ccv.js build/ccv_without_filesystem.js 

build/ccv.js: CXXFLAGS += -s NO_FILESYSTEM=0 -s FORCE_FILESYSTEM=1
build/ccv.js: CXXFLAGS += --embed-file external/ccv/samples/face.sqlite3@/
build/ccv.js: CXXFLAGS += --embed-file external/ccv/samples/pedestrian.m@/
build/ccv.js: CXXFLAGS += --embed-file external/ccv/samples/car.m@/
build/ccv.js: CXXFLAGS += --embed-file external/ccv/samples/pedestrian.icf@/
build/ccv.js: CPPFLAGS += -DWITH_FILESYSTEM
build/ccv.js: ccv_bindings.cpp external/ccv/lib/libccv.a ccv_pre.js
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) ccv_bindings.cpp -o $@ $(LDLIBS)
	echo "CCV = CCVLib();" >> build/ccv.js
	du -h build/ccv.js

build/ccv_without_filesystem.js: CPPFLAGS += -s NO_FILESYSTEM=1
build/ccv_without_filesystem.js: ccv_bindings.cpp external/ccv/lib/libccv.a ccv_pre.js
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) ccv_bindings.cpp -o $@ $(LDLIBS)
	echo "CCV = CCVLib();" >> build/ccv_without_filesystem.js
	du -h build/ccv_without_filesystem.js

# TODO add -msse2? https://kripken.github.io/emscripten-site/docs/porting/simd.html
external/ccv/lib/libccv.a:
	git submodule update --init
	cd external/ccv/lib && emconfigure ./configure && emmake make libccv.a

.PHONY: clean
clean:
	rm -f build/*
	#cd external/ccv/lib && make clean
