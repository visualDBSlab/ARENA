function [outputArg1,outputArg2] = BrainlabExtractor_AssignMaster(menu,eventdata,scene)
%BRAINLABEXTRACTOT_ASSIGNMASTER Summary of this function goes here
%   Detailed explanation goes here

[actorlist,namelist,indexlist] =  ArenaScene.getActorsOfClass(scene,'Slicei');
indx = listdlg("PromptString",'Select the image','ListString',[{'...browse'},namelist],'ListSize',[300,160]);
if indx==1
    [filename,foldername] = uigetfile('*.nii','Locate the native template');
    if filename==0
        return
    end
else
    thisActor = actorlist(indx-1);
    foldername = tempdir;
    filename = thisActor.Tag;
    thisActor.Data.parent.savenii(fullfile(foldername,filename))
end

%update the menu text
splt = strsplit(foldername(1:end-1),'/');
menuname = [splt{end},filesep,filename];
menu.Text = ['Master: ',menuname];


%save the filename
menu.Parent.UserData.master = fullfile(foldername,filename);
    

end

