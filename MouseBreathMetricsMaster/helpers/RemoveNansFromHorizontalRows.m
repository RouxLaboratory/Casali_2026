function Input = RemoveNansFromHorizontalRows(Input)

Output = isnan(Input) ;

Input(sum(Output,2)>0,:) = [];


end