function SAVE_Figure(gcf, Title, Format,Orientation , verbose)

drawnow;
if ~exist('Orientation','var')
    Orientation = 'landscape';
end;

if ~exist('verbose','var')
    verbose = true;
end;

if strcmp(Format,'pdf') | strcmp(Format,'emf')
set(gcf,'Renderer','painters');

elseif strcmp(Format,'png') | strcmp(Format,'tiff')
set(gcf,'Renderer','open gl');

end

set(gcf,'NumberTitle','off','Name',Title,'PaperOrientation',Orientation,'PaperUnits','normalized','PaperPosition',[0 0 1 1]);

saveas(gcf,Title,Format);
%export_fig(Title,['-' Format])

if verbose;
disp([ Title ' saved in ' cd]);
end;


end