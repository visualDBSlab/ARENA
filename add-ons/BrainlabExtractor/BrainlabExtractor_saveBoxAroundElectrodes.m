function [outputArg1,outputArg2] = BrainlabExtractor_saveBoxAroundElectrodes(menu,eventdata,scene)

    actors = scene.getActorsOfClass(scene,'Electrode');
    if numel(actors)>2
        actors = scene.getSelectedActors();
    end
    
    pc = PointCloud;
    for iActor = 1:numel(actors)
        thisActor = actors(iActor);
        pc.addVectors(thisActor.Data.C0)
    end
    
    center = pc.getCOG;
    padding = Vector3D(50,50,50);
    rightup= center + padding;
    leftdown = center - padding;
    
    indx = scene.selectActor();
    cropped = scene.Actors(indx).Data.parent.crop(leftdown,rightup);
    new = cropped.getslice.see(scene);
    new.changeName(['cropped ',scene.Actors(indx).Tag])
end


