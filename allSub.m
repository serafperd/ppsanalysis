clear;close all;clc;

%% Parametrization (add here any high-level or global params)

% Do or not FORCe artifact removal (1: do, 0: dont)
doclean = 0;
if(doclean) cleandir = 'clean'; else cleandir = 'raw'; end


% EEGLAB style channel locations (needed for FORCe, topoplots)
load('chanlocs16.mat');chanlocs = chanlocs16;

%% Libraries to include
addpath(genpath('./biosig/')); % Biosig toolbox for loading GDF files
addpath(genpath('./FORCe')); % Artifact removal as pre-processing and potentially criterion for data rejection

%% Input/output paths (EDIT THESE FOR YOUR OWN WORKSTATION)
RawDataPath = 'E:\Data\PPS_CHUV_sorted\'; 
SaveOutPath = 'C:\Users\sp19284\tmpdata\ppschuv\';

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
SubDir = dir(RawDataPath);
SubDir = SubDir(3:end); % Get rid of directories './', '../'
isd = [SubDir(:).isdir]; % Filter out any files in the same directory
SubDir = SubDir(isd);

for subject = 1:length(SubDir)
    
    % Find session folders in each subject folder. Again, the convention is
    % that each subject folder will contain one or more session folders
    % whose name is the date of recording as YYYMMDD
    Sub = SubDir(subject).name;
    SubSes = dir([RawDataPath '/' Sub]);
    SubSes = SubSes(3:end);
    isd = [SubSes(:).isdir];
    SubSes = SubSes(isd);
    
    % Prepare output file directory
    if(~exist([SaveOutPath '/' cleandir '/' Sub],'dir'))
        % Create subject's folder
        mkdir([SaveOutPath '/' cleandir],Sub);
        mkdir([SaveOutPath '/' cleandir '/' Sub],'excluded');
    end

    % Process all sessions
    for ses=1:length(SubSes)
        SesName = SubSes(ses).name;
   
        % Find GDF files in the sessino folder
        GDFFiles = dir([RawDataPath '/' Sub '/' SesName '/*.gdf']);
            
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
            
            if( (exist([SaveOutPath '/' cleandir '/' Sub '/' GDFName(1:end-4) '.mat'],'file') == 0) && (exist([SaveOutPath '/' cleandir '/' Sub '/'  '/excluded/' GDFName(1:end-4) '.mat'],'file') == 0))
                RunOutput = preanalyzePPS(GDFPath, doclean, chanlocs);
                if(RunOutput.fine == 1)
                    save([SaveOutPath '/' cleandir '/' Sub '/' GDFName(1:end-4) '.mat'],'RunOutput');
                else
                    % Save excluded dummy mat file
                    save([SaveOutPath '/' cleandir '/' Sub '/excluded/' GDFName(1:end-4) '.mat'],'RunOutput');
                    continue;
                end
            else
                if(exist([SaveOutPath '/' cleandir '/' Sub '/' GDFName(1:end-4) '.mat'],'file') == 2)
                    load([SaveOutPath '/' cleandir '/' Sub '/' GDFName(1:end-4) '.mat']);
                else
                    % Faulty run saved, skip it
                    continue;
                end
            end
            
            disp(['Subject: ' Sub ' , Session: ' num2str(ses) ' , Run: ' num2str(run)]);      
        end
    end
end