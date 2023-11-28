%RawPath = 'E:\Data\CNBI_DATA\TOSORT_CNBI\CHUV\From_INBOX\CNBI_2017_AwarenessPPSCHUV_Perdikis\pps\';
%RawPath = 'E:\Data\CNBI_DATA\TOSORT_CNBI\CHUV\FromDaliMNT\';
%RawPath = 'E:\Data\CNBI_DATA\TOSORT_CNBI\CHUV\FromDaliScratc\';
%RawPath = 'E:\Data\CNBI_DATA\TOSORT_CNBI\CHUV\tmpchuv\';
RawPath = 'C:\Users\sp19284\Downloads\all_raw_data_patients\';


SortedPath = 'E:\Data\PPS_CHUV_sorted\';

%% Find all GDF files in rawpath
PPSGDFFiles = dir([RawPath '\**\*pps.gdf']);
PPSLOGFiles = dir([RawPath '\**\*pps.log']);

% Sort GDF files
for r=1:length(PPSGDFFiles)
    IndDots = strfind(PPSGDFFiles(r).name,'.');
    SubID = PPSGDFFiles(r).name(1:IndDots(1)-1);
    Session = PPSGDFFiles(r).name(IndDots(1)+1:IndDots(2)-1);
    Run = PPSGDFFiles(r).name(IndDots(2)+1:IndDots(3)-1);
    if(~exist([SortedPath '\' SubID],'dir'))
        mkdir(SortedPath, SubID);
    end
    if(~exist([SortedPath '\' SubID '\' Session],'dir'))
        mkdir([SortedPath '\' SubID], Session);
    end
    
    if(~exist([SortedPath '\' SubID '\' Session '\' SubID '.' Session '.' Run '.pps.gdf'],'file'))
        % Copy into sorted folder if it does not exist already
       copyfile([PPSGDFFiles(r).folder '\' PPSGDFFiles(r).name], [SortedPath '\' SubID '\' Session '\']); 
    end
end

% Sort LOG files
for s=1:length(PPSLOGFiles)
    IndDots = strfind(PPSLOGFiles(s).name,'.');
    SubID = PPSLOGFiles(s).name(1:IndDots(1)-1);
    Session = PPSLOGFiles(s).name(IndDots(1)+1:IndDots(2)-1);
    if(~exist([SortedPath '\' SubID],'dir'))
        mkdir(SortedPath, SubID);
    end
    if(~exist([SortedPath '\' SubID '\' Session],'dir'))
        mkdir([SortedPath '\' SubID], Session);
    end
    
    if(~exist([SortedPath '\' SubID '\' Session '\' SubID '.' Session '.pps.log'],'file'))
        % Copy into sorted folder if it does not exist already
        copyfile([PPSLOGFiles(s).folder '\' PPSLOGFiles(s).name], [SortedPath '\' SubID '\' Session '\']); 
    end
end