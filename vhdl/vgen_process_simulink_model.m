% vgen_process_simulink_model
%
% This script parses the simulink model and extracts the interface signals
% and puts this information in a JSON file.

% Copyright 2019 Flat Earth Inc
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
% INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
% PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
% FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
% Ross K. Snider, Trevor Vannoy
% Flat Earth Inc
% 985 Technology Blvd
% Bozeman, MT 59718
% support@flatearthinc.com


%% Parse the Simulink Model (currently opened model)
% We parse the model to get the Avalon signals and control registers we need for the Avalon vhdl wrapper
disp(['vgen: Parsing Simulink model: ' mp.model_name '. Please wait until you see the message "vgen: Finished."'])
try
    % turn off fast sim so that the model runs at the system clock rate
    mp.fastsim_flag = 0;
    % turn off the simulation prompts and the stop callbacks when running HDL workflow (otherwise this runs at each HDL workflow step)
    mp.sim_prompts = 0;   
    avalon = vgen_get_simulink_block_interfaces(mp);
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

%% save the specified clock frequencies
avalon.clocks.sample_frequency_Hz   = mp.Fs;
avalon.clocks.sample_period_seconds = mp.Ts;
avalon.clocks.system_frequency_Hz   = mp.Fs_system;
avalon.clocks.system_period_seconds = mp.Ts_system;

%% save the device info
avalon.model_name           = mp.model_name;
avalon.model_abbreviation   = mp.model_abbreviation;
avalon.linux_device_name    = mp.linux_device_name;
avalon.linux_device_version = mp.linux_device_version;

%% Save the avalon structure to a json file and a .mat file
writejson(avalon, [avalon.entity,'.json'])
save([avalon.entity '_avalon'], 'avalon')

%% Create UI config files
disp('Creating linker json file.')
mp = createLinkerWidgetNames(mp);
genLinkerConfig(mp, ['Linker_', mp.model_name, '.json']);
disp('Creating UI config json file.')
genUiConfig(mp, ['UI_', mp.model_name, '.json']);

%% Generate the Simulink model VHDL code

% run the hdl coder
hdlworkflow

% this is where hdlworkflow puts the vhdl files
hdlpath = [mp.model_path filesep 'hdlsrc' filesep mp.model_abbreviation];

%% Generate the Avalon VHDL wrapper for the VHDL code generated by the HDL Coder
disp('vgen: Creating Avalon VDHL wrapper.')
infile = [avalon.entity '.json'];
outfile = [hdlpath filesep avalon.entity '_avalon.vhd'];
vgenAvalonWrapper(infile, outfile, false, false);
disp(['      created vhdl file: ' outfile])

%% Generate the .tcl script to be used by Platform Designer in Quartus
disp('vgen: Creating .tcl script for Platform Designer.')
infile = [avalon.entity '.json'];
% NOTE: platform designer only adds components if they have the _hw.tcl suffix
outfile = [hdlpath filesep avalon.entity '_avalon_hw.tcl'];
vgenTcl(infile, outfile, hdlpath);
disp(['      created tcl file: ' outfile])

%% Generate the device driver code
disp('Creating device driver.')
outfile = [hdlpath filesep mp.model_name '.c'];
genDeviceDriver(infile, outfile)
disp(['      created device driver: ' outfile])

%% Generate kernel module build files
disp('Creating Makefile and Kbuild.')
genMakefile([hdlpath filesep], mp.model_name)
disp(['      created Makefile: ' [hdlpath filesep 'Makefile']])
disp(['      created Kbuild: ' [hdlpath filesep 'Kbuild']])

%% Build kernel module
% TODO: this needs to be platform independent, but how? Our Windows users 
%       use a virtual machine to compile the device driver, but that
%       won't automate very well. Maybe we can build the kernel module 
%       with Quartus' embedded command shell instead?
if isunix
    disp('Building kernel module.')
    cd(hdlpath)
    !make clean
    !make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- 
else
    disp('Kernel module needs to be manually built in a Linux environment.')
end

% TODO: this file now generates C code, but "vgen" make it seem like it is just VHDL still. This should be changed, and the repository should be reorganized a bit. 
%       This file shouldn't live in the vhdl folder anymore.


disp('vgen: Finished.')

cd(mp.model_path)

% reset fast simulation flag so running the model simulation isn't so slow after generating code. 
mp.fastsim_flag = 1;

% turn simulation prompts and callbacks back on for normal simulation.
mp.sim_prompts = 1;
