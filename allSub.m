clear;close all;clc;

%% Parametrization (add here any high-level or global params)

% EEGLAB style channel locations (needed for FORCe, topoplots)
load('chanlocs16.mat');chanlocs = chanlocs16;

%% Libraries to include
addpath(genpath('./biosig/')); % Biosig toolbox for loading GDF files
addpath(genpath('./FORCe')); % Artifact removal as pre-processing and potentially criterion for data rejection

%% Input/output paths (EDIT THESE FOR YOUR OWN WORKSTATION)
% RawDataPath = 'E:\Data\PPS_CHUV_sorted\'; 
% SaveOutPath = 'C:\Users\sp19284\tmpdata\ppschuv\';
RawDataPath = 'Z:\tommaso_transfer\'; 
SaveOutPath = 'Z:\Processed\';


%% Main processing code
% This scrit is meant to discover data, load them, do trial extraction,
% some basic preprocessing (artifact removal, data rejection, spatial
% filtering, etc.), gather the data with session as unit, and output a mat
% file per session saved in SaveOutPath for further processing by other
% scripts. Since log files were saved during recording containing the
% info of which and ho many runs (GDF files) were done, they will be used
% here, as a menas to confirm the sanity of the recording by comparison to 
% the data we actually see on the disk. To my best knowledge for this dataset 
% there are no missing files, anyway.


% Find subjects in RawDataPath. Convention is there is one folder per
% subject, no folders that are NOT subjects (should) exist
SubSesDir = dir(RawDataPath);
SubSesDir = SubSesDir(3:end); % Get rid of directories './', '../'
isd = [SubSesDir(:).isdir]; % Filter out any files in the same directory
SubSesDir = SubSesDir(isd);

SubInSes = regexprep({SubSesDir.name},'[\d"]',''); % Index of which subject is in each session folder
SubID = unique(SubInSes);

for subject = 1:length(SubID)
    
    % The script has been changed for Tommaso's big database where each
    % session X is in its own folder as SubidX. For previous versions of
    % this script working with ny own ordering (sessions are folders within
    % each subject's folder) revert the git to the appropriate tag
    
    Sub = SubID{subject};
    SessionFolderIndex = [];
    SessionFolderIndex = find(contains(SubInSes,Sub));
    
    % Prepare output file directory
    if(~exist([SaveOutPath '/' Sub],'dir'))
        % Create subject's folder
        mkdir([SaveOutPath],Sub);
        mkdir([SaveOutPath '/' Sub],'excluded');
    end

    % Process all sessions
    for ses=1:length(SessionFolderIndex)
        SesName = SubSesDir(SessionFolderIndex(ses)).name;
   
        % Find GDF files in the session folder
        GDFFiles = dir([RawDataPath '/' SesName '/*.gdf']);
            
        for run=1:length(GDFFiles)

            GDFName = GDFFiles(run).name;
            GDFPath = [GDFFiles(run).folder '/' GDFName];
          
            if(exist(GDFPath,'file')>0)
                ff = dir(GDFPath);
                if( (ff.bytes / (1024^2)) < 5.0 ) % Get rid of too small GDFs, probably failed attempts to start the loop or interrupted runs
                    continue;
                end
            else
                continue;
            end
            
            if( (exist([SaveOutPath '/' Sub '/' GDFName(1:end-4) '.mat'],'file') == 0) && (exist([SaveOutPath '/' Sub '/'  '/excluded/' GDFName(1:end-4) '.mat'],'file') == 0))
                RunOutput = preanalyzePPS(GDFPath, chanlocs);
                if(RunOutput.fine == 1)
                    save([SaveOutPath '/' Sub '/' GDFName(1:end-4) '.mat'],'RunOutput');
                else
                    % Save excluded dummy mat file
                    save([SaveOutPath '/' Sub '/excluded/' GDFName(1:end-4) '.mat'],'RunOutput');
                    continue;
                end
            else
                if(exist([SaveOutPath '/' Sub '/' GDFName(1:end-4) '.mat'],'file') == 2)
                    load([SaveOutPath '/' Sub '/' GDFName(1:end-4) '.mat']);
                else
                    % Faulty run saved, skip it
                    continue;
                end
            end
            
            disp(['Subject: ' Sub ' , Session: ' num2str(ses) ' , Run: ' num2str(run)]);      
        end
    end
end