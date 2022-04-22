function transform_probtrackX_output(file_id)
fid=fopen(file_id);
tline = fgetl(fid);
A_str=readlines('/Users/eghbalhosseini/Desktop/fdt_network_matrix');
A_num=[]
for k=1:size(A_str,1)
    A_num=[A_num;str2num(A_str(k,:))];
end 

A=str2num(tline)
while ischar(tline)
    
    tline = fgetl(fid);
    disp(tline)
end
fclose(fid);


imagesc(A_num)
daspect([1,1,1])
shg