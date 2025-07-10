function [outputArg1,outputArg2] = BrainlabExtractor_AssignBI(menu,eventdata,scene)
%BRAINLABEXTRACTOR_DEFINEBI Summary of this function goes here
%   Detailed explanation goes here

%BI stands for Burned-In
[actorlist,namelist,indexlist] =  ArenaScene.getActorsOfClass(scene,'Slicei');
indx = listdlg("PromptString",'Select other image(s)','ListString',[{'...browse'},namelist],'ListSize',[300,160],'SelectionMode','multiple');

if indx==1
    [Otherfilename,Otherfoldername] = uigetfile('*.nii','Get other images','MultiSelect','on');
    if ~iscell(Otherfilename)
        if Otherfilename==0
            return
        end
    end
    
    if not(iscell(Otherfilename))
        Otherfilename = {Otherfilename};
    end
else
    Otherfilename = {};
    Otherfoldername = tempdir;
    for i = indx
        thisActor = actorlist(i-1);
        filename = thisActor.Tag;
        thisActor.Data.parent.savenii(fullfile(Otherfoldername,filename))
        Otherfilename{end+1} = filename;
    end
menu.Text = ['Other: ',num2str(numel(Otherfilename))];


%save the filename
menu.Parent.UserData.Otherfilename = Otherfilename;
menu.Parent.UserData.Otherfoldername = Otherfoldername;
end

