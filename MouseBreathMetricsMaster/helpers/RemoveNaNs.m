function [ ArrayWithOutNaNs ] = RemoveNaNs( ArrayWithNaNs );
%Deletes NANs from an vector...

if ~any(isnan(ArrayWithNaNs)) | ~any(isinf(ArrayWithNaNs)) ;
    
    %disp ( 'NO NANS, fine');
    ArrayWithOutNaNs = ArrayWithNaNs;
else
    
if size(ArrayWithNaNs,2)>1
   ArrayWithNaNs(find(nansum(isnan(ArrayWithNaNs),2)),:) = [];
else
    ArrayWithNaNs(find(isnan(ArrayWithNaNs)))=[];
end
ArrayWithOutNaNs = ArrayWithNaNs;

end

ArrayWithOutNaNs;
end

