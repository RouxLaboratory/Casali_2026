function [ StatsIndex ] = ConcatentateIntoStructureIndices( Stats ,subStruct, field, Indices,Computation , ThirdColumn , NaNIfMissing )
% Gets the data into a structure one by one...
%if ~exist('ThirdColumn','var'); ThirdColumn = 1 ; end;


[Average , Peak , Transpose , KeepMatrix , MakeMatrix , Median , ...
 StackMatrices , CountData , Linearize , Sum , IsChar , MakeHorizontalMatrix ,AverageAcrossColumsn ,AverageAcrossRows ,IsConcatenatedStructure,DiffRows,...
AverageAcrossStack,Keep3Dims,Stack3DMatrices, AverageAcrossRowsAndStackRow,SumDiffRows,DiffColumns]=deal(false);
if isempty(Computation)
    Computation = false ;
end

if Computation ==1 ;
Average= true;
%Peak =0;Transpose = 0 ;KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==2;
Peak =true;
%Average = 0;Transpose = 0 ;KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==3;
Transpose = true ;
%Average= 0;Peak =0;KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==4;
KeepMatrix = true ;
%Average= 0;Peak =0;Transpose = 0; MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==5;
MakeMatrix = true ;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==6;
Median = true;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==7;
StackMatrices = true;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;Median = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==8;
CountData = true;Keep3Dims= true;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==9;
Linearize = true;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==10;
Sum = true;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==11;
IsChar = true ;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;MakeHorizontalMatrix = 0 ; AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==12;
MakeHorizontalMatrix = true ;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;AverageAcrossColumsn = 0 ;AverageAcrossRows = 0; 
elseif Computation ==13;
AverageAcrossColumsn = true ;
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossRows = 0; 
elseif Computation ==14;
AverageAcrossRows = true; 
%Average= 0;Peak =0;Transpose = 0; KeepMatrix = 0;MakeMatrix = 0;Median = 0;StackMatrices = 0;CountData = 0;Linearize = 0;Sum = 0;IsChar = 0 ;MakeHorizontalMatrix = 0 ;AverageAcrossColumsn = 0 ;
elseif Computation ==15;
IsConcatenatedStructure = true;
elseif Computation ==16;
DiffRows = true; 
elseif Computation ==17;
AverageAcrossStack = true; 
KeepMatrix = true;
elseif Computation ==18;
Keep3Dims = true; 
Stack3DMatrices = true;
elseif Computation ==19;
 AverageAcrossRowsAndStackRow =  true; 
elseif Computation ==20;
 SumDiffRows=true;
elseif Computation ==21;
 DiffColumns=true;

end


if isempty(Indices)
    Indices = 1 : numel(Stats);
end

StatsIndex = [];


if ~exist('ThirdColumn','var') | isempty(ThirdColumn) ; ThirdColumn = repmat(1,1,numel(Indices)) ; end;
if ~exist('NaNIfMissing','var')| isempty(NaNIfMissing) ; NaNIfMissing = 1 ; end;




for iStat = 1 : numel (Indices)

ToTake = Indices(iStat);
if isfield(Stats(ToTake),subStruct(1:end-1))
  if  eval(['isstruct(Stats(ToTake).' subStruct(1:end-1) ');' ]) %& eval(['isfield(Stats(ToTake).' subStruct(1:end-1) ',' char(39) field char(39) ');' ])
      WithinStructures = textscan(field, '%s' , 'Delimiter', '.')  ;;
      if numel(WithinStructures{1})>1  
