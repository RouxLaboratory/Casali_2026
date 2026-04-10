function figure1 =imagesc_2mat(Matrix1,Matrix2,colormapchoice)
% make an imagesc-like plot for two matricieswith equal dimensions, in 
% which each each cell of the plot is split diagonally with the upper 
% triangle of cell (i,j) in the plot representing the Matrix1(i,j) and the 
% lower triangle representing Matrix2(i,j).
% 
% Inputs:
% Matrix1,Matrix2       The two matricies you want to visualize
% colormapchoice        a colormap array (e.g., jet(128))
% 
% Output:
% figure1               Figure handle
% 
% example:
% h =imagesc_2mat(rand(5,4),rand(5,4)+1,bone(256)) 
% 
% Nathan E. Lewis, UC San Diego -- Jan 6, 2010
if nargin ==0
    Matrix1= ones(10,5)-randn(10,5)+randn(10,5);
    Matrix2= ones(10,5)-randn(10,5)+randn(10,5);
        Matrix1= ones(10,5);
    Matrix2= zeros(10,5);
end
if nargin<3
%     colormapchoice = redgreencmap(256,'Interpolation','linear');
colormapchoice = summer(128);
end
if size(Matrix1)~=size(Matrix2)
    error('Matricies not the same size!')
end
cmap2useInd = linspace(min(min([Matrix1;Matrix2])),max(max([Matrix1;Matrix2])),length(colormapchoice(:,1)));
cmap2use=(colormapchoice);
figure1 = figure;
axes1 = axes('Parent',figure1,'YDir','reverse','Layer','top','Linewidth',2);
hold on;box('on')
[m n]=size(Matrix1);
for i=1:m
    for j=1:n
        p = fill([j-.5 j-.5 j+.5],[i+.5 i-.5 i-.5],cmap2use(find(cmap2useInd>=Matrix1(i,j),1,'first'),:));
        set(p,'Linewidth',2)
        p = fill([j-.5 j+.5 j+.5],[i+.5 i+.5 i-.5],cmap2use(find(cmap2useInd>=Matrix2(i,j),1,'first'),:));
        set(p,'Linewidth',2)
    end
end
set(axes1,'ytick',[1:m],'yticklabel',[1:m],'xtick',[1:n],'xticklabel',[1:n],'xlim',[.5 n+.5],'ylim',[.5 m+.5]);
colormap(cmap2use);
colorbar('ytick',[0:.1:1],'yticklabel',linspace(min(min([Matrix1;Matrix2])),max(max([Matrix1;Matrix2])),11),'Linewidth',2);
