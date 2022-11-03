%% Function to convert *.mprd file to JSON encoded data
%
% author: Alexander MacLaren
% revised: 14/08/2021
%
% Usage:
%   B = mprd2json() - a file open dialog is provided to open *.mprd file
%       and to save *.json file. To be used at the command line or as a
%       standalone script.
%   B = mprd2json(infileloc, outfileloc) - the strings or character vectors
%       infileloc and outfileloc respectively contain the locations of the
%       desired input (mprd) and output (JSON) files.
% 
% Return value:
%   B is a MATLAB data structure containing the contents of the mprd file
%   as received by jsonencode()
%
% Notes:
%

function [B] = mprd2json(varargin)

if (nargin==0)
    % open input file
    [flnm,pth,~] = uigetfile({'*.mprd','MPR Data Files (*.mprd)';'*.*','All Files (*.*)'});
    f = fopen([pth,flnm]);

elseif (nargin>2)
    error("Too many arguments (%d given)",nargin);

else 
    flnm = varargin{1};
    f = fopen(flnm);
end

raw = fread(f, inf, 'uint8=>uint8');
data = raw';
fclose(f);

disp("Parsing file "+flnm+" ...");

c = uint64(length(data));
k = uint64(1);
i = 0;

if (c>=34)
    dmpr = [1 0 0 0]==data(k:k+4-1);
    if (~all(dmpr))
        warning("Unexpected pattern " + num2str(data(k:k+4-1)) + " in header - is this an MPR data file?");
    end
    k = k + 4;
    [B.dataFilePath, ki] = parsestr(data, k); k = k + ki;
    [B.profileFilePath, ki] = parsestr(data, k); k = k + ki;
    [B.description, ki] = parsestr(data, k); k = k + ki;
    [B.lubeName, ki] = parsestr(data, k); k = k + ki;
    [B.comments, ki] = parsestr(data, k); k = k + ki;
    B.numSteps = typecast(data(k:k+4-1),'uint32'); k = k + 4;
    B.testStartTime = char(string(datetime(typecast(data(k:k+8-1), 'uint64'), 'ConvertFrom', '.net', 'TimeZone', 'Europe/London'),'dd/MM/yyyy HH:mm:ss','en_GB')); k = k + 8;
    [B.status, ki] = parsestr(data, k); k = k + ki;
    B.testEndTime = char(string(datetime(typecast(data(k:k+8-1), 'uint64'), 'ConvertFrom', '.net', 'TimeZone', 'Europe/London'),'dd/MM/yyyy HH:mm:ss','en_GB')); k = k + 8;
    B.numStepsCompleted = typecast(data(k:k+4-1),'uint32'); k = k + 4;
else
    error("File shorter than expected header");
end

while (k<c)
    stephead = typecast(data(k:k+8-1),'uint64');
    k = k + 8;
    i = i + 1;
    switch (stephead)
        case hex2dec('0000000100000000') % Fatigue
            disp ("Fatigue step "+num2str(i)+" of "+num2str(B.numStepsCompleted));
            B.Steps{i}.stepType = 'Fatigue';
        otherwise
            error("Step header "+num2str(typecast(data(k-8:k-1),'uint32'))+" at byte "+num2str(k-8)+" unrecognised")
    end
    [B.Steps{i}.stepName, ki] = parsestr(data, k); k = k + ki;
    % For some reason this one needs the 2nd-to-most significant bit
    % deasserted for it to parse as a time
    B.Steps{i}.stepStartTime = char(string(datetime(bitand(bitcmp(bitshift(uint64(1),62)),typecast(data(k:k+8-1), 'uint64')), 'ConvertFrom', '.net', 'TimeZone', 'Europe/London'),'dd/MM/yyyy HH:mm:ss','en_GB')); k = k + 8;
    B.Steps{i}.stepDurationSeconds = round(double(typecast(data(k:k+4-1), 'uint32'))/1e7,3); k = k + 4;
    k = k + 8; % not sure what these do
    B.Steps{i}.numDatapoints = typecast(data(k:k+4-1),'uint32'); k = k + 4;
    for j = 1:B.Steps{i}.numDatapoints
        % K.Steps{i}.dataTimestamp(j) = string(datetime(typecast(data(k:k+8-1), 'uint64'), 'ConvertFrom', '.net', 'TimeZone', 'Europe/London'),'dd/MM/yyyy HH:mm:ss','en_GB');
        k = k + 8;
        B.Steps{i}.secondsElapsed(j) = round(typecast(data(k:k+8-1),'double'),2); k = k + 8;
        B.Steps{i}.millionCyclesElapsed(j) = round(typecast(data(k:k+8-1),'double'),6); k = k + 8;
        B.Steps{i}.rollerSpeed(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.discSpeed(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.entrainmentSpeed(j) = round(typecast(data(k:k+8-1),'double'),2); k = k + 8;
        B.Steps{i}.slidingSpeed(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.SRR(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.Load(j) = round(typecast(data(k:k+8-1),'double'),1); k = k + 8;
        B.Steps{i}.CLAaccel(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.CLAslope(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.P2Paccel(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.P2Pslope(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.wear(j) = round(typecast(data(k:k+8-1),'double'),1); k = k + 8;
        B.Steps{i}.torque(j) = round(typecast(data(k:k+8-1),'double'),3); k = k + 8;
        B.Steps{i}.tractionCoefficient(j) = round(typecast(data(k:k+8-1),'double'),4); k = k + 8;
        B.Steps{i}.mainTemperature(j) = round(typecast(data(k:k+8-1),'double'),2); k = k + 8;
        B.Steps{i}.alarmTemperature(j) = round(typecast(data(k:k+8-1),'double'),2); k = k + 8;
    end
end

str = jsonencode(B); %, 'PrettyPrint', true);
% PrettyPrint option not working until R2021a so this is the poor man's JSON beautifier (no indentation)
str = strrep(str, ',"', sprintf(',\n"'));
str = strrep(str, '":', '": ');
str = strrep(str, '{', sprintf('\n{\n'));
str = strrep(str, '}', sprintf('\n}\n'));
str = strrep(str, sprintf('}\n,'), '},');

if (nargin==2)
    flnm = varargin{2};
    f = fopen(flnm,'w');
else
    [flnm,pth,~] = uiputfile({'*.json','JavaScript Object Notation Files (*.json)';'*.*','All Files (*.*)'},'Save File',flnm(1:length(flnm)-5));
    f = fopen([pth,flnm],'w');
end

% write JSON string to file
fwrite(f, str(2:end));
fclose(f);

end

function [str, ki] = parsestr(data, k)
    ki = 1;
    str = '';
    c = uint64(data(k));
    if (c==0)
        return;
    else
        ci = 1;
        while (bitand(uint64(data(k)),128)~=0)
            c = c + bitshift(1,7*ci)*(uint64(data(k+1))-1); % if more than 127 chars in descriptor, account for extra byte
            ki = ki + 1;
            k = k + 1;
            ci = ci + 1;
        end
    end
    str = char(data(k+1:k+c));
    ki = c + ki;
end
