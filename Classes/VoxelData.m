classdef VoxelData <handle &  matlab.mixin.Copyable
    %VOXELDATA contains Voxels [3D array], R [imref], can load nii.
    %   Detailed explanation goes here

    properties
        Voxels
        R
    end

    properties (Hidden)
        SourceFile
        Tag
    end


    methods
        function obj = VoxelData(varargin)
            %VOXELDATA Construct an instance of this class
            %   Detailed explanation goes here
            if nargin==1
                if ischar(varargin{1})
                    if isfile(varargin{1})
                        obj = obj.loadnii(varargin{1});
                    else
                        warning(['input (',varargin{1},') is not a valid filename.. (it has to include .nii)'])

                    end

                else
                    if and(isnumeric(varargin{1}),length(size(varargin{1}))==3)
                        %make an imref that centers the volume
                        obj.Voxels = varargin{1};
                        obj.R = imref3d(size(varargin{1}));
                        obj.originToCenter()

                    end

                end
            elseif nargin==2
                obj.Voxels = varargin{1};
                obj.R = varargin{2};
            end
        end

        function obj = originToCenter(obj) %why Jonas??
            obj.R.XWorldLimits = obj.R.XWorldLimits - mean(obj.R.XWorldLimits);
            obj.R.YWorldLimits = obj.R.YWorldLimits - mean(obj.R.YWorldLimits);
            obj.R.ZWorldLimits = obj.R.ZWorldLimits - mean(obj.R.ZWorldLimits);
        end


        function objout = setVoxelSizeTo(obj,mm)

            switch class(mm)
                case 'Vector3D'
                    mmx = mm.x;
                    mmy = mm.y;
                    mmz = mm.z;
                case 'double'
                    if length(mm)==1
                        mmx = mm;
                        mmy = mm;
                        mmz = mm;
                    elseif length(mm)==3
                        mmx = mm(1);
                        mmy = mm(2);
                        mmz = mm(3);
                    else
                        error('VoxelSize should be 1x1, or 1x3 or a Vector3D')
                    end

            end

            newR = imref3d(obj.R.ImageSize,mmx,mmy,mmz);
            newVoxelData = VoxelData(obj.Voxels,newR);

            %re-align centers
            move = newVoxelData.getCenter - obj.getCenter;
            newVoxelData.R.XWorldLimits = newVoxelData.R.XWorldLimits - move.x;
            newVoxelData.R.YWorldLimits = newVoxelData.R.YWorldLimits - move.y;
            newVoxelData.R.ZWorldLimits = newVoxelData.R.ZWorldLimits - move.z;

            if nargout==1
                objout = newVoxelData;
            elseif nargout==0
                obj.Voxels = newVoxelData.Voxels;
                obj.R = newVoxelData.R;
                objout = obj;
            end

        end

        function out = mask(obj,maskVD)
            maskVD_w=maskVD.warpto(obj);
            if nargout ==1
                out = VoxelData();
                out.Voxels = obj.Voxels;
                out.R = obj.R;

                out.Voxels(not(maskVD_w.Voxels))=nan;
            else

                obj.Voxels(not(maskVD_w.Voxels))=nan;
            end
        end


        function objout = move(obj,v3D)
            %does not overwrite the obj, unless no output is requested.
            newVoxelData = VoxelData;
            newVoxelData.Voxels = obj.Voxels;
            newVoxelData.R = obj.R;

            %move the imref
            newVoxelData.R.XWorldLimits = newVoxelData.R.XWorldLimits + v3D.x;
            newVoxelData.R.YWorldLimits = newVoxelData.R.YWorldLimits + v3D.y;
            newVoxelData.R.ZWorldLimits = newVoxelData.R.ZWorldLimits + v3D.z;

            if nargout==1
                objout = newVoxelData;
            else
                obj.Voxels = newVoxelData.Voxels;
                obj.R = newVoxelData.R;
                objout = newVoxelData;
            end
        end

        function center = getCenter(obj)
            center = Vector3D(mean(obj.R.XWorldLimits),...
                mean(obj.R.YWorldLimits),...
                mean(obj.R.ZWorldLimits));
        end


        function savenii(obj,filename)
            if nargin==1
                filename = obj.Tag;

                while exist(fullfile(cd,[filename,'.nii']))==2
                    filename = [filename,'_copy'];
                end
                filename = [filename,'.nii'];
            end

            [x,y,z] = obj.R.worldToIntrinsic(0,0,0);
            spacing = [obj.R.PixelExtentInWorldX,obj.R.PixelExtentInWorldY,obj.R.PixelExtentInWorldZ];
            origin = [x y z];
            datatype = 16;%64;
            nii = make_nii(double(permute(obj.Voxels,[2 1 3])), spacing, origin, datatype);
            save_nii(nii,filename);
        end

        function savedcm(obj,dicomFilename)
            % Inputs:
            %   obj - Your custom class object containing `img` (3D array) and `R` (imref3d).
            %   dicomFilename - File path where the multiframe DICOM will be saved.

            assert(ndims(obj.Voxels) == 3, 'Image volume must be 3D.');

            voxels = reshape(obj.Voxels,[obj.R.ImageSize(1),obj.R.ImageSize(2),1,obj.R.ImageSize(3)]);

            % Extract spatial referencing from imref3d
            spatialRef = obj.R;

            % Prepare metadata (customize to your use-case)
            metadata.PatientName = 'SamplePatient';
            metadata.PatientID = '12345';
            metadata.Modality = 'MR';  % Example modality (can be CT, MR, etc.)
            metadata.SeriesDescription = 'Falafel is good';
            metadata.PixelSpacing = [spatialRef.PixelExtentInWorldX, spatialRef.PixelExtentInWorldY];
            metadata.SliceThickness = spatialRef.PixelExtentInWorldZ;
            metadata.SOPClassUID = '1.2.840.10008.5.1.4.1.1.4';

            % Define the spatial referencing for each slice
            numSlices = size(obj.Voxels, 3); % Number of slices along the 3rd dimension
            imagePositions = zeros(numSlices, 3);
            zStart = spatialRef.ZWorldLimits(1); % Starting Z-world coordinate

            for i = 1:numSlices
                zWorld = zStart + (i - 1) * spatialRef.PixelExtentInWorldZ;
                imagePositions(i, :) = [spatialRef.XWorldLimits(1), spatialRef.YWorldLimits(1), zWorld];
            end

            % Custom multiframe metadata
            metadata.ImagePositionPatient = imagePositions;
            metadata.NumberOfFrames = numSlices;

            % Write multiframe DICOM file
            dicomwrite(uint16(voxels), dicomFilename, metadata, 'CreateMode', 'copy', 'Multiframe', true);

            disp(['Multiframe DICOM saved to: ', dicomFilename]);
        end



        function outdir = saveniidlg(obj)
            [name,folder] = uiputfile('*.nii');
            outdir = fullfile(folder,name);
            obj.savenii(outdir)
        end

        function obj = importSuretuneDataset(obj,dataset)
            if isa(dataset,'Dataset')
                volume = dataset.volume;
            elseif isa(dataset,'Volume')
                volume = dataset;
            end

            a = 1;
            b = 2;
            c = 3;
            info = volume.volumeInfo;
            voxels = permute(volume.voxelArray,[2 1 3]);
            R = imref3d(info.dimensions([2 1 3]),info.spacing(a),info.spacing(b),info.spacing(c));
            R.XWorldLimits = R.XWorldLimits+info.origin(a)-info.spacing(a);%-Rfrom.ImageExtentInWorldX;
            R.YWorldLimits = R.YWorldLimits+info.origin(b)-info.spacing(b);%-Rfrom.ImageExtentInWorldY;
            R.ZWorldLimits = R.ZWorldLimits+info.origin(c)-info.spacing(c);

            disp('LPS to RAS warp is automatically applied')
            [imOut,rOut] = imwarp(voxels,R,affine3d(diag([-1 -1 1 1])));
            obj.Voxels = imOut;
            obj.R = rOut;
        end

        function cropped = trim(obj)
            %get min and max per x,y,z
            containsData = find(obj.Voxels~=0);
            [xi,yi,zi] = ind2sub(size(obj.Voxels),containsData);
            [ld.x,ld.y,ld.z] = obj.R.intrinsicToWorld(min(yi),min(xi),min(zi));
            [ru.x,ru.y,ru.z] = obj.R.intrinsicToWorld(max(yi),max(xi),max(zi));

            if ~isa(obj.Voxels,'double')
                obj.Voxels = double(obj.Voxels);
            end
            %crop
            cropped = crop(obj,ld,ru);

            if nargout==0
                obj.Voxels = cropped.Voxels;
                obj.R = cropped.R;
            end
        end

        function obj = squeeze(obj)
            %get leftdown and rightup based on where data is.
            [x,y,z] = ind2sub(size(obj.Voxels),find(obj.Voxels>0));
            [leftdownx,leftdowny,leftdownz] = obj.R.intrinsicToWorld(min(x)-5,min(y)-5,min(z)-5); %5 voxel margin
            [rightupx,rightupy,rightupz] = obj.R.intrinsicToWorld(max(x)+5,max(y)+5,max(z)+5);





            obj2 = obj.crop([leftdownx,leftdowny,leftdownz],[rightupx,rightupy,rightupz]);
            if nargout
                obj = obj2;
            else
                obj.Voxels = obj2.Voxels;
                obj.R = obj2.R;
            end


        end

        function obj = crop(obj,leftdown,rightup)
            if not(isa(leftdown,'Vector3D'))
                leftdown = Vector3D(leftdown);
                rightup = Vector3D(rightup);
            end

            X = obj.R.XWorldLimits;
            Y = obj.R.YWorldLimits;
            Z = obj.R.ZWorldLimits;
            %get the voxelindices at boundingbox edges
            [ldy,ldx,ldz] = obj.R.worldToSubscript(max([leftdown.x,X(1)]),max([leftdown.y,Y(1)]),max([leftdown.z,Z(1)]));
            [ruy,rux,ruz] = obj.R.worldToSubscript(min([rightup.x,X(2)]),min([rightup.y,Y(2)]),min([rightup.z,Z(2)]));

            %crop voxels
            v  = obj.Voxels(ldy:ruy,ldx:rux,ldz:ruz);

            %voxel size correction
            vxlsz = [obj.R.PixelExtentInWorldX,obj.R.PixelExtentInWorldY,obj.R.PixelExtentInWorldZ];

            %make new imref
            new_x_span = [obj.R.XWorldLimits(1)+obj.R.PixelExtentInWorldX*ldx,...
                obj.R.XWorldLimits(1)+obj.R.PixelExtentInWorldX*(rux+1)] - vxlsz(1);

            new_y_span = [obj.R.YWorldLimits(1)+obj.R.PixelExtentInWorldY*ldy,...
                obj.R.YWorldLimits(1)+obj.R.PixelExtentInWorldY*(ruy+1)]- vxlsz(2);

            new_z_span = [obj.R.ZWorldLimits(1)+obj.R.PixelExtentInWorldZ*ldz,...
                obj.R.ZWorldLimits(1)+obj.R.PixelExtentInWorldZ*(ruz+1)]- vxlsz(3);



            sz = size(v);
            newR = imref3d(sz,new_x_span,new_y_span,new_z_span);


            %save

            if nargout==1 %make a copy (default is overwrite)
                obj = CroppedVoxelData(obj.Voxels,obj.R,leftdown,rightup,obj);
            end
            obj.Voxels = v;
            obj.R = newR;


        end

        function cropped = convertToCropped(obj)
            leftdown = Vector3D([obj.R.XWorldLimits(1),...
                obj.R.YWorldLimits(1),...
                obj.R.ZWorldLimits(1)]);
            rightup = Vector3D([obj.R.XWorldLimits(2),...
                obj.R.YWorldLimits(2),...
                obj.R.ZWorldLimits(2)]);
            cropped = CroppedVoxelData(obj.Voxels,obj.R,leftdown,rightup,obj);
        end

        %         function newVD = copy(obj)
        %             newVD = VoxelData(obj.Voxels,obj.R);
        %             newVD.SourceFile = obj.SourceFile;
        %             newVD.Tag = obj.Tag;
        %         end

        function [obj,filename] = loadnii(obj,niifile,noreslice)

            if nargin==1
                [filename,pathname] = uigetfile('*.nii','Find nii image');
                if filename==0
                    return
                end
                niifile = fullfile(pathname,filename);

                noreslice = 0;%checkIfReslicingIsRecommended(niifile);
                %noreslice = 0;
            elseif nargin==2
                noreslice = 0;%checkIfReslicingIsRecommended(niifile);
            elseif nargin==3
                if ischar(noreslice)
                    switch lower(noreslice)
                        case 'true'
                            noreslice = 1;
                        case 'false'
                            noreslice = 0;
                        otherwise
                            error('cannnot interpret if I should reslice or not, please use 0 or 1')
                    end
                end
            else
                [~,filename] = fileparts(niifile);
            end

            if not(contains(niifile,'.nii'));error('input has to be a nifti file');end

            tempname = [datestr(datetime('now'),'yyyymmddhhMMss'),'.nii'];

            if noreslice %for heatmaps: reslicing might alter voxelvalues slightly.
                warning('Reslicing is turned off.')
                loadednifti = load_untouch_nii(niifile);
                slope = loadednifti.hdr.dime.scl_slope;
                intercept = loadednifti.hdr.dime.scl_inter;

            else %reslicing might change your data slightly, but rotates the data when a rotation is saved in the header.
                % reslicing is recommended for normal use.

                %check for multiple slices
                hdr = load_nii_hdr(niifile);
                if hdr.dime.dim(5)>1 %4D
                    answer = inputdlg(['Enter space-separated numbers [1 - ',num2str(hdr.dime.dim(5)),'] or 0 to load all:'],...
                        'Sample', [1 50]);
                    user_val = str2num(answer{1});

                    if any(user_val)==0
                        user_val = 1:hdr.dime.dim(5);
                    end

                    if numel(user_val)>1
                        vds = VoxelDataStack;

                    end
                    for i = 1:numel(user_val)
                        reslice_nii(niifile,fullfile(tempdir,tempname),[],[],[],[],user_val(i));
                        vdtemp = VoxelData;
                        vdtemp.loadnii(fullfile(tempdir,tempname),'true')
                        if numel(user_val)>1
                            vds.InsertVoxelDataAt(vdtemp,i)
                            vds.Weights(i) = user_val(i);
                            if isempty(vds.R)
                                vds.R = vdtemp.R;
                            end
                        end
                    end
                    if numel(user_val)>1
                        obj = vds;
                        return
                    else
                        obj.Voxels = vdtemp.Voxels;
                        obj.R = vdtemp.R;
                        return
                    end

                else %3D
                    reslice_nii(niifile,fullfile(tempdir,tempname));
                    loadednifti = load_nii(fullfile(tempdir,tempname));
                    delete(fullfile(tempdir,tempname));
                    slope = 1;
                    intercept = 0;
                end
            end

            if length(size(loadednifti.img))>3
                error(['This nifti has ',num2str(length(size(loadednifti.img))),' dimensions. VoxelData supports only 3D data. You can try to load nii in a VoxelDataStack.'])
            end
            obj.Voxels = permute(loadednifti.img,[2 1 3])*slope+intercept;

            dimensions = loadednifti.hdr.dime.dim(2:4);
            voxelsize = loadednifti.hdr.dime.pixdim(2:4);
            transform = [loadednifti.hdr.hist.srow_x;...
                loadednifti.hdr.hist.srow_y;...
                loadednifti.hdr.hist.srow_z;...
                0 0 0 1];



            % make imref
            Ref = imref3d(dimensions([2 1 3]),voxelsize(1),voxelsize(2),voxelsize(3));
            Ref.XWorldLimits = Ref.XWorldLimits+transform(1,4)-voxelsize(1);
            Ref.YWorldLimits = Ref.YWorldLimits+transform(2,4)-voxelsize(2);
            Ref.ZWorldLimits = Ref.ZWorldLimits+transform(3,4)-voxelsize(3);

            obj.R = Ref;
            obj.SourceFile = niifile;
            [~,filename] = fileparts(niifile);
            obj.Tag = filename;

            function noreslice = checkIfReslicingIsRecommended(niifile)
                hdr = load_nii_hdr(niifile);
                %get the SFORM transformation matrix
                T = [hdr.hist.srow_x;hdr.hist.srow_y;hdr.hist.srow_z;0 0 0 1]';

                %switch of scaling
                T(eye(4)>0.5)= 1;

                noreslice = affine3d(T).isRigid;

            end
        end

        function bool = isProbablyAMesh(obj)
            ratioOfNonZero = nnz(obj.Voxels)/numel(obj.Voxels);
            DataTendency=mean(obj.Voxels(obj.Voxels~=0));
            bool = ratioOfNonZero < 0.1;

        end

        function [bool, percentage_nonbinary] = isBinary(obj,slack)
            if nargin==1
                %default slack is 0%
                slack = 0;
            end
            v = obj.Voxels;
            high = v==max(v(:));
            low = v==min(v(:));

            inbetween = not(or(high,low));
            percentage_nonbinary = sum(inbetween(:))/numel(v(:))*100;

            if percentage_nonbinary <= slack
                bool = true;
            else
                bool = false;
            end


        end

        function out = setContrast(obj,slope,intercept)
            if nargout==1
                out = VoxelData((o1.Voxels*slope)+intercept,obj.R);
            else
                obj.Voxels = (obj.Voxels*slope)+intercept;
            end
        end

        function obj = setCorner(obj,corner)
            current_corner = [obj.R.XWorldLimits(1),obj.R.YWorldLimits(1),obj.R.ZWorldLimits(1)];
            delta =corner-Vector3D(current_corner);
            obj.move(delta)
            
        end

        function showprojection(o1,view)

            [i,j,k] = o1.R.worldToIntrinsic(0,0,0);
            Origin_vxl = round([i,j,k]);
            if nargin == 1;view = 'a';end
            switch lower(view)
                case {'sagittal','s','sag'}
                    slice = squeeze(sum(o1.Voxels,2))';
                    origin_index = [2,3];
                case {'coronal','c','cor'}
                    slice = squeeze(sum(o1.Voxels,1))';
                    origin_index = [1,3];
                case {'axial','a','ax','axi'}
                    slice = sum(o1.Voxels,3);
                    origin_index = [1,2];
            end
            figure;imshow(slice/max(slice(:)));
            hold on
            scatter(Origin_vxl(origin_index(1)),Origin_vxl(origin_index(2)),'r','filled')
            ax = gca;
            ax.YDir = 'normal';

        end

        function showorigin(obj,view)
            [i,j,k] = obj.R.worldToIntrinsic(0,0,0);
            Origin_vxl = round([i,j,k]);
            if nargin == 1;view = 'a';end
            switch lower(view)
                case {'sagittal','s','sag'}
                    slice = squeeze(obj.Voxels(:,Origin_vxl(1),:))';
                    origin_index = [2,3];
                case {'coronal','c','cor'}
                    slice = squeeze(obj.Voxels(Origin_vxl(2),:,:))';
                    origin_index = [1,3];
                case {'axial','a','ax','axi'}
                    slice = obj.Voxels(:,:,Origin_vxl(3));
                    origin_index = [1,2];
            end
            figure;imshow(slice/max(slice(:)));
            hold on
            scatter(Origin_vxl(origin_index(1)),Origin_vxl(origin_index(2)),'r','filled')
            ax = gca;
            ax.YDir = 'normal';
        end

        function [meshobj,T] = getmesh(obj,T)
            if not(isdouble(obj))
                if islogical(obj.Voxels)
                    T = 0.5;
                end
                obj = obj.double();
            end

            try
                meshobj = Mesh(obj,T);
            catch
                meshobj = Mesh(obj);
                T = meshobj.Settings.T;
            end

            if not(isempty(obj.Tag))
                meshobj.Label = obj.Tag;
            else
                if not(isempty(inputname(1)))
                    meshobj.Label = inputname(1);
                end
            end
        end

        function sliceobj = getslice(obj)
            sliceobj = Slicei;
            sliceobj.getFromVoxelData(obj);

            %             if nargin>1
            %                 sliceobj = Slice(obj,x,y,z);
            %             else
            %                 sliceobj = Slice(obj);
            %             end

            if not(isempty(obj.Tag))
                sliceobj.Tag = obj.Tag;
            else
                if not(isempty(inputname(1)))
                    sliceobj.Tag = inputname(1);
                end
            end
        end


        function [x,y,z] = getMeshgrid(obj)
            [x_coords,y_coords,z_coords]= obj.getlinspace;
            [x,y,z] = meshgrid(x_coords,y_coords,z_coords);

        end

        function value = getValueAt(obj,coordinate)
            [X,Y,Z] = obj.getMeshgrid();

            if isa(coordinate,'Vector3D')
                value = interp3(X,Y,Z,obj.Voxels,coordinate.x,coordinate.y,coordinate.z);
            elseif isa(coordinate,'PointCloud')
                value = [];

                allVectors = coordinate.Vectors.getArray;
                value = interp3(X,Y,Z,double(obj.Voxels),allVectors(:,1),allVectors(:,2),allVectors(:,3));

            end
        end

        function out_obj = changevoxelsizeto(obj,newvoxelsize)
            currently = [obj.R.PixelExtentInWorldX,obj.R.PixelExtentInWorldY,obj.R.PixelExtentInWorldZ];
            if numel(newvoxelsize)==1
                newvoxelsize = repmat(newvoxelsize,1,3);
            end
            disp(['Changing voxelsize from: ',num2str(currently),' to: ',num2str(newvoxelsize)])

            newSize = obj.R.ImageSize .*currently./newvoxelsize;

            template = VoxelData;
            template.R = imref3d(newSize,...
                obj.R.XWorldLimits,...
                obj.R.YWorldLimits,...
                obj.R.ZWorldLimits);

            upsampled = obj.warpto(template);
            if nargout == 1
                obj.Voxels = upsampled.Voxels;
                obj.R = upsampled.R;
                out_obj = obj;
            else
                out_obj = upsampled;
            end
        end




        function o3 = and(o1,o2)

            img1 = o1.Voxels;
            img2 = o2.Voxels;

            if not(islogical(img1))
                error('input 1 should be binary')
            end
            if not(islogical(img2))
                error('input 2 should be binary')
            end

            o3 = VoxelData(and(img1,img2),o1.R);
        end

        function o3 = times(o1,o2)
            img1 = o1.Voxels;
            if isa(o2,'VoxelData')
                img2 = o2.Voxels;
                o3 = VoxelData(img1.*img2,o1.R);
            else %assuming o2 is a number
                o3 = VoxelData(img1*o2,o1.R);
            end



        end

        function val = corr(o1,o2,statmethod)
            v1 = o1.Voxels(:);
            v2 = o2.Voxels(:);

            remove = or(isnan(v1),isnan(v2));
            v1(remove) = [];
            v2(remove) = [];

            if nargin==3
                %Statmethod can be Pearson, Spearmann, Kendall
                val = corr(v1,v2,'Type',statmethod);
            else
                val = corr(v1,v2);
            end

        end
        

        function o3 = minus(o1,o2)
            img1 = o1.Voxels;
            img2 = o2.Voxels;

            o3 = VoxelData(img1-img2,o1.R);
        end

        function o3 = plus(varargin)

            Stack=VoxelDataStack;
            Stack.R=varargin{1}.R;

            if not(all(size(varargin{1})==size(varargin{2})))
                varargin{2} = varargin{2}.warpto(varargin{1});
                warning('Adding VoxelDatas of different dimensions. A+B, B = warped to A, in order to proceed. Please check input')
            end

            for iStack=1:numel(varargin)
                Stack.Voxels(:,:,:,iStack)= varargin{iStack}.Voxels;
            end

            o3=Stack.sum;
            o3.Tag = varargin{1}.Tag;
        end


        function out = zeros(obj)
            if nargout ==1
                out = VoxelData(zeros(size(obj.Voxels)),obj.R);
            else
                obj.Voxels = zeros(size(obj.Voxels));
            end
        end

        function out = ones(obj)
            if nargout ==1
                out = VoxelData(ones(size(obj.Voxels)),obj.R);
            else
                obj.Voxels = zeros(size(obj.Voxels));
            end
        end



        function out = round(o1)
            if nargout==1
                out = VoxelData(round(o1.Voxels), o1.R);
            else
                o1.Voxels = round(o1.Voxels);
            end
        end

        function out = total(o1)
            out = nansum(o1.Voxels(:));
        end

        function out = gt(o1,o2)
            switch class(o2)
                case 'VoxelData'
                    out = VoxelData(o1.Voxels > o2.warpto(o1).Voxels,o1.R);
                case 'double'
                    out = VoxelData(o1.Voxels > o2, o1.R);
            end
        end

        function out = ge(o1,o2)
            switch class(o2)
                case 'VoxelData'
                    out = VoxelData(o1.Voxels >= o2.warpto(o1).Voxels,o1.R);
                case 'double'
                    out = VoxelData(o1.Voxels >= o2, o1.R);
            end
        end

        function out = le(o1,o2)
            switch class(o2)
                case 'VoxelData'
                    out = VoxelData(o1.Voxels <= o2.warpto(o1).Voxels,o1.R);
                case 'double'
                    out = VoxelData(o1.Voxels <= o2, o1.R);
            end
        end

        function out = lt(o1,o2)
            switch class(o2)
                case 'VoxelData'
                    out = VoxelData(o1.Voxels < o2.warpto(o1).Voxels,o1.R);
                case 'double'
                    out = VoxelData(o1.Voxels < o2, o1.R);
            end
        end

        function out = mean(obj)
            out = nanmean(obj.Voxels(:));
        end

        function out = numvox(obj)
            out = numel(obj.Voxels);
        end
        function maxvalue = max(obj)
            maxvalue = max(obj.Voxels(:));
        end

        function bool = isdouble(obj)
            bool = strcmp(class(obj.Voxels),'double');
        end


        function out = double(obj)
            if nargout==1
                out = VoxelData(double(obj.Voxels),obj.R);
                out.Tag = obj.Tag;
            else
                obj.Voxels = double(obj.Voxels);
            end
        end




        function o3=combineBinary(o1,o2);
            img1 = o1.Voxels;
            img2 = o2.Voxels;

            o3=VoxelData(double(nanmax(img1,img2)),o1.R);
        end

        function vd_out = abs(vd)
            if nargout==1
                vd_out = VoxelData(abs(vd.Voxels),vd.R);
            else
                vd.Voxels = abs(vd.Voxels);
                vd_out =  vd;
            end
        end

        function vd_out = changeToNan(vd,value)
            if nargout==1
                vd_out = VoxelData(vd.Voxels,vd.R);
                vd_out.Voxels(vd_out.Voxels==value) = nan;
            else
                vd.Voxels(vd.Voxels==value) = nan;
                vd_out = vd;
            end


        end

        function value = dice(o1,o2)
            value = dice(o1.Voxels>0,o2.Voxels>0);
        end


        function center_of_gravity = getcog(obj)
            [yq,xq,zq] = meshgrid(1:size(obj.Voxels,2),...
                1:size(obj.Voxels,1),...
                1:size(obj.Voxels,3));

            xm = xq(:)'*double(obj.Voxels(:)) / sum(obj.Voxels(:));
            ym = yq(:)'*double(obj.Voxels(:)) / sum(obj.Voxels(:));
            zm = zq(:)'*double(obj.Voxels(:)) / sum(obj.Voxels(:));

            center_of_gravity_internal = [ym,xm,zm];
            [x,y,z] = obj.R.intrinsicToWorld(center_of_gravity_internal(1),center_of_gravity_internal(2),center_of_gravity_internal(3));
            center_of_gravity = Vector3D([x,y,z]);
        end

        function [x_coords,y_coords,z_coords] = getlinspace(obj)
            v = obj.Voxels;
            %squeeze the data into one dimension
            v_x = sum(sum(v,3),1);
            v_y = sum(sum(v,3),2);
            v_z = squeeze(sum(sum(v,2),1));

            %convert the voxel locations to worldlocations
            [firstX,firstY,firstZ] = obj.R.intrinsicToWorld(1,1,1);
            [lastX,lastY,lastZ] = obj.R.intrinsicToWorld(length(v_x),length(v_y),length(v_z));

            %define the x-axis values
            x_coords = linspace(firstX,lastX,length(v_x));
            y_coords = linspace(firstY,lastY,length(v_y));
            z_coords = linspace(firstZ,lastZ,length(v_z));
        end


        function obj = imclose(obj,width)
            se = strel('disk',width);
            obj.Voxels = imclose(obj.Voxels,se);

        end

        function imerode(obj,width)
            se = strel('sphere',width);
            obj.Voxels = imerode(obj.Voxels,se);
        end

        function out = imdilate(obj,width)
            se = strel('sphere',width);


            if nargout==0
                obj.Voxels = imdilate(obj.Voxels,se);
            else
                out= VoxelData(imdilate(obj.Voxels,se),obj.R);
            end

        end


        function setValueAtWorldLocation(obj,value,location)
            if isa(location,'Vector3D')
                location = location.getArray();
            end

            [x,y,z] = obj.R.worldToSubscript(location(1),location(2),location(3));
            obj.Voxels(x,y,z) = value;
        end

        function T = getTransformToIntrinsic(obj)
            T = inv(obj.getTransformToWorld);
        end

        function T = getTransformToWorld(obj)
            T = zeros(4);
            T(1,1) = obj.R.PixelExtentInWorldX;
            T(2,2) = obj.R.PixelExtentInWorldY;
            T(3,3) = obj.R.PixelExtentInWorldZ;
            T(4,4) = 1;

            x = obj.R.XWorldLimits(1)-0.5 * T(1,1);
            y = obj.R.YWorldLimits(1)-0.5 * T(2,2);
            z = obj.R.ZWorldLimits(1)-0.5 * T(3,3);

            T(4,1:3) = [x,y,z]';
        end



        function Vq = getValueAtWorldLocation(obj,location)
            if isa(location,'Vector3D')
                location = location.getArray();
            end
            if numel(location)>3

                %[Xq,Yq,Zq] = obj.R.worldToIntrinsic(location(:,1),location(:,2),location(:,3));
                Xq = location(:,1);
                Yq = location(:,2);
                Zq = location(:,3);
            else
                [Xq,Yq,Zq] = obj.R.worldToIntrinsic(location(1),location(2),location(3));
            end

            [X,Y,Z] = obj.getMeshgrid;
            Vq = interp3(X,Y,Z,obj.Voxels,Xq,Yq,Zq);
            %value = obj.Voxels(x,y,z);
        end

        function values = getValuesAtVerticesOfPatch(obj,patch)
            switch class(patch)
                case 'matlab.graphics.primitive.Patch'
                    c = patch.Vertices;
                case 'PointCloud'
                    c = patch.getArray;

            end

            values = obj.getValueAtWorldLocation(c)
        end


        function [fwhm,f] = getDensityDistribution(obj)
            v = obj.Voxels;

            %squeeze the data into one dimension
            v_x = sum(sum(v,3),1);
            v_y = sum(sum(v,3),2);
            v_z = squeeze(sum(sum(v,2),1));

            %convert the voxel locations to worldlocations
            [firstX,firstY,firstZ] = obj.R.intrinsicToWorld(1,1,1);
            [lastX,lastY,lastZ] = obj.R.intrinsicToWorld(length(v_x),length(v_y),length(v_z));

            %define the x-axis values
            x_coords = linspace(firstX,lastX,length(v_x));
            y_coords = linspace(firstY,lastY,length(v_y));
            z_coords = linspace(firstZ,lastZ,length(v_z));

            %interpolate
            xCi = linspace(firstX,lastX,length(v_x)*10);
            yCi = linspace(firstY,lastY,length(v_y)*10);
            zCi = linspace(firstZ,lastZ,length(v_z)*10);

            xVi = interp1(x_coords,v_x,xCi,'pchip');
            yVi = interp1(y_coords,v_y,yCi,'pchip');
            zVi = interp1(z_coords,v_z,zCi,'pchip');

            %plot
            f = figure; hold on
            set(f,'DefaultLineLineWidth',2)
            p = plot(xCi,xVi,'r',yCi,yVi,'g',zCi,zVi,'b');



            %find the xlim (to only include data >0)
            minCoord = min([xCi(find(xVi>0,1,'first')),...
                yCi(find(yVi>0,1,'first')),...
                zCi(find(zVi>0,1,'first'))]);

            maxCoord = max([xCi(find(xVi>0,1,'last')),...
                yCi(find(yVi>0,1,'last')),...
                zCi(find(zVi>0,1,'last'))]);

            xlim([minCoord,maxCoord])
            legend({'x','y','z'})

            %FWHM
            x_1 = xCi(find(xVi>max(xVi)/2,1,'first'));
            x_2 = xCi(find(xVi>max(xVi)/2,1,'last'));

            y_1 = yCi(find(yVi>max(yVi)/2,1,'first'));
            y_2 = yCi(find(yVi>max(yVi)/2,1,'last'));

            z_1 = zCi(find(zVi>max(zVi)/2,1,'first'));
            z_2 = zCi(find(zVi>max(zVi)/2,1,'last'));

            patch([x_1 x_1 x_2 x_2],[0 max(xVi)/2 max(xVi)/2 0],'red','FaceAlpha',0.4);
            patch([y_1 y_1 y_2 y_2],[0 max(yVi)/2 max(yVi)/2 0],'green','FaceAlpha',0.4);
            patch([z_1 z_1 z_2 z_2],[0 max(zVi)/2 max(zVi)/2 0],'blue','FaceAlpha',0.4);

            legend({'x','y','z','FWHM x','FWHM y','FWHM z'})

            %output
            fwhm.x = x_2-x_1;
            fwhm.y = y_2-y_1;
            fwhm.z = z_2-z_1;
            fwhm.xrange = [x_1 x_2];
            fwhm.yrange = [y_1 y_2];
            fwhm.zrange = [z_1 z_2];
            fwhm.xCi = xCi;
            fwhm.yCi = yCi;
            fwhm.zCi = zCi;
            fwhm.xVi = xVi;
            fwhm.yVi = yVi;
            fwhm.zVi = zVi;


        end


        function normalizeToMNI(obj,otherFiles)

            %make tempdir
            mkdir(fullfile(tempdir,'SPMfiles'))
            other = {};

            %write obj
            if not(isempty(obj.Tag))
                filename = fullfile(tempdir,'SPMfiles',obj.Tag);
            else
                filename = fullfile(tempdir,'template.nii');
            end
            obj.savenii(filename)

            other{end+1} = [filename,',1'];
            sourceDir = [filemame',1'];

            if nargin==2

                for i = length(otherFiles)
                    if isa(otherFiles(i),'VoxelDaa')
                        if not(isempty(otherFiles(i).Tag))
                            filename = fullfile(tempdir,'SPMfiles',otherFiles(i).Tag);
                        else
                            filename = fullfile(tempdir,[num2str(i),'.nii']);
                        end
                        otherFiles(i).warpto(obj).savenii(filename)
                        other{end+1} = [filename,',1'];
                    end
                end
            end

            global arena
            lead_MNI_dir = [arena.Settings,'templates/space/MNI_ICBM_2009b_NLIN_ASYM/TPM.nii'];

            %make matlab batch
            matlabbatch{1}.spm.spatial.normalise.estwrite.subj.vol ={sourceDir};
            matlabbatch{1}.spm.spatial.normalise.estwrite.subj.resample = otherDir;
            matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001;
            matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60;
            matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {lead_MNI_dir};
            %matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {fullfile(SPMdir,'Tpm/TPM.nii')};
            matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.affreg = 'mni';
            matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.reg = [0 0.001 0.5 0.05 0.2];
            matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0;
            matlabbatch{1}.spm.spatial.normalise.estwrite.eoptions.samp = 3;
            matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.bb = [-78 -112 -70 78 76 85];
            matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.vox = [1 1 1];
            matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.estwrite.woptions.prefix = 'temp_';


            spm_jobman('run', matlabbatch);




        end



        function see(obj,OPTIONALscene)
            if nargin==2
                obj.getmesh().see(OPTIONALscene);
            else
                obj.getmesh().see();
            end
        end

        function Points = detectPoints(obj)
            bw = obj.Voxels>25;
            [labels,n] = bwlabeln(bw);
            Points = Vector3D.empty;
            for iL = 1:n
                [x,y,z] = ind2sub(size(obj.Voxels),find(labels==iL));
                [xw,yw,zw] = obj.R.intrinsicToWorld(y,x,z);
                Points(iL) = Vector3D(mean(xw),mean(yw),mean(zw));
            end


        end

        function newobj = warpto(obj,target,T)
            if nargin==2
                T = affine3d(eye(4));
            end

            if isa(target,'VoxelData')
                R = target.R;
            elseif isa(target,'imref3d')
                R = target;
            elseif isa(target,'VoxelDataStack')
                R = target.R;
            elseif isa(target,'Heatmap')
                R = target.R;
            else
                error('input requirments: obj, target, T.  Your target seems invalid.')
            end

            inputVoxels = double(obj.Voxels);
            inputVoxels(isnan(inputVoxels)) = 0;
            newVoxels = imwarp(inputVoxels,obj.R,T,'OutputView',R);

            %restore binary data if it was binary
            if islogical(obj.Voxels)
                newVoxels = newVoxels>0.5;
            end

            if nargout==1
                newobj = VoxelData(newVoxels,R);
            else
                obj.Voxels = newVoxels;
                obj.R = R;
            end
        end

        function newObj = imwarp(obj,T)
            if nargin ==1
                T = affine3d(eye(4));
            end
            if and(not(isa(T,'affine3d')),numel(T==16))
                T = round(T,6);
                try
                    T = affine3d(T);
                catch
                    T = affine3d(T');
                end
            end

            obj.Voxels(isnan(obj.Voxels))= 0;

            if nargout==0
                disp('Transformation is applied on original object')
                [obj.Voxels,obj.R] = imwarp(obj.Voxels,obj.R,T,'cubic');
            else
                disp('Transformation is applied on new object')
                [Voxels,R] = imwarp(obj.Voxels,obj.R,T,'cubic');
                newObj = VoxelData(Voxels,R);
                newObj.Tag = [obj.Tag,'_warped'];
            end
        end

        function newObj = mirror(obj)

            [imOut,rOut] = imwarp(obj.Voxels,obj.R,affine3d(diag([-1 1 1 1])));

            if nargout==1
                newObj = VoxelData(imOut,rOut);
            else
                newObj = obj;
                newObj.Voxels = imOut;
                newObj.R = rOut;
            end

        end

        function subscript = pointToSubscript(obj,point)
            % Convert the world coordinates to voxel indices
            [x,y,z] = obj.R.worldToSubscript(point.x,point.y,point.z);

            % Extract the subscript indices from the voxel indices
            subscript = [x,y,z];

        end

        function subscript = pointToIntrinsic(obj,point)
            % Convert the world coordinates to voxel indices
            [x,y,z] = obj.R.worldToIntrinsic(point.x,point.y,point.z);

            % Extract the subscript indices from the voxel indices
            subscript = [x,y,z];
        end

        function binaryObj = makeBinaryPos(obj)
            if nargout==1
                binaryObj = obj.copy;
                binaryObj.Voxels = obj.Voxels>0;
            else
                obj.Voxels = obj.Voxels>0;
            end
        end


        function binaryObj = makeBinaryNeg(obj)
            if nargout==1
                binaryObj = obj.copy;
                binaryObj.Voxels = obj.Voxels<0;
            else
                obj.Voxels = obj.Voxels<0;
            end
        end

        function binaryObj = makeBinary(obj,T)
            if nargin==1

                if obj.isBinary
                    T = 0.5;
                else
                    %ask for user input
                    histf = figure;histogram(obj.Voxels(:),50);
                    set(gca, 'YScale', 'log')
                    try
                        fcnNames = {'WindowButtonDownFcn','WindowButtonMotionFcn'}; %https://www.mathworks.com/matlabcentral/answers/22461-ginput-is-turning-off-mouse-cursor
                        fcnVals = get(gcf,fcnNames);
                        oldFcnNameValPairs = cat(1, fcnNames, fcnVals);
                        [T,~] = ginput(1);
                        set(gcf, oldFcnNameValPairs{:});
                    catch
                        error('user canceled')
                    end
                    close(histf)
                end
            end

            %Assuming that the foreground is an element on top of the
            %background:
            if obj.Voxels(1,1,1)<T


                if nargout==1
                    binaryObj = obj.copy;
                    binaryObj.Voxels = obj.Voxels>T;
                else
                    obj.Voxels = obj.Voxels>T;
                end
            else
                if nargout==1
                    binaryObj = obj.copy;
                    binaryObj.Voxels = obj.Voxels<T;
                else
                    obj.Voxels = obj.Voxels<T;
                end
            end
        end

        function obj = polishVTA(obj)
            obj = obj.makeBinary(0.5).imclose(3).smooth().makeBinary(0.5);
        end

        function [PointCloudWorld,PointCloudIntrinsic,indcs] = getCoordinatesOfBinary(obj)
            if not(obj.isBinary)
                warning('Input data is not binary. Run function .makeBinary(0.5) first.')
                PointCloudWorld = nan;
                PointCloudIntrinsic = nan;
                return
            end

            indcs = find(obj.Voxels);
            [intrinsic_x,intrinsic_y,intrinsic_z] = ind2sub(obj.size,indcs);
            [world_x,world_y,world_z] = obj.R.intrinsicToWorld(intrinsic_y,intrinsic_x,intrinsic_z);

            PointCloudWorld = PointCloud([world_x,world_y,world_z]);
            PointCloudIntrinsic= PointCloud([intrinsic_x,intrinsic_y,intrinsic_z]);


        end

        function [dims,dims2,dims3] = size(obj)
            if or(nargout==1,nargout==0)
                dims = size(obj.Voxels);
                
            elseif nargout==3
                dims123 = size(obj.Voxels);
                dims= dims123(1);
                dims2 = dims123(2);
                dims3 = dims123(3);
            else
                error('wroing number of output arguments. Use 1 or 3.')
            end

        end
        function [CubicMM,voxelcount] = getCubicMM(obj,T)
            if not(all(islogical(obj.Voxels)))
                if nargin==1
                    obj = makeBinary(obj);
                elseif nargin==2
                    obj = makeBinary(obj,T);
                end
            end

            voxelsBW = obj.Voxels;
            voxelcount = sum(double(voxelsBW(:)));
            voxelsize = obj.R.PixelExtentInWorldX * obj.R.PixelExtentInWorldY * obj.R.PixelExtentInWorldZ;
            CubicMM = voxelcount * voxelsize;

        end


        function [cellarray, scalaroutput,sizelist] = seperateROI(obj)
            cellarray = {};
            v = obj.Voxels;

            if not(islogical(v))
                v_bw = v > 0.5;
            else
                v_bw = v;
            end

            [L,n] = bwlabeln(v_bw);

            sizelist = [];
            for i = 0:n
                region = (L==i);
                sizelist(i+1) = sum(region(:));
                region = int16(region);
                region_voxeldata = VoxelData(region,obj.R);
                cellarray{i+1} = region_voxeldata;
            end

            scalaroutput = VoxelData(L,obj.R);


        end
        function savenii_withSourceHeader(obj,filename)

            disp('Saving nii with source header. Note: voxelvalues are unaffected.')
            nii.img = double(permute(obj.Voxels,[2 1 3]));
            nii.hdr = load_nii_hdr(obj.SourceFile);

            %nii.hdr.dime.scl_slope = 0;
            save_nii(nii,filename)
        end

        function saveToFolder(obj,outdir,tag)
            savenii(obj,fullfile(outdir,[tag,'.nii']))
        end

        function obj_out=smooth(obj,size,sd)
            if nargin==1
                v = smooth3(obj.Voxels);
            elseif nargin==2
                v = smooth3(obj.Voxels,'box',size);
            elseif nargin==3
                v = smooth3(obj.Voxels,'gaussian',size,sd);
            end

            if nargout==1
                obj_out = VoxelData(v,obj.R);
            else
                obj.Voxels = v;
                obj_out = obj;
            end

        end

        function whatis(obj)
            disp('VOXELDATA')
            disp('---------')
            whatis(obj.Voxels)
        end

    end
end

