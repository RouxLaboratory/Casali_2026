function [SniffInt] = VisuallyInspectSniffSignalForSniffInt(Signal)
%% Function written by Giulio Casali (giulio.casali.pro@gmail.com)
% This is to display the resp signal (input = Signal) 
% and decide if there are intervals where the signal disappeared.
% The goal is to add intervals in the dialog like this:
% SniffInt= [0, 330;  8364       16454; 16467       16496 ; 16505       16528];
% These valid blocks can be added step by step, simply by keeping the default answer "no" in the pop-up dialog window.
% At each iteration of the loop use the zoom IN/OUT for careful evaluation, and the the good intervals selected will be highlighted in green. 
% Once the entire session is examined , the answer "y" can be given to go out of the while/loop.
% NOTE, the intervals will be consolidated to account for overlapping
% chunks - not a problem,
% if the entire session is good, the full trace examined can be given (this
% info can be retrieved from the prompt directly).
    
    clf;
    PlotXY([Signal ] ,'Color','k')
    SniffInt = [0,0];
    KeepExaminesniffSession = true;
    FullWindow = floor(Signal(end,1)); %% it was ceil - better to round it to the minimum second
    
        
    while KeepExaminesniffSession 
        %disp(['Full window = ' num2str(FullWindow) ' seconds...'])
        keyboard;
        prompt={['Select sniff int (0 - ' num2str(FullWindow) ')' ],[ 'Full trace examined' ]};
        name='Input for Sniff intervals ' ;
        numlines=1;
        defaultanswer={ mat2str([SniffInt]) , 'no' };
        answer= inputdlg(prompt,name,numlines,defaultanswer);
        SniffInt =ConsolidateIntervals([SniffInt; str2num(  answer{1})]);
        PlotIntervals([SniffInt],'Color','g','alpha',0.2);
        xlim([0,FullWindow]);
        KeepExaminesniffSession = strcmp(answer{2},defaultanswer{2});
    end
    if size(SniffInt,1)>1
        SniffInt = ConsolidateIntervals([SniffInt ] ) ; 
    end
    
    
end