%        for iField = 1 : numel(WithinStructures{1})-1;%              if  eval(['isstruct(Stats(ToTake).' subStruct char(WithinStructures{1}(iField))  ') ;' ] );%                  eval([ 'X = Stats(ToTake).' subStruct field ' ;' ] );%              else;%                 X= NaN; ;%              end    ;%           end    
      UltimateField = [ 'Stats(ToTake).' subStruct(1:end-1) ]  ;                   
      iField=1;
      
      while iField < numel(WithinStructures{1})+1
          
          IsThereParenthesis(iField) = sum(ismember( char(WithinStructures{1}(iField)),'('));
          
          if IsThereParenthesis(iField);
              Broken = textscan( char(WithinStructures{1}(iField)) ,'%s' , 'Delimiter', '()') ; TextField = Broken{1}{1,1};
          else
              TextField = WithinStructures{1} {iField};
          end
          
          if  eval(['~isfield(' UltimateField ',' char(39) TextField char(39) ')' ]) ;%...eval(['~isfield(' UltimateField ',' char(39) char(WithinStructures{1} (iField)) char(39) ')' ])
              %X = NaN; iField = numel(WithinStructures{1})+1;
              X = []; iField = numel(WithinStructures{1})+1;
          else
              if IsThereParenthesis(iField)
                  UltimateField = [ UltimateField  '.'  char(WithinStructures{1}(iField))]  ;
              else
                  UltimateField = [ UltimateField  '.' TextField]  ;
              end
              if iField == numel(WithinStructures{1})
                  if ~ThirdColumn(iStat)
                      if  eval(['iscell(' UltimateField ') ' ])
                          eval(['X = cell2mat(' UltimateField '(:,1) );' ])
                      else
                          eval([' X= ' UltimateField '(: , : , 1);' ] );
                      end
                  else
                      if IsConcatenatedStructure ; 
                          
                          eval(['X = ConcatentateIntoStructureIndices(' UltimateField(1:end-(numel(WithinStructures{1}{iField})+1)) ',' char(39) '.' char(39) ',' char(39) WithinStructures{1}{iField} char(39) ',[],[]) ; ' ] );
                          
                      elseif eval(['~IsConcatenatedStructure & iscell(' UltimateField ') ' ])
                          eval(['X = cell2mat(' UltimateField '(:,ThirdColumn(iStat)) );' ])
                      elseif not(AverageAcrossStack) & not(Keep3Dims)
                          eval([' X= ' UltimateField '(: , : , ThirdColumn(iStat));' ] );
                      
                      elseif not(AverageAcrossStack) & Keep3Dims 
                          eval([' X= ' UltimateField '(: , : , :);' ] );
                      elseif AverageAcrossStack
                          eval([' X= nanmean(' UltimateField '(: , : , :),3);' ] );
                      end
                  end
              end
              iField =iField +1;
              
          end
      end
      else
          if eval(['isfield(Stats(ToTake).' subStruct(1:end-1) ',field ) ' ] )
            eval ([ 'X = Stats(ToTake).' subStruct field ';' ] )  ;
          else
              %X = NaN;
              if NaNIfMissing
                X = NaN ;
              else
                  X = [] ;
              end
          end
      end
          if isstruct(X)
               X = char(fields(X)); 
          elseif isempty(X);
              if NaNIfMissing
                X = NaN ;
              else
                  X = [] ;
              end
          end  
        if Average;
        X = nanmean(X(:));
        elseif Median;
        X = nanmedian(X(:));
        elseif Peak;
        X = max(X(:));
        elseif Transpose
        X=reshape(X,1,[])  ; 
        elseif Linearize
        X=reshape(X,[],[1])  ; 
        elseif KeepMatrix
        X=X;
        elseif MakeMatrix
        X = X;
        elseif StackMatrices
        X = X;
        elseif CountData
        X = numel(X);
        elseif Sum
        X = nansum(X(:));
        elseif AverageAcrossColumsn;
        X = nanmean(X,1);
        elseif AverageAcrossRows ; 
        X = nanmean(X,2);
%         elseif AverageAcrossStack ; 
%         X = nanmean(X,3);
        elseif AverageAcrossRowsAndStackRow ; 
        X = nanmean(X,2);
        X = reshape(X,1,[]);
        elseif MakeHorizontalMatrix        
         X = X; 
        elseif DiffRows        
         X = nanmean(diff(X,[],2)) ; 
        elseif SumDiffRows        
         X = nansum(diff(X,[],2)) ; 
        elseif DiffColumns;
         X = diff(X,[],1) ; 
        elseif IsChar
            X = X;
            if iStat==1;
               clear StatsIndex;
               StatsIndex{1} =X;;
            else
               StatsIndex{iStat}=[X] ;
            end
        elseif Keep3Dims
        X =X;
        else
        X= X(:,:,1)' ;
        end
  else
      %% X = NaN;
      if NaNIfMissing
          X = NaN ;
      else
          X = [] ;
      end
  end
