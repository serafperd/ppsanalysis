clear;close all;clc;

%% Parametrization (add here any high-level or global params)

% Laplacian (cross) spatial filtering
lap = load('laplacian16.mat'); lap = lap.lap;

% EEGLAB style channel locations (needed for FORCe, topoplots)
load('chanlocs16.mat');chanlocs = chanlocs16;

%% Libraries to include
addpath(genpath('./biosig/')); % Biosig toolbox for loading GDF files
addpath(genpath('./FORCe')); % Artifact removal as pre-processing and potentially criterion for data rejection

%% Input/output paths (EDIT THESE FOR YOUR OWN WORKSTATION)
RawDataPath = 'D:\Data\CNBI_DATA\TOSORT_CNBI\CHUV\From_INBOX\CNBI_2017_AwarenessPPSCHUV_Perdikis\pps\'; 
SaveOutPath = 'C:\Users\seraf\Data\ppschuv\';

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
    if(~exist([SaveOutPath '/' Sub],'dir'))
        % Create subject's folder
        mkdir(SaveOutPath,Sub);
        mkdir([SaveOutPath '/' Sub],'excluded');
    end

    % Process all sessions
    for ses=1:length(SubSes)
        SesName = SubSes(ses).name;
   
        % Load log file
        LogFile = dir([RawDataPath '/' Sub '/' SesName '/*.log']);
        if(~isempty(LogFile))
            LogFile = LogFile.name;
            fid = fopen([RawDataPath '/' Sub '/' SesName '/' LogFile]);
            
            % Find runs in the log file
            run=0;
            while(true)
                % Read log line
                Line = fgetl(fid);
                if(Line == -1)
                    break;
                end
                
                GDFName = Line(1:strfind(Line, 'gdf')+2);
                GDFPath = [RawDataPath '/' Sub '/' SesName '/' GDFName];
              
                if(exist(GDFPath,'file')>0)
                    ff = dir(GDFPath);
                    if( (ff.bytes / (1024^2)) < 1.0 ) % Get rid of too small GDFs, probably failed attempts to start the loop or interrupted runs
                        continue;
                    end
                else
                    continue;
                end
                
                if( (exist([SaveOutPath '/' Sub '/' GDFName(1:end-4) '.mat'],'file') == 0) && (exist([SaveOutPath '/' Sub '/'  '/excluded/' GDFName(1:end-4) '.mat'],'file') == 0))
                    RunOutput = preanalyzePPS(GDFPath, lap, chanlocs);
                    if(RunOutput.fine == 1)
                        save([SaveOutPath Sub '/' GDFName(1:end-4) '.mat'],'RunOutput');
                    else
                        % Save excluded dummy mat file
                        save([SaveOutPath Sub '/excluded/' GDFName(1:end-4) '.mat'],'RunOutput');
                        continue;
                    end
                else
                    if(exist([SaveOutPath Sub '/' GDFName(1:end-4) '.mat'],'file') == 2)
                        load([SaveOutPath Sub '/' GDFName(1:end-4) '.mat']);
                    else
                        % Faulty run saved, skip it
                        continue;
                    end
                end
                
                disp(['Subject: ' Sub ' , Session: ' num2str(ses) ' , Run: ' num2str(run)]);
                run = run+1;                    
            end
            fclose(fid);
        else
            disp(['WARNING! No log file for session ' Sub ', ' SesName]);
        end
    end
end