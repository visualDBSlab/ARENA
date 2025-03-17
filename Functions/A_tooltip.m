
function [anchors] = A_tooltip(scene)
    anchors = Anchors(scene);

    for iActor = 1:numel(scene.Actors)
        thisActor = scene.Actors(iActor);
        anchors.addActor(thisActor)
    end

    anchors.update2D()

    set(scene.handles.figure, 'WindowButtonMotionFcn', {@mouseMove,anchors})
    set(scene.handles.figure,'WindowButtonDownFcn',{@selectActor,anchors})
    set(scene.handles.figure,'WindowKeyPressFcn','')

    %--> the Anchors class has a copy of the original callbacks, which will
    %be restored as soon as .select() is executed.

    
end

function selectActor(fig,~,anchors)
    set(anchors.scene.handles.figure, 'WindowButtonMotionFcn', {@mouseMove,anchors})
    set(anchors.scene.handles.figure,'WindowButtonDownFcn',{@selectActor,anchors})
    set(anchors.scene.handles.figure,'WindowKeyPressFcn','')
    switch fig.SelectionType
        case 'extend'
            anchors.shiftselect()
            
        otherwise
            anchors.select()
            
            
    end

end


function mouseMove(fig,event,anchors)
        
        %get cursor position
        C = get(anchors.scene.handles.axes, 'CurrentPoint');
        Cursor3D = C(1,:);

        %find closest
        indx = anchors.findClosestTo3D(Cursor3D);

        %draw line
        anchors.connect(indx,Cursor3D)
        
     
    end






