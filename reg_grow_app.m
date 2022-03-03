function I=reg_grow_app(Image,seed_coord,reg_maxdist,range,forb_region)
% This function performs "region growing" in a 3D image from a specified seed
%
% The region is iteratively grown by comparing all unallocated neighbouring pixels to the region. 
% The difference between a pixel's intensity value and the region's mean, 
% is used as a measure of similarity. The pixel with the smallest difference 
% measured this way is allocated to the respective region. 
% This process stops when the intensity difference between region mean and
% new pixel become larger than a certain treshold (t)

if(exist('reg_maxdist','var')==0), reg_maxdist=0.15; end
if(exist('range','var')==0)
    range(1,1) = 1; range(2,1) = 1; range(3,1) = 1;
    range(1,2) = size(Image,1); range(2,2) = size(Image,2); range(3,2) = size(Image,3); 
end
if(exist('forb_region','var')==0); forb_region = zeros(size(Image)); end

Image = im2double(Image);
x1 = seed_coord(1); y1 = seed_coord(2); z1 = seed_coord(3); %Original coordinates
x = x1-range(1,1)+1; y = y1-range(2,1)+1; z = z1-range(3,1)+1; %New image coordinates
I = Image(range(1,1):range(1,2),range(2,1):range(2,2),range(3,1):range(3,2));
Forb = forb_region(range(1,1):range(1,2),range(2,1):range(2,2),range(3,1):range(3,2));
J = zeros(size(I)); % Output 
Isizes = size(I); % Dimensions of input image

reg_mean = I(x,y,z); % The mean of the segmented region
reg_size = 1; % Number of pixels in region

% Free memory to store neighbours of the (segmented) region
neg_free = 10000; neg_pos=0;    no_neg=0;
neg_list = zeros(neg_free,4); 

pixdist=0; % Distance of the region newest pixel to the regio mean

% Neighbor locations (footprint)
neigb=[-1 0 0; 1 0 0; 0 -1 0; 0 1 0; 0 0 -1; 0 0 1];

% Start regiogrowing until distance between regio and posible new pixels become
% higher than a certain treshold
%CONTINUO A CRESCERE FINO A CHE LA DISTANZA DALLA REGIONE E' DI DIMENSIONE
%MINORE AL VALORE DI SOGLIA CHE HO IMPOSTATO
tic
while(pixdist<reg_maxdist && reg_size<numel(I) && toc < 180 && no_neg==0) %LA REGIONE DEVE ESSERE PIU PICCOLA DI TUTTA L'IMMAGINE
    % Add new neighbors pixels
    for j=1:size(neigb,1) %VEDO TUTTI I POSSIBILI VICINI IMPOSTATI IN PRECEDENZA
        % Calculate the neighbour coordinate
        xn = x +neigb(j,1); yn = y +neigb(j,2); zn = z +neigb(j,3);
        
        % Check if neighbour is inside or outside the image
        ins=(xn>=1)&&(yn>=1)&&(zn>=1)&&(xn<=Isizes(1))&&(yn<=Isizes(2))&&(zn<=Isizes(3));
        
        % Add neighbor if inside and not already part of the segmented area
        if(ins&&(J(xn,yn,zn)==0)&&Forb(xn,yn,zn)==0) 
                neg_pos = neg_pos+1;
                neg_list(neg_pos,:) = [xn yn zn I(xn,yn,zn)];
                J(xn,yn,zn)=1;
        end
    end
    if neg_pos==0
        no_neg=1;
        continue
    end
    % Add a new block of free memory
    if(neg_pos+10>neg_free), neg_free=neg_free+10000; neg_list((neg_pos+1):neg_free,:)=0; end
    
    % Add pixel with intensity nearest to the mean of the region, to the region
    dist = abs(neg_list(1:neg_pos,4)-reg_mean);
    [pixdist, index] = min(dist);
    J(x,y,z)=2; reg_size=reg_size+1;
    
    % Calculate the new mean of the region
    reg_mean= (reg_mean*reg_size + neg_list(index,4))/(reg_size+1);
    
    % Save the x and y coordinates of the pixel (for the neighbour add proccess)
    x = neg_list(index,1); y = neg_list(index,2); z = neg_list(index,3);
    
    % Remove the pixel from the neighbour (check) list
    neg_list(index,:)=neg_list(neg_pos,:);
    neg_pos=neg_pos-1;

end

% Return the segmented area as logical matrix
J=J>1;
I= zeros(size(Image));
I(range(1,1):range(1,2),range(2,1):range(2,2),range(3,1):range(3,2)) = (J)*255;
I = uint8(I);
end



