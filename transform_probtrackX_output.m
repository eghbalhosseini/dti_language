function output=transform_probtrackX_output(varargin)
p=inputParser();
addParameter(p, 'file_id', '');
addParameter(p, 'target_mask_file', '');
addParameter(p, 'save_dir', '');
addParameter(p, 'hemi', '');
parse(p, varargin{:});
ops = p.Results;
A_str=readlines(ops.file_id);
target_str=readlines(ops.target_mask_file);
assert(length(target_str)==length(A_str));
% drop empty lines 
if any(cellfun(@isempty,A_str))
    line_ids=find(cellfun(@isempty,A_str));
    fprintf('found %d empty lines \n',length(line_ids));
    % make sure all the empty lines are not pointing to anything 
    for idx=1:length(line_ids)
        line_id=line_ids(idx);
        assert((target_str(line_id)==""));
    end 
    A_str(line_ids)=[];
    target_str(line_ids)=[];
end  
assert(length(target_str)==length(A_str));
% read values 
A_num=[];
for k=1:size(A_str,1)
    A_num=[A_num;str2num(A_str(k,:))];
end
assert(size(A_num,1)==size(A_num,2))
% read targets 
[A,B]=fileparts(target_str);
B=erase(B,'.nii');
if ~isempty(unique(cell2mat((strfind(B,'LH_')))))
    hemi='LH';
    assert(length(unique(cell2mat((strfind(B,'LH_'))))==1));
elseif ~isempty(unique(cell2mat((strfind(B,'RH_')))))
    hemi='RH';
    assert(length(unique(cell2mat((strfind(B,'RH_'))))==1));
end 
assert(hemi==ops.hemi);
sub_id=regexp(A(1),'sub\d+','match');
fdt_st=struct;
fdt_st.sub_id=sub_id;
fdt_st.targets=B;
fdt_st.fdt_mat=A_num;
fdt_st.hemi=hemi;
save(ops.save_dir,'fdt_st');
fprintf('saved file in %s', ops.save_dir);
end 
 