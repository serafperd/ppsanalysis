clear all;close all;clc;

% Path to preanalyzed, trial-extracted session data
Path = 'C:\Users\seraf\ppsdata\ProcessedPPSFull\Processed\';
cleantype = 1; % 1 for FORCe-cleaned, 0 otherwise


ChannelLabel = {'Fz','FC3','FC1','FCz','FC2','FC4','C3','C1','Cz','C2','C4',...
    'CP3','CP1','CPz','CP2','CP4'};

Stimuli = [10 21 22 31 32];
StimColor = {'k','b','r','m','c'};
StimStyle = {'-','-.','--',':','--'};
SubPlotPos = [3, 6:20];

if(exist('result.mat')~=2)
    SessionFolders = dir(Path);
    SessionFolders = SessionFolders(3:end); % Get rid of . and ..
    NSessions = length(SessionFolders);
    
    for ses=1:NSessions
        disp(['Processing session ' num2str(ses) ' / ' num2str(NSessions)]);
        result(ses) = analyzeSession(ses, [SessionFolders(ses).folder '\' SessionFolders(ses).name], cleantype);
    end
else
    load('result.mat');
end

for ses=1:length(result)
    for st=1:length(Stimuli)
        ga_all_gfp(ses, st, :) = result(ses).gfp.GA_median(st,:);
        for ch=1:length(ChannelLabel)
            ga_all_channel(ses, st, ch, :) = result(ses).channel(ch).GA_median(st,:);
        end
    end
end


figure(20);
for st=1:length(Stimuli)
    plot([-1:1/500:2-1/500], mean(squeeze(ga_all_gfp(:, st,:)),1), 'Color', StimColor{st},...
        'LineWidth', 1, 'LineStyle', StimStyle{st});hold on;
end
h = gca;
line([0 0],[h.YLim(1) h.YLim(2)],'Color','k','LineWidth',2,'LineStyle','--');
hold off;
xlabel('Time [s]', 'FontSize', 20);
ylabel('Amplitude [uV]', 'FontSize', 20);
set(gca, 'XTick',[-1:0.25:2]);
set(gca, 'XTickLabel',[-1:0.25:2], 'FontSize', 20);
legend({'T','AC','AF','ATC','ATF'}, 'FontSize', 20);
title('Grand average GFP (mean of medians)', 'FontSize', 20);
set(gca, 'FontSize', 20);
mysavefig(['./plots/GA_GFP.png']);


for ch=1:length(ChannelLabel)
    figure(ch);
    for st=1:length(Stimuli)
        plot([-1:1/500:2-1/500], mean(squeeze(ga_all_channel(:, st,ch, :)),1), 'Color', StimColor{st},...
            'LineWidth', 2, 'LineStyle', StimStyle{st});hold on;
    end
    h = gca;
    line([0 0],[h.YLim(1) h.YLim(2)],'Color','k','LineWidth',2,'LineStyle','--');
    hold off;
    xlabel('Time [s]', 'FontSize', 20);
    ylabel('Amplitude [uV]', 'FontSize', 20);
    set(gca, 'XTick',[-1:0.25:2]);
    set(gca, 'XTickLabel',[-1:0.25:2], 'FontSize', 20);
    legend({'T','AC','AF','ATC','ATF'}, 'FontSize', 20);
    title([ChannelLabel{ch} ' - Grand average ERP (mean of medians)'], 'FontSize', 20);
    set(gca, 'FontSize', 20);
    mysavefig(['./plots/GA_' ChannelLabel{ch} '.png']);
end
