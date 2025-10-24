function [] = HeatmapMaker_Lazy(menu,eventdata,scene)
%HEATMAPMAKER_LAZY Summary of this function goes here
%   Detailed explanation goes here
    global BrainlabMirror
    switch menu.Checked
        case 'on'
            BrainlabMirror = false;
            menu.Checked = 'off';

        case 'off'
            BrainlabMirror = true;
            menu.Checked = 'on';

    end
end

