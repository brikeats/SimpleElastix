#!/bin/bash

# run this with 
# docker run --rm -e PLAT=manylinux2010_x86_64 -v /home/user/local_dir:/io quay.io/pypa/manylinux2010_x86_64 /io/make_selx.sh

IO_DIR=${IO_DIR:-/io}
BASE_DIR=${BASE_DIR:-$IO_DIR}
PLAT=${PLAT:-manylinux2010_x86_64}
PYTHON_TARGET=${PYTHON_TARGET:-cp38-cp38}
MODULE_NAME=${MODULE_NAME:-SimpleITK-Elastix}
MAKE_THREADS=${MAKE_THREADS:-4}

PYTHON_BIN=/opt/python/$PYTHON_TARGET/bin
PYTHON_EXE=$PYTHON_BIN/python
INCLUDES=(/opt/python/$PYTHON_TARGET/include/*) # all subdirs
PYTHON_INCLUDE=${INCLUDES[0]} # get the appropriate include directory

mkdir -p "$BASE_DIR"
cd $BASE_DIR
git clone https://github.com/SuperElastix/SimpleElastix.git
cd SimpleElastix
git pull
rm -rf build
mkdir build
cd build
cmake ../SuperBuild
cmake -DBUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_TESTING:BOOL=OFF \
    -DWRAP_CSHARP:BOOL=OFF \
    -DWRAP_JAVA:BOOL=OFF \
    -DWRAP_LUA:BOOL=OFF \
    -DWRAP_R:BOOL=OFF \
    -DWRAP_RUBY:BOOL=OFF \
    -DWRAP_TCL:BOOL=OFF \
    -DWRAP_PYTHON:BOOL=ON \
    -DPYTHON_EXECUTABLE:STRING=$PYTHON_EXE \
    -DPYTHON_INCLUDE_DIR:STRING=$PYTHON_INCLUDE .
    
make -j$MAKE_THREADS

# copy the setup.py script
cp SimpleITK-build/Wrapping/Python/Packaging/setup.py SimpleITK-build/Wrapping/Python/
cd SimpleITK-build/Wrapping/Python/
sed -i.bak -e "s/sitkHASH\s*=\s*[\"'][a-zA-Z0-9]*[\"']/sitkHASH = None/" -e "s/name\s*=\s*[\"']SimpleITK[\"']/name='$MODULE_NAME'/" setup.py
$PYTHON_EXE setup.py bdist_wheel
cd dist
auditwheel repair --plat $PLAT *.whl
mkdir -p "$IO_DIR"
cp wheelhouse/*.whl "$IO_DIR"
