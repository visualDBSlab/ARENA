function [outputArg1,outputArg2] = BrainlabExtractor_AssignBI(menu,eventdata,scene)
%BRAINLABEXTRACTOR_DEFINEBI Summary of this function goes here
%   Detailed explanation goes here

%BI stands for Burned-In

[Otherfilename,Otherfoldername] = uigetfile('*.nii','Get other images','MultiSelect','on');
    if ~iscell(Otherfilename)
        if Otherfilename==0
            return
        end
    end
    
    if not(iscell(Otherfilename))
        Otherfilename = {Otherfilename};
    end
menu.Text = ['Other: ',num2str(numel(Otherfilename))];


%save the filename
menu.Parent.UserData.Otherfilename = Otherfilename;
menu.Parent.UserData.Otherfoldername = Otherfoldername;
    


end

