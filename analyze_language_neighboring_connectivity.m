clear all;
close all;
threshold=20;
num_subs=70;
%num_subs=120;
w_type='sum';
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/';
path_directory=sprintf('probtrackX_paths_lang_glasser_thr_%d',threshold);
lang_glasser_directory=sprintf('lang_glasser_parcels_thr_%d',threshold);
% find files 
subject_paths=dir(fullfile(probtrack_folder,path_directory,'*.nii.gz'));
subject_lang_glasser=dir(fullfile(probtrack_folder,lang_glasser_directory,'*.nii.gz'));

probtrack_folder=sprintf('/Users/eghbalhosseini/MyData/dti_language/probtrackX_results_lang_glasser_thr_%d',threshold);
% get files 
fdt_files=dir(fullfile(probtrack_folder,'*fdt_network.mat'));
sub_ids=regexp({fdt_files(:).name},'sub\d+','match');
sub_ids=cellfun(@(x) x(1) , sub_ids);


% subselect subject with BOTH 
both_hemis=find(arrayfun(@(x) contains(subject_lang_glasser(x).name,'BOTH'),1:size(subject_lang_glasser,1)));
FSLUT_LH_=readtable('/Users/eghbalhosseini/MyData/dti_language/FSLUT_lang_glasser/FSLUT_LH_lang_glasser_thr_20_ctab.txt');
LH_temporal_target=[sprintf("LH_AntTemp_top_%d",threshold);sprintf("LH_PostTemp_top_%d",threshold)];
LH_temporal_bottom_target=[sprintf("LH_AntTemp_bottom_%d",threshold);sprintf("LH_PostTemp_bottom_%d",threshold)];
LH_frontal_target=[sprintf("LH_IFGorb_top_%d",threshold);sprintf("LH_IFG_top_%d",threshold);sprintf("LH_MFG_top_%d",threshold)];
LH_frontal_bottom_target=[sprintf("LH_IFGorb_bottom_%d",threshold);sprintf("LH_IFG_bottom_%d",threshold);sprintf("LH_MFG_bottom_%d",threshold)];
%% 
% extract number form 
subj_id={};
subj_temporal_frontal_connectivity={};
subj_temporal_neighbor_connectivity={};
subject_temporal_neighbor_labels={};
for k=1:length(both_hemis)
    V=niftiread(fullfile(subject_lang_glasser(both_hemis(k)).folder,subject_lang_glasser(both_hemis(k)).name));
    % for the same subject load connectivity pattern 
    sub_=regexp(subject_lang_glasser(both_hemis(k)).name,'sub\d+','match');
    overlap=find(contains(sub_ids,sub_));
    if length(overlap)==2
        subj_id=[subj_id;sub_];
    file_1=load(fullfile(fdt_files(overlap(1)).folder,fdt_files(overlap(1)).name),'fdt_st');
    file_1=file_1.fdt_st;
    assert(strcmp(file_1.hemi,'LH'));
    file_LH=file_1;
    temp_fdt=(triu(file_LH.fdt_mat)+transpose(tril(file_LH.fdt_mat)))/2;
    LH_fdt=temp_fdt+transpose(triu(temp_fdt));
    imagesc(LH_fdt)
    file_2=load(fullfile(fdt_files(overlap(2)).folder,fdt_files(overlap(2)).name),'fdt_st');
    file_2=file_2.fdt_st;
    assert(strcmp(file_2.hemi,'RH'));
    file_RH=file_2;
    temp_fdt=(triu(file_RH.fdt_mat)+transpose(tril(file_RH.fdt_mat)))/2;
    RH_fdt=temp_fdt+transpose(triu(temp_fdt));
    % find the index for temporal and frontal 
    LH_frontal_id=cellfun(@(x) FSLUT_LH_.Var1(find(contains(FSLUT_LH_.Var2,x))),LH_frontal_target,'uni',false);
    LH_temporal_id=cellfun(@(x) FSLUT_LH_.Var1(find(contains(FSLUT_LH_.Var2,x))),LH_temporal_target,'uni',false);
    [C,~,L_T]=intersect(LH_temporal_target,file_LH.targets,'stable');
    %source_id=LH_temporal_id{1};
    %    VV=V==source_id;
    %    sum(sum(sum(VV)));
    % get center of mass for all the parcels: 
    cms=[];
    for v_=FSLUT_LH_.Var1'
         VV=(V==v_);
         [cm] = tensor_center_of_mass(VV);
         cms=[cms;[v_,cm]];
     end 
    cms_cords=cms(:,2:end);
    cms_labels=cms(:,1);
    region_to_region_dist=pdist2(cms_cords,cms_cords);
    % find targets close to frontal regions:
    frontal_connectivity={};
    neighbor_connectivity={};
    neighbor_labels={};
    for kk=1:length(LH_frontal_id)
        source_id=find(cms_labels==LH_frontal_id{kk});
        [~,srt_id]=sort(region_to_region_dist(:,source_id));
        neigbors=FSLUT_LH_.Var2(srt_id);
        % find and drop LH_frontal_targets
        [C,~,L_t]=intersect(LH_frontal_target,neigbors,'stable');
        [C,~,L_b]=intersect(LH_frontal_bottom_target,neigbors,'stable');
        neigbors(horzcat(L_t,L_b))=[];
        %neigbors_index=FSLUT_LH_.Var1(srt_id);
        % find where they intersect 
        [C,~,L_neighbor]=intersect(neigbors(1:4),file_LH.targets,'stable');
        source_fdt=LH_fdt(L_T,:);
        neighbor_fdt=source_fdt(:,L_neighbor);
        neighbor_label=neigbors(1:4)';
        % 
        [C,~,L_frontal]=intersect(LH_frontal_target(kk),file_LH.targets,'stable');
        frontal_lang_fdt=source_fdt(:,L_frontal);
        frontal_connectivity=[frontal_connectivity;frontal_lang_fdt];
        neighbor_connectivity=[neighbor_connectivity;neighbor_fdt];
        neighbor_labels=[neighbor_labels;neighbor_label];
    end
    subj_temporal_frontal_connectivity=[subj_temporal_frontal_connectivity,frontal_connectivity];
    subj_temporal_neighbor_connectivity=[subj_temporal_neighbor_connectivity,neighbor_connectivity];
    subject_temporal_neighbor_labels=[subject_temporal_neighbor_labels,neighbor_labels];
    end 