elseif   isfield(Stats(ToTake),field)
    eval ([ 'X = Stats(ToTake).'  field ';' ] )  ;
       
        if isstruct(X)
           X = char(fields(X)); 
        end    
       if Average; 
        X = nanmean(X(:));
       elseif CountData
        X = numel(X);
        elseif Linearize
        X=reshape(X,[],[1])  ;        
        elseif Sum;
        X = nansum(X(:));
       elseif isempty(X);
              if NaNIfMissing
                    X = NaN ;
              else
                    X = [] ;
              end

       elseif Median;
        X = nanmedian(X(:));
       elseif Peak;
        X = max(X(:)); 
       elseif Transpose
        X=reshape(X,1,[])  ; 
        elseif AverageAcrossColumsn;
        X = nanmean(X,1);  
%         elseif AverageAcrossStack ; 
%         X = nanmean(X,3);
     elseif SumDiffRows        
         X = nansum(diff(X,[],2)) ; 
       elseif IsChar
        X = X;
         if ischar(X)
            if iStat==1;
               clear StatsIndex;
               StatsIndex{1} =X;;
            else
               StatsIndex{iStat}=[X] ;
            end
           else
            X= X' ;
           end
        end
  
else

      if NaNIfMissing
          X = NaN ;
      else
          X = [] ;
      end

end

if ~ischar(X) & Computation~=11
    if KeepMatrix
        if isempty(X);
            if NaNIfMissing
                X = NaN(size (StatsIndex(:,:,iStat-1))); 
            else
                X = [] ;
            end
        end
                if iStat ~=1 & [~isequal(size(StatsIndex,1) , size(X,1) ) | ~isequal(size(StatsIndex,2) , size(X,2) )]
                        if NaNIfMissing
                        StatsIndex(1:size(X,1),1:size(X,2),1:iStat-1) = [ NaN ] ;
                        else
                        X = [] ;
                        end
                end
                StatsIndex(:,:,iStat) = X ;
    elseif MakeMatrix
        StatsIndex = [StatsIndex X];
    
    else
        if isempty(X);
            if NaNIfMissing
            X =repmat(NaN,1,size(StatsIndex,2)) ;
            else
            X =repmat([],1,size(StatsIndex,2)) ;
            end
        elseif MakeHorizontalMatrix
            if isempty(StatsIndex);
            elseif numel(X) < size(StatsIndex,2)
                    if NaNIfMissing
                    X(end+1:size(StatsIndex,2)) = NaN ;
                    end
            elseif numel(X) > size(StatsIndex,2)
                    if NaNIfMissing
                    StatsIndex(:,size(StatsIndex,2)+1:numel(X)) = NaN;
                    end
            end  
           StatsIndex= [StatsIndex;X];  
        
        elseif Stack3DMatrices
            if all(isnan(X)) ;
                X = NaN(size(StatsIndex,1),size(StatsIndex,2)); 
            end
            
                if not(isempty(X));
                    StatsIndex = cat(3, StatsIndex,X);
                end
        else
            if size(X,2) < size(StatsIndex,2) & iStat ~= 1;
                if NaNIfMissing; X(:, size(X,2)+1:size(StatsIndex,2)) = NaN ;end;
            elseif size(X,2) > size(StatsIndex,2) & iStat ~= 1;
                if NaNIfMissing;
                    StatsIndex(:,size(StatsIndex,2)+1:size(X,2)) = NaN;
                end;
            end
                StatsIndex= [StatsIndex;X]; 
        end;

        if iStat~= 1;
        if size(X,2) ~= size(StatsIndex,2) ;

        if size(X,2) > size(StatsIndex,2);
            if iStat-1 == 1;
            StatsIndex(:,size(StatsIndex,2)+1: size(X,2) ) = NaN;
            %disp('data added with NaNs... take a look here');
            else    
            X= X(:,1:size(StatsIndex,2) );
            %disp('data shrunk... take a look here');
            end
        else size(X,2) < size(StatsIndex,2);

           X = [X NaN(size(X,1),size(StatsIndex,2) - size(X,2))] ;
           %disp('data expanded... take a look here');
        end

        end
        end
    end
%end
 %StatsIndex = [StatsIndex; X]; %% changed by GC on 20/11/2019
elseif ischar(X) & Computation==11
    StatsIndex;
end

        
        clear X
    end

end


