function [RunOutput] = preanalyzePPS(GDFPath, lap, chanlocs)

RunOutput.fine = 1;
try
    [data, header] = sload(GDFPath); % Load GDF data and header
    
    data = data(:,1:16); % Remove unused HW trigger channel
    
    %Obtain sampling freq. Note that few sessions have 512 Hz (USBamp)
    %while the vast majority has 500 Hz Nautilus
    sfreq = header.EVENT.SampleRate;

    % %% Artifact removal /run rejection
    % %Clean signal with FORCe
    % for w=1:sfreq:size(data,1) - sfreq
    %     tmp = ARFORCe(data(w:w+sfreq-1,:)', sfreq, chanlocs, 0)';     
    %     data(w:w+sfreq-1,:) = tmp;
    % end
    
    %% HERE we should catch FORCe messages for cleaned windows and if there
    % are too many warnings for uncleaned signal set a criterion to reject
    % runs/subjects
    % TODO

    % Some times (rarely) there are may be NaNs in some channels, set to 0
    data(isnan(data))=0;
    
catch
    disp(['Problem loading file, skipping: '  GDFPath]);
    RunOutput.fine = 0;
    return;
end

%% Pre-processing
% Remove overall DC
data = data-repmat(mean(data),size(data,1),1);

% Laplacian spatial filtering
data = laplacianSP(data,lap);

% TODO: Add some additional detrending and/or bandpass filtering,
% especially because some few runs in the beginning where ran without
% hardware filters on the amp side.

%% Trial extraction
dur = 2.0; % All trials have 2 second duration
cue = header.EVENT.TYP;
pos = header.EVENT.POS;
pos(cue==666) = [];
cue(cue==666) = []; % Get rid of closing run trigger

if(length(cue) < 250)
    disp(['Warning! This run seems to contain less than the anticipated 250 trials: '...
        num2str(length(cue))])
end

trials = [pos pos+ dur*sfreq];
labels = cue;

% Arrange trials in 3D matrix Trials x time x channels
trialdata = [];
for tr=1:size(trials, 1)
    trialdata(tr,:,:) = data(trials(tr,1):trials(tr,2)-1,:);
end

RunOutput.data = data;
RunOutput.labels = labels;