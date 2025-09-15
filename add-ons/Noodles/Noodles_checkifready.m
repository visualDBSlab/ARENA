function [outputArg1,outputArg2] = Noodles_checkifready(workflow,scene)
%NOODLES_CHECKIFREADY Summary of this function goes here
%   Detailed explanation goes here
disp('checking status...')
load('NoodlesConfig')
switch lower(workflow)
    case 'basic'
        if all([not(isempty(NoodlesConfig.fibers)),...
                not(isempty(NoodlesConfig.Cohort1)),...
                not(isempty(NoodlesConfig.Cohort2))])
            set(NoodlesConfig.handles.run,'Enable','on')
            answer = questdlg('Your preparations are admirable','Huzzah!','Proceed with vigour','I beg your forgiveness, I must demure','Proceed with vigour');
            switch answer
                case 'Proceed with vigour'
                    Noodles_runbasic(nan,nan,scene)
            end
                    
        end
    case 'recipe'
        
        if all([not(isempty(NoodlesConfig.fibers)),...
                not(isempty(NoodlesConfig.Recipe1)),...
                 not(isempty(NoodlesConfig.Recipe2))])
            set(NoodlesConfig.handles.runrecipe,'Enable','on')
            answer = questdlg('Looks like you are ready to go','Nice!','Start analysis','Nope, not yet','Start analysis');
                switch answer
                    case 'Start analyis'
                        Noodles_runrecipe(nan,nan,scene)
                end
        end


end
end
