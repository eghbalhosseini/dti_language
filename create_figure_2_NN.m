clear all;
close all;
threshold=20;
num_subs=70;
%num_subs=120;
w_type='sum';
probtrack_folder='/Users/eghbalhosseini/MyData/dti_language/';
analysis_path='/Users/eghbalhosseini/MyData/dti_language/analysis';
titles={'n.s.';'-->';'<--'};

source_x='PostTemp';
source_y='AntTemp';
target='IFGorb';

folders={sprintf('probtrackX_results_IFGorb_top_%d-PostTemp_top_%d_TO_IFGorb_top_%d-PostTemp_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
         sprintf('probtrackX_results_IFGorb_top_%d-AntTemp_top_%d_TO_IFGorb_top_%d-AntTemp_top_%d_EX_IFG_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold)};

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
rng(1)
[train_subs,ids]=datasample(unique_subs,num_subs,'Replace',false);

if strcmp(w_type,'sum')
    X_w=results{1}.unique_LH_fdt_sum(ids);
    Y_w=results{2}.unique_LH_fdt_sum(ids);
else
    X_w=results{1}.unique_LH_fdt_raw(ids);
    Y_w=results{2}.unique_LH_fdt_raw(ids);
end 
%% 
ff=figure();
ff.Units='Inches';
ff.Position=[55.5139 10.6250 8 11];
ff.PaperOrientation='portrait';
pa_ratio=8/11;
ax=axes('position',[.1,.1,.25,.25*pa_ratio]);
x=cellfun(@(x) x(1,2), X_w);
y=cellfun(@(x) x(1,2), Y_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,25);
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

source_x='PostTemp';
source_y='AntTemp';
target='IFG';

folders={sprintf('probtrackX_results_IFG_top_%d-PostTemp_top_%d_TO_IFG_top_%d-PostTemp_top_%d_EX_IFGorb_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
         sprintf('probtrackX_results_IFG_top_%d-AntTemp_top_%d_TO_IFG_top_%d-AntTemp_top_%d_EX_IFGorb_top_%d-MFG_top_%d',threshold,threshold,threshold,threshold,threshold,threshold)};

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
rng(1)
[train_subs,ids]=datasample(unique_subs,num_subs,'Replace',false);

if strcmp(w_type,'sum')
    X_w=results{1}.unique_LH_fdt_sum(ids);
    Y_w=results{2}.unique_LH_fdt_sum(ids);
else
    X_w=results{1}.unique_LH_fdt_raw(ids);
    Y_w=results{2}.unique_LH_fdt_raw(ids);
end 

ax=axes('position',[.1,.4,.25,.25*pa_ratio]);
x=cellfun(@(x) x(1,2), X_w);
y=cellfun(@(x) x(1,2), Y_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,20);
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
 source_x='PostTemp';
source_y='AntTemp';
target='MFG';

folders={sprintf('probtrackX_results_MFG_top_%d-PostTemp_top_%d_TO_MFG_top_%d-PostTemp_top_%d_EX_IFG_top_%d-IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold,threshold);
         sprintf('probtrackX_results_MFG_top_%d-AntTemp_top_%d_TO_MFG_top_%d-AntTemp_top_%d_EX_IFG_top_%d-IFGorb_top_%d',threshold,threshold,threshold,threshold,threshold,threshold)};

results={};
for idx=1:size(folders,1)
   results{idx}=load(fullfile(probtrack_folder,folders{idx},'unique_subjects_pkg'),'unique_dti').unique_dti;
end 
assert(all(cell2mat(cellfun(@(x,y) strcmp(x,y),results{1}.unique_subs,results{2}.unique_subs,'uni',false))))
unique_subs=results{1}.unique_subs;
rng(1)
[train_subs,ids]=datasample(unique_subs,70,'Replace',false);

if strcmp(w_type,'sum')
    X_w=results{1}.unique_LH_fdt_sum(ids);
    Y_w=results{2}.unique_LH_fdt_sum(ids);
else
    X_w=results{1}.unique_LH_fdt_raw(ids);
    Y_w=results{2}.unique_LH_fdt_raw(ids);
end 

ax=axes('position',[.5,.4,.25,.25*pa_ratio]);
x=cellfun(@(x) x(1,2), X_w);
y=cellfun(@(x) x(1,2), Y_w);
[hscatter,hbar,ax,ahist]=scatterDiagHist(x,y,20);
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
export_fig(strcat(analysis_path,'/','figure_2_temporal_to_frontal_selectivity_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs)), '-png');
export_fig(strcat(analysis_path,'/','figure_2_temporal_to_frontal_selectivity_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'),'-pdf' ,'-painters')
%% 
pos = get(ff,'Position');
aspect = pos(3)/pos(4);  %width/height
set(ff,'PaperOrientation','portrait');
set(ff,'PaperPositionMode','manual');  
set(ff,'PaperUnits','normalized');
s = get(ff,'PaperSize');
paperaspect = s(1)/s(2); %width/height
if(aspect > paperaspect)
      set(ff,'PaperPosition', [0 .5-.5/aspect 1 1/aspect]);
elseif(aspect < 1)
      set(ff,'PaperPosition', [.5-.5*aspect 0 aspect 1]);
else 
      set(ff,'PaperPosition', [0 0 1 1]);
end
print(ff, '-dpdf', '-painters', strcat(analysis_path,'/','figure_2_temporal_to_frontal_selectivity_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
set(ff,'PaperUnits', 'inches');


%print(ff,'-dpdf','-bestfit','-painters', strcat(analysis_path,'/','figure_2_temporal_to_frontal_selectivity_thr_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.pdf'));
%print(ff,'-painters','-dpng', strcat(analysis_path,'/','figure_2_temporal_to_frontal_selectivity_thr_','_',num2str(threshold),'_',w_type,'_subs_',num2str(num_subs),'.png'));
