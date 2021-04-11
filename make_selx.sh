kate #!/bin/bash

PYTHON_TARGET=$1

IO_DIR=/wheels
BASE_DIR=${BASE_DIR:-$IO_DIR}
PLAT=${PLAT:-manylinux2010_x86_64}
PYTHON_TARGET=${PYTHON_TARGET:-cp38-cp38}
MODULE_NAME=${MODULE_NAME:-SimpleITK-Elastix}
MAKE_THREADS=$(cat /proc/cpuinfo | grep -c processor)

PYTHON_BIN=/opt/python/$PYTHON_TARGET/bin
PYTHON_EXE=$PYTHON_BIN/python
INCLUDES=(/opt/python/$PYTHON_TARGET/include/*) # all subdirs
PYTHON_INCLUDE=${INCLUDES[0]} # get the appropriate include directory

echo ======== Using Python: $PYTHON_EXE ============
$PYTHON_EXE -V
echo ======== Platform: $PLAT ======================
ls /opt

exit 0 # debug

cd src
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
    -DWRAP_PYTHON:BOOL=ON .
make -j$MAKE_THREADS

echo ====== Successfully compiled SimpleElastix ======


# copy the setup.py script
cp SimpleITK-build/Wrapping/Python/Packaging/setup.py SimpleITK-build/Wrapping/Python/
cd SimpleITK-build/Wrapping/Python/
sed -i.bak -e "s/sitkHASH\s*=\s*[\"'][a-zA-Z0-9]*[\"']/sitkHASH = None/" -e "s/name\s*=\s*[\"']SimpleITK[\"']/name='$MODULE_NAME'/" setup.py
$PYTHON_EXE setup.py bdist_wheel
cd dist
auditwheel repair --plat manylinux2010_x86_64 *.whl
mkdir -p "$IO_DIR"
cp wheelhouse/*.whl "$IO_DIR"

echo ====== Successfully built wheel ======
ls $IO_DIR
