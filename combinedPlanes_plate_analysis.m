clear;
close all;
clc;

%% USER INPUTS
file = 'IMAGES_High_Def_20240227161441_2.nii';
tolerance = 3; % How many std deviations away from mean to be labeled as an artifact

frontalWellNumber = 1;
sagittalWellNumber = 5;

%% PROGRAM
global artifactPixelIntensities artifactPixelCount meanIntensity stdIntensity;
artifactPixelIntensities = [];
artifactPixelCount = 0;
meanIntensity = 0.320909645909646;
stdIntensity = 0.004835688973947;

% Load the MRI scan
Va = niftiread(file);
Va_info = niftiinfo(file);
pixelDims = Va_info.PixelDimensions;

% Calculate the scaling factors for each dimension to fix image aspect
scaleFactor = [1, 1, pixelDims(3) / pixelDims(1)];

% Prepare the new size for z-dimension, maintaining the aspect ratio
newSize = ceil(size(Va) .* scaleFactor);

% Resize the volume
Va = imresize3(Va, newSize, 'nearest');

% Get the screen size and calculate the new position for figures
screenSize = get(0, 'ScreenSize');
newWidth = screenSize(3) * 0.75;
newHeight = screenSize(4) * 0.75;
newX = screenSize(1) + screenSize(3) * 0.125; 
newY = screenSize(2) + screenSize(4) * 0.125;
newPosition = [newX, newY, newWidth, newHeight];

% Normalize the scan values to be between 0 and 1
Vmax = max(Va,[],'all');
Vmin = min(Va,[],'all');
Va_prime = (double(Va) - double(Vmin)) ./ (double(Vmax) - double(Vmin));
totalPixels = numel(Va_prime);
dim = size(Va_prime);

% Define options for the dialog
list = {'Frontal', 'Sagittal', 'Horizontal'};
[selection, ok] = listdlg('PromptString', 'Select a plane to view:', ...
                          'SelectionMode', 'single', ...
                          'ListString', list, ...
                          'ListSize', [160, 100], ...
                          'Name', 'Plane Selection');

% Check if the user made a selection
if ok
    choice = selection;
else
    disp('User cancelled the selection');
    choice = 4;
end

