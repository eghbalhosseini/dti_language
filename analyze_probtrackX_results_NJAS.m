% probtrack results folder
probtrack_folder='/om/user/ehoseini/MyData/dti_language/probtrackX_results';
% get files 
fdt_files=dir(fullfile(probtrack_folder,'*fdt_network.mat'));
sub_ids=regexp({fdt_files(:).name},'sub\d+','match');
sub_ids=cellfun(@(x) x(1) , sub_ids);
unique_subs=unique(sub_ids);

% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
train_subs=datasample(unique_subs,60,'Replace',false);

% get the files for these subjects 
LH_cell={};
RH_cell={};
for id_sub=1:length(train_subs)
    sub=train_subs{id_sub};
    overlap=find(strcmp(sub_ids,sub));
    assert(length(overlap)==2)
    file_1=load(fullfile(fdt_files(overlap(1)).folder,fdt_files(overlap(1)).name),'fdt_st');
    file_1=file_1.fdt_st;
    file_2=load(fullfile(fdt_files(overlap(2)).folder,fdt_files(overlap(2)).name),'fdt_st');
    file_2=file_2.fdt_st;
    
    for file_id=overlap
        file_dat=load(fullfile(fdt_files(file_id).folder,fdt_files(file_id).name),'fdt_st');
        file_dat=file_dat.fdt_st;
        switch file_dat.hemi
            case 'LH'
                LH_cell{id_sub,1}=file_dat.fdt_mat;
                LH_cell{id_sub,2}=file_dat.targets;
                LH_cell{id_sub,3}=file_dat.sub_id;
            case 'RH'
                RH_cell{id_sub,1}=file_dat.fdt_mat;
                RH_cell{id_sub,2}=file_dat.targets;
                RH_cell{id_sub,3}=file_dat.sub_id;
        end 
    end 
end 
%% do some checks to make sure everything is properly aligned across subjects
LH_targets=[LH_cell{:,2}];
LH_fdt=[LH_cell(:,1)];
arrayfun(@(x) assert(length(unique(LH_targets(x,:)))==1), 1:size(LH_targets,1));

RH_targets=[RH_cell{:,2}];
RH_fdt=[RH_cell(:,1)];
arrayfun(@(x) assert(length(unique(RH_targets(x,:)))==1), 1:size(RH_targets,1));

%% do some cleanning 
% LH 
% make symmetric by summing up upper and lower halves
temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, LH_fdt,'uni',false); 
temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false); 
% devide values by the sum of weights 
%temp_fdt=cellfun(@(t) t./(.5*sum(sum(t))),temp_fdt,'uni',false);
cellfun(@(x) assert(issymmetric(x)),temp_fdt)
LH_fdt=temp_fdt;
% RH 
temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, RH_fdt,'uni',false); 
temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false); 
% devide values by the sum of weights 
%temp_fdt=cellfun(@(t) t./(.5*sum(sum(t))),temp_fdt,'uni',false);
cellfun(@(x) assert(issymmetric(x)),temp_fdt)
RH_fdt=temp_fdt;

%% hypothesis 1. test difference in left and right connectivity for temporal to frontal connection 
LH_temporal_target=["LH_AntTemp_top_90";"LH_PostTemp_top_90";"LH_AngG_top_90"];
LH_frontal_target=["LH_IFGorb_top_90";"LH_IFG_top_90";"LH_MFG_top_90"];
% 
RH_temporal_target=["RH_AntTemp_top_90";"RH_PostTemp_top_90";"RH_AngG_top_90"];
RH_frontal_target=["RH_IFGorb_top_90";"RH_IFG_top_90";"RH_MFG_top_90"];
% 
[C,~,L_T]=intersect(LH_temporal_target,LH_targets,'stable');
[C,~,L_F]=intersect(LH_frontal_target,LH_targets,'stable');
t=LH_fdt{1};
source_fdt=cellfun(@(t) t(L_T,:),LH_fdt,'uni',false);
target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);
LH_temp_frontal=cell2mat(cellfun(@(x) sum(sum(x)), target_fdt,'uni',false));
% 
[C,~,R_T]=intersect(RH_temporal_target,RH_targets,'stable');
[C,~,R_F]=intersect(RH_frontal_target,RH_targets,'stable');
t=RH_fdt{1};
source_fdt=cellfun(@(t) t(R_T,:),RH_fdt,'uni',false);
target_fdt=cellfun(@(t) t(:,R_F),source_fdt,'uni',false);
RH_temp_frontal=cell2mat(cellfun(@(x) sum(sum(x)), target_fdt,'uni',false));

% 
figure;
hist(RH_temp_frontal)%,(LH_temp_frontal))
hold on 
hist(LH_temp_frontal)

[a,b]=ttest2(LH_temp_frontal,RH_temp_frontal,'Tail','lef')
