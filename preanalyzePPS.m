function [RunOutput] = preanalyzePPS(GDFPath, chanlocs, doFORCe, varargin)

% function [RunOutput] = preanalyzePPS(GDFPath, lap, chanlocs, clean)
%
% Inputs:
% GDFPath: Path to the GDF raw EEG fle to be processed
%
% Output(s):
% RunOutput: struct with data after trial extraction (+ other useful info)
%
% Function to produce data ready for further analysis after trial
% extraction and/or artifact removal. No pre-processing whatsoever is done,
% which means subsequent analysis should take care to do that. It should be
% noted that some (few) of the data may have been recorded with0out
% hbardware filters, so, it is important to apply some pre-processing for
% that (DC removal or other baselining, highpass/bandpass, etc.)

% Default values
filter       = 0; % By default, do not filter
low_cutoff   = 1; % Default low cutoff frequency
high_cutoff  = 40; % Default high cutoff frequency
filter_order = 4; % Default filter order
    
% Parse variable inputs
for i = 1:2:length(varargin)
    switch lower(varargin{i})
        case 'filter'
            filter = varargin{i+1};
        case 'low_cutoff'
            low_cutoff = varargin{i+1};
        case 'high_cutoff'
            high_cutoff = varargin{i+1};
        case 'filter_order'
            filter_order = varargin{i+1};
        otherwise
            error('Unknown input parameter');
    end
end

RunOutput.fine = 1;
try
    [data, header] = sload(GDFPath); % Load GDF data and header
    
    data = data(:,1:16); % Remove unused HW trigger channel
    
    % Obtain sampling freq. Note that few sessions have 512 Hz (USBamp)
    % whilst the vast majority has 500 Hz Nautilus
    RunOutput.sfreq = header.EVENT.SampleRate;

    % Some times (rarely) there are may be NaNs in some channels, set to 0
    data(isnan(data))=0;
    
catch
    disp(['Problem loading file, skipping: '  GDFPath]);
    RunOutput.fine = 0;
    return;
end
%% Check if filter should be applied
if filter == 1
    % Design Butterworth filter
    [b, a] = butter(filter_order, [low_cutoff, high_cutoff] / (RunOutput.sfreq/2), 'bandpass');
    
    % Initialize filtered data matrix
    filteredData = zeros(size(data));
    
    % Apply filter to each channel
    for channel = 1:size(data, 2)
        filteredData(:, channel) = filtfilt(b, a, data(:, channel));
    end
    
elseif filter == 0
    % Do not filter the data
    filteredData = data;
else
    error('Filter input must be 0 or 1');
end

data = filteredData;

%% Trial extraction
preStim = 1.0; % Each stimulus include 1 sec pre-stimulus samples
dur = 2.0; % All trials have 2 second duration
cue = header.EVENT.TYP;
pos = header.EVENT.POS;
pos(cue==666) = [];
cue(cue==666) = []; % Get rid of closing run trigger

if(length(cue) < 250)
    disp(['Warning! This run seems to contain less than the anticipated 250 trials: '...
        num2str(length(cue))]);
end

% trials = [pos pos+dur*RunOutput.sfreq];     <------------------- this line is commented by rab
trials = [pos-preStim*RunOutput.sfreq pos+dur*RunOutput.sfreq];
labels = cue;

% Arrange trials in 3D matrix Trials x time x channels
trialdata = [];
for tr=1:size(trials, 1)
    if(trials(tr,2)-1 > size(data,1))
        % This means the file for some reason ended too soon, we need to
        % discard this and all forthcoming trials
        labels = labels(1:tr-1);
        break;
    else
        trialdata(tr,:,:) = data(trials(tr,1):trials(tr,2)-1,:);
    end
end

%% Artifact removal /run rejection
%Check data for artifacts with FORCe
if doFORCe
    %Initialize cleaned version of trialdata
    cleantrialdata = trialdata;
    
    trialsuccess = [];
    for tr=1:size(trialdata, 1)
        for w=1:RunOutput.sfreq:size(trialdata,2)-RunOutput.sfreq+1
            [tmp, successFlag] = ARFORCe(squeeze(trialdata(tr, w:w+RunOutput.sfreq-1,:))', RunOutput.sfreq, chanlocs, 0);
            trialsuccess(tr,w) = successFlag;
            cleantrialdata(tr, w:w+RunOutput.sfreq-1,:) = tmp';
        end
    end
    % Percentage of windows where FORCe failed to clean, indicator of how
    % usable this run is
    RunOutput.trialsuccess = trialsuccess;
    RunOutput.noiseprct = 100*(length(trialsuccess(:))-sum(trialsuccess(:)))/length(trialsuccess(:)); 
    RunOutput.data.clean = cleantrialdata;
end
RunOutput.data.raw = trialdata;
RunOutput.labels = labels;

% Store also meta-data
SlashInd = union(strfind(GDFPath, '\'), strfind(GDFPath, '/'));
DotInd = strfind(GDFPath,'.');
RunOutput.subid = GDFPath(SlashInd(end)+1:DotInd(1)-1);
RunOutput.session = GDFPath(DotInd(1)+1:DotInd(2)-1);
RunOutput.time = GDFPath(DotInd(2)+1:DotInd(3)-1); 