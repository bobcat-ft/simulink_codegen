% vgen_process_simulink_model
%
% This script parses the simulink model and extracts the interface signals
% and puts this information in a JSON file.

% Copyright 2019 Audio Logic
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
% INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
% PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
% FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
% Ross K. Snider, Trevor Vannoy
% Audio Logic
% 985 Technology Blvd
% Bozeman, MT 59718
% openspeech@flatearthinc.com


%% Parse the Simulink Model (currently opened model)
% We parse the model to get the Avalon signals and control registers we need for the Avalon vhdl wrapper
disp(['vgen: Parsing Simulink model: ' mp.modelName '. Please wait until you see the message "vgen: Finished."'])
try
    % turn off fast sim so that the model runs at the system clock rate
    mp.fastsim_flag = 0;
    % turn off the simulation prompts and the stop callbacks when running HDL workflow (otherwise this runs at each HDL workflow step)
    mp.sim_prompts = 0;   
catch ME
    % Terminate the compile mode if an error occurs while the model
    % has been placed in compile mode. Otherwise the model will be frozen
    % and you can't quit Matlab
    cmd = [bdroot,'([],[],[],''term'');'];
    eval(cmd)

    disp('***************************************************************************');
    disp('Error occurred in function vgen_get_simulink_block_interfaces(mp)');
    disp(['line number: ' num2str(ME.stack(1).line)])
    disp(ME.message)
    disp('***************************************************************************');

    % reset fast simulation flag so running the model simulation isn't so slow after generating code. 
    mp.fastsim_flag = 1;

    % turn simulation prompts and callbacks back on for normal simulation.
    mp.sim_prompts = 1;
end

%% Generate the Simulink model VHDL code

% run the hdl coder
hdlworkflow

% this is where hdlworkflow puts the vhdl files
hdlpath = [mp.modelPath filesep 'hdlsrc' filesep mp.modelAbbreviation];

if ispc
    python = "python "
else 
    python = "python3 "

%% Generate the Avalon VHDL wrapper for the VHDL code generated by the HDL Coder
disp('vgen: Creating Avalon VDHL wrapper.')
config_filepath = [mp.modelPath filesep 'model.json'];
config_file = ['model.json'];
outfile = [hdlpath filesep mp.modelName '_avalon.vhd'];
system(python + mp.ipcore_codegen_path + filesep + "vgenAvalonWrapper.py -c " + config_filepath + " -o " + outfile);
disp(['      created vhdl file: ' outfile])

%% Generate the .tcl script to be used by Platform Designer in Quartus
disp('vgen: Creating .tcl script for Platform Designer.')
% NOTE: platform designer only adds components if they have the _hw.tcl suffix
outfile = [hdlpath filesep mp.modelName '_avalon_hw.tcl'];
disp(['file ' config_file ' out ' outfile ' path ' hdlpath])
disp(python + mp.ipcore_codegen_path + filesep + "create_hw_tcl.py -c " + config_file + " -w " + hdlpath + " -o " + outfile )
system(python + mp.ipcore_codegen_path + filesep + "create_hw_tcl.py -c " + config_file + " -w " + hdlpath + " -o " + outfile );
disp(['      created tcl file: ' outfile])

disp('vgen: Executing Quartus workflow')
if ispc; second_cmd = "&"; else; second_cmd = ";"; end
working_dir = hdlpath + "/quartus/";

quartus_workflow_cmd = python + mp.codegen_path + "/autogen_quartus.py -j " + config_file ...
    + " -w " + working_dir + " -l " + second_cmd + " exit &";
disp(quartus_workflow_cmd + "wtf")
system(quartus_workflow_cmd);

% Stream the Quartus workflow log and display it to the user
fid = fopen("autogen_quartus.log");
if fid>0
    while 1
        % read the current line
        where = ftell(fid);
        line = fgetl(fid);
        % Print file until exit is encountered
        if line == -1
            pause(20/1000)
            fseek(fid, where, 'bof');
        elseif line == "exit"
            break
        else
            disp(line)
        end
    end
    fclose(fid);
end

disp('Executed Quartus workflow')

%% Generate the device driver code
disp('Creating device driver.')
outfile = [hdlpath filesep mp.modelName '.c'];
device_driver_cmd = python + mp.codegen_path + "/autogen_device_driver.py -c " + config_filepath ...
    + " -w " + hdlpath ;
system(device_driver_cmd);
disp(['      created device driver: ' outfile])

%% Generate kernel module build files
disp('Creating Makefile and Kbuild.')
system(python + mp.driver_codegen_path + filesep + "gen_makefile.py " + [hdlpath filesep] + " " + mp.modelName);
disp(['      created Makefile: ' [hdlpath filesep 'Makefile']])
disp(['      created Kbuild: ' [hdlpath filesep 'Kbuild']])

%% Build kernel module
disp('Building kernel module.')
cd(hdlpath)
if ispc
    if system('wsl.exe cd') == 0 
        !wsl.exe make clean
        !wsl.exe make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
    else
        disp("Windows Subsystem for Linux is currently required to automate building kernel modules")
    end
elseif isunix
    !make clean
    !make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
else
    disp('The current operating system is unsupported for automatically building kernel modules')
end

% TODO: this file now generates C code, but "vgen" make it seem like it is just VHDL still. This should be changed, and the repository should be reorganized a bit. 
%% Build Device Tree blob
target = lower(char(mp.target));
project_revision = mp.modelName + "_" + target;
sopcinfo_file = hdlpath + "/quartus/" + target + '_system.sopcinfo';
disp("Generating device tree source file")
disp(python + mp.dtogen_path + filesep + "dtogen -s " + sopcinfo_file + " -r " + project_revision + " -o " + hdlpath)
system(python + mp.dtogen_path + filesep + "dtogen -s " + sopcinfo_file + " -r " + project_revision + " -o " + hdlpath);

disp("Compiling device tree source file")

if ispc
    if system('wsl.exe cd') == 0 
        system("wsl.exe dtc -@ -O dtb -o " + project_revision + ".dtbo " + project_revision + ".dts");
    else
        disp("Windows Subsystem for Linux is currently required to automate compiling device tree overlays")
    end
elseif isunix
    system("dtc -@ -O dtb -o " + project_revision + ".dtbo " + project_revision + ".dts");
else
    disp('The current operating system is unsupported for automatically compiling device tree overlays')
end

disp('vgen: Finished.')

% reset fast simulation flag so running the model simulation isn't so slow after generating code. 
mp.fastsim_flag = 1;

% turn simulation prompts and callbacks back on for normal simulation.
mp.sim_prompts = 1;
