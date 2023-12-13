function [RunOutput] = preanalyzePPS(GDFPath, chanlocs)

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

%% Trial extraction
dur = 2.0; % All trials have 2 second duration
cue = header.EVENT.TYP;
pos = header.EVENT.POS;
pos(cue==666) = [];
cue(cue==666) = []; % Get rid of closing run trigger

if(length(cue) < 250)
    disp(['Warning! This run seems to contain less than the anticipated 250 trials: '...
        num2str(length(cue))]);
end

trials = [pos pos+dur*RunOutput.sfreq];
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

% Initialize cleaned version of trialdata
cleantrialdata = trialdata;


%% Artifact removal /run rejection
%Check data for artifacts with FORCe
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
RunOutput.data.raw = trialdata;
RunOutput.data.clean = cleantrialdata;
RunOutput.labels = labels;

% Store also meta-data
SlashInd = union(strfind(GDFPath, '\'), strfind(GDFPath, '/'));
DotInd = strfind(GDFPath,'.');
RunOutput.subid = GDFPath(SlashInd(end)+1:DotInd(1)-1);
RunOutput.session = GDFPath(DotInd(1)+1:DotInd(2)-1);
RunOutput.time = GDFPath(DotInd(2)+1:DotInd(3)-1); 