function result = analyzeSession(sesnum, Path, cleantype)

ChannelLabel = {'Fz','FC3','FC1','FCz','FC2','FC4','C3','C1','Cz','C2','C4',...
    'CP3','CP1','CPz','CP2','CP4'};
SubPlotPos = [3, 6:20];

Runs = dir([Path '\*.mat']);

if(isempty(Runs))
    result.bad = 1;
    return;
end
IndDot = strfind(Runs(1).name,'.');
SubjectID = Runs(1).name(1:IndDot(1)-1);
SessionDate = Runs(1).name(IndDot(1)+1:IndDot(2)-1);

eegdata = [];
stimlabels = [];
for run=1:length(Runs)

    % Incorporate here a check for rejecting due to too much noise
    
    rundata = load([Path '\' Runs(run).name]);
    
    SamplingFrequency = rundata.RunOutput.sfreq; % No case of multiple sfreq within a session, so, overweiting fine
    
    stimlabels = [stimlabels ; rundata.RunOutput.labels];
    if(cleantype > 0)
        eegdata = cat(1, eegdata, rundata.RunOutput.data.clean);
    else
        eegdata = cat(1, eegdata, rundata.RunOutput.data.raw);
    end
end
clear rundata;
Stimuli = unique(stimlabels);
StimColor = {'k','b','r','m','c'};
StimStyle = {'-','-.','--',':','--'};

% Resampe data from 512 Hz down o 500 Hz to get rid of this issue
if(SamplingFrequency == 512)
    for tr=1:size(eegdata,1)
        neegdata(tr,:,:)= resample(squeeze(eegdata(tr,:,:)), 500, 512);
    end
    eegdata = neegdata; clear neegdata;
end


%RejectTrials = find(sum(squeeze(mean(eegdata > 150, 2)),2) > 10); %
%Essentially reject trials where more than 10 channels have a lot of values
%above 150μV

for tr=1:size(eegdata,1)
    GFP(tr,:) = std(squeeze(eegdata(tr,:,:)),0,2);
end

result.gfp = processWaveform(GFP, stimlabels, Stimuli);

figure((sesnum-1)*10+1);
for ch=1:size(eegdata,3)
    result.channel(ch) = processWaveform(squeeze(eegdata(:,:,ch)), stimlabels, Stimuli);
    %subplot(4,5,SubPlotPos(ch)); plot_ga(0, result.channel(ch), Stimuli, StimColor, StimStyle, SubjectID, ChannelLabel{ch}, 0);
end

result.SubID = SubjectID;
result.date = SessionDate;


plot_ga((sesnum-1)*10+2, result.gfp, Stimuli, StimColor, StimStyle, SubjectID, 'GFP', 1);
mysavefig(['./plots/S' num2str(sesnum) '_' SubjectID '_GFP.png']);

% figure(2);
% for st=1:length(Stimuli)
%     shadedErrorBar([-1:1/500:2-1/500], result.gfp.GA_median(st,:), [result.gfp.GA_prct75(st,:) ; result.gfp.GA_prct25(st,:)],{'Color', StimColor{st}},1);hold on;    
% end
% hold off;

%figure(3);
%shadedErrorBar([-1:1/500:2-1/500], result.GA_mean(st,:), result.GA_std(st,:),{'Color', StimColor{st}},1);hold on;
