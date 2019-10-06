% genDeviceDriver Generate a device driver from a json input file
%
% genDeviceDriver(infile, outfile)
%
% The json file this function expects has a specific format that contains information about the vhdl entity and
% the Avalon streaming interface parameters. This will often be generated by MATLAB/Simulink, but it can also be written
% by hand. 
%
% Inputs:
%   infile = the json input filename
%   outfile = the vhdl output filename

% Copyright 2019 Flat Earth Inc, Montana State University
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
% INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
% PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
% FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%
% Trevor Vannoy
% Flat Earth Inc
% 985 Technology Blvd
% Bozeman, MT 59718
% support@flatearthinc.com

function genDeviceDriver(infile, outfile)

% call the python file that autogens the code
py.JsonToDriver.JsonToDriver(infile, outfile)