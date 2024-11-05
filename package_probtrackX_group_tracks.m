% probtrack results folder
clear all
close all
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';

threshold=20;
w_type='sum';
titles={'n.s.';'-->';'<--'};
folders={... % first 3 are how frontal are connected to temporal 
    'probtrackX_group_results_PostTemp_top_20-AntTemp_top_20-AngG_top_20-MFG_top_20_TO_PostTemp_top_20-AntTemp_top_20-AngG_top_20-MFG_top_20_EX_IFG_top_20-IFGorb_top_20';...
    'probtrackX_group_results_PostTemp_top_20-AntTemp_top_20-AngG_top_20-IFG_top_20_TO_PostTemp_top_20-AntTemp_top_20-AngG_top_20-IFG_top_20_EX_IFGorb_top_20-MFG_top_20';...
    'probtrackX_group_results_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_PostTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_AntTemp_top_20-AngG_top_20';...
    
    'probtrackX_group_results_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_TO_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_PostTemp_top_20-AngG_top_20';...
    'probtrackX_group_results_PostTemp_top_20-AntTemp_top_20-AngG_top_20-IFGorb_top_20_TO_PostTemp_top_20-AntTemp_top_20-AngG_top_20-IFGorb_top_20_EX_IFG_top_20-MFG_top_20';...
    'probtrackX_group_results_IFGorb_top_20-IFG_top_20-AngG_top_20-MFG_top_20_TO_AngG_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20_EX_AntTemp_top_20-PostTemp_top_20'...
    };
