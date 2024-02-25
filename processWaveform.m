function result = processWaveform(eeg, stimlabels, Stimuli)


for st=1:length(Stimuli)

    result.GA_mean(st,:) = mean(eeg(stimlabels==Stimuli(st),:));
    result.GA_median(st,:) = median(eeg(stimlabels==Stimuli(st),:));
    result.GA_std(st,:) = std(eeg(stimlabels==Stimuli(st),:),0,1);
    result.GA_prct25(st,:) = prctile(eeg(stimlabels==Stimuli(st),:),25,1);
    result.GA_prct75(st,:) = prctile(eeg(stimlabels==Stimuli(st),:),75,1);
    IndStim{st} = find(stimlabels==Stimuli(st));
    NStim(st) = length(IndStim{st});
end

Nmin = min(NStim);

for t=1:size(eeg,2)
    result.pA(t) = ranksum(eeg(stimlabels==21,t), eeg(stimlabels==22,t));
    result.pAT(t) = ranksum(eeg(stimlabels==31,t), eeg(stimlabels==32,t));
    result.pPPS(t) = ranksum(eeg(IndStim{1}(1:Nmin),t) + eeg(IndStim{2}(1:Nmin),t) - eeg(IndStim{4}(1:Nmin),t),...
        eeg(IndStim{1}(1:Nmin),t) + eeg(IndStim{3}(1:Nmin),t) - eeg(IndStim{5}(1:Nmin),t));
end