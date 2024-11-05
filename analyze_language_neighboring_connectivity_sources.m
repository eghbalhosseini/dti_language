clear all;
close all;
threshold=20;
num_subs=70;
%num_subs=125;
left_out=false;
w_type='sum';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';
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
LH_temporal_target=[sprintf("LH_AntTemp_top_%d",threshold);sprintf("LH_PostTemp_top_%d",threshold);sprintf("LH_AngG_top_%d",threshold)];
LH_temporal_bottom_target=[sprintf("LH_AntTemp_bottom_%d",threshold);sprintf("LH_PostTemp_bottom_%d",threshold);sprintf("LH_AngG_bottom_%d",threshold)];
LH_frontal_target=[sprintf("LH_IFGorb_top_%d",threshold);sprintf("LH_IFG_top_%d",threshold);sprintf("LH_MFG_top_%d",threshold)];
LH_frontal_bottom_target=[sprintf("LH_IFGorb_bottom_%d",threshold);sprintf("LH_IFG_bottom_%d",threshold);sprintf("LH_MFG_bottom_%d",threshold)];

LH_frontal_id=cellfun(@(x) FSLUT_LH_.Var1(find(contains(FSLUT_LH_.Var2,x))),LH_frontal_target,'uni',false);
LH_temporal_id=cellfun(@(x) FSLUT_LH_.Var1(find(contains(FSLUT_LH_.Var2,x))),LH_temporal_target,'uni',false);
%% 
% extract number form
num_neighbors=6;
subj_id={};
subj_temporal_frontal_connectivity={};
subject_temporal_neighbor_size={};
subject_temporal_neighbor_labels={};
subject_full_connectivity={};
pbar=ProgressBar(length(both_hemis), ...
            'Title', 'Permutations');
            
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
        file_2=load(fullfile(fdt_files(overlap(2)).folder,fdt_files(overlap(2)).name),'fdt_st');
        file_2=file_2.fdt_st;
        assert(strcmp(file_2.hemi,'RH'));
        file_RH=file_2;
        temp_fdt=(triu(file_RH.fdt_mat)+transpose(tril(file_RH.fdt_mat)))/2;
        RH_fdt=temp_fdt+transpose(triu(temp_fdt));
        % find the index for temporal and frontal
        
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
        area_sizes={};
        for kk=1:length(LH_temporal_id)
            source_id=find(cms_labels==LH_temporal_id{kk});
            [~,srt_id]=sort(region_to_region_dist(:,source_id));
            neigbors=FSLUT_LH_.Var2(srt_id);
            neigbor_ids=FSLUT_LH_.Var1(srt_id);
            % find and drop LH_frontal_targets
            [~,~,L_t]=intersect(LH_temporal_target,neigbors,'stable');
            [~,~,L_b]=intersect(LH_temporal_bottom_target,neigbors,'stable');
            neigbors(horzcat(L_t,L_b))=[];
            neigbor_ids(horzcat(L_t,L_b))=[];
            %neigbors_index=FSLUT_LH_.Var1(srt_id);
            % find where they intersect
            [~,~,L_neighbor]=intersect(neigbors(1:num_neighbors),file_LH.targets,'stable');
            source_fdt=LH_fdt(L_T(kk),:);
            neighbor_fdt=LH_fdt(L_neighbor,:);
            neighbor_label=neigbors(1:num_neighbors);
            %
            [C,~,L_frontal]=intersect(LH_frontal_target,file_LH.targets,'stable');
            frontal_lang_fdt=source_fdt(:,L_frontal);
            frontal_neigbor_fdt=neighbor_fdt(:,L_frontal);
            % get size of areas to normalize
            area_size=arrayfun(@(x) sum(sum(sum(V==x))),neigbor_ids(1:num_neighbors));
            source_size=sum(sum(sum(V==LH_temporal_id{kk})));
            % combine them so that the first item is the source
            frontal_all_fdt=vertcat(frontal_lang_fdt,frontal_neigbor_fdt);
            frontal_all_area_size=vertcat(source_size,area_size);
            frontal_connectivity{kk}=frontal_all_fdt;
            neighbor_labels{kk}=vertcat(LH_temporal_target(kk),neighbor_label);
            area_sizes{kk}=frontal_all_area_size;
        end
        subj_temporal_frontal_connectivity=[subj_temporal_frontal_connectivity;frontal_connectivity];
        subject_temporal_neighbor_labels=[subject_temporal_neighbor_labels;neighbor_labels];
        subject_temporal_neighbor_size = [subject_temporal_neighbor_size;area_sizes];
        subject_full_connectivity=[subject_full_connectivity;{LH_fdt,RH_fdt}];
        pbar(1,[],[])
    end
