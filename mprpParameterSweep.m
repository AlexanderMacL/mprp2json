%% Script to generate multi-step *.mprp files with parameter sweep

Temperatures = 40:10:80; % parameter to sweep

%% Construct JSON-style data structure
% (you could alternatively use mprp2json.m to parse an existing mprp file
% and return the data structure D whose elements you could change/add to)

D.Type = 'MPR Profile'; % Type field must always take this value
D.Name = 'Temperature Sweep Test for David';
D.contactLength = 1.000;
D.Steps = {};
D.outFileLocation = 'TemperatureSweep.mprp';

%% Fatigue step template
FatigueTemplate.stepType = 'Fatigue';
FatigueTemplate.stepName = '';
% Temperature control parameters
FatigueTemplate.tempCtrlEn = true;
FatigueTemplate.waitForTempBeforeStep = true;
FatigueTemplate.idleSpeed = 1000;
FatigueTemplate.idleSRR = 0;
FatigueTemplate.idleLoad = 0;
FatigueTemplate.coolerEn = true;
% Data logging parameters
FatigueTemplate.stepDurationSeconds = 600;
FatigueTemplate.logData = true;
FatigueTemplate.logDataIntervalSeconds = 5;
FatigueTemplate.startTemp = 0;
FatigueTemplate.endTemp = 0;
FatigueTemplate.startLoad = 250;
FatigueTemplate.endLoad = 250;
FatigueTemplate.startSpeed = 1000;
FatigueTemplate.endSpeed = 1000;
FatigueTemplate.startSRR = -10;
FatigueTemplate.endSRR = -10;
% Trip parameters
FatigueTemplate.highTempTripEn = false;
FatigueTemplate.highTempTrip = 0;
FatigueTemplate.tractionTripEn = false;
FatigueTemplate.tractionTrip = 0;
FatigueTemplate.CLAaccelTripEn = false;
FatigueTemplate.CLAaccelTrip = 0;
FatigueTemplate.CLAslopeTripEn = false;
FatigueTemplate.CLAslopeTrip = 0;
FatigueTemplate.P2PaccelTripEn = false;
FatigueTemplate.P2PaccelTrip = 0;
FatigueTemplate.P2PslopeTripEn = false;
FatigueTemplate.P2PslopeTrip = 0;
FatigueTemplate.wearTripEn = false;
FatigueTemplate.wearTrip = 0;
FatigueTemplate.lowTorqueTripEn = false;
FatigueTemplate.lowTorqueTrip = 0;

%% Suspend step template
SuspendTemplate.stepType = 'Suspend';
SuspendTemplate.stepName = '';
SuspendTemplate.stepText = '';

%% Add steps in loop, tweaking the template each time
for i = 1:2:2*length(Temperatures)
    j = (i-1)/2+1; % index of Temperatures array
    D.Steps{i} = FatigueTemplate;
    D.Steps{i}.stepName = ['Temperature = ' num2str(Temperatures(j)) 'C'];
    D.Steps{i}.startTemp = Temperatures(j);
    D.Steps{i}.endTemp = Temperatures(j);
    
    D.Steps{i+1} = SuspendTemplate;
    D.Steps{i+1}.stepName = ['Suspend ' num2str(j)];
    D.Steps{i+1}.stepText = ['Fatigue step at ' num2str(Temperatures(j)) 'C complete.'];
end

json2mprp(D);