% Use the choice variable as needed for further processing
switch choice
    case 1
        % Code for Frontal
        frontalWellCoords = {
            [297, 247, 331 - 297, 293- 247]; % Well 1
            [343, 247, 380 - 343, 293 - 247]; % Well 2
            [388, 247, 425 - 388, 293 - 247]; % Well 3
            [434, 247, 472 - 434, 293 - 247]; % Well 4
            };
        sliceZ = 310;
        userDone = false;
        plane = 1;

         while ~userDone
        % Ensure all GUI components are set up correctly
        hFig = figure('Name', 'MRI Slice Viewer', 'NumberTitle', 'off');
        set(hFig, 'Position', newPosition); % Make the figure full screen
        set(hFig, 'UserData', struct('currentSlice', sliceZ, 'Va_prime', Va_prime));

        % Adjust slider setup
        hSlider = uicontrol('Style', 'slider', 'Min',1, 'Max',size(Va_prime,3), 'Value',sliceZ, 'SliderStep', [1 10]./(size(Va_prime,3)-1), ...
            'Position', [20 20 300 20], 'Callback', @(src, evnt)displaySliceCallback(hFig, round(src.Value), dim, plane));

        % Add an event listener for mouse scroll wheel that updates the current slice
        set(hFig, 'WindowScrollWheelFcn', @(src, event) scrollWheelCallback(src, event, hSlider, plane));

        % Immediately display the initial slice
        displaySlice(hFig, sliceZ, dim, plane); % This line ensures the initial slice is displayed

        % Button for processing the currently viewed slice and disabling the slider
        hButtonProcess = uicontrol('Style', 'pushbutton', 'String', 'Save Slice & Process', 'Position', [440 20 150 30], ...
            'Callback', @(src, evnt)processCurrentSlice(hFig));

        % Pause script execution waiting for user to select the slice and process it
        uiwait(hFig);
        userData = get(hFig, 'UserData');
        finalslice = userData.finalslice; % Get the finalslice from UserData
        close(hFig);
        clc;

        horizontal = Va_prime(:,:,finalslice);

        % Process well
        wellRect = frontalWellCoords{frontalWellNumber};
        processWell(imrotate(horizontal, -90), wellRect, totalPixels, tolerance, newPosition, frontalWellNumber);
        uiwait(gcf)

        fprintf("Slice %d\n", finalslice)

        choice = questdlg('Do you want to process another slice?', ...
        'Continue Processing', ...
        'Yes', 'No', 'Yes');

        % Handle the user's choice
        switch choice
            case 'Yes'
                userDone = false;
            case 'No'
                userDone = true;
            otherwise
                userDone = true;
        end
        sliceZ = finalslice;

         end
         clc;
         meanArtifactIntensity = mean(artifactPixelIntensities);
         fprintf('Mean artifact intensity: %f\n', meanArtifactIntensity);

    case 2
        % Code for Sagittal
        sagittalWellCoords = {
            [58, 246, 95 - 55, 288 - 246];    % Well 1  0 mg/ml
            [104, 246, 144 - 104, 288 - 246]; % Well 2 17 mg/ml
            [156, 246, 187 - 156, 288 - 246]; % Well 3 34 mg/ml
            [198, 246, 234 - 198, 289 - 246]; % Well 4 51 mg/ml
            [249, 246, 279 - 249, 288 - 246]; % Well 5 68 mg/ml
            [294, 246, 326 - 294, 288 - 246]; % Well 6 85 mg/ml
            };

        sliceX = 200;
        userDone = false;
        plane = 2;
        
        while ~userDone
        % Ensure all GUI components are set up correctly
        hFig = figure('Name', 'MRI Slice Viewer', 'NumberTitle', 'off');
        set(hFig, 'Position', newPosition); % Make the figure full screen
        set(hFig, 'UserData', struct('currentSlice', sliceX, 'Va_prime', Va_prime));

        % Adjust slider setup
        hSlider = uicontrol('Style', 'slider', 'Min',1, 'Max',size(Va_prime,1), 'Value',sliceX, 'SliderStep', [1 10]./(size(Va_prime,3)-1), ...
            'Position', [20 20 300 20], 'Callback', @(src, evnt)displaySliceCallback(hFig, round(src.Value), dim, plane));

        % Add an event listener for mouse scroll wheel that updates the current slice
        set(hFig, 'WindowScrollWheelFcn', @(src, event) scrollWheelCallback(src, event, hSlider, plane));

        % Immediately display the initial slice
        displaySlice(hFig, sliceX, dim, plane); % This line ensures the initial slice is displayed

        % Button for processing the currently viewed slice and disabling the slider
        hButtonProcess = uicontrol('Style', 'pushbutton', 'String', 'Save Slice & Process', 'Position', [440 20 150 30], ...
            'Callback', @(src, evnt)processCurrentSlice(hFig));

        % Pause script execution waiting for user to select the slice and process it
        uiwait(hFig);
        userData = get(hFig, 'UserData');
        finalslice = userData.finalslice; % Get the finalslice from UserData
        close(hFig);
        clc;

        horizontal = reshape(Va_prime(finalslice,:,:), [dim(2) dim(3)]);

        % Process well
        wellRect = sagittalWellCoords{sagittalWellNumber};
        processWell(horizontal, wellRect, totalPixels, tolerance, newPosition, sagittalWellNumber);
        uiwait(gcf)

        fprintf("Slice %d", finalslice)

        choice = questdlg('Do you want to process another slice?', ...
        'Continue Processing', ...
        'Yes', 'No', 'Yes');
    
    % Handle the user's choice
    switch choice
        case 'Yes'
            userDone = false;
        case 'No'
            userDone = true;
        otherwise
            userDone = true;
    end

    sliceX = finalslice;
        end
clc;
meanArtifactIntensity = mean(artifactPixelIntensities);
fprintf('Mean artifact intensity: %f\n', meanArtifactIntensity);

    case 3
        % Code for Horizontal
        sliceY = 285;
        userDone = false;
        plane = 3;

     while ~userDone
        % Ensure all GUI components are set up correctly
        hFig = figure('Name', 'MRI Slice Viewer', 'NumberTitle', 'off');
        set(hFig, 'Position', newPosition); % Make the figure full screen
        set(hFig, 'UserData', struct('currentSlice', sliceY, 'Va_prime', Va_prime));

        % Adjust slider setup
        hSlider = uicontrol('Style', 'slider', 'Min',1, 'Max',size(Va_prime,1), 'Value',sliceY, 'SliderStep', [1 10]./(size(Va_prime,3)-1), ...
            'Position', [20 20 300 20], 'Callback', @(src, evnt)displaySliceCallback(hFig, round(src.Value), dim, plane));

        % Add an event listener for mouse scroll wheel that updates the current slice
        set(hFig, 'WindowScrollWheelFcn', @(src, event) scrollWheelCallback(src, event, hSlider, plane));

        % Immediately display the initial slice
        displaySlice(hFig, sliceY, dim, plane); % This line ensures the initial slice is displayed

        % Button for processing the currently viewed slice and disabling the slider
        hButtonProcess = uicontrol('Style', 'pushbutton', 'String', 'Save Slice & Process', 'Position', [440 20 150 30], ...
            'Callback', @(src, evnt)processCurrentSlice(hFig));

        % Pause script execution waiting for user to select the slice and process it
        uiwait(hFig);
        userData = get(hFig, 'UserData');
        finalslice = userData.finalslice; % Get the finalslice from UserData
        close(hFig);

        horizontal = reshape(Va_prime(:,finalslice,:), [dim(1) dim(3)]);

         % Process well
        wellRect = sagittalWellCoords{sagittalWellNumber};
        processWell(horizontal, wellRect, totalPixels, tolerance, newPosition, sagittalWellNumber);
        uiwait(gcf)

        choice = questdlg('Do you want to process another slice?', ...
        'Continue Processing', ...
        'Yes', 'No', 'Yes');
    
    % Handle the user's choice
    switch choice
        case 'Yes'
            userDone = false;
        case 'No'
            userDone = true;
        otherwise
            userDone = true;
    end
     end

    case 4
    otherwise
        % Handle no selection or cancellation
