
% Get all timefram for further analysis reference
ExtractDateTime;

% To get all RR
CalculateAllHR;

% Run HRV analysis to get time domain and freq domain parameter results
HRVAnalysis_TimeFreq;

% Generate all AWD related to HRV parameters
GenerateAWD;

% Extract and generate telemetry activity AWD
Activity_Extract;

% Analysis on HRV Time Freq domains using Cosinor
GenerateTimeFreqHRVGraph;

% Generate example for ectopic detection results
EctopicExample;