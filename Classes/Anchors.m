classdef Anchors < handle
    %ANCHOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        v3D
        v2D
        color
        label
        n = 0
        scene
        handle
        indx
        indcs
        handle_frozen = {};
        callback_backup = {};
    end
    
    
    methods
        function obj = Anchors(scene)
            obj.scene = scene;
            obj.newTextBox();
            obj.save_callback();
        end

        function save_callback(obj)
            obj.callback_backup{1} = get(obj.scene.handles.figure, 'WindowButtonMotionFcn');
            obj.callback_backup{2} = get(obj.scene.handles.figure,'WindowKeyPressFcn');
            obj.callback_backup{3} = get(obj.scene.handles.figure,'WindowButtonUpFcn');
        end

        function restore_callback(obj)
            set(obj.scene.handles.figure, 'WindowButtonMotionFcn',obj.callback_backup{1})
            set(obj.scene.handles.figure, 'WindowKeyPressFcn',obj.callback_backup{2})
            set(obj.scene.handles.figure, 'WindowButtonUpFcn',obj.callback_backup{3})
            
        end


        function newTextBox(obj)
            obj.handle.line = plot3([0,0],[0,0],[0,0]);
            obj.handle.txt = text(0,0,'','Interpreter', 'none'); 

        end

        function obj = addActor(obj,actor)
            switch class(actor.Data)
                case 'Mesh'
                    if ~isempty(actor.Anchor)
                        actor.Anchor = actor.getCOG;
                    end
                    
                    obj.n = obj.n+1;
                    obj.v3D(obj.n,:) = actor.Anchor.getArray';
                    obj.color(obj.n,:) = actor.Visualisation.settings.colorFace;
                    obj.label{obj.n} = actor.Tag;
            end
                   
        end

        function update2D(obj)
            a = obj.scene.handles.axes;
            camTarget = a.CameraTarget;
            camPos = a.CameraPosition;
            camUp = a.CameraUpVector;
            fov = a.CameraViewAngle; 

            % Step 1: Compute camera's coordinate system
            z_cam = (camTarget - camPos) / norm(camTarget - camPos);  % Viewing direction (Z-axis)
            x_cam = cross(camUp, z_cam);  % Right direction (X-axis)
            x_cam = x_cam / norm(x_cam);  % Normalize
            y_cam = cross(z_cam, x_cam);  % Up direction (Y-axis)
        
            % Field of view scaling factor
            fov_rad = deg2rad(fov);  % Convert FOV to radians
            f = 1 / tan(fov_rad);  % Perspective scalar based on FOV
        
            % Step 2: Transform points to camera space
            numPoints = obj.n;  % Number of 3D points
            obj.v2D = zeros(numPoints, 2);  % Initialize projected points array

            for i = 1:numPoints
                p = obj.v3D(i, :);  % Current 3D point
        
                % Transform to camera space
                p_prime = p - camPos;  % Translate relative to camera position
                p_camera = [dot(x_cam, p_prime), dot(y_cam, p_prime), dot(z_cam, p_prime)];  % Camera-space coordinates
        
                % Step 3: Apply perspective projection (scale by depth)
                if p_camera(3) > 0  % Only project points in front of the camera
                    x_proj = f * p_camera(1) / p_camera(3);  % Perspective scaling for X
                    y_proj = f * p_camera(2) / p_camera(3);  % Perspective scaling for Y
                    obj.v2D(i, :) = [x_proj, y_proj];
                else
                    % If the Z component is non-positive, the point is behind the camera
                    obj.v2D(i, :) = [NaN, NaN];
                end
            end

        end
        
        function indx = findClosestTo3D(obj,cursor3D)
            %first warp 3D to 2D:
            cursor = Anchors(obj.scene);
            cursor.v3D = cursor3D;
            cursor.n = 1;
            cursor.update2D()

            %get distances
            distances = vecnorm(obj.v2D - cursor.v2D, 2, 2);
            [~, indx] = min(distances);
            obj.indx = indx;

        end
        

        function connect(obj,indx,Cursor3D)
            obj.handle.line.XData = [Cursor3D(1),obj.v3D(indx,1)];
            obj.handle.line.YData = [Cursor3D(2),obj.v3D(indx,2)];
            obj.handle.line.ZData = [Cursor3D(3),obj.v3D(indx,3)];
            obj.handle.line.Color = obj.color(indx,:);

            obj.handle.txt.Position = Cursor3D;
            obj.handle.txt.String = obj.label{indx};
            obj.handle.txt.BackgroundColor = obj.color(indx,:);
  


        end

        function hide(obj)
            obj.handle.line.Visible = 'off';
            obj.handle.txt.Visible = 'off';

            for iFrozen = 1:numel(obj.handle_frozen)
                obj.handle_frozen{iFrozen}.line.Visible = 'off';
                obj.handle_frozen{iFrozen}.txt.Visible = 'off';
            end
        end

        function shiftselect(obj)
            %obj.indcs(end+1) = obj.indx;

            %freeze_handle and make new one.
            %obj.handle_frozen{end+1} = obj.handle;
            %obj.newTextBox()

            %update layers
            %obj.scene.selectlayer(unique(obj.indcs))
        end

        function select(obj)
            obj.indcs = obj.indx;

            %hide
            obj.hide()

            %update layers
            obj.scene.selectlayer(obj.indcs)

            %restore callbacks
            obj.restore_callback()
        end
    end
end

