function [Out] = RemoveFieldsFromStrucrue(Input,F)
% GC Made this function
Out = Input  ; 
for iField = 1  : numel(F)
    if isfield(Input,F{iField})
    Out = rmfield(Out , F{iField});
    end
end

end