end 


%% 
rng(1)
[train_subs,ids]=datasample(subj_id,num_subs,'Replace',false);
% select training data 
train_temporal_frontal=subj_temporal_frontal_connectivity(:,ids);
train_temporal_neighbor_connectivity=subj_temporal_neighbor_connectivity(:,ids);




ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
ax=axes('position',[.1,.1,.2,.2*pa_ratio]);
% find ant_temporal to all 3 frontal areas 
x=cellfun(@(x) x(1,1),train_temporal_frontal);
% find ant_temopral to neigboring to 3 frontal 
x_n=cellfun(@(x) x(1,:),train_temporal_neighbor_connectivity,'uni',false);
% plot from an_temp to LH_IFGorb and compare to neighbors of IFG orb 
t=1;
source=x(t,:);
neighbors=cell2mat(x_n(t,:)');
s=bar(0,mean(source));
hold on ;
er=errorbar(0,mean(source),std(source)/sqrt(length(source)),std(source)/sqrt(length(source)));
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
n=bar([1:size(neighbors,2)],mean(neighbors,1));
er=errorbar([1:size(neighbors,2)],mean(neighbors,1),std(neighbors,0,1)/sqrt(length(source)),std(neighbors,0,1)/sqrt(length(source)));
er.Color = [0 0 0];                            
er.LineStyle = 'none';  

ax=axes('position',[.35,.1,.2,.2*pa_ratio]);

t=2;
source=x(t,:);
neighbors=cell2mat(x_n(t,:)');
s=bar(0,mean(source));
hold on ;
er=errorbar(0,mean(source),std(source)/sqrt(length(source)),std(source)/sqrt(length(source)));
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
n=bar([1:size(neighbors,2)],mean(neighbors,1));
er=errorbar([1:size(neighbors,2)],mean(neighbors,1),std(neighbors,0,1)/sqrt(length(source)),std(neighbors,0,1)/sqrt(length(source)));
er.Color = [0 0 0];  
er.LineStyle = 'none'; 

ax=axes('position',[.6,.1,.2,.2*pa_ratio]);

t=3;
source=x(t,:);
neighbors=cell2mat(x_n(t,:)');
s=bar(0,mean(source));
hold on ;
er=errorbar(0,mean(source),std(source)/sqrt(length(source)),std(source)/sqrt(length(source)));
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
n=bar([1:size(neighbors,2)],mean(neighbors,1));
er=errorbar([1:size(neighbors,2)],mean(neighbors,1),std(neighbors,0,1)/sqrt(length(source)),std(neighbors,0,1)/sqrt(length(source)));
er.Color = [0 0 0];  
er.LineStyle = 'none'; 



ax=axes('position',[.1,.4,.2,.2*pa_ratio]);
% find ant_temporal to all 3 frontal areas 
x=cellfun(@(x) x(2,1),train_temporal_frontal);
% find ant_temopral to neigboring to 3 frontal 
x_n=cellfun(@(x) x(2,:),train_temporal_neighbor_connectivity,'uni',false);
% plot from an_temp to LH_IFGorb and compare to neighbors of IFG orb 
t=1;
source=x(t,:);
neighbors=cell2mat(x_n(t,:)');
s=bar(0,mean(source));
hold on ;
er=errorbar(0,mean(source),std(source)/sqrt(length(source)),std(source)/sqrt(length(source)));
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
n=bar([1:size(neighbors,2)],mean(neighbors,1));
er=errorbar([1:size(neighbors,2)],mean(neighbors,1),std(neighbors,0,1)/sqrt(length(source)),std(neighbors,0,1)/sqrt(length(source)));
er.Color = [0 0 0];                            
er.LineStyle = 'none';  

ax=axes('position',[.35,.4,.2,.2*pa_ratio]);

t=2;
source=x(t,:);
neighbors=cell2mat(x_n(t,:)');
s=bar(0,mean(source));
hold on ;
er=errorbar(0,mean(source),std(source)/sqrt(length(source)),std(source)/sqrt(length(source)));
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
n=bar([1:size(neighbors,2)],mean(neighbors,1));
er=errorbar([1:size(neighbors,2)],mean(neighbors,1),std(neighbors,0,1)/sqrt(length(source)),std(neighbors,0,1)/sqrt(length(source)));
er.Color = [0 0 0];  
er.LineStyle = 'none'; 

ax=axes('position',[.6,.4,.2,.2*pa_ratio]);

t=3;
source=x(t,:);
neighbors=cell2mat(x_n(t,:)');
s=bar(0,mean(source));
hold on ;
er=errorbar(0,mean(source),std(source)/sqrt(length(source)),std(source)/sqrt(length(source)));
er.Color = [0 0 0];                            
er.LineStyle = 'none';  
n=bar([1:size(neighbors,2)],mean(neighbors,1));
er=errorbar([1:size(neighbors,2)],mean(neighbors,1),std(neighbors,0,1)/sqrt(length(source)),std(neighbors,0,1)/sqrt(length(source)));
er.Color = [0 0 0];  
er.LineStyle = 'none'; 