end
pbar.release();

%% 
rng(1)
[train_subs,ids]=datasample(subj_id,num_subs,'Replace',false);

if left_out
   leftout_subs=setdiff(subj_id,train_subs);
   ids=cellfun(@(x) find(contains(subj_id,x)), leftout_subs);
   train_subs=leftout_subs;
end 

% select training data 
train_temporal_frontal=subj_temporal_frontal_connectivity(ids,:);
train_temporal_neighbor_label=subject_temporal_neighbor_labels(ids,:);
train_temporal_neighbor_size=subject_temporal_neighbor_size(ids,:);
train_LH_connectivity=subject_full_connectivity(ids,1);
train_RH_connectivity=subject_full_connectivity(ids,2);


xx=cat(2,train_temporal_neighbor_label{:,1});
x_uniq = unique(xx);

x_counts=cellfun(@(x) sum(sum(contains(xx,x))),x_uniq);
[~,srt_idx]=sort(x_counts);
sorted_label=x_uniq(flipud(srt_idx));
sorted_counts=x_counts(flipud(srt_idx));
x_all=train_temporal_frontal(:,1);
label_all=train_temporal_neighbor_label(:,1);
% for each label find the subject that have the label and combine them 
xx_per_label={};
for sort_l=sorted_label'
    included_subs=find(cell2mat(cellfun(@(x) sum(contains(x,sort_l))>0,label_all,'uni',false)));
    xx_subs=x_all(included_subs);
    locations=arrayfun(@(y) find(contains(xx(:,y),sort_l)),included_subs,'uni',false);
    values=cell2mat(cellfun(@(y,z) y(z,:),xx_subs,locations,'uni',false));
    % append with nan
    values=vertcat(values,nan*ones(num_subs-size(values,1),size(values,2)));
    xx_per_label=[xx_per_label,values];
end 

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
ax=axes('position',[.2,.1,.15,.15*pa_ratio]);

x_all_labels=cat(3,xx_per_label{1:3});
x_labels=sorted_label(1:3);
find(contains(x_labels,LH_temporal_target{1}))
swapidx=[1,find(contains(x_labels,LH_temporal_target{1}))];
x_labels(swapidx) = x_labels(fliplr(swapidx));
x=squeeze(x_all_labels(:,1,:))';

x(swapidx,:) = x(fliplr(swapidx),:);
x=flipud(x);
x_labels=flipud(x_labels);
n=barh([1:size(x,1)],nanmean(x,2),.75,'facecolor','flat','linewidth',2);
n.CData=([1,1,1;1,1,1;1,0,0]);

n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x,2),[1:size(x,1)],nanstd(x,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);

ax.YTickLabel=cellfun(@(x) strrep(x,'_',' '),x_labels,'uni',false);
ax.XLim=ceil(ax.XLim);
ax.YLim=[.5,3.5];
ax.XTick=ax.XLim;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{1},'_',' ');
%ax.Title.FontSize=10;

