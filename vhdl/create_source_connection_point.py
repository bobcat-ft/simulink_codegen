def create_source_connection_point(input_struct):
    if not input_struct.has_source_signal:
        return ""
    built_string = "# # # # # # # # # # # # # # # # # # # # # # #\n"
    built_string += "# Created in create_source_connection_point\n"
    built_string += "# # # # # # # # # # # # # # # # # # # # # # #\n\n"
    ssname = input_struct.source_signal_name
    built_string += "add_interface " + ssname + " avalon_streaming start\n"
    built_string += "set_interface_property " + ssname + " associatedClock clock\n"
    built_string += "set_interface_property " + ssname + " associatedReset reset\n"
    built_string += "set_interface_property " + ssname + " dataBitsPerSymbol " + str(input_struct.data_bus_size) + "\n"
    built_string += "set_interface_property " + ssname + " errorDescriptor \"\"\n"
    built_string += "set_interface_property " + ssname + " firstSymbolInHighOrderBits true\n"
    built_string += "set_interface_property " + ssname + " maxChannel " + str(input_struct.source_max_channel) + "\n"
    built_string += "set_interface_property " + ssname + " readyLatency 0\n"
    built_string += "set_interface_property " + ssname + " ENABLED true\n"
    built_string += "set_interface_property " + ssname + " EXPORT_OF \"\"\n"
    built_string += "set_interface_property " + ssname + " PORT_NAME_MAP \"\"\n"
    built_string += "set_interface_property " + ssname + " CMSIS_SVD_VARIABLES \"\"\n"
    built_string += "set_interface_property " + ssname + " SVD_ADDRESS_GROUP \"\"\n"

    for port_name, num_bits in input_struct.source_signal_port_names_and_widths.items():
        port_type = port_name.rpartition('_')[2]
        built_string += ("add_interface_port " + ssname + " " + port_name + " " + port_type + " Output "
                         + str(num_bits) + "\n")
    built_string += "# End create_sink_connection_point\n\n\n"
    return built_string
