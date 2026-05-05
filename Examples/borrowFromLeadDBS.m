function borrowT1FromLeadDBS()
    disp('trying to copy t1.nii from lead-dbs')
    load(fullfile(ArenaManager.getrootdir(),'config.mat'))
    from = fullfile(config.leadDBS,'templates','space','MNI_ICBM_2009b_NLIN_ASYM','t1.nii');
    to = fullfile(fileparts(mfilename('fullpath')),'t1.nii');
    copyfile(from,to)
end
