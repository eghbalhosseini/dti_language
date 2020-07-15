function create_sub_file_scripts(varargin)
p=inputParser();
addParameter(p, 'csv_file', '/Users/eghbalhosseini/MyData/dti_language/DTI_Sessions_05242020_ev_eh - DTI_Sessions_05242020.csv');
addParameter(p, 'save_path', '~/MyData/dti_language/');
parse(p, varargin{:});
ops = p.Results;
sub_table=readtable(ops.csv_file);
sub_unq=unique(sub_table.UID);
sub_locs=cellfun(@(x) find(contains(sub_table.UID,x)),sub_unq,'uni',false);
sub_runs=cellfun(@(x) sub_table.SessionID(x),sub_locs,'uni',false);
% make file with unique runs 
fileID = fopen(strcat(ops.save_path,'/','sub_unique_run.txt'),'w');
arrayfun(@(x) fprintf(fileID,'%s , %s \n ',sub_unq{x},sub_runs{x}{1}),1:length(sub_unq),'UniformOutput',false);
fclose(fileID);
% make file with all runs 
run_format=cellfun(@(x) strcat('%s, ',repmat('%s,',1,length(x)),'\n'),sub_runs,'uni',false);
run_format=strrep(run_format,',\n','\n');

fileID1 = fopen(strcat(ops.save_path,'/','sub_individual_runs.txt'),'w');
arrayfun(@(x) fprintf(fileID1,run_format{x},string([sub_unq{x};sub_runs{x}(:)])),1:length(sub_unq),'UniformOutput',false);
fclose(fileID1);
% make a file with all runs and empty spaces for subject with fewer runs 
max_run=max(cellfun(@length,sub_runs));
run_format=cellfun(@(x) strcat('%s, ',repmat('%s,',1,max_run),'\n'),sub_runs,'uni',false);
run_format=strrep(run_format,',\n','\n');
mod_runs=arrayfun(@(x) [string([sub_unq{x};sub_runs{x}(:)]);repmat(blanks(1),max_run-length(sub_runs{x}))],1:length(sub_unq),'Uniformoutput',false);
fileID2 = fopen(strcat(ops.save_path,'/','sub_all_runs.txt'),'w');
arrayfun(@(x) fprintf(fileID2,run_format{x},mod_runs{x}),1:length(sub_unq),'UniformOutput',false);
fclose(fileID2);
% make a file for all the files (first column)
run_format=cellfun(@(x) strcat('%s, ','%s\n'),sub_runs,'uni',false);
fileID = fopen(strcat(ops.save_path,'/','sub_run.txt'),'w');
arrayfun(@(x) fprintf(fileID,run_format{x},sub_table.UID{x},sub_table.SessionID{x}),1:length(sub_unq),'UniformOutput',false);
fclose(fileID);

 
end 