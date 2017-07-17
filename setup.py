#!/usr/bin/env python3

from Cython.Distutils import build_ext
from setuptools import setup, Extension
import subprocess
import numpy


VERSION = "0.0.1"


def has_package(package_name):
    return subprocess.call(["pkg-config", "--exists", package_name]) == 0


# Base method to find library include files in system
def locate_includes(package_name):
    proc = subprocess.Popen(["pkg-config", "--cflags-only-I", package_name],
                            stdout=subprocess.PIPE)
    if proc.wait() == 0:
        buf = proc.stdout.read().decode("utf8")
        return buf[2:].rstrip()
    else:
        raise RuntimeError("Looking for package error: %s" % package_name)


def locate_library(package_name):
    proc = subprocess.Popen(["pkg-config", "--libs-only-L", package_name],
                            stdout=subprocess.PIPE)
    if proc.wait() == 0:
        buf = proc.stdout.read().decode("utf8")
        return buf[2:].rstrip()
    else:
        raise RuntimeError("Looking for package error: %s" % package_name)


setup(
    name="tesseract",
    version=VERSION,
    author="Cerberus",
    author_email="cerberus@flux3dp.com",
    description="...",
    long_description="...",
    keywords=["tesseract"],
    license="AGPLv3",
    platforms=['Linux', 'Mac OSX'],
    url="https://github.com/yagami-cerberus/tesseract-python",
    classifiers=[
        'Programming Language :: C',
        'Programming Language :: C++',
        'Programming Language :: Cython',
        'Programming Language :: Python :: 3 :: Only',
        'Topic :: Software Development :: Libraries :: Python Modules'
    ],
    include_package_data=True,
    packages=[],
    # test_suite="tests.main.everything",
    install_requires=['setuptools'],
    setup_requires=['pytest-runner'],
    tests_require=['pytest'],
    cmdclass={'build_ext': build_ext},
    ext_modules=[
        Extension(
            'tesseract',
            sources=[
                "src/tesseract.pyx"
            ],
            language="c++",
            libraries=["tesseract"],
            library_dirs=[locate_library("tesseract")],
            include_dirs=[numpy.get_include(),
                          locate_includes("tesseract")],
            extra_compile_args=["-DPACKAGE_VER=\"" + VERSION + "\""])

    ],
)
