function [outputArg1,outputArg2] = HeatmapMaker_exportHostsToRecipe(menu,eventdata,scene)
SUBFOLDERNAME = 'subfolder';

waitfor(msgbox('Select outputfolder (a subfolder will be created and filled with all electrodes in this scene)'))
parent_folder = uigetdir();


for iActor = 1:numel(scene.VTAstorage)
    thisVTA = scene.VTAstorage(iActor);

    subfolderName = thisVTA.Tag;
    output_folder = fullfile(parent_folder,subfolderName);
    if ~exist(output_folder,'dir')
        mkdir(output_folder)
    end

    %get electrode:
    E = thisVTA.Electrode.copy();
    E.Space = thisVTA.Space;
    E.VTA = VTA.empty(); %MAYBE I SHOULD ADD VTA nii EXPORT TOO.
    E.saveToFolder(output_folder,'host')


   %get VTA

    thisVTA.Volume.makeBinary(max(thisVTA.Volume.Voxels(:))/2).saveToFolder(output_folder,'host')


end

T = table;
T.folderID{1,1} = SUBFOLDERNAME;
T.fullpath{1,1} = output_folder;
T.ENTER_SCORE_LABEL_AND_VALUES(1,1) = 0;
T. Move_or_keep_left(1,1) = 1;
writetable(T,fullfile(parent_folder,'recipe.xlsx'))
Done;
disp(['--> Recipe is saved in: ',parent_folder]);
disp('BE AWARE THIS STEP HAS SET ALL SPACES TO MNI. IF THIS IS NOT THE CASE, ANY ANALYSIS WILL BE INVALID')
end