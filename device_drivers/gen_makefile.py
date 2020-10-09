#!/usr/bin/python

# @file gen_makefile.py
#
#     Python function to auto generate files used to build kernel modules
#
#     @author Trevor Vannoy
#     @date 2020
#     @copyright 2020 Audio Logic
#
#     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
#     INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
#     PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
#     FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#     ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#     Trevor Vannoy
#     Audio Logic
#     985 Technology Blvd
#     Bozeman, MT 59718
#     openspeech@flatearthinc.com

import argparse

def create_kbuild(path, model_name):
    """Create Kbuild file for kernel module compilation.

    This creates a minimal Kbuild file so we can build our 
    autogenerated kernel modules. Our kernel modules rely on 
    a separate header file that defines fixed-point/string 
    conversion functions, so we include that directory in the 
    include search path. This function writes the Kbuild file to
    the kernel module directory.

    Inputs:
        path = path, including trailing slash, to the kernel module location
        model_name = name of the kernel module source file (without file extension)
    """
    # by convention, all of our repositories get cloned into the same 
    # root folder; this relative paths reflect that setup, so as long
    # the convention is followed, this path will work
    INCLUDE_PATH = '../../../../../component_library/include'

    output = 'ccflags-y := -I$(src)/' + INCLUDE_PATH + '\n'
    output += 'obj-m := ' + model_name + '.o\n'

    with open(path + 'Kbuild', 'w') as outfile:
        outfile.write(output)


def create_makefile(path):
    """Create Makefile for kernel module compilation.

    This function writes the Makefile to the kernel module directory.

    Inputs:
        path = path, including trailing slash, to the kernel module location
    """
    # by convention, all of our repositories get cloned into the same 
    # root folder; this relative paths reflect that setup, so as long
    # the convention is followed, this path will work
    KERNEL_SOURCE_PATH = '~/linux-socfpga'

    output = 'KDIR ?= ' + KERNEL_SOURCE_PATH + '\n'
    output += 'default:\n'
    output += '\t$(MAKE) -C $(KDIR) ARCH=arm M=$(CURDIR) CROSS_COMPILE=arm-linux-gnueabihf-\n'
    output += 'clean:\n'
    output += '\t$(MAKE) -C $(KDIR) ARCH=arm M=$(CURDIR) clean\n'
    output += 'help:\n'
    output += '\t$(MAKE) -C $(KDIR) ARCH=arm M=$(CURDIR) help\n'

    with open(path + 'Makefile', 'w') as outfile:
        outfile.write(output)


def parseargs():
    """Parse commandline input arguments."""
    parser = argparse.ArgumentParser(description=\
        "Generate files used for building kernel modules.")
    parser.add_argument('path',
        help="path where kernel module lives; must contain trailing slash for your operating system!")
    parser.add_argument('model_name',
        help="name of kernel module; e.g. <model_name>.c")
    args = parser.parse_args()
    return (args.path, args.model_name)


# NOTE: path MUST contain a trailing slash so this code can be platform independent
def main(path, model_name):
    """Run the program and build files needed for building a kernel module.

    Inputs:
        path = path, including trailing slash, to the kernel module location
        model_name = name of the kernel module source file (without file extension)
    """
    create_kbuild(path, model_name)
    create_makefile(path)


if __name__ == '__main__':
    (path, model_name) = parseargs()
    main(path, model_name)