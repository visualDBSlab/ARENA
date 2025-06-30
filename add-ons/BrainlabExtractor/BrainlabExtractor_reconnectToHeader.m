function [outputArg1,outputArg2] = BrainlabExtractor_warpToNative(menu,eventdata,scene)

%get input
try
    master = menu.Parent.Parent.UserData.master;
catch
    msgbox('No master image was found! First add the master image to the menu. Then try again.')
    return
end

[files,folder] = uigetfile('*.nii','Get other images','MultiSelect','on');
if not(iscell(files))
    files = {files};
end


% load untouched master
disp('--- loading master')
template = load_untouch_nii(master);

for i = 1:numel(files)
    disp(['--- loading file ',num2str(i)])
    vta = load_untouch_nii(fullfile(folder,files{i}));
    
    %cast to the same type
    if not(strcmp(class(template.img),class(vta.img)))
        disp(['--- casting to: ',class(template.img)])
        img = cast(vta.img,class(template.img));
    else
        img = vta.img;
    end
    

    %take the first slice in a 4D dataset
    if length(size(img))==4
        disp('--- taking first slice')
        img = img(:,:,:,1);
    end
    
    
    %Set the right order of dimensions
    disp('--- setting the right order of dimensions X Y Z')
    S = [template.hdr.hist.srow_x(1:3);...
        template.hdr.hist.srow_y(1:3);...
        template.hdr.hist.srow_z(1:3)];
    [~,xyz] = max(abs(S));
    img = permute(img,xyz);
    
    disp('--- setting the right direction R A S')
    %Set the right direction of the data (flipping)
    flip_axes = S(sub2ind([3,3],xyz,1:3))<0;
    for f = 1:3
        if flip_axes(f)
            disp(['--- + flipping axis ',num2str(f)])
            img = flip(img,f);
        end
    end
    
    
    template.img = img;
    disp(['--- saving file ',num2str(i)])
    save_untouch_nii(template,fullfile(folder,['reconnected_',files{i}]))
    disp(' ')


end

Done


end

