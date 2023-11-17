function mysavefig(Path)
%
% Function for exporting and saving figures programmatically
% Inputs:
% Path: Filepath of saved image
% Outputs:
% None

warning off;
set(gcf,'color','w')
set(gcf,'PaperOrientation','portrait')
set(gcf,'PaperType','A3')   

drawnow;
javaH = get(handle(gcf),'JavaFrame');
javaH.setMaximized(true);
disp(Path)

saveas(gcf,Path);
warning on;