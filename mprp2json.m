%% Function to convert *.mprp file to JSON encoded data
%
% author: Alexander MacLaren
% revised: 21/07/2021
%
% Usage:
%   D = mprp2json() - a file open dialog is provided to open *.mprp file
%       and to save *.json file. To be used at the command line or as a
%       standalone script.
%   D = mprp2json(infileloc, outfileloc) - the strings or character vectors
%       infileloc and outfileloc respectively contain the locations of the
%       desired input (mprp) and output (JSON) files.
% 
% Return value:
%   D is a MATLAB data structure containing the contents of the mprp file
%   as received by jsonencode()
%
% Notes:
%


function [D] = mprp2json(varargin)

if (nargin==0)
    
    % open input file
    [flnm,pth,~] = uigetfile({'*.mprp','MPR Profile Files (*.mprp)';'*.*','All Files (*.*)'});
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

if (c>=19)
    if (all([2 0 0 0]==data(1:4))) % File version
        D.Type = "MPR profile";
        k = k + 4;
    else
        error("File type unsupported - this version only supports MPR v2 profiles");
    end
    if (bitand(data(k),128)~=0)
        if (data(k+1)==1)
            data(k+1) = data(k); k = k + 1; % if more than 127 chars in descriptor, account for extra byte
        else
            warning("Unexpected description string header bytes 0x%x 0x%x at byte %d",data(k),data(k+1),k);
        end
    end
    if (c>=k+uint64(data(k)))
        D.Name = char(data(k+1:k+uint64(data(k))));
        k = k + 1 + uint64(data(k));
        D.contactLength = typecast(data(k:k+8-1),'double'); k = k + 8;
        D.numSteps = typecast(data(k:k+4-1),'uint32'); k = k + 4;
    else
        error("File shorter than expected string");
    end
    
else
    error("File shorter than expected header");
end

while (k<c)
    stephead = typecast(data(k:k+8-1),'uint64');
    k = k + 8;
    i = i + 1;
    switch (stephead)
        case hex2dec('0000000700000000') % Fatigue
            disp ("Fatigue step "+num2str(i)+" of "+num2str(D.numSteps));
            D.Steps{i}.stepType = 'Fatigue';
            D.Steps{i}.stepName = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            % Temperature Control
            D.Steps{i}.tempCtrlEn = data(k)==1; k = k + 1;
            D.Steps{i}.waitForTempBeforeStep = data(k)==1; k = k + 1;
            D.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.coolerEn = data(k)==1; k = k + 1;
            % Trip parameters
            D.Steps{i}.highTempTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.highTempTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.tractionTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.tractionTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.CLAaccelTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.CLAaccelTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.CLAslopeTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.CLAslopeTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.P2PaccelTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.P2PaccelTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.P2PslopeTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.P2PslopeTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.wearTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.wearTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.lowTorqueTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.lowTorqueTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            % Parameters
            d = [1, 0, 0, 0]==data(k:k+4-1);
            if (~all(d)); e = find(~d); warning("Unexpected Fatigue step duration flag at byte "+num2str(k+e(1)-1)); end
            k = k + 4;
            D.Steps{i}.stepDurationSeconds = typecast(data(k:k+4-1),'uint32'); k = k + 4;
            D.Steps{i}.logData = data(k)==1; k = k + 1;
            D.Steps{i}.logDataIntervalSeconds = typecast(data(k:k+4-1),'uint32'); k = k + 4;
            d = [1, 0, 0, 0]==data(k:k+4-1);
            if (~all(d)); e = find(~d); warning("Unexpected Fatigue step parameter flag at byte "+num2str(k+e(1)-1)); end
            k = k + 4;
            D.Steps{i}.startTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.endTemp = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.startLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.endLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.startSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.endSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.startSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.endSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            
        
        case hex2dec('0000000700000004') % Suspend
            disp("Suspend step "+num2str(i)+" of "+num2str(D.numSteps));
            D.Steps{i}.stepType = 'Suspend';
            D.Steps{i}.stepName = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            D.Steps{i}.tempCtrlEn = data(k)==1; k = k + 1;
            D.Steps{i}.waitForTempBeforeStep = data(k)==1; k = k + 1;
            D.Steps{i}.idleSpeed = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.idleSRR = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.idleLoad = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.coolerEnabled = data(k)==1; k = k + 1;
            D.Steps{i}.highTempTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.highTempTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.tractionTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.tractionTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.CLAaccelTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.CLAaccelTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.CLAslopeTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.CLAslopeTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.P2PaccelTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.P2PaccelTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.P2PslopeTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.P2PslopeTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.wearTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.wearTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            D.Steps{i}.lowTorqueTripEn = data(k)==1; k = k + 1;
            D.Steps{i}.lowTorqueTrip = typecast(data(k:k+8-1),'double'); k = k + 8;
            d = [1, 0, 0, 0]==data(k:k+4-1);
            if (~all(d)); e = find(~d); warning("Unexpected Suspend step duration flag at byte "+num2str(k+e(1)-1)); end
            k = k + 4;
            D.Steps{i}.stepText = char(data(k+1:k+uint64(data(k))));
            k = k + 1 + uint64(data(k));
            
        otherwise
            error("Step header "+num2str(typecast(data(k-8:k-1),'uint32'))+" at byte "+num2str(k-8)+" unrecognised")
    end
end

str = jsonencode(D, 'PrettyPrint', true);

if (nargin==2)
    flnm = varargin{2};
    f = fopen(flnm,'w');
else
    [flnm,pth,~] = uiputfile({'*.json','JavaScript Object Notation Files (*.json)';'*.*','All Files (*.*)'},'Save File',flnm(1:length(flnm)-5));
    f = fopen([pth,flnm],'w');
end

% write JSON string to file
fwrite(f, str);
fclose(f);
