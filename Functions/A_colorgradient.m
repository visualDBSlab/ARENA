function [grad,im]=A_colorgradient(c1,c2,c3,depth)
if and(numel(c3)==1,nargin==3) %if c3 is depth
    grad = halfGradient(c1,c2,c3);
else
    gradient_1 = halfGradient(c1,c2,floor(depth/2));
    gradient_2 = halfGradient(c2,c3,floor(depth/2));

    if mod(depth/2,1)>0
        grad = [gradient_1;c2;gradient_2];
    else
        grad = [gradient_1;gradient_2];
    end
end


function [grad,im] = halfGradient(c1,c2,depth)
%A_COLORGRADIENT allows you to generate a gradient between 2 given colors,
% that can be used as colormap in your figures.
%
% USAGE:
%
% [grad,im]=getGradient(c1,c2,depth)
%
% INPUT:
% - c1: color vector given as Intensity or RGB color. Initial value.
% - c2: same as c1. This is the final value of the gradient.
% - depth: number of colors or elements of the gradient.
%
% OUTPUT:
% - grad: a matrix of depth*3 elements containing colormap (or gradient).
% - im: a depth*20*3 RGB image that can be used to display the result.
%
% EXAMPLES:
% grad=colorGradient([1 0 0],[0.5 0.8 1],128);
% surf(peaks)
% colormap(grad);
%
% --------------------
% [grad,im]=colorGradient([1 0 0],[0.5 0.8 1],128);
% image(im); %display an image with the color gradient.
% Copyright 2011. Jose Maria Garcia-Valdecasas Bernal
% v:1.0 22 May 2011. Initial release.
%Check input arguments.
%input arguments must be 2 or 3.
error(nargchk(2, 3, nargin));
%If c1 or c2 is not a valid RGB vector return an error.
if numel(c1)~=3
    error('color c1 is not a valir RGB vector');
end
if numel(c2)~=3
    error('color c2 is not a valir RGB vector');
end
if max(c1)>1&&max(c1)<=255
    %warn if RGB values are given instead of Intensity values. Convert and
    %keep procesing.
    warning('color c1 is not given as intensity values. Trying to convert');
    c1=c1./255;
elseif max(c1)>255||min(c1)<0
    error('C1 RGB values are not valid.')
end
if max(c2)>1&&max(c2)<=255
    %warn if RGB values are given instead of Intensity values. Convert and
    %keep procesing.
    warning('color c2 is not given as intensity values. Trying to convert');
    c2=c2./255;
elseif max(c2)>255||min(c2)<0
    error('C2 RGB values are not valid.')
end
%default depth is 64 colors. Just in case we did not define that argument.
if nargin < 3
    depth=64;
end
%determine increment step for each color channel.
dr=(c2(1)-c1(1))/(depth-1);
dg=(c2(2)-c1(2))/(depth-1);
db=(c2(3)-c1(3))/(depth-1);
%initialize gradient matrix.
grad=zeros(depth,3);
%initialize matrix for each color. Needed for the image. Size 20*depth.
r=zeros(20,depth);
g=zeros(20,depth);
b=zeros(20,depth);
%for each color step, increase/reduce the value of Intensity data.
for j=1:depth
    grad(j,1)=c1(1)+dr*(j-1);
    grad(j,2)=c1(2)+dg*(j-1);
    grad(j,3)=c1(3)+db*(j-1);
    r(:,j)=grad(j,1);
    g(:,j)=grad(j,2);
    b(:,j)=grad(j,3);
end
%merge R G B matrix and obtain our image.
im=cat(3,r,g,b);
