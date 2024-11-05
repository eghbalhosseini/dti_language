% probtrack results folder
clear all
close all
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';
%% Calculate temporal to frontal pairs 
% Left parcels 
threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
folders={   'probtrackX_results_IFG_top_20-AngG_top_20_TO_IFG_top_20-AngG_top_20_EX_IFGorb_top_20-MFG_top_20';
            'probtrackX_results_IFG_top_20-AntTemp_top_20_TO_IFG_top_20-AntTemp_top_20_EX_IFGorb_top_20-MFG_top_20';
            'probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_IFGorb_top_20-MFG_top_20';

            'probtrackX_results_IFGorb_top_20-AngG_top_20_TO_IFGorb_top_20-AngG_top_20_EX_IFG_top_20-MFG_top_20';
            'probtrackX_results_IFGorb_top_20-AntTemp_top_20_TO_IFGorb_top_20-AntTemp_top_20_EX_IFG_top_20-MFG_top_20';
            'probtrackX_results_IFGorb_top_20-PostTemp_top_20_TO_IFGorb_top_20-PostTemp_top_20_EX_IFG_top_20-MFG_top_20';
            
            'probtrackX_results_MFG_top_20-AngG_top_20_TO_MFG_top_20-AngG_top_20_EX_IFG_top_20-IFGorb_top_20';
            'probtrackX_results_MFG_top_20-AntTemp_top_20_TO_MFG_top_20-AntTemp_top_20_EX_IFG_top_20-IFGorb_top_20';
            'probtrackX_results_MFG_top_20-PostTemp_top_20_TO_MFG_top_20-PostTemp_top_20_EX_IFG_top_20-IFGorb_top_20'
    }
results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
subject_list=(cellfun(@(x) x.unique_subs,results,'uni',false));
subject_list=vertcat(subject_list{:});

arrayfun(@(x) assert(length(unique(subject_list(:,x)))==1), 1:size(subject_list,2))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

seeds={'AntTemp_top_20','PostTemp_top_20','AngG_top_20'};
targets={'IFG_top_20';'IFGorb_top_20';'MFG_top_20'};


% get activation and parcels for subjects
dti_activation_dir='/Users/eghbalhosseini/MyData/dti_language/lang_froi_activations_thr_20';
actvation_files=dir([dti_activation_dir,'/*LH_top_20_indti.nii.gz']);

subj_activation_id=cellfun(@(x) find(contains({actvation_files.name}',x)), train_subs,'uni',false);
subj_activation_files=arrayfun(@(x) [actvation_files(x).folder,'/',actvation_files(x).name], cell2mat(subj_activation_id),'uni',false)';
for idx = 1:length(train_subs)
    assert(contains(subj_activation_files{idx},train_subs{idx}))
end 

dti_parcels_dir='/Users/eghbalhosseini/MyData/dti_language/lang_glasser_parcels_thr_20';
parcel_files=dir([dti_parcels_dir,'/*LH_thr_20_indti.nii.gz']);

subj_parcel_id=cellfun(@(x) find(contains({parcel_files.name}',x)), train_subs,'uni',false);
subj_parcel_files=arrayfun(@(x) [parcel_files(x).folder,'/',parcel_files(x).name], cell2mat(subj_parcel_id),'uni',false)';
for idx = 1:length(train_subs)
    assert(contains(subj_parcel_files{idx},train_subs{idx}))
end 
% read FSLUT table 
FSLUT_table=readtable('/Users/eghbalhosseini/MyData/dti_language/FSLUT_lang_glasser/FSLUT_LH_lang_glasser_thr_20_ctab.txt',...
'NumHeaderLines',1);
seed_loc=cellfun(@(x) find(contains(FSLUT_table.Label,x)),seeds,'uni',false);
seed_ids=cellfun(@(x) FSLUT_table.x_No_(x), seed_loc);

target_loc=cellfun(@(x) find(contains(FSLUT_table.Label,x)),targets,'uni',false);
target_ids=cellfun(@(x) FSLUT_table.x_No_(x), target_loc);

s_act=nan*ones(length(subj_parcel_files),length(seed_ids));
t_act=nan*ones(length(subj_parcel_files),length(target_ids));
for kkk=1:length(subj_parcel_files)
    sub_parcel_image=double(niftiread(subj_parcel_files{kkk}));
    sub_activation_image=double(niftiread(subj_activation_files{kkk}));
    
    for k=1:length(seed_ids)
        seed_id=seed_ids(k);
        seed_parcel=sub_parcel_image==seed_id;
        seed_act=sub_activation_image(seed_parcel);
        s_act(kkk,k)=mean(seed_act);
    end 
    for kk=1:length(target_ids)
        target_id=target_ids(kk);
        target_parcel=sub_parcel_image==target_id;
        target_act=sub_activation_image(target_parcel);
        t_act(kkk,kk)=mean(target_act);
    end 
end 

s_t_corr=corr(s_act,t_act,'Type','Pearson');

% compute s_t weight 
seed_target_weights={};
for k=1:length(seeds)
    s_t_weights=[];
    for kk=1:length(targets)
        t_idx=contains(folders,[targets{kk},'-',seeds{k}]);
        s_t_con=cat(3,results{t_idx}.unique_RH_fdt_sum{ids});
        assert(sum(sum(contains(results{t_idx}.unique_RH_targets(:,ids),targets{kk})))==size(s_t_con,3));
        assert(sum(sum(contains(results{t_idx}.unique_RH_targets(:,ids),seeds{k})))==size(s_t_con,3));
        s_t_weights=[s_t_weights,squeeze([s_t_con(1,2,:)])]
        
    end 
    seed_target_weigthts{k,1}=s_t_weights;
end
%% for each subject compute the correlation between pairs of activations
