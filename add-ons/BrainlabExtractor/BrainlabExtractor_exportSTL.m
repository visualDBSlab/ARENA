function BrainlabExtractor_exportSTL(menu,eventdata,scene)
    dcm = menu.Parent.UserData;
    LPSorigin = dcm.raw_corner.getArray();

    if any(isinf(LPSorigin))
        for iS = 1:numel(menu.Parent.Parent.Children)
            sibling = menu.Parent.Parent.Children(iS);
            if isa(sibling.UserData,'Dicom')
                LPSorigin = sibling.UserData.raw_corner.getArray();
                if not(any(isinf(LPSorigin)))
                    disp(['Origin is missing. Therefore origin is used from: ',sibling.Text])
                    break
                end
            end
        end
    end
    fullwidth = dcm.RAS_VoxelData.R.ImageSize .* [dcm.RAS_VoxelData.R.PixelExtentInWorldX,dcm.RAS_VoxelData.R.PixelExtentInWorldY,dcm.RAS_VoxelData.R.PixelExtentInWorldZ];
    


    actor = scene.getSelectedActors(scene);
    switch class(actor.Data)
        case 'ObjFile'
            actor.Data.convertToMesh.RAS2LPSImageSpaceCorrection(LPSorigin,fullwidth).stlwrite([actor.Tag,'.stl'])
        case 'Mesh'
            actor.Data.RAS2LPSImageSpaceCorrection(LPSorigin,fullwidth).stlwrite([actor.Tag,'.stl'])
    end
    
disp([actor.Tag,'.stl is saved in current folder: ',pwd])


end