end

function processWell(imageSlice, wellRect, ~ , tolerance, newPosition, wellNum)
    global artifactPixelIntensities artifactPixelCount meanIntensity stdIntensity;
    
    % Crop the well region from the image slice
    wellImage = imcrop(imageSlice, wellRect);
    
    % Threshold for artifacts based on the mean and standard deviation
    artifactThreshold = meanIntensity + tolerance * stdIntensity;

    % Detect artifact pixels
    artifactMask = wellImage > artifactThreshold;
    artifactPixels = wellImage(artifactMask);

    % Update the global variables for artifact analysis
    artifactPixelIntensities = [artifactPixelIntensities; artifactPixels(:)];  % Append the intensities
    artifactPixelCount = artifactPixelCount + numel(artifactPixels);  % Update the pixel count

    % Visualization
    wellOverlay = overlayBoundaries(wellImage, artifactMask);

    % Display the result for the current well
    hFig = figure('Name', ['Artifacts in Well ' num2str(wellNum)]);
    imshow(wellOverlay);
    set(hFig, 'Position', newPosition); % Make the figure full screen
    title(sprintf('Well %d', wellNum));
end

function imgRGB = overlayBoundaries(horizontalImage, artifactMask)
    % Define green color for artifacts
       artifactPixelColor = [0, 255, 0];
    
    % Ensure the mask is logical
    artifactMask = logical(artifactMask);
    
    % Convert the original image to RGB if it's not already
    if size(horizontalImage, 3) == 1
        imgRGB = repmat(horizontalImage, [1, 1, 3]);
    else
        imgRGB = horizontalImage;  % Assuming horizontalImage is already an RGB image
    end
    
    % Overlay green color on the artifact pixels within the specified artifact area
    for c = 1:3
        imgChannel = imgRGB(:,:,c);
        % Apply the green color only to the artifact pixels
        imgChannel(artifactMask) = artifactPixelColor(c);
        imgRGB(:,:,c) = imgChannel;
    end
end


% Slider callback simplified
function displaySliceCallback(hFig, sliceNum, dim, plane)
    displaySlice(hFig, sliceNum, dim, plane);
end

% Function to process the current slice, disable the slider, and close the figure
function processCurrentSlice(hFig)
    userData = get(hFig, 'UserData');
    currentSlice = userData.currentSlice;

    % Logic to determine finalslice based on choice
    userData.finalslice = currentSlice; % Store final slice in UserData
    set(hFig, 'UserData', userData); % Save UserData back to the figure
    uiresume(hFig); % Signal that the event is done  
end

% Function to update and display the selected slice
function displaySlice(hFig, sliceNum, dim, plane)
    data = get(hFig, 'UserData');
    if plane == 1
        horizontal = data.Va_prime(:,:,sliceNum);
        rotate = -90;
    elseif plane == 2
        horizontal = reshape(data.Va_prime(sliceNum,:,:), [dim(2) dim(3)]);
        rotate = 0;
    elseif plane == 3
        horizontal = reshape(data.Va_prime(:,sliceNum,:), [dim(1) dim(3)]);
        rotate = 90;
    end

    imshow(imrotate(horizontal, rotate), 'Parent', gca);
    title(['Slice: ', num2str(sliceNum)]);
    
    % Update currentSlice in figure UserData for consistency
    data.currentSlice = sliceNum;
    set(hFig, 'UserData', data);
end

% Callback function for mouse scroll wheel event
function scrollWheelCallback(src, event, hSlider, choice)
    % Get the current slice from the slider
    currentSlice = round(get(hSlider, 'Value'));
    
    % Determine the scroll direction and update current slice
    if event.VerticalScrollCount > 0
        newSlice = currentSlice - 1; % scroll down -> previous slice
    elseif event.VerticalScrollCount < 0
        newSlice = currentSlice + 1; % scroll up -> next slice
    end
    
    % Ensure new slice is within the allowable range
    newSlice = max(min(newSlice, get(hSlider, 'Max')), get(hSlider, 'Min'));
    
    % Set the new slice value to the slider and update the display
    set(hSlider, 'Value', newSlice);
    displaySlice(src, newSlice, size(get(src, 'UserData').Va_prime), choice);
end
