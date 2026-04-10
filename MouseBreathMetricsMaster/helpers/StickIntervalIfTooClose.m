function  out = StickIntervalIfTooClose(in,MinDistance)
out = in;
if size(out,1)>1 & size(out,2)==2;
ContinueGlue = any( in(2:end,1)-in(1:end-1,2)<MinDistance) ;
while ContinueGlue
  
    
    
out(...
[find(out(2:end,1)-out(1:end-1,2)<MinDistance)]+1,1) = out([find(out(2:end,1)-out(1:end-1,2)<MinDistance)]+0,1);

out =ConsolidateIntervals(out);
ContinueGlue = any( out(2:end,1)-out(1:end-1,2)<MinDistance) ;
    
end
end
end