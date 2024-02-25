function plot_ga(hnum, result, Stimuli, StimColor, StimStyle, SubjectID, PlotType, showlegend)

if(hnum > 0)
    figure(hnum);
end
for st=1:length(Stimuli)
    plot([-1:1/500:2-1/500], result.GA_median(st,:), 'Color', StimColor{st},...
        'LineWidth', 1, 'LineStyle', StimStyle{st});hold on;
end
h = gca;
line([0 0],[h.YLim(1) h.YLim(2)],'Color','k','LineWidth',2,'LineStyle','--');
hold off;
xlabel('Time [s]', 'FontSize', 20);
ylabel('Amplitude [uV]', 'FontSize', 20);
set(gca, 'XTick',[-1:0.25:2]);
set(gca, 'XTickLabel',[-1:0.25:2], 'FontSize', 20);
if(showlegend)
    legend({'T','AC','AF','ATC','ATF'}, 'FontSize', 20);
end
title([SubjectID ', ' PlotType], 'FontSize', 20);
set(gca, 'FontSize', 20);