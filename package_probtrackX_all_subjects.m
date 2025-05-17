% probtrack results folder
clear all
close all
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';
threshold=20;
folders={['probtrackX_results_lang_glasser_thr_',num2str(threshold)]};


%% 
all_unique_subs={};
for folder =folders'
    fdt_files=dir(fullfile(probtrack_folder,folder{1},'*fdt_network.mat'));
    sub_ids=regexp({fdt_files(:).name},'sub\d+','match');
    sub_ids=cellfun(@(x) x(1) , sub_ids);
    unique_subs=unique(sub_ids);
    new_ids=find(~cellfun(@(x) contains(x,'sub197'),unique_subs));
    unique_subs=unique_subs(new_ids);
    LH_cell={};
    RH_cell={};
    for id_sub=1:length(unique_subs)
        sub=unique_subs{id_sub};
        overlap=find(strcmp(sub_ids,sub));
        assert(length(overlap)==2)
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
    % do some checks to make sure everything is properly aligned across subjects
    LH_targets=[LH_cell{:,2}];
    LH_fdt=[LH_cell(:,1)];
    LH_subs=[LH_cell(:,3)];
    % check that the labels are the same for the subjects in each row
    arrayfun(@(x) assert(length(unique(LH_targets(x,:)))==1), 1:size(LH_targets,1));
    
    RH_targets=[RH_cell{:,2}];
    RH_fdt=[RH_cell(:,1)];
    arrayfun(@(x) assert(length(unique(RH_targets(x,:)))==1), 1:size(RH_targets,1));
    RH_subs=[RH_cell(:,3)];
    assert(all(cellfun(@(x,y) strcmp(x,y), RH_subs,LH_subs)));
    
    % LH
    % make symmetric by summing up upper and lower halves
    temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, LH_fdt,'uni',false);
    temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false);
    temp_fdt_sum=cellfun(@(t) t./(.5*sum(sum(t))),temp_fdt,'uni',false);
    %for kk=1:length(temp_fdt)
    %    t=temp_fdt{kk};
    %    if sum(t)~=0, t=t./(.5*sum(sum(t)));else t=t;end ;
    %    temp_fdt_sum{kk,1}=t;
    %end 
    
    cellfun(@(x) assert(issymmetric(x)),temp_fdt_sum)
    LH_fdt_raw=LH_fdt;
    LH_fdt_sum=temp_fdt_sum;
    % RH
    temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, RH_fdt,'uni',false);
    temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false);
    temp_fdt_sum=cellfun(@(t) t./(.5*sum(sum(t))),temp_fdt,'uni',false);
    %for kk=1:length(temp_fdt)
    %    t=temp_fdt{kk};
    %    if sum(t)~=0, t=t./(.5*sum(sum(t)));else t=t;end ;
    %    temp_fdt_sum{kk,1}=t;
    %end 
    cellfun(@(x) assert(issymmetric(x)),temp_fdt)
    cellfun(@(x) assert(issymmetric(x)),temp_fdt_sum)
    RH_fdt_raw=RH_fdt;
    RH_fdt_sum=temp_fdt_sum;
    assert(all(cellfun(@(x,y) strcmp(x,y),LH_subs,unique_subs')))
    assert(all(cellfun(@(x,y) strcmp(x,y),RH_subs,unique_subs')))
    
    unique_dti=struct;
    unique_dti.unique_subs=unique_subs;
    unique_dti.unique_LH_targets=LH_targets;
    unique_dti.unique_RH_targets=RH_targets;
    unique_dti.unique_LH_fdt_raw=LH_fdt_raw;
    unique_dti.unique_LH_fdt_sum=LH_fdt_sum;
    unique_dti.unique_RH_fdt_raw=RH_fdt_raw;
    unique_dti.unique_RH_fdt_sum=RH_fdt_sum;

    save(fullfile(probtrack_folder,folder{1},'unique_subjects_pkg'),'unique_dti');
    
    
end


%% hypothesis 1. 

unique_dti=load(fullfile(probtrack_folder,['probtrackX_results_lang_glasser_thr_',num2str(threshold)],'unique_subjects_pkg'));
unique_dti=unique_dti.unique_dti;

unique_subs=unique_dti.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% unique_subs=unique_subs(ids);
num_subs=70;
[unique_subs,ids]=datasample(unique_subs,70,'Replace',false);

train_dti=struct;
train_dti.unique_subs=unique_dti.unique_subs(ids);
train_dti.unique_LH_fdt_raw=unique_dti.unique_LH_fdt_raw(ids);
train_dti.unique_LH_fdt_sum=unique_dti.unique_LH_fdt_sum(ids);

train_dti.unique_RH_fdt_raw=unique_dti.unique_RH_fdt_raw(ids);
train_dti.unique_RH_fdt_sum=unique_dti.unique_RH_fdt_sum(ids);

train_dti.unique_LH_targets=unique_dti.unique_LH_targets(:,ids);
train_dti.unique_RH_targets=unique_dti.unique_RH_targets(:,ids);

save(fullfile(probtrack_folder,folder{1},'train_subjects_pkg'),'train_dti');

%% 
titles={'n.s.';'-->';'<--'};
LH_temporal_target=[sprintf("LH_AntTemp_top_%d",threshold);sprintf("LH_PostTemp_top_%d",threshold)];
LH_frontal_target=[sprintf("LH_IFGorb_top_%d",threshold);sprintf("LH_IFG_top_%d",threshold);sprintf("LH_MFG_top_%d",threshold)];

LH_fdt=train_dti.unique_LH_fdt_sum;

[C,~,L_T]=intersect(LH_temporal_target,train_dti.unique_LH_targets,'stable');
[C,~,L_F]=intersect(LH_frontal_target,train_dti.unique_LH_targets,'stable');
% 
source_fdt=cellfun(@(t) t(L_T,:),LH_fdt,'uni',false);
target_fdt=cellfun(@(t) t(:,L_F),source_fdt,'uni',false);

%
for tmp_targ=1:length(LH_frontal_target)
   test=cell2mat(cellfun(@(t) t(:,tmp_targ)',target_fdt,'uni',false)); 
   non_zero=sum(test,2)~=0;
   test=test(non_zero,:);
   ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

%ax=subplot(1,1,1)
ax=axes('position',[.1,.1,.5,.5*11/8])

x=test(:,1);
y=test(:,2);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,50);
hscatter.Marker='o'
hscatter.MarkerFaceColor='r'
hscatter.MarkerEdgeColor='k'
hbar.FaceColor='r';
ax.YLim=[0,1.1*max([x;y])]
ax.XLim=[0,1.1*max([x;y])]
hbar.LineWidth=2;
%[h,p]=ttest(x,y);
%ahist.Title.String=titles{h+1}
    [h1,p1]=ttest(x,y,'Tail','right');
    [h2,p2]=ttest(x,y,'Tail','left');
    if h1
        ahist.Title.String=titles{2};
    elseif h2
        ahist.Title.String=titles{3};
    else
        ahist.Title.String=titles{1};
    end
    

ahist.Title.Rotation=-45;
ahist.Title.FontSize=15;

ahist.Title.Position=[0,max(ahist.YLim),0];
ax.XLabel.String=sprintf('%s --> \n %s',strrep(LH_temporal_target{1},'_',' '),strrep(LH_frontal_target{tmp_targ},'_',' '));
ax.YLabel.String=sprintf('%s --> \n %s',strrep(LH_temporal_target{2},'_',' '),strrep(LH_frontal_target{tmp_targ},'_',' '));
ax.FontSize=12;

dim = [.55 .1 .4 .2];
    str = sprintf('Connectivity from two temporal region \n %s (SUM , dropped subjects with zero: %d)',strrep(LH_frontal_target{tmp_targ},'_',' '),sum(non_zero==0));
    a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
    a.LineStyle='none'
    

    print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_all_tracts_temporal_to_',LH_frontal_target{tmp_targ},'_','_','_subs_',num2str(num_subs),'.pdf'));
    print(ff,'-painters','-dpng', strcat(analysis_path,'/','LH_all_tracts_temporal_to_',LH_frontal_target{tmp_targ},'_','_subs_',num2str(num_subs),'.png'));
   
end 
   
%% 
LH_lang_target=[sprintf("LH_AntTemp_top_%d",threshold);
                sprintf("LH_PostTemp_top_%d",threshold);
                sprintf("LH_AngG_top_%d",threshold);
                sprintf("LH_IFGorb_top_%d",threshold);
                sprintf("LH_IFG_top_%d",threshold);
                sprintf("LH_MFG_top_%d",threshold)];


[C,~,L_T]=intersect(LH_lang_target,train_dti.unique_LH_targets,'stable');
LH_fdt=train_dti.unique_LH_fdt_sum;
source_fdt=cellfun(@(t) t(L_T,:),LH_fdt,'uni',false);
target_fdt=cellfun(@(t) t(:,L_T),source_fdt,'uni',false);

all_lang=cat(3,target_fdt{:});
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8];
ff.PaperOrientation='landscape';

ax=axes('position',[.14,.2,.3,.3*11/8])
colormap(inferno)
imagesc(log(mean(all_lang,3)))
originalSize2 = get(gca, 'Position')

ax1=colorbar(ax);
ax1.Position=[.45,.2,.02,.3*11/8];
ax1.Label.String = 'weight (log)';

ax.XTickLabel=cellfun(@(x) strrep(x,'_',' '),LH_lang_target,'uni',false)
ax.XTickLabelRotation=90;

ax.YTickLabel=cellfun(@(x) strrep(x,'_',' '),LH_lang_target,'uni',false)
ax.YTickLabelRotation=0;


line([0.5,6.5], [3.5 ,3.5], 'Color', 'w','linewidth',3);
line([3.5 ,3.5],[0.5,6.5], 'Color', 'w','linewidth',3);
% 
log_conn=log(mean(all_lang,3));

ax=axes('position',[.52,.7,.15,.15*11/8])
colormap(inferno)
imagesc(log_conn(1:3,4:6))
originalSize2 = get(gca, 'Position')

ax1=colorbar(ax);
ax1.Position=[.7,.7,.02,.15*11/8];
ax1.Label.String = 'weight (log)';

ax.XTick=1:3;
ax.XTickLabel=cellfun(@(x) strrep(x,'_',' '),LH_lang_target(4:6),'uni',false);
ax.XTickLabelRotation=90;

ax.YTick=1:3;
ax.YTickLabel=cellfun(@(x) strrep(x,'_',' '),LH_lang_target(1:3),'uni',false)
ax.YTickLabelRotation=0;

ax=axes('position',[.14,.78,.15,.15*11/8])
colormap(inferno)
imagesc(log_conn(1:3,1:3))
originalSize2 = get(gca, 'Position')

ax1=colorbar(ax);
ax1.Position=[.3,.78,.02,.15*11/8];
ax1.Label.String = 'weight (log)';

ax.XTick=1:3;
ax.XTickLabel=cellfun(@(x) strrep(x,'_',' '),LH_lang_target(1:3),'uni',false);
ax.XTickLabelRotation=90;
ax.XAxis.FontSize=10;

ax.YTick=1:3;
ax.YTickLabel=cellfun(@(x) strrep(x,'_',' '),LH_lang_target(1:3),'uni',false)
ax.YTickLabelRotation=0;
ax.YAxis.FontSize=10;

ax=axes('position',[.65,.2,.15,.15*11/8])
colormap(inferno)
imagesc(log_conn(4:6,4:6))
originalSize2 = get(gca, 'Position')

ax1=colorbar(ax);
ax1.Position=[.82,.2,.02,.15*11/8];
ax1.Label.String = 'weight (log)';

ax.XTick=1:3;
ax.XTickLabel=cellfun(@(x) strrep(x,'_',' '),LH_lang_target(4:6),'uni',false);
ax.XTickLabelRotation=90;

ax.YTick=1:3;
ax.YTickLabel=cellfun(@(x) strrep(x,'_',' '),LH_lang_target(4:6),'uni',false)
ax.YTickLabelRotation=0;

print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_all_tracts_temporal_to_frontal_thr_',num2str(threshold),'_','_subs_',num2str(num_subs),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','LH_all_tracts_temporal_to_frontal_thr_',num2str(threshold),'_subs_',num2str(num_subs),'.png'));