ax=axes('position',[.38,.1,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,2,:))';
x(swapidx,:) = x(fliplr(swapidx),:);
x=flipud(x);
n=barh([1:size(x,1)],nanmean(x,2),.75,'facecolor','flat','linewidth',2);
n.CData=([1,1,1;1,1,1;1,0,0]);
n.BaseLine.LineStyle='none'
hold on 
er=errorbar(nanmean(x,2),[1:size(x,1)],nanstd(x,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.XLim=ceil(ax.XLim);
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YLim=[.5,3.5];
ax.YTick=[];
ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{2},'_',' ');
%ax.Title.FontSize=10;


ax=axes('position',[.56,.1,.15,.15*pa_ratio]);

x=squeeze(x_all_labels(:,3,:))';
x(swapidx,:) = x(fliplr(swapidx),:);
x=flipud(x);
n=barh([1:size(x,1)],nanmean(x,2),.75,'facecolor','flat','linewidth',2);
n.CData=([1,1,1;1,1,1;1,0,0]);
n.BaseLine.LineStyle='none'
hold on 
er=errorbar(nanmean(x,2),[1:size(x,1)],nanstd(x,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.XLim=[0,.1];%ceil(ax.XLim);
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YLim=[.5,3.5];
ax.YTick=[];
ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{3},'_',' ');
%ax.Title.FontSize=10;



%% 

xx=cat(2,train_temporal_neighbor_label{:,2});
x_uniq = unique(xx);

x_counts=cellfun(@(x) sum(sum(contains(xx,x))),x_uniq);
[~,srt_idx]=sort(x_counts);
sorted_label=x_uniq(flipud(srt_idx));
x_all=train_temporal_frontal(:,2);
label_all=train_temporal_neighbor_label(:,2);
% for each label find the subject that have the label and combine them 
xx_per_label={};
for sort_l=sorted_label'
    included_subs=find(cell2mat(cellfun(@(x) sum(contains(x,sort_l))>0,label_all,'uni',false)));
    xx_subs=x_all(included_subs);
    locations=arrayfun(@(y) find(contains(xx(:,y),sort_l)),included_subs,'uni',false);
    values=cell2mat(cellfun(@(y,z) y(z,:),xx_subs,locations,'uni',false));
    % append with nan
    values=vertcat(values,nan*ones(num_subs-size(values,1),size(values,2)));
    xx_per_label=[xx_per_label,values];
end 

x_all_labels=cat(3,xx_per_label{1:3});
x_labels=sorted_label(1:3);
swapidx=[1,find(contains(x_labels,LH_temporal_target{2}))];
x_labels(swapidx) = x_labels(fliplr(swapidx));

x=squeeze(x_all_labels(:,1,:))';
x(swapidx,:) = x(fliplr(swapidx),:);

x_labels=flipud(x_labels);
x=flipud(x);
ax=axes('position',[.2,.22,.15,.15*pa_ratio]);
n=barh([1:size(x,1)],nanmean(x,2),.75,'facecolor','flat','linewidth',2);
n.CData=([1,1,1;1,1,1;1,0,0]);
n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x,2),[1:size(x,1)],nanstd(x,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.YTickLabel=cellfun(@(x) strrep(x,'_',' '),x_labels,'uni',false);
ax.XLim=ceil(ax.XLim);
ax.YLim=[.5,3.5];
ax.XTick=ax.XLim;
ax=makeaxis_eh(ax);
ax.Title.String=strrep(LH_frontal_target{1},'_',' ');
ax.Title.FontSize=10;
ax.Title.FontWeight='normal';


ax=axes('position',[.38,.22,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,2,:))';
x(swapidx,:) = x(fliplr(swapidx),:);
x=flipud(x);
n=barh([1:size(x,1)],nanmean(x,2),.75,'facecolor','flat','linewidth',2);
n.CData=([1,1,1;1,1,1;1,0,0]);
n.BaseLine.LineStyle='none'
hold on 
er=errorbar(nanmean(x,2),[1:size(x,1)],nanstd(x,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.XLim=ceil(ax.XLim);
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YLim=[.5,3.5];
ax.YTick=[];
ax=makeaxis_eh(ax);
ax.Title.String=strrep(LH_frontal_target{2},'_',' ');
ax.Title.FontSize=10;
ax.Title.FontWeight='normal';



ax=axes('position',[.56,.22,.15,.15*pa_ratio]);

x=squeeze(x_all_labels(:,3,:))';
x(swapidx,:) = x(fliplr(swapidx),:);
x=flipud(x);
n=barh([1:size(x,1)],nanmean(x,2),.75,'facecolor','flat','linewidth',2);
n.CData=([1,1,1;1,1,1;1,0,0]);
n.BaseLine.LineStyle='none'
hold on 
er=errorbar(nanmean(x,2),[1:size(x,1)],nanstd(x,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.XLim=ceil(ax.XLim);
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YLim=[.5,3.5];
ax.YTick=[];
ax=makeaxis_eh(ax);
ax.Title.String=strrep(LH_frontal_target{3},'_',' ');
ax.Title.FontSize=10;
ax.Title.FontWeight='normal';
%% 
set(ff, 'Color', 'w');
user_string('ghostscript','/usr/local/Cellar/ghostscript@9.26/9.26_1/bin/gs')
export_fig(strcat(analysis_path,'/','figure_1_temporal_to_frontal_vs_neighbor_connectivity_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)), '-png'));
export_fig(strcat(analysis_path,'/','figure_1_temporal_to_frontal_vs_neighbor_connectivity_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.pdf'),'-pdf' ,'-painters')


%% do it using a ratio 
train_temporal_frontal=subj_temporal_frontal_connectivity(ids,:);
train_temporal_neighbor_label=subject_temporal_neighbor_labels(ids,:);
train_temporal_neighbor_size=subject_temporal_neighbor_size(ids,:);


xx=cat(2,train_temporal_neighbor_label{:,1});
x_uniq = unique(xx);

x_counts=cellfun(@(x) sum(sum(contains(xx,x))),x_uniq);
[~,srt_idx]=sort(x_counts);
sorted_label=x_uniq(flipud(srt_idx));
sorted_counts=x_counts(flipud(srt_idx));
x_all=train_temporal_frontal(:,1);
label_all=train_temporal_neighbor_label(:,1);
% for each label find the subject that have the label and combine them 
xx_per_label={};
for sort_l=sorted_label'
    included_subs=find(cell2mat(cellfun(@(x) sum(contains(x,sort_l))>0,label_all,'uni',false)));
    xx_subs=x_all(included_subs);
    locations=arrayfun(@(y) find(contains(xx(:,y),sort_l)),included_subs,'uni',false);
    values=cell2mat(cellfun(@(y,z) y(z,:),xx_subs,locations,'uni',false));
    % append with nan
    values=vertcat(values,nan*ones(num_subs-size(values,1),size(values,2)));
    xx_per_label=[xx_per_label,values];
end 

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
ax=axes('position',[.2,.1,.15,.15*pa_ratio]);
ylabels=["STSva";"STSda";"AntTemp"];
locations=cellfun(@(x) find(contains(sorted_label,x)), flipud([LH_temporal_target(1);"LH_STSda_ROI";"LH_STSva_ROI"]));
x_all=cat(3,xx_per_label{:});
x_all_labels=cat(3,xx_per_label{locations});
x_labels=sorted_label(locations);

x=squeeze(x_all_labels(:,1,:))';
x_all_1=squeeze(x_all(:,1,:))';
% get the row from matrix 
a=nansum(x,1);
a=nansum(x_all_1,1);
%x_labels=flipud(x_labels);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=([77, 166 , 255;0,89,179;255,0,0])/256;

n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);

ax.YTickLabel=ylabels;
ax.XLim=ceil(ax.XLim);
ax.XLim=[0,.4];
ax.YLim=[.5,3.5];
ax.XTick=ax.XLim;
ax.XLabel.String=["weight ratio (a.u.)" , "(mean / standard error)"];
ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{1},'_',' ');
%ax.Title.FontSize=10;

ax=axes('position',[.38,.1,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,2,:))';
x_all_1=squeeze(x_all(:,2,:))';
a=sum(x,1);
a=nansum(x_all_1,1);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=([77, 166 , 255;0,89,179;255,0,0])/256;
n.BaseLine.LineStyle='none'
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
%
ax.XLim=ceil(ax.XLim);
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YLim=[.5,3.5];
ax.YTick=[];
ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{2},'_',' ');
%ax.Title.FontSize=10;


ax=axes('position',[.56,.1,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,3,:))';
a=sum(x,1);
x_all_1=squeeze(x_all(:,3,:))';
a=nansum(x_all_1,1);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=([77, 166 , 255;0,89,179;255,0,0])/256;
n.BaseLine.LineStyle='none'
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.XLim=ceil(ax.XLim);
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YLim=[.5,3.5];
ax.YTick=[];
ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{3},'_',' ');
%ax.Title.FontSize=10;

 %% 
xx=cat(2,train_temporal_neighbor_label{:,2});
x_uniq = unique(xx);

x_counts=cellfun(@(x) sum(sum(contains(xx,x))),x_uniq);
[~,srt_idx]=sort(x_counts);
sorted_label=x_uniq(flipud(srt_idx));
x_all=train_temporal_frontal(:,2);
label_all=train_temporal_neighbor_label(:,2);
% for each label find the subject that have the label and combine them 
xx_per_label={};
for sort_l=sorted_label'
    included_subs=find(cell2mat(cellfun(@(x) sum(contains(x,sort_l))>0,label_all,'uni',false)));
    xx_subs=x_all(included_subs);
    locations=arrayfun(@(y) find(contains(xx(:,y),sort_l)),included_subs,'uni',false);
    values=cell2mat(cellfun(@(y,z) y(z,:),xx_subs,locations,'uni',false));
    % append with nan
    values=vertcat(values,nan*ones(num_subs-size(values,1),size(values,2)));
    xx_per_label=[xx_per_label,values];
end 


ylabels=["TPOJ1";"STV";"PostTemp"];
locations=cellfun(@(x) find(contains(sorted_label,x)), flipud([LH_temporal_target(2);"LH_STV_ROI";"LH_TPOJ1_ROI"]));
x_all=cat(3,xx_per_label{:});
x_all_labels=cat(3,xx_per_label{locations});
x_labels=sorted_label(locations);



ax=axes('position',[.2,.22,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,1,:))';
x_all_1=squeeze(x_all(:,1,:))';
a=nansum(x,1);
a=nansum(x_all_1,1);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=([77, 166 , 255;0,89,179;255,0,0])/256;
n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.YTickLabel=ylabels;
ax.XLim=ceil(ax.XLim);
ax.XLim=[0,.4];
ax.YLim=[.5,3.5];
ax.XTick=ax.XLim;
ax=makeaxis_eh(ax);
ax.Title.String=strrep(LH_frontal_target{1},'_',' ');
ax.Title.FontSize=10;
ax.Title.FontWeight='normal';


ax=axes('position',[.38,.22,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,2,:))';
x_all_1=squeeze(x_all(:,2,:))';
a=nansum(x,1);
a=nansum(x_all_1,1);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=([77, 166 , 255;0,89,179;255,0,0])/256;
n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.XLim=ceil(ax.XLim);
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YLim=[.5,3.5];
ax.YTick=[];
ax=makeaxis_eh(ax);
ax.Title.String=strrep(LH_frontal_target{2},'_',' ');
ax.Title.FontSize=10;
ax.Title.FontWeight='normal';

ax=axes('position',[.56,.22,.15,.15*pa_ratio]);

x=squeeze(x_all_labels(:,3,:))';
x_all_1=squeeze(x_all(:,3,:))';
a=nansum(x,1);
a=nansum(x_all_1,1);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=([77, 166 , 255;0,89,179;255,0,0])/256;
n.BaseLine.LineStyle='none';
hold on 

er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
ax.XLim=ceil(ax.XLim);
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YLim=[.5,3.5];
ax.YTick=[];
ax=makeaxis_eh(ax);
ax.Title.String=strrep(LH_frontal_target{3},'_',' ');
ax.Title.FontSize=10;
ax.Title.FontWeight='normal';
%% 
set(ff, 'Color', 'w');
user_string('ghostscript','/usr/local/Cellar/ghostscript@9.26/9.26_1/bin/gs')
export_fig(strcat(analysis_path,'/','figure_1_temporal_to_frontal_vs_neighbor_connectivity_ratio_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)), '-png'));
export_fig(strcat(analysis_path,'/','figure_1_temporal_to_frontal_vs_neighbor_connectivity_ratio_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(length(train_subs)),'.pdf'),'-pdf' ,'-painters')
%% 

train_temporal_frontal=subj_temporal_frontal_connectivity(ids,:);
train_temporal_neighbor_label=subject_temporal_neighbor_labels(ids,:);
train_temporal_neighbor_size=subject_temporal_neighbor_size(ids,:);


xx=cat(2,train_temporal_neighbor_label{:,1});
x_uniq = unique(xx);

x_counts=cellfun(@(x) sum(sum(contains(xx,x))),x_uniq);
[~,srt_idx]=sort(x_counts);
sorted_label=x_uniq(flipud(srt_idx));
sorted_counts=x_counts(flipud(srt_idx));
x_all=train_temporal_frontal(:,1);
label_all=train_temporal_neighbor_label(:,1);
% for each label find the subject that have the label and combine them 
xx_per_label={};
for sort_l=sorted_label'
    included_subs=find(cell2mat(cellfun(@(x) sum(contains(x,sort_l))>0,label_all,'uni',false)));
    xx_subs=x_all(included_subs);
    locations=arrayfun(@(y) find(contains(xx(:,y),sort_l)),included_subs,'uni',false);
    values=cell2mat(cellfun(@(y,z) y(z,:),xx_subs,locations,'uni',false));
    % append with nan
    values=vertcat(values,nan*ones(num_subs-size(values,1),size(values,2)));
    xx_per_label=[xx_per_label,values];
end 

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
ax=axes('position',[.2,.1,.15,.15*pa_ratio]);


locations=find(sorted_counts>70);
x_all=cat(3,xx_per_label{:});
x_all_labels=cat(3,xx_per_label{locations});
x_labels=sorted_label(locations);

x=squeeze(x_all_labels(:,1,:))';
x_all_1=squeeze(x_all(:,1,:))';
a=nansum(x_all_1,1);
swapidx=[1,find(contains(x_labels,LH_temporal_target{1}))];
x_labels(swapidx) = x_labels(fliplr(swapidx));
x(swapidx,:) = x(fliplr(swapidx),:);
a(swapidx) = a(fliplr(swapidx));
x_labels=flipud(x_labels);
labl=(cellfun(@(x) strsplit(erase(x,'LH_'),'_'), x_labels,'uni',false));
labl=cellfun(@(x) x{1} ,labl,'uni',false);
x=flipud(x);
a=flipud(a);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=vertcat(repmat([100,100,255],size(x,1)-1,1),[255,0,0])/256;

n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',1,'capsize',0);
ax.YTickLabel=labl;
ax.XLim=ceil(ax.XLim);
ax.XLim=[0,.4];
ax.YLim=[.5,size(x,1)+.5];
ax.XTick=ax.XLim;
ax.XLabel.String=["weight ratio (a.u.)" , "(mean / standard error)"];
ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{1},'_',' ');
%ax.Title.FontSize=10;

ax=axes('position',[.38,.1,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,2,:))';
x_all_1=squeeze(x_all(:,2,:))';
a=nansum(x_all_1,1);
x(swapidx,:) = x(fliplr(swapidx),:);
a(swapidx) = a(fliplr(swapidx));
x=flipud(x);
a=flipud(a);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=vertcat(repmat([100,100,255],size(x,1)-1,1),[255,0,0])/256;
n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
%
ax.XLim=[0,.4];
ax.XTick=ax.XLim;

ax.YLim=[.5,size(x,1)+.5];

ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';

ax.YTick=[];
ax.YLim=[.5,size(x,1)+.5];

ax=makeaxis_eh(ax);

ax=axes('position',[.56,.1,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,3,:))';
x_all_1=squeeze(x_all(:,3,:))';
a=nansum(x_all_1,1);


x(swapidx,:) = x(fliplr(swapidx),:);
a(swapidx) = a(fliplr(swapidx));
labl=(cellfun(@(x) strsplit(erase(x,'LH_'),'_'), x_labels,'uni',false));
labl=cellfun(@(x) x{1} ,labl,'uni',false);
x=flipud(x);
a=flipud(a);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=vertcat(repmat([100,100,255],size(x,1)-1,1),[255,0,0])/256;
n.BaseLine.LineStyle='none'
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
%
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YTick=[];
ax.YLim=[.5,size(x,1)+.5];

ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{2},'_',' ');
%ax.Title.FontSize=10;



%ax.Title.String=strrep(LH_frontal_target{2},'_',' ');
%ax.Title.FontSize=10;

%% 

train_temporal_frontal=subj_temporal_frontal_connectivity(ids,:);
train_temporal_neighbor_label=subject_temporal_neighbor_labels(ids,:);
train_temporal_neighbor_size=subject_temporal_neighbor_size(ids,:);


xx=cat(2,train_temporal_neighbor_label{:,2});
x_uniq = unique(xx);

x_counts=cellfun(@(x) sum(sum(contains(xx,x))),x_uniq);
[~,srt_idx]=sort(x_counts);
sorted_label=x_uniq(flipud(srt_idx));
sorted_counts=x_counts(flipud(srt_idx));
x_all=train_temporal_frontal(:,2);
label_all=train_temporal_neighbor_label(:,2);
% for each label find the subject that have the label and combine them 
xx_per_label={};
for sort_l=sorted_label'
    included_subs=find(cell2mat(cellfun(@(x) sum(contains(x,sort_l))>0,label_all,'uni',false)));
    xx_subs=x_all(included_subs);
    locations=arrayfun(@(y) find(contains(xx(:,y),sort_l)),included_subs,'uni',false);
    values=cell2mat(cellfun(@(y,z) y(z,:),xx_subs,locations,'uni',false));
    % append with nan
    values=vertcat(values,nan*ones(num_subs-size(values,1),size(values,2)));
    xx_per_label=[xx_per_label,values];
end 

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
ax=axes('position',[.2,.22,.15,.15*pa_ratio]);


locations=find(sorted_counts>70);
x_all=cat(3,xx_per_label{:});
x_all_labels=cat(3,xx_per_label{locations});
x_labels=sorted_label(locations);

x=squeeze(x_all_labels(:,1,:))';
x_all_1=squeeze(x_all(:,1,:))';
a=nansum(x_all_1,1);
swapidx=[1,find(contains(x_labels,LH_temporal_target{2}))];
x_labels(swapidx) = x_labels(fliplr(swapidx));
x(swapidx,:) = x(fliplr(swapidx),:);
a(swapidx) = a(fliplr(swapidx));
x_labels=flipud(x_labels);
labl=(cellfun(@(x) strsplit(erase(x,'LH_'),'_'), x_labels,'uni',false));
labl=cellfun(@(x) x{1} ,labl,'uni',false);
x=flipud(x);
a=flipud(a);


n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=vertcat(repmat([100,100,255],size(x,1)-1,1),[255,0,0])/256;

n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',1,'capsize',0);
ax.YTickLabel=labl;
ax.XLim=ceil(ax.XLim);
ax.XLim=[0,.4];
ax.YLim=[.5,size(x,1)+.5];
ax.XTick=ax.XLim;
ax.XLabel.String=["weight ratio (a.u.)" , "(mean / standard error)"];
ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{1},'_',' ');
%ax.Title.FontSize=10;

ax=axes('position',[.38,.22,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,2,:))';
x_all_1=squeeze(x_all(:,2,:))';
a=nansum(x_all_1,1);
x(swapidx,:) = x(fliplr(swapidx),:);
a(swapidx) = a(fliplr(swapidx));
x=flipud(x);
a=flipud(a);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=vertcat(repmat([100,100,255],size(x,1)-1,1),[255,0,0])/256;
n.BaseLine.LineStyle='none';
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
%
ax.XLim=[0,.4];
ax.XTick=ax.XLim;

ax.YLim=[.5,size(x,1)+.5];

ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';

ax.YTick=[];
ax.YLim=[.5,size(x,1)+.5];

ax=makeaxis_eh(ax);

ax=axes('position',[.56,.22,.15,.15*pa_ratio]);
x=squeeze(x_all_labels(:,3,:))';
x_all_1=squeeze(x_all(:,3,:))';
a=nansum(x_all_1,1);


x(swapidx,:) = x(fliplr(swapidx),:);
a(swapidx) = a(fliplr(swapidx));
labl=(cellfun(@(x) strsplit(erase(x,'LH_'),'_'), x_labels,'uni',false));
labl=cellfun(@(x) x{1} ,labl,'uni',false);
x=flipud(x);
a=flipud(a);

n=barh([1:size(x,1)],nanmean(x./a,2),.75,'facecolor','flat','linestyle','none');
n.CData=vertcat(repmat([100,100,255],size(x,1)-1,1),[255,0,0])/256;
n.BaseLine.LineStyle='none'
hold on 
er=errorbar(nanmean(x./a,2),[1:size(x,1)],nanstd(x./a,0,2)/sqrt(length(x)),'horizontal','linestyle','none','color','k','linewidth',2,'capsize',0);
%
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.XLim=[0,.4];
ax.XTick=ax.XLim;
ax.YAxis.Visible='off';
ax.YTick=[];
ax.YLim=[.5,size(x,1)+.5];

ax=makeaxis_eh(ax);
%ax.Title.String=strrep(LH_frontal_target{2},'_',' ');
%ax.Title.FontSize=10;



