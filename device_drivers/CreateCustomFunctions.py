def CreateCustomFunctions(inputParams):
    functionString =  "/*********************************************\n"
    functionString += "Generated by CreateCustomFunctions\n"
    functionString += "**********************************************/\n"
    if inputParams.needsVolumeTable:
        file = open("FindVolumeLevelTable", "r")
        functionString += file.read()
    elif inputParams.device_type != 2:  #FPGAS don't need find_volume?
        file = open("FindVolumeLevelNoTable", "r")
        functionString += file.read()
    functionString += "/* End CreateCustomFunctions */\n\n\n"
    return functionString