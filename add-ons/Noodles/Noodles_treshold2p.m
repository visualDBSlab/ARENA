function [fibersOut] = Noodles_treshold2p (fibers, treshold) %get new bundle of supratreshold fibers

fibersOut = Fibers();



for iBundle = 1:numel(fibers)
 
     for iFiber = 1:numel (fibers{iBundle}.Indices)

         if abs(fibers{iBundle}.Weight(1,iFiber))>treshold

             fibersOut.Vertices(end+1)=fibers{iBundle}.Vertices(1,iFiber);
             fibersOut.Weight(end+1)=fibers{iBundle}.Weight(1,iFiber);
             fibersOut.Indices(end+1)=fibers{iBundle}.Indices(1,iFiber);
         end

     end
end

end



            

   
