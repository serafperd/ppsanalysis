function [CRSR_Total, CRSR_Diagnosis, CRSR_Motor, CRSR_Auditory, CRSR_Visual, CRSR_Arousal, ...
    CRSR_Verbal, CRSR_Communication, MBT_Diagnosis_Original] = ...
    getClinicalScores(SubjectID, SessionDate, ClinicalDataTable)
% Function to return the clinical/demographic data corresponding to a
% patient's PPS session (CRSR, diganosis, etc.)
%
% Inputs: 
%
% SubjectID: Subject ID as it appears in the GDF/mat file name
% SessionDate: Date of session of GDF/mat file as it appears in the filename,
% in format 'yyy.mm.dd' (i.e., '2019.03.23')
% ClinicalDataTable: The result of running readtable on the Excel file
% (matlab table variable representing the Excel sheet)
%
% Outputs
% As indicated by the names of the variables

if(nargin < 3)
    Path = 'D:\Data\ppsdata_full\'; %Replace with your own path to the clinical Excel file
    disp(['No data table specified, loading from default location']);
    ClinicalDataTable = readtable([Path '\PPS_79_clinical_data_06_07_2023.xlsx']);
end

% Locate sessions of specified patients
SubjectSessionInd = find(strcmp(ClinicalDataTable.Patient, SubjectID));

% Locate specific PPS session date
DatePPSNum = datenum(ClinicalDataTable.DatePPS);
DateGDFNum = datenum(SessionDate,'yyyy.mm.dd');
PPSSessionInd = find(DatePPSNum(SubjectSessionInd) == DateGDFNum);

if(isempty(PPSSessionInd))
    
    disp(['Warning! There is no clinical entry for this date and subject.']);
    DiffDates = DatePPSNum(SubjectSessionInd) - datenum(SessionDate,'yyyy.mm.dd');
    [~, minInd] = min(abs(DiffDates));
    SignDiff = DiffDates(minInd);
    if(SignDiff < 0)
        disp(['The closest date for this subject is ' num2str(abs(DiffDates(minInd))) ' day(s) ahead of the date appearing in the GDF file name.']);
    else
        disp(['The closest date for this subject is ' num2str(abs(DiffDates(minInd))) ' day(s) later than the date appearing in the GDF file name.']);
    end
    FinalEntryInd = SubjectSessionInd(minInd);
else
    FinalEntryInd = SubjectSessionInd(PPSSessionInd);

end


CRSR_Total = ClinicalDataTable.CRS_RAtAssessment(FinalEntryInd);
CRSR_Auditory = ClinicalDataTable.CRS_RAuditorySubscaleScore(FinalEntryInd);
CRSR_Arousal = ClinicalDataTable.CRS_RArousalSubscaleScore(FinalEntryInd);
CRSR_Visual = ClinicalDataTable.CRS_RVisualSubscaleScore(FinalEntryInd);
CRSR_Motor = ClinicalDataTable.CRS_RMotorSubscaleScore(FinalEntryInd);
CRSR_Verbal = ClinicalDataTable.CRS_RVerbalSubscaleScore(FinalEntryInd);
CRSR_Communication = ClinicalDataTable.CRS_RCommunicationSubscaleScore(FinalEntryInd);
CRSR_Diagnosis = ClinicalDataTable.ClassificationPerCRS_R{FinalEntryInd}; % To convert form categorial to numeric based on a system to be decided    
MBT_Diagnosis_Original = ClinicalDataTable.CMDAccordingToInitialMBTAcessment_1_CMD_{FinalEntryInd};