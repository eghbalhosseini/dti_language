% probtrack results folder
clear all
close all
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';

threshold=10;
w_type='sum';
folders={   %sprintf('probtrackX_results_IFG_top_%d-AngG_top_%d_TO_IFG_top_%d-AngG_top_%d_EX_IFGorb_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFG_top_%d-AntTemp_top_%d_TO_IFG_top_%d-AntTemp_top_%d_EX_IFGorb_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_IFGorb_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            % 
            %sprintf('probtrackX_results_IFGorb_top_%d-AngG_top_%d_TO_IFGorb_top_%d-AngG_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_IFGorb_top_%d-PostTemp_top_%d_TO_IFGorb_top_%d-PostTemp_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            %
            %sprintf('probtrackX_results_MFG_top_%d-AngG_top_%d_TO_MFG_top_%d-AngG_top_%d_EX_IFG_top_%d-IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_MFG_top_%d-AntTemp_top_%d_TO_MFG_top_%d-AntTemp_top_%d_EX_IFG_top_%d-IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
            sprintf('probtrackX_results_MFG_top_%d-PostTemp_top_%d_TO_MFG_top_%d-PostTemp_top_%d_EX_IFG_top_%d-IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
    }


%% 
all_unique_subs={};
for folder =folders'
    fdt_files=dir(fullfile(probtrack_folder,folder{1},'*fdt_network.mat'));
    sub_ids=regexp({fdt_files(:).name},'sub\d+','match');
    sub_ids=cellfun(@(x) x(1) , sub_ids);
    unique_subs=unique(sub_ids);
    all_unique_subs=[all_unique_subs;unique_subs];
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
    temp_fdt_sum=temp_fdt;
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
    temp_fdt_sum=temp_fdt;
    %for kk=1:length(temp_fdt)
    %    t=temp_fdt{kk};
    %    if sum(t)~=0, t=t./(.5*sum(sum(t)));else t=t;end ;
    %    temp_fdt_sum{kk,1}=t;
    %end 
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
for kk=1:size(all_unique_subs,2)
    assert(size(unique(all_unique_subs(:,kk)),1)==1)
end 
% get files both LH and RH 



%% hypothesis 1. 
% Left hemisphere, post temp to IFG , vs AntTemp to IFGorb

titles={'n.s.';'-->';'<--'};
%folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
%    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 

folders={'probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_IFGorb_top_20-MFG_top_20';
         'probtrackX_results_IFGorb_top_20-AntTemp_top_20_TO_IFGorb_top_20-AntTemp_top_20_EX_IFG_top_20-MFG_top_20'
    }

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFG_Post=results{1}.unique_LH_targets(:,1);
IFGorb_Ant=results{2}.unique_LH_targets(:,1);
if strcmp(w_type,'sum')
    IFG_post_w=results{1}.unique_LH_fdt_sum(ids);
    IFGorb_Ant_w=results{2}.unique_LH_fdt_sum(ids);
else
    IFG_post_w=results{1}.unique_LH_fdt_raw(ids);
    IFGorb_Ant_w=results{2}.unique_LH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=axes('position',[.1,.1,.5,.5*11/8])
x=cellfun(@(x) x(1,2), IFGorb_Ant_w);
y=cellfun(@(x) x(1,2), IFG_post_w);
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFG_Post{1},'_',' '),strrep(IFG_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s --> \n %s',strrep(IFGorb_Ant{1},'_',' '),strrep(IFGorb_Ant{2},'_',' '));
ax.FontSize=12;
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
print(ff,'-dpng','-painters', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));
%% hypothesis 1. 
% Right hemisphere, post temp to IFG , vs AntTemp to IFGorbthreshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
%folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
%    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 

folders={'probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_IFGorb_top_20-MFG_top_20';
         'probtrackX_results_IFGorb_top_20-AntTemp_top_20_TO_IFGorb_top_20-AntTemp_top_20_EX_IFG_top_20-MFG_top_20'}

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFG_Post=results{1}.unique_RH_targets(:,1);
IFGorb_Ant=results{2}.unique_RH_targets(:,1);
if strcmp(w_type,'sum')
    IFG_post_w=results{1}.unique_RH_fdt_sum(ids);
    IFGorb_Ant_w=results{2}.unique_RH_fdt_sum(ids);
else
    IFG_post_w=results{1}.unique_RH_fdt_raw(ids);
    IFGorb_Ant_w=results{2}.unique_RH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=axes('position',[.1,.1,.5,.5*11/8])
x=cellfun(@(x) x(1,2), IFGorb_Ant_w);
y=cellfun(@(x) x(1,2), IFG_post_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,50);
hscatter.Marker='o'
hscatter.MarkerFaceColor=[51,153,255]/256;
hscatter.MarkerEdgeColor='k'
hbar.FaceColor=[51,153,255]/256;
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFG_Post{1},'_',' '),strrep(IFG_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s --> \n %s',strrep(IFGorb_Ant{1},'_',' '),strrep(IFGorb_Ant{2},'_',' '));
ax.FontSize=12;
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','RH_select_tracts_temporal_to_frontal_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
print(ff,'-dpng','-painters', strcat(analysis_path,'/','RH_select_tracts_temporal_to_frontal_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));



%% hypothesis 2. 
% Left hemisphere, post temp to IFG , vs postTemp to IFGorb

threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
%folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
%    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 

folders={'probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_IFGorb_top_20-MFG_top_20';
    'probtrackX_results_IFG_top_20-AntTemp_top_20_TO_IFG_top_20-AntTemp_top_20_EX_IFGorb_top_20-MFG_top_20'
         }

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFG_Post=results{1}.unique_LH_targets(:,1);
IFG_Ant=results{2}.unique_LH_targets(:,1);
if strcmp(w_type,'sum')
    IFG_post_w=results{1}.unique_LH_fdt_sum(ids);
    IFG_Ant_w=results{2}.unique_LH_fdt_sum(ids);
else
    IFG_post_w=results{1}.unique_LH_fdt_raw(ids);
    IFG_Ant_w=results{2}.unique_LH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=axes('position',[.1,.1,.5,.5*11/8])
x=cellfun(@(x) x(1,2), IFG_Ant_w);
y=cellfun(@(x) x(1,2), IFG_post_w);
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFG_Post{1},'_',' '),strrep(IFG_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s --> \n %s',strrep(IFG_Ant{1},'_',' '),strrep(IFG_Ant{2},'_',' '));
ax.FontSize=12;
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',IFG_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',IFG_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));

%% hypothesis 2. 
% Right hemisphere, post temp to IFG , vs postTemp to IFGorb

threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
%folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
%    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 

folders={'probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_IFGorb_top_20-MFG_top_20';
        'probtrackX_results_IFG_top_20-AntTemp_top_20_TO_IFG_top_20-AntTemp_top_20_EX_IFGorb_top_20-MFG_top_20'}

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFG_Post=results{1}.unique_RH_targets(:,1);
IFG_Ant=results{2}.unique_RH_targets(:,1);
if strcmp(w_type,'sum')
    IFG_post_w=results{1}.unique_RH_fdt_sum(ids);
    IFG_Ant_w=results{2}.unique_RH_fdt_sum(ids);
else
    IFG_post_w=results{1}.unique_RH_fdt_raw(ids);
    IFG_Ant_w=results{2}.unique_RH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=axes('position',[.1,.1,.5,.5*11/8])
x=cellfun(@(x) x(1,2), IFG_Ant_w);
y=cellfun(@(x) x(1,2), IFG_post_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,50);
hscatter.Marker='o'
hscatter.MarkerFaceColor=[51,153,255]/256;
hscatter.MarkerEdgeColor='k'
hbar.FaceColor=[51,153,255]/256;
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFG_Post{1},'_',' '),strrep(IFG_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s --> \n %s',strrep(IFG_Ant{1},'_',' '),strrep(IFG_Ant{2},'_',' '));
ax.FontSize=12;
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','RH_select_tracts_temporal_to_frontal_',IFG_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','RH_select_tracts_temporal_to_frontal_',IFG_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));




%% hypothesis 3. 
% Left hemisphere, AntTemp to IFG , vs AntTemp to IFGorb

threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
%folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
%    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 

folders={'probtrackX_results_IFGorb_top_20-PostTemp_top_20_TO_IFGorb_top_20-PostTemp_top_20_EX_IFG_top_20-MFG_top_20';
            'probtrackX_results_IFGorb_top_20-AntTemp_top_20_TO_IFGorb_top_20-AntTemp_top_20_EX_IFG_top_20-MFG_top_20'
            };
        
results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;

rng(1)
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFGorb_Post=results{1}.unique_LH_targets(:,1);
IFGorb_Ant=results{2}.unique_LH_targets(:,1);
if strcmp(w_type,'sum')
    IFGorb_post_w=results{1}.unique_LH_fdt_sum(ids);
    IFGorb_Ant_w=results{2}.unique_LH_fdt_sum(ids);
else
    IFGorb_post_w=results{1}.unique_LH_fdt_raw(ids);
    IFGorb_Ant_w=results{2}.unique_LH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=axes('position',[.1,.1,.5,.5*11/8])
x=cellfun(@(x) x(1,2), IFGorb_Ant_w);
y=cellfun(@(x) x(1,2), IFGorb_post_w);

%test=[x,y];
%non_zero=sum(test,2)~=0;
%test=test(non_zero,:);
%x=test(:,1);
%y=test(:,2);

[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,50);
hscatter.Marker='o'
hscatter.MarkerFaceColor='r';
hscatter.MarkerEdgeColor='k';
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFGorb_Post{1},'_',' '),strrep(IFGorb_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s -->  \n %s',strrep(IFGorb_Ant{1},'_',' '),strrep(IFGorb_Ant{2},'_',' '));
ax.FontSize=12;

% dim = [.55 .1 .4 .2];
%     str = sprintf('Connectivity from two temporal region \n %s (SUM , dropped subjects with zero: %d)',strrep(LH_frontal_target{tmp_targ},'_',' '),sum(non_zero==0));
%     a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
%     a.LineStyle='none'
% 
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',IFGorb_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',IFGorb_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));

%% hypothesis 3. 
% Right hemisphere, AntTemp to IFG , vs AntTemp to IFGorb

threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
%folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
%    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 

folders={'probtrackX_results_IFGorb_top_20-PostTemp_top_20_TO_IFGorb_top_20-PostTemp_top_20_EX_IFG_top_20-MFG_top_20';
            'probtrackX_results_IFGorb_top_20-AntTemp_top_20_TO_IFGorb_top_20-AntTemp_top_20_EX_IFG_top_20-MFG_top_20'
            };
        
results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;

rng(1)
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFGorb_Post=results{1}.unique_RH_targets(:,1);
IFGorb_Ant=results{2}.unique_RH_targets(:,1);
if strcmp(w_type,'sum')
    IFGorb_post_w=results{1}.unique_RH_fdt_sum(ids);
    IFGorb_Ant_w=results{2}.unique_RH_fdt_sum(ids);
else
    IFGorb_post_w=results{1}.unique_RH_fdt_raw(ids);
    IFGorb_Ant_w=results{2}.unique_RH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=axes('position',[.1,.1,.5,.5*11/8])
x=cellfun(@(x) x(1,2), IFGorb_Ant_w);
y=cellfun(@(x) x(1,2), IFGorb_post_w);

%test=[x,y];
%non_zero=sum(test,2)~=0;
%test=test(non_zero,:);
%x=test(:,1);
%y=test(:,2);

[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,50);
hscatter.Marker='o'
hscatter.MarkerFaceColor=[51,153,255]/256;
hscatter.MarkerEdgeColor='k';
hbar.FaceColor=[51,153,255]/256;
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFGorb_Post{1},'_',' '),strrep(IFGorb_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s -->  \n %s',strrep(IFGorb_Ant{1},'_',' '),strrep(IFGorb_Ant{2},'_',' '));
ax.FontSize=12;

% dim = [.55 .1 .4 .2];
%     str = sprintf('Connectivity from two temporal region \n %s (SUM , dropped subjects with zero: %d)',strrep(LH_frontal_target{tmp_targ},'_',' '),sum(non_zero==0));
%     a=annotation(ff,'textbox',dim,'String',str,'fontsize',14,'fontweight','bold');
%     a.LineStyle='none'
% 
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','RH_select_tracts_temporal_to_frontal_',IFGorb_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','RH_select_tracts_temporal_to_frontal_',IFGorb_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));


%% Hpyothesis 4
% Left hemisphere, PostTemp to MFG , vs AntTemp to MFG
threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
%folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
%    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 

folders={'probtrackX_results_MFG_top_20-PostTemp_top_20_TO_MFG_top_20-PostTemp_top_20_EX_IFG_top_20-IFGorb_top_20';
            'probtrackX_results_MFG_top_20-AntTemp_top_20_TO_MFG_top_20-AntTemp_top_20_EX_IFG_top_20-IFGorb_top_20'
         };

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFG_Post=results{1}.unique_LH_targets(:,1);
IFG_Ant=results{2}.unique_LH_targets(:,1);
if strcmp(w_type,'sum')
    IFG_post_w=results{1}.unique_LH_fdt_sum(ids);
    IFG_Ant_w=results{2}.unique_LH_fdt_sum(ids);
else
    IFG_post_w=results{1}.unique_LH_fdt_raw(ids);
    IFG_Ant_w=results{2}.unique_LH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=axes('position',[.1,.1,.5,.5*11/8])
x=cellfun(@(x) x(1,2), IFG_Ant_w);
y=cellfun(@(x) x(1,2), IFG_post_w);
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFG_Post{1},'_',' '),strrep(IFG_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s --> \n %s',strrep(IFG_Ant{1},'_',' '),strrep(IFG_Ant{2},'_',' '));
ax.FontSize=12;
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])
print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',IFG_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','LH_select_tracts_temporal_to_frontal_',IFG_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));

%% Hpyothesis 4
% Right hemisphere, PostTemp to MFG , vs AntTemp to MFG
threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
%folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold);
%    sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_MFG_top_%d',threshold,threshold,threshold,threshold,threshold)}; 

folders={'probtrackX_results_MFG_top_20-PostTemp_top_20_TO_MFG_top_20-PostTemp_top_20_EX_IFG_top_20-IFGorb_top_20';
            'probtrackX_results_MFG_top_20-AntTemp_top_20_TO_MFG_top_20-AntTemp_top_20_EX_IFG_top_20-IFGorb_top_20'
         };

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
% pick a random set of 60 subject 
rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

IFG_Post=results{1}.unique_RH_targets(:,1);
IFG_Ant=results{2}.unique_RH_targets(:,1);
if strcmp(w_type,'sum')
    IFG_post_w=results{1}.unique_RH_fdt_sum(ids);
    IFG_Ant_w=results{2}.unique_RH_fdt_sum(ids);
else
    IFG_post_w=results{1}.unique_RH_fdt_raw(ids);
    IFG_Ant_w=results{2}.unique_RH_fdt_raw(ids);
