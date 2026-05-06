function borrowT1FromLeadDBS()
    disp('trying to copy t1.nii from lead-dbs')
    load(fullfile(ArenaManager.getrootdir(),'config.mat'))
    from = fullfile(config.leadDBS,'templates','space','MNI_ICBM_2009b_NLIN_ASYM','t1.nii');
    if ~exist(from)
        from = fullfile(config.leadDBS,'templates','space','MNI152NLin2009bAsym','t1.nii');
        if ~exist(from)
            print('Unable to find t1.nii')
            return
        end
    end
    to = fullfile(fileparts(mfilename('fullpath')),'t1.nii');

    copyfile(from,to)
    disp('copy succesful')
end
