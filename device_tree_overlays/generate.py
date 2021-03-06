import argparse
import pathlib

from dtogen.parser import parse
from dtogen.node import FpgaRegionNode, DeviceTreeRootNode


def generate_device_tree_overlay(sopcinfo_file, rbf_file, output_dir="", dts=None):
    """Run the device tree generation process.

    Parameters
    ----------
    sopcinfo_file : str
        Filepath to sopcinfo file
    rbf_file : str
        Filename of Raw Binary file
    output_dir : str, optional
        Path to output directory, by default ""
    """
    sopcinfo_file = sopcinfo_file.replace("\\\\", "\\")
    output_dir = pathlib.Path(output_dir)
    if rbf_file is not None:
        rbf_file = str(pathlib.Path(rbf_file).with_suffix(".rbf"))
    if dts is None:
        dts_file = pathlib.Path(rbf_file).with_suffix(".dts")
    else:
        dts_file = pathlib.Path(dts).with_suffix(".dts")

    nodes = parse(sopcinfo_file)
    fpga_region_node = FpgaRegionNode(
        "base_fpga_region", rbf_file, "base_fpga_region", nodes)
    dtroot = DeviceTreeRootNode([fpga_region_node])

    with open(str(output_dir.joinpath(dts_file)), "w") as out_file:
        out_file.write(str(dtroot))


def parseargs():
    """Parse command line arguments for device tree overlay generator.

    Returns
    -------
    Tuple of str
        Tuple containing sopcinfo filepath, rbf filename, and output directory
    """
    arg_parser = argparse.ArgumentParser(
        description="Generates a device tree overlay file")
    arg_parser.add_argument(
        '-s', '--sopcinfo', help="Path to sopcinfo file containing description of Platform Designer system")
    arg_parser.add_argument('-r', '--rbf', default=None, required=False,
                            help="Name of programming file for the fpga")
    arg_parser.add_argument('-d', '--dts', default=None, required=False,
                            help="Name of Device Tree Source file that will be generated")
    arg_parser.add_argument('-o', '--output-dir', default="",
                            required=False, help="Output directory for the dts file")
    args = arg_parser.parse_args()
    return (args.sopcinfo, args.rbf, args.output_dir, args.dts)


if __name__ == "__main__":
    generate_device_tree_overlay(*parseargs())