%% 
all_unique_subs={};
for folder =folders'
    fdt_files=dir(fullfile(probtrack_folder,folder{1},'*fdt_network.mat'));
    sub_ids=regexp({fdt_files(:).name},'sub\d+','match');
    sub_ids=cellfun(@(x) x(1) , sub_ids);
    unique_subs=unique(sub_ids);
    % drop one subject 
    %new_ids=find(~cellfun(@(x) contains(x,'sub197'),unique_subs));
    %unique_subs=unique_subs(new_ids);
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
    RH_targets=[RH_cell{:,2}];
    RH_fdt=[RH_cell(:,1)];
    RH_subs=[RH_cell(:,3)];
    
    % check that the labels are the same for the subjects in each row
    arrayfun(@(x) assert(length(unique(LH_targets(x,:)))==1), 1:size(LH_targets,1));
    arrayfun(@(x) assert(length(unique(RH_targets(x,:)))==1), 1:size(RH_targets,1));
    assert(all(cellfun(@(x,y) strcmp(x,y), RH_subs,LH_subs)));
    % LH
    % make symmetric by summing up upper and lower halves
    temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, LH_fdt,'uni',false);
    temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false);
    temp_fdt_sum=temp_fdt;
    
    cellfun(@(x) assert(issymmetric(x)),temp_fdt_sum)
    LH_fdt_raw=LH_fdt;
    LH_fdt_sum=temp_fdt_sum;
    % RH
    temp_fdt=cellfun(@(t) (triu(t)+transpose(tril(t)))/2, RH_fdt,'uni',false);
    temp_fdt=cellfun(@(t_sym) t_sym+transpose(triu(t_sym)), temp_fdt,'uni',false);
    temp_fdt_sum=temp_fdt;
    cellfun(@(x) assert(issymmetric(x)),temp_fdt_sum)
    RH_fdt_raw=RH_fdt;
    RH_fdt_sum=temp_fdt_sum;
    assert(all(cellfun(@(x,y) strcmp(x,y),LH_subs,unique_subs')));
    assert(all(cellfun(@(x,y) strcmp(x,y),RH_subs,unique_subs')));
    
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
%% 
for kk=1:size(all_unique_subs,2)
    assert(size(unique(all_unique_subs(:,kk)),1)==1)
end 

%% 
results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
subject_list=(cellfun(@(x) x.unique_subs,results,'uni',false));
subject_list=vertcat(subject_list{:});

arrayfun(@(x) assert(length(unique(subject_list(:,x)))==1), 1:size(subject_list,2))
unique_subs=results{1}.unique_subs;

rng(1)
% ids=randi(length(unique_subs),1,60);
% train_subs=unique_subs(ids);
num_subs=100;
[train_subs,ids]=datasample(unique_subs,num_subs,'Replace',false);

%% plot IFG projection_pattern 
IFGorb_project=results{1}.unique_LH_targets(:,1);
IFG_project=results{2}.unique_LH_targets(:,1);
MFG_project=results{3}.unique_LH_targets(:,1);

if strcmp(w_type,'sum')
    IFGorb_w=results{1}.unique_LH_fdt_sum(ids);
    IFG_w=results{2}.unique_LH_fdt_sum(ids);
    MFG_w=results{3}.unique_LH_fdt_sum(ids);
else
    IFGorb_w=results{1}.unique_LH_fdt_raw(ids);
    IFG_w=results{2}.unique_LH_fdt_raw(ids);
    MFG_w=results{3}.unique_LH_fdt_raw(ids);
end 
%% load full connectivity matrix 
unique_dti=load(fullfile(probtrack_folder,'probtrackX_lang_results_AntTemp_top_20-IFGorb_top_20-IFG_top_20-MFG_top_20-PostTemp_top_20-AngG_top_20','unique_subjects_pkg'));
unique_dti=unique_dti.unique_dti;

train_dti=struct;
train_dti.unique_subs=unique_dti.unique_subs(ids);
train_dti.unique_LH_fdt_raw=unique_dti.unique_LH_fdt_raw(ids);
train_dti.unique_LH_fdt_sum=unique_dti.unique_LH_fdt_sum(ids);

train_dti.unique_RH_fdt_raw=unique_dti.unique_RH_fdt_raw(ids);
train_dti.unique_RH_fdt_sum=unique_dti.unique_RH_fdt_sum(ids);

train_dti.unique_LH_targets=unique_dti.unique_LH_targets(:,ids);
train_dti.unique_RH_targets=unique_dti.unique_RH_targets(:,ids);

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
ax=axes('position',[.3,.3,.45,.45*pa_ratio]);

LH_norm=cellfun(@(x) x./sum(x(:)) , train_dti.unique_LH_fdt_sum,'uni',false);
LH_norm=cat(3,LH_norm{:});
LH_mean=mean(LH_norm,3);
%imagesc(LH_mean);

x = repmat(1:length(LH_norm),length(LH_norm),1); % generate x-coordinates
y = x'; % generate y-coordinates
% Generate Labels
t = num2cell(LH_norm); % extact values into cells
t = cellfun(@(x) sprintf('%.4f',x), t, 'UniformOutput', false); % convert to string
% Draw Image and Label Pixels
imagesc(M)
text(x(:), y(:), t, 'HorizontalAlignment', 'Center')





%% 
[C,~,L_T]=intersect(IFGorb_project{4},train_dti.unique_LH_targets,'stable');
LH_fdt=train_dti.unique_LH_fdt_sum;
% 
target_fdt=cellfun(@(t) t(L_T,:),LH_fdt,'uni',false);
target_sum=cellfun(@sum,target_fdt);
% 
X_w=IFGorb_w;
X_total=cell2mat(cellfun(@(x) sum(x(:,4)), X_w,'uni',false));
% drop zeros 
non_zero_idx=find(~(X_total==0));
X_total=X_total(non_zero_idx);
x=cellfun(@(x) x(1,4), X_w);
y=cellfun(@(x) x(2,4), X_w);
x=x(non_zero_idx);
y=y(non_zero_idx);
all_=target_sum(non_zero_idx);
source_x=strrep(IFGorb_project{1},'_',' ');
source_y=strrep(IFGorb_project{2},'_',' ');
target=strrep(IFGorb_project{4},'_',' ');

ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
ax=axes('position',[.1,.1,.25,.25*pa_ratio]);

[hscatter,hbar,ax,ahist]=scatterDiagHist(x./all_,y./all_,25);
hscatter.Marker='o';hscatter.MarkerFaceColor='r';hscatter.MarkerEdgeColor='w';hbar.FaceColor='r';
hscatter.SizeData=10;hscatter.MarkerEdgeAlpha=.5;
ax.YLim=[0,1];
ax.XLim=ax.YLim;
ax.XTick=ax.YLim;
ax.YTick=ax.XTick;
ax.XTickLabel=ax.XTick;
ax.YTickLabel=ax.YTick;

ahist.Position=ahist.Position-[0.045,0.045*pa_ratio,0,0];
ahist.YAxis.Visible='off';
%ahist.XAxis.Visible='off';
ahist.XAxisLocation='origin';
hbar.BaseLine.LineStyle='None';
hbar.EdgeAlpha=0;

hbar.LineWidth=1;

[h1,p1]=ttest(x,y,'Tail','right');
[h2,p2]=ttest(x,y,'Tail','left');
if h1
    ahist.Title.String=titles{2};
elseif h2
    ahist.Title.String=titles{3};
else
    ahist.Title.String=titles{1};
end
ahist.Title.FontWeight='normal';
    

ahist.Title.Rotation=-45;
ahist.Title.FontSize=8;
ahist.XAxis.FontSize=8;
ahist.YAxis.FontSize=8;
ahist.XTick= [];
%ahist.XTick= ahist.XTick(ahist.XTick~=0);
ahist.Title.Position=[0,max(ahist.YLim),0];
ax.XLabel.String=source_x;
ax.YLabel.String=source_y;
ax.FontSize=8;


ahist=makeaxis_eh(ahist);
ax=makeaxis_eh(ax)
ax.Title.String=target;
set(ax,'FontName','helvetica');
set(ax,'FontAngle','italic');
ax.Title.Position=[ax.Title.Position(1),1.1*max([x;y]),0];
ax.Title.FontWeight='normal';
%% 
[C,~,L_T]=intersect(IFG_project{4},train_dti.unique_LH_targets,'stable');
LH_fdt=train_dti.unique_LH_fdt_sum;
% 
target_fdt=cellfun(@(t) t(L_T,:),LH_fdt,'uni',false);
target_sum=cellfun(@sum,target_fdt);


X_w=IFG_w;
X_total=cell2mat(cellfun(@(x) sum(x(:,4)), X_w,'uni',false));
% drop zeros 
non_zero_idx=find(~(X_total==0));
X_total=X_total(non_zero_idx);
x=cellfun(@(x) x(1,4), X_w);
y=cellfun(@(x) x(2,4), X_w);
x=x(non_zero_idx);
y=y(non_zero_idx);
all_=target_sum(non_zero_idx);


ax=axes('position',[.4,.1,.25,.25*pa_ratio]);

[hscatter,hbar,ax,ahist]=scatterDiagHist(x./all_,y./all_,20);
hscatter.Marker='o';hscatter.MarkerFaceColor='r';hscatter.MarkerEdgeColor='w';hbar.FaceColor='r';
hscatter.SizeData=10;hscatter.MarkerEdgeAlpha=.5;
ax.YLim=[0,1];
ax.XLim=ax.YLim;
ax.XTick=[0,1];
ax.YTick=ax.XTick;
ax.XTickLabel=ax.XTick;
ax.YTickLabel=ax.YTick;
ahist.Position=ahist.Position-[0.045,0.045*pa_ratio,0,0];
ahist.YAxis.Visible='off';
ahist.XAxisLocation='origin';
hbar.BaseLine.LineStyle='None';
hbar.EdgeAlpha=0;

hbar.LineWidth=1;
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
ahist.Title.FontSize=8;
ahist.XAxis.FontSize=8;
ahist.YAxis.FontSize=8;
ahist.XTick= [];% ahist.XTick(ahist.XTick~=0);
ahist.Title.Position=[0,max(ahist.YLim),0];
ax.XLabel.String=source_x;
ax.YLabel.String=source_y;
ax.FontSize=8;



ahist=makeaxis_eh(ahist);
ax=makeaxis_eh(ax)
ax.Title.String=target;
set(ax,'FontName','helvetica');
set(ax,'FontAngle','italic');
ax.Title.Position=[ax.Title.Position(1),1.1*max([x;y]),0];
ax.Title.FontWeight='normal';

%% 
[C,~,L_T]=intersect(MFG_project{4},train_dti.unique_LH_targets,'stable');
LH_fdt=train_dti.unique_LH_fdt_sum;
% 
target_fdt=cellfun(@(t) t(L_T,:),LH_fdt,'uni',false);
target_sum=cellfun(@sum,target_fdt);
% 
X_w=MFG_w;
X_total=cell2mat(cellfun(@(x) sum(x(:,4)), X_w,'uni',false));
% drop zeros 
non_zero_idx=find(~(X_total==0));
X_total=X_total(non_zero_idx);
x=cellfun(@(x) x(1,4), X_w);
y=cellfun(@(x) x(2,4), X_w);
x=x(non_zero_idx);
y=y(non_zero_idx);
all_=target_sum(non_zero_idx);



ax=axes('position',[.7,.1,.25,.25*pa_ratio]);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x./all_,y./all_,20);
hscatter.Marker='o';hscatter.MarkerFaceColor='r';hscatter.MarkerEdgeColor='w';hbar.FaceColor='r';
hscatter.SizeData=10;hscatter.MarkerEdgeAlpha=.5;
ax.YLim=[-1,1.1*max([x;y])];ax.XLim=[-1,1.1*max([x;y])];
ax.XLim=ax.YLim;
ax.XTick=round(linspace(0,1.1*max([x;y]),3)/10)*10;
ax.YTick=ax.XTick;
ax.XTickLabel=ax.XTick;
ax.YTickLabel=ax.YTick;
ahist.Position=ahist.Position-[0.045,0.045*pa_ratio,0,0];
ahist.YAxis.Visible='off';
ahist.XAxisLocation='origin';
hbar.BaseLine.LineStyle='None';
hbar.EdgeAlpha=0;

hbar.LineWidth=1;
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
ahist.Title.FontSize=8;
ahist.XAxis.FontSize=8;
ahist.YAxis.FontSize=8;
ahist.XTick= [];% ahist.XTick(ahist.XTick~=0);
ahist.Title.Position=[0,max(ahist.YLim),0];
ax.XLabel.String=source_x;
ax.YLabel.String=source_y;
ax.FontSize=8;



ahist=makeaxis_eh(ahist);
ax=makeaxis_eh(ax)
ax.Title.String=target;
set(ax,'FontName','helvetica');
set(ax,'FontAngle','italic');
ax.Title.Position=[ax.Title.Position(1),1.1*max([x;y]),0];
ax.Title.FontWeight='normal';


%% 
set(ff, 'Color', 'w');
user_string('ghostscript','/usr/local/Cellar/ghostscript@9.26/9.26_1/bin/gs')
export_fig(strcat(analysis_path,'/','suppl_figure_2_temporal_to_frontal_selectivity_group_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs)), '-png');
export_fig(strcat(analysis_path,'/','suppl_figure_2_temporal_to_frontal_selectivity_group_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'),'-pdf' ,'-painters')
%% 
targets={sprintf('AntTemp_top_%d',threshold),sprintf('PostTemp_top_%d',threshold),sprintf('AngG_top_%d',threshold)};
seeds={sprintf('IFG_top_%d',threshold);sprintf('IFGorb_top_%d',threshold);sprintf('MFG_top_%d',threshold)};
sources_y={'IFG','IFGorb','MFG'};
targets_x={'AntTemp','PostTemp','AngG'};


ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
edges=[.15,.45,.75]
ax_=[];
k=1;
source_id=cell2mat(cellfun(@(x) find(contains(IFG_project,x)), seeds(1),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(IFG_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),IFG_w,'uni',false);
s_t_weights=vertcat(s_t_weights{:});
ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(find(sum(s_t_weights,2)>0),:);
b=barh(1:length(targets),mean(s_t_nonzero,1));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,1),1:length(targets),std(s_t_nonzero,0,1)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_x;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_y{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';
    
k=2;
source_id=cell2mat(cellfun(@(x) find(contains(IFGorb_project,x)), seeds(2),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(IFGorb_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),IFGorb_w,'uni',false);
s_t_weights=vertcat(s_t_weights{:});

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(find(sum(s_t_weights,2)>0),:);
b=barh(1:length(targets),mean(s_t_nonzero,1));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,1),1:length(targets),std(s_t_nonzero,0,1)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_x;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_y{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';


k=3;
source_id=cell2mat(cellfun(@(x) find(contains(MFG_project,x)), seeds(3),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(MFG_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),MFG_w,'uni',false);
s_t_weights=vertcat(s_t_weights{:});

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(find(sum(s_t_weights,2)>0),:);
b=barh(1:length(targets),mean(s_t_nonzero,1));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,1),1:length(targets),std(s_t_nonzero,0,1)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_x;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_y{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';

%% 
%% 
targets={sprintf('AntTemp_top_%d',threshold),sprintf('PostTemp_top_%d',threshold),sprintf('AngG_top_%d',threshold)};
seeds={sprintf('IFG_top_%d',threshold);sprintf('IFGorb_top_%d',threshold);sprintf('MFG_top_%d',threshold)};
sources_y={'IFG','IFGorb','MFG'};
targets_x={'AntTemp','PostTemp','AngG'};


ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
edges=[.15,.45,.75]
ax_=[];
k=1;
source_id=cell2mat(cellfun(@(x) find(contains(IFG_project,x)), seeds(1),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(IFG_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),IFG_w,'uni',false);
s_t_weights=vertcat(s_t_weights{:});
ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(find(sum(s_t_weights,2)>0),:);
s_t_nonzero=s_t_nonzero./(sum(s_t_nonzero,2));
b=barh(1:length(targets),mean(s_t_nonzero,1));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,1),1:length(targets),std(s_t_nonzero,0,1)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_x;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_y{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';
    
k=2;
source_id=cell2mat(cellfun(@(x) find(contains(IFGorb_project,x)), seeds(2),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(IFGorb_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),IFGorb_w,'uni',false);
s_t_weights=vertcat(s_t_weights{:});

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(find(sum(s_t_weights,2)>0),:);
s_t_nonzero=s_t_nonzero./(sum(s_t_nonzero,2));
b=barh(1:length(targets),mean(s_t_nonzero,1));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,1),1:length(targets),std(s_t_nonzero,0,1)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_x;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_y{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';


k=3;
source_id=cell2mat(cellfun(@(x) find(contains(MFG_project,x)), seeds(3),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(MFG_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),MFG_w,'uni',false);
s_t_weights=vertcat(s_t_weights{:});

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(find(sum(s_t_weights,2)>0),:);
s_t_nonzero=s_t_nonzero./(sum(s_t_nonzero,2));
b=barh(1:length(targets),mean(s_t_nonzero,1));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,1),1:length(targets),std(s_t_nonzero,0,1)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_x;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_y{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';

%% plot IFG projection_pattern 
AngG_project=results{4}.unique_LH_targets(:,1);
PosTemp_project=results{5}.unique_LH_targets(:,1);
AntTemp_project=results{6}.unique_LH_targets(:,1);

if strcmp(w_type,'sum')
    AngG_w=results{4}.unique_LH_fdt_sum(ids);
    PostTemp_w=results{5}.unique_LH_fdt_sum(ids);
    AntTemp_w=results{6}.unique_LH_fdt_sum(ids);
    
else
    AngG_w=results{4}.unique_LH_fdt_raw(ids);
    PostTemp_w=results{1}.unique_LH_fdt_raw(ids);
    AntTemp_w=results{2}.unique_LH_fdt_raw(ids);
    
end 

seeds={sprintf('AntTemp_top_%d',threshold),sprintf('PostTemp_top_%d',threshold),sprintf('AngG_top_%d',threshold)};
targets={sprintf('IFG_top_%d',threshold);sprintf('IFGorb_top_%d',threshold);sprintf('MFG_top_%d',threshold)};
targets_y={'IFG','IFGorb','MFG'};
sources_x={'AntTemp','PostTemp','AngG'};
%%  


ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
edges=[.15,.45,.75]
ax_=[];
k=1;
source_id=cell2mat(cellfun(@(x) find(contains(AntTemp_project,x)), seeds(1),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(AntTemp_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),AntTemp_w,'uni',false);
s_t_weights=horzcat(s_t_weights{:});
ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(:,find(sum(s_t_weights,1)>0));
b=barh(1:length(targets)',mean(s_t_nonzero,2));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,2),1:length(targets),std(s_t_nonzero,0,2)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_y;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_x{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';
    
k=2
source_id=cell2mat(cellfun(@(x) find(contains(PosTemp_project,x)), seeds(2),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(PosTemp_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),PostTemp_w,'uni',false);
s_t_weights=horzcat(s_t_weights{:});

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(:,find(sum(s_t_weights,1)>0));
b=barh(1:length(targets)',mean(s_t_nonzero,2));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,2),1:length(targets),std(s_t_nonzero,0,2)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_y;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_x{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';


k=3;
source_id=cell2mat(cellfun(@(x) find(contains(AngG_project,x)), seeds(3),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(AngG_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),AngG_w,'uni',false);
s_t_weights=horzcat(s_t_weights{:});

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(:,find(sum(s_t_weights,1)>0));
b=barh(1:length(targets)',mean(s_t_nonzero,2));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,2),1:length(targets),std(s_t_nonzero,0,2)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_y;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_x{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';

%% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
edges=[.15,.45,.75]
ax_=[];
k=1;
source_id=cell2mat(cellfun(@(x) find(contains(AntTemp_project,x)), seeds(1),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(AntTemp_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),AntTemp_w,'uni',false);
s_t_weights=horzcat(s_t_weights{:});

s_t_nonzero=s_t_weights(:,find(sum(s_t_weights,1)>0));
s_t_nonzero=s_t_nonzero./(sum(s_t_nonzero,1));

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
b=barh(1:length(targets)',mean(s_t_nonzero,2));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,2),1:length(targets),std(s_t_nonzero,0,2)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_y;
ax.YAxis.FontSize=8;
ax.XLim=[0,1];
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_x{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';
    
k=2
source_id=cell2mat(cellfun(@(x) find(contains(PosTemp_project,x)), seeds(2),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(PosTemp_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),PostTemp_w,'uni',false);
s_t_weights=horzcat(s_t_weights{:});

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(:,find(sum(s_t_weights,1)>0));
s_t_nonzero=s_t_nonzero./(sum(s_t_nonzero,1));
b=barh(1:length(targets)',mean(s_t_nonzero,2));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,2),1:length(targets),std(s_t_nonzero,0,2)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_y;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax.XLim=[0,1];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_x{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';


k=3;
source_id=cell2mat(cellfun(@(x) find(contains(AngG_project,x)), seeds(k),'uni',false));
target_ids=cell2mat(cellfun(@(x) find(contains(AngG_project,x)), targets,'uni',false));
s_t_weights=cellfun(@(Y) arrayfun(@(x) Y(source_id,x),target_ids),AngG_w,'uni',false);
s_t_weights=horzcat(s_t_weights{:});

ax=subplot('position',[edges(k),.7,.2,.3*pa_ratio]);
s_t_nonzero=s_t_weights(:,find(sum(s_t_weights,1)>0));
s_t_nonzero=s_t_nonzero./(sum(s_t_nonzero,1));
b=barh(1:length(targets)',mean(s_t_nonzero,2));
b.BaseLine.LineStyle='none';
hold on
b.FaceColor='r';
errorbar(mean(s_t_nonzero,2),1:length(targets),std(s_t_nonzero,0,2)/sqrt(length(s_t_nonzero)),'horizontal','linestyle','none','color','k','linewidth',2)
ax.XAxis.FontSize=8;
ax.YTickLabel=targets_y;
ax.YAxis.FontSize=8;
ax.XLabel.String=["average weight" , "(mean / standard error)"];
ax.XLim=[0,1];
ax=makeaxis_eh(ax)
%ax.Title.String=strcat(strrep(seeds{k},'_',' '),' #sub:',num2str(size(s_t_weights,1)));
ax.Title.String=sources_x{k};
ax.Title.FontSize=10;
ax_=[ax_,ax];
ax.Box='off';
