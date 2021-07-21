%% Function to create MPR profile file from JSON encoded data
%
% author: Alexander MacLaren
% revised: 21/07/2021
% 
% Usage:
%   json2mprp() - a file open dialog is provided to open *.json file and to
%       save *.mprp file. To be used at the command line or as a standalone
%       script.
%   json2mprp(D) - the MATLAB data structure D containing the relevant
%       fields is used in place of the *.json file, and the output file is
%       saved to the location given by D.outFileLocation
%   json2mprp(infileloc, outfileloc) - the character vectors infileloc and
%       outfileloc respectively contain the locations of the desired input
%       (JSON) and output (mprp) files.
% 
% Notes:
%   See commented example JSON file for allowed fields, or use accompanying
%       function mprp2json to decode an existing mprp
%   


function json2mprp(varargin)

if (nargin==0)
    % open input file
    [flnm,pth,~] = uigetfile({'*.json','JavaScript Object Notation Files (*.json)';'*.*','All Files (*.*)'});
    f = fopen([pth,flnm]);
    raw = fread(f, inf);
    txt = char(raw');
    fclose(f);
    % decode JSON
    D = jsondecode(txt);
    
elseif (nargin==1)
    D = varargin{1};
    
elseif (nargin==2)
    % open input file
    f = fopen(varargin{1});
    raw = fread(f, inf);
    txt = char(raw');
    fclose(f);
    % decode JSON
    D = jsondecode(txt);
    
elseif (nargin>2)
    error("Too many arguments (%d given)",nargin);

end

% open output file
if (nargin==2)
    flnm = varargin{2};
    f = fopen(flnm,"w");
elseif (nargin==1)
    flnm = D.outFileLocation;
    f = fopen(flnm,"w");
else
    [flnm,pth,~] = uiputfile({'*.mprp','MPR Profile Files (*.mprp)';'*.*','All Files (*.*)'},'Save File',flnm(1:length(flnm)-5));
    f = fopen([pth,flnm],"w");
end


% Construct byte arrays
Header = [2, zeros(1,3), ...
    length(D.Name)];
if (length(D.Name)>127); Header = [Header, 1]; end
Header = [Header, uint8(D.Name), ...
    typecast(double(D.contactLength), 'uint8'), typecast(uint32(length(D.Steps)), 'uint8')];

if (~ iscell(D.Steps))
    D.Steps = num2cell(D.Steps);
end

for i = 1:length(D.Steps)
    % Fatigue step
    if (strcmpi(D.Steps{i}.stepType,'Fatigue'))
        disp("Step "+num2str(i)+" Fatigue");
        StepHeadBytes = [typecast(uint32(0), 'uint8'), typecast(uint32(7), 'uint8')];
        Step{i} = [StepHeadBytes, ...
            length(D.Steps{i}.stepName), uint8(D.Steps{i}.stepName), ...
            D.Steps{i}.tempCtrlEn, D.Steps{i}.waitForTempBeforeStep, ...
            typecast(double(D.Steps{i}.idleSpeed), 'uint8'), ...
            typecast(double(D.Steps{i}.idleSRR), 'uint8'), ...
            typecast(double(D.Steps{i}.idleLoad), 'uint8'), ...
            D.Steps{i}.coolerEn, ...
            D.Steps{i}.highTempTripEn, typecast(double(D.Steps{i}.highTempTrip), 'uint8'), ...
            D.Steps{i}.tractionTripEn, typecast(double(D.Steps{i}.tractionTrip), 'uint8'), ...
            D.Steps{i}.CLAaccelTripEn, typecast(double(D.Steps{i}.CLAaccelTrip), 'uint8'), ...
            D.Steps{i}.CLAslopeTripEn, typecast(double(D.Steps{i}.CLAslopeTrip), 'uint8'), ...
            D.Steps{i}.P2PaccelTripEn, typecast(double(D.Steps{i}.P2PaccelTrip), 'uint8'), ...
            D.Steps{i}.P2PslopeTripEn, typecast(double(D.Steps{i}.P2PslopeTrip), 'uint8'), ...
            D.Steps{i}.wearTripEn, typecast(double(D.Steps{i}.wearTrip), 'uint8'), ...
            D.Steps{i}.lowTorqueTripEn, typecast(double(D.Steps{i}.lowTorqueTrip), 'uint8'), ...
            1, zeros(1,3), ...
            typecast(uint32(D.Steps{i}.stepDurationSeconds), 'uint8'), D.Steps{i}.logData, ...
            typecast(uint32(D.Steps{i}.logDataIntervalSeconds), 'uint8'), ...
            1, zeros(1,3), ...
            typecast(double(D.Steps{i}.startTemp), 'uint8'), ...
            typecast(double(D.Steps{i}.endTemp), 'uint8'), ...
            typecast(double(D.Steps{i}.startLoad), 'uint8'), ...
            typecast(double(D.Steps{i}.endLoad), 'uint8'), ...
            typecast(double(D.Steps{i}.startSpeed), 'uint8'), ...
            typecast(double(D.Steps{i}.endSpeed), 'uint8'), ...
            typecast(double(D.Steps{i}.startSRR), 'uint8'), ...
            typecast(double(D.Steps{i}.endSRR), 'uint8')
        ];

    % Suspend
    elseif (strcmpi(D.Steps{i}.stepType,'Suspend'))
        disp("Step "+num2str(i)+" Suspend");
            StepHeadBytes = [typecast(uint32(4), 'uint8'), typecast(uint32(7), 'uint8')];
        Step{i} = [StepHeadBytes, ...
            length(D.Steps{i}.stepName), uint8(D.Steps{i}.stepName), ...
            zeros(1,99), 1, zeros(1,3),...
            length(D.Steps{i}.stepText), uint8(D.Steps{i}.stepText)
        ];
    else
        error("stepType """ + D.Steps{i}.stepType + """ unsupported")
    end
end

% write byte arrays
fwrite(f, Header, 'uint8');
disp(['Writing file ' flnm])
for i = 1:length(D.Steps)
    fwrite(f, Step{i}, 'uint8');
end

fclose(f);