end 
% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=axes('position',[.1,.1,.5,.5*11/8])
x=cellfun(@(x) x(1,2), IFG_Ant_w);
y=cellfun(@(x) x(1,2), IFG_post_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,50);
hscatter.Marker='o'
hscatter.MarkerFaceColor=[51,153,255]/256;
hscatter.MarkerEdgeColor='k';
hbar.FaceColor=[51,153,255]/256;
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.YLabel.String=sprintf('%s --> \n %s',strrep(IFG_Post{1},'_',' '),strrep(IFG_Post{2},'_',' '));
ax.XLabel.String=sprintf('%s --> \n %s',strrep(IFG_Ant{1},'_',' '),strrep(IFG_Ant{2},'_',' '));
ax.FontSize=12;

print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','RH_select_tracts_temporal_to_frontal_',IFG_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','RH_select_tracts_temporal_to_frontal_',IFG_Post{1},'_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));


%% compare LH vs RH parcels 

rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=70;
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);


LH_IFG_Post=results{1}.unique_LH_targets(:,1);
RH_IFG_Post=results{1}.unique_RH_targets(:,1);
LH_IFGorb_Ant=results{2}.unique_LH_targets(:,1);
RH_IFGorb_Ant=results{2}.unique_RH_targets(:,1);
if strcmp(w_type,'sum')
    LH_IFG_post_w=results{1}.unique_LH_fdt_sum(ids);
    LH_IFGorb_Ant_w=results{2}.unique_LH_fdt_sum(ids);
    RH_IFG_post_w=results{1}.unique_RH_fdt_sum(ids);
    RH_IFGorb_Ant_w=results{2}.unique_RH_fdt_sum(ids);
end 


ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';

ax=subplot(1,1,1)
x=cellfun(@(x) x(1,2), RH_IFG_post_w);
y=cellfun(@(x) x(1,2), LH_IFG_post_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.XLabel.String=sprintf('%s --> \n %s',strrep(RH_IFG_Post{1},'_',' '),strrep(RH_IFG_Post{2},'_',' '));
ax.YLabel.String=sprintf('%s --> \n %s',strrep(LH_IFG_Post{1},'_',' '),strrep(LH_IFG_Post{2},'_',' '));
ax.FontSize=12;


print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_vs_RH_select_tracts_PosTemp_to_IFG_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));


ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 11 8]
ff.PaperOrientation='landscape';
ax=subplot(1,1,1)
x=cellfun(@(x) x(1,2), RH_IFGorb_Ant_w);
y=cellfun(@(x) x(1,2), LH_IFGorb_Ant_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y);
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
ahist.Title.FontSize=15

ahist.Title.Position=[0,max(ahist.YLim),0]
ax.XLabel.String=sprintf('%s --> \n %s',strrep(RH_IFGorb_Ant{1},'_',' '),strrep(RH_IFGorb_Ant{2},'_',' '));
ax.YLabel.String=sprintf('%s --> \n %s',strrep(LH_IFGorb_Ant{1},'_',' '),strrep(LH_IFGorb_Ant{2},'_',' '));
ax.FontSize=12;

print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_vs_RH_select_tracts_Anttemp_to_IFGorb_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
%ylim([min([x;y]),max([x;y])])
%xlim([min([x;y]),max([x;y])])

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

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11]
ff.PaperOrientation='portrait';
edges=[.15,.45,.75]
ax_=[];
for k=1:length(seeds)
    ax=subplot('position',[edges(k),.5,.2,.3])
    s_t_weights=[];
    for kk=1:length(targets)
        t_idx=contains(folders,[targets{kk},'-',seeds{k}]);
        s_t_con=cat(3,results{t_idx}.unique_LH_fdt_sum{ids});
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),targets{kk})))==size(s_t_con,3));
        assert(sum(sum(contains(results{t_idx}.unique_LH_targets(:,ids),seeds{k})))==size(s_t_con,3));
        s_t_weights=[s_t_weights,squeeze([s_t_con(1,2,:)])]
        
    end 
    b=barh(1:length(seeds),mean(s_t_weights,1))
    hold on
    b.FaceColor='r'
    errorbar(mean(s_t_weights,1),1:length(seeds),std(s_t_weights,[],1)/sqrt(length(s_t_weights)),'horizontal','linestyle','none','color','k','linewidth',4)
    ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
    ax.Title.FontSize=12;
    ax.Title.FontWeight='bold';
    ax.XAxis.FontSize=12;
    ax.XAxis.FontWeight='bold';
    if k==1
        ax.YTickLabel=strrep(targets,'_',' ')
        ax.YAxis.FontSize=12;
        ax.YAxis.FontWeight='bold';
        ax.XLabel.String=["average weight" , "(mean / standard error)"]

    else
        ax.YTickLabel=[];
    end 
    ax_=[ax_,ax];
    ax.Box='off';
end 
%linkaxes(ax_,'xy');

%print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_all_targeted_connectivity_subs_',num2str(num_subs),'_thr_',num2str(threshold),'.pdf'));
%print(ff,'-painters','-dpng', strcat(analysis_path,'/','LH_all_targeted_connectivity_subs_',num2str(num_subs),'_thr_',num2str(threshold),'.png'));

%% 

%% Calculate temporal to frontal pairs 
% RIght parcels 
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

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11]
ff.PaperOrientation='portrait';
edges=[.15,.45,.75]
ax_=[];
for k=1:length(seeds)
    ax=subplot('position',[edges(k),.5,.2,.3])
    s_t_weights=[];
    for kk=1:length(targets)
        t_idx=contains(folders,[targets{kk},'-',seeds{k}]);
        s_t_con=cat(3,results{t_idx}.unique_RH_fdt_sum{ids});
        assert(sum(sum(contains(results{t_idx}.unique_RH_targets(:,ids),targets{kk})))==size(s_t_con,3));
        assert(sum(sum(contains(results{t_idx}.unique_RH_targets(:,ids),seeds{k})))==size(s_t_con,3));
        s_t_weights=[s_t_weights,squeeze([s_t_con(1,2,:)])]
        
    end 
    b=barh(1:length(seeds),mean(s_t_weights,1))
    hold on
    b.FaceColor=[51,153,255]/256;
    errorbar(mean(s_t_weights,1),1:length(seeds),std(s_t_weights,[],1)/sqrt(length(s_t_weights)),'horizontal','linestyle','none','color','k','linewidth',4)
    ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
    ax.Title.FontSize=12;
    ax.Title.FontWeight='bold';
    ax.XAxis.FontSize=12;
    ax.XAxis.FontWeight='bold';
    if k==1
        ax.YTickLabel=strrep(targets,'_',' ')
        ax.YAxis.FontSize=12;
        ax.YAxis.FontWeight='bold';
        ax.XLabel.String=["average weight" , "(mean / standard error)"]

    else
        ax.YTickLabel=[];
    end 
    ax_=[ax_,ax];
    ax.Box='off';
end 
%linkaxes(ax_,'xy');

print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','RH_all_targeted_connectivity_subs_',num2str(num_subs),'_thr_',num2str(threshold),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','RH_all_targeted_connectivity_subs_',num2str(num_subs),'_thr_',num2str(threshold),'.png'));

%% look at correlation between actvitity in a parcel and its connectivity to a another parcel 

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

%% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11]
ff.PaperOrientation='portrait';
edges=[.15,.45,.75]
ax_=[];
for k=1:length(seeds)
    ax=subplot('position',[edges(k),.5,.2,.3])
    s_t_w=seed_target_weigthts{k};
    non_zero_sub=find(sum(s_t_w==0,2)~=3);
    s_=s_act(non_zero_sub,k);
    s_mod=repmat(s_,1,3).*s_t_w(non_zero_sub,:);
    s_t_corr=corr(s_mod,t_act(non_zero_sub,:),'Type','Pearson');
    %mdl=fitlm(s_,t_act(non_zero_sub,3))
    %plot(mdl)
    b=barh(1:length(seeds),diag(s_t_corr))
    hold on
    b.FaceColor='r'
    %errorbar(mean(s_t_weights,1),1:length(seeds),std(s_t_weights,[],1)/sqrt(length(s_t_weights)),'horizontal','linestyle','none','color','k','linewidth',4)
    ax.Title.String=strrep(seeds{k},'_',' ');
    ax.Title.FontSize=12;
    ax.Title.FontWeight='bold';
    ax.XAxis.FontSize=12;
    ax.XAxis.FontWeight='bold';
    if k==1
        ax.YTickLabel=strrep(targets,'_',' ')
        ax.YAxis.FontSize=12;
        ax.YAxis.FontWeight='bold';
        ax.XLabel.String=["average weight" , "(mean / standard error)"]

    else
        ax.YTickLabel=[];
    end 
    ax_=[ax_,ax];
    ax.Box='off';
end 
%linkaxes(ax_,'xy');

print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_all_targeted_connectivity_vs_activity_subs_',num2str(num_subs),'_thr_',num2str(threshold),'.pdf'));
print(ff,'-painters','-dpng', strcat(analysis_path,'/','LH_all_targeted_connectivity_vs_activity_subs_',num2str(num_subs),'_thr_',num2str(threshold),'.png'));


% do a linear fit 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11]
ff.PaperOrientation='portrait';
edges=[.15,.45,.75]
ax_=[];
for k=1:length(seeds)
    s_t_w=seed_target_weigthts{k};
    non_zero_sub=find(sum(s_t_w==0,2)~=3);
    s_=s_act(non_zero_sub,k);
    R_sq=[];
    for kk=1:size(t_act,2)
        s_mod=s_.*s_t_w(non_zero_sub,kk);
        mdl=fitlm(s_mod,t_act(non_zero_sub,kk));
        ax=subplot('position',[edges(k),.05+(kk-1)*.2,.2,.14]);
        plot(mdl)
        R_sq=[R_sq;mdl.Rsquared.Adjusted];
        ax.Children(4).Marker='o';
        ax.Children(4).MarkerFaceColor='r';
        ax.Children(4).MarkerEdgeColor='k';
        ax.Children(3).LineWidth=2;
        ax.Children(3).Color='k';
        %ax.Title.String=strcat(strrep(seeds{k},'_',' '),' to ',strrep(targets{kk},'_',' '));
        ax.Title.String='';
        ax.XLabel.String=strcat(strrep(seeds{k},'_',' ') ,' activity X target connectivity');
        ax.YLabel.String=strcat(strrep(targets{kk},'_',' ') ,' activity');
        legend off
    end 
    ax=subplot('position',[edges(k),.65,.2,.3])
    
    %
    b=barh(1:length(seeds),R_sq)
    hold on
    b.FaceColor='r'
    %errorbar(mean(s_t_weights,1),1:length(seeds),std(s_t_weights,[],1)/sqrt(length(s_t_weights)),'horizontal','linestyle','none','color','k','linewidth',4)
    ax.Title.String=strrep(seeds{k},'_',' ');
    ax.Title.FontSize=12;
    ax.Title.FontWeight='bold';
    ax.XAxis.FontSize=12;
    ax.XAxis.FontWeight='bold';
    if k==1
        ax.YTickLabel=strrep(targets,'_',' ')
        ax.YAxis.FontSize=12;
        ax.YAxis.FontWeight='bold';
        ax.XLabel.String=["average weight" , "(mean / standard error)"]

    else
        ax.YTickLabel=[];
    end 
    ax_=[ax_,ax];
    ax.Box='off';
end 
%linkaxes(ax_,'xy');

%print(ff,'-fillpage','-dpdf','-painters', strcat(analysis_path,'/','LH_all_targeted_connectivity_vs_activity_subs_',num2str(num_subs),'_thr_',num2str(threshold),'.pdf'));
%print(ff,'-painters','-dpng', strcat(analysis_path,'/','LH_all_targeted_connectivity_vs_activity_subs_',num2str(num_subs),'_thr_',num2str(threshold),'.png'));

