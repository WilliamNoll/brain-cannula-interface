clear;
close all;
clc;

%% USER INPUTS
file = 'patient_1_artifact2.nii';
tolerance = 4; % How many std deviations away from mean to be labeled as an artifact

%% PROGRAM
% Global variables
global artifactRatio meanIntensity stdIntensity;

% Load the MRI scan
Va = niftiread(file);

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
        % Initial sliceZ value
        sliceZ = dim(3)/2;

        % Ensure all GUI components are set up correctly
        hFig = figure('Name', 'MRI Slice Viewer', 'NumberTitle', 'off');
        userData = struct('currentSlice', sliceZ, 'Va_prime', Va_prime, 'finalslice', []);
        set(hFig, 'Position', newPosition); % Make the figure full screen
        set(hFig, 'UserData', userData);
        % Adjust slider setup
        hSlider = uicontrol('Style', 'slider', 'Min',1, 'Max',size(Va_prime,3), 'Value',sliceZ, 'SliderStep', [1 10]./(size(Va_prime,3)-1), ...
            'Position', [20 20 300 20], 'Callback', @(src, evnt)displaySliceCallback(hFig, round(src.Value), dim, choice));

        % Add an event listener for mouse scroll wheel that updates the current slice
        set(hFig, 'WindowScrollWheelFcn', @(src, event) scrollWheelCallback(src, event, hSlider, choice));

        % Immediately display the initial slice
        displaySlice(hFig, sliceZ, dim, choice); % This line ensures the initial slice is displayed

        % Button for processing the currently viewed slice and disabling the slider
        hButtonProcess = uicontrol('Style', 'pushbutton', 'String', 'Save Slice & Process', 'Position', [440 20 150 30], 'Callback', ...
             @(src, event)processCurrentSlice(hFig));

        % Pause script execution waiting for user to select the slice and process it
        uiwait(hFig);
        userData = get(hFig, 'UserData');
        finalslice = userData.finalslice; % Get the finalslice from UserData
        close(hFig);
        
        % Display the horizontal slice and allow user to draw a freehand ROI for normal brain tissue
        horizontal = Va_prime(:,:,finalslice);
        ROIfig = figure();
        imshow(imrotate(horizontal, -90));
        set(ROIfig, 'Position', newPosition); % Make the figure full screen
        title('Draw around normal brain tissue');
        
        % Let user draw the initial region
        hFreehandNormal = drawfreehand('Color', 'r');

        % Create a button to process the normal brain tissue ROI after drawing
        hButton = uicontrol('Style', 'pushbutton', 'String', 'Process', ...
            'Position', [20 20 100 30], 'Callback', {@processNormalROICallback, imrotate(horizontal,-90), ROIfig, totalPixels, tolerance, newPosition} );

        % Store hFreehandNormal in the UserData property of the figure or button
        set(hButton, 'UserData', hFreehandNormal);
        uiwait(gcf)

        % Add a listener to the freehand object to close the figure when the ROI is drawn
        if isvalid(hFreehandNormal)
            addlistener(hFreehandNormal, 'ROIMoved', @(src, evnt) closeDrawROIFigure(src));
        end

        fprintf('Frontal Plane (Slice %d)\nArtifact ratio: %4f (artifact pixels/total image kilopixels)\n', finalslice, artifactRatio)
    case 2
        % Code for Sagittal
        % Initial sliceX value
        sliceX = dim(2)/2;

        % Ensure all GUI components are set up correctly
        hFig = figure('Name', 'MRI Slice Viewer', 'NumberTitle', 'off');
        set(hFig, 'Position', newPosition); % Make the figure full screen
        set(hFig, 'UserData', struct('currentSlice', sliceX, 'Va_prime', Va_prime));

        % Adjust slider setup
        hSlider = uicontrol('Style', 'slider', 'Min',1, 'Max',size(Va_prime,1), 'Value',sliceX, 'SliderStep', [1 10]./(size(Va_prime,3)-1), ...
            'Position', [20 20 300 20], 'Callback', @(src, evnt)displaySliceCallback(hFig, round(src.Value), dim, choice));

        % Add an event listener for mouse scroll wheel that updates the current slice
        set(hFig, 'WindowScrollWheelFcn', @(src, event) scrollWheelCallback(src, event, hSlider, choice));

        % Immediately display the initial slice
        displaySlice(hFig, sliceX, dim, choice); % This line ensures the initial slice is displayed

        % Button for processing the currently viewed slice and disabling the slider
        hButtonProcess = uicontrol('Style', 'pushbutton', 'String', 'Save Slice & Process', 'Position', [440 20 150 30], ...
            'Callback', @(src, evnt)processCurrentSlice(hFig));

        % Pause script execution waiting for user to select the slice and process it
        uiwait(hFig);
        userData = get(hFig, 'UserData');
        finalslice = userData.finalslice; % Get the finalslice from UserData
        close(hFig);

        horizontal = reshape(Va_prime(finalslice,:,:), [dim(2) dim(3)]);

        % Display the horizontal slice and allow user to draw a freehand ROI for normal brain tissue
        ROIfig = figure();
        imshow(imrotate(horizontal, 90));
        set(ROIfig, 'Position', newPosition); % Make the figure full screen
        title('Draw around normal brain tissue');
        % Let user draw the initial region
        hFreehandNormal = drawfreehand('Color', 'r');

        % Create a button to process the normal brain tissue ROI after drawing
        hButton = uicontrol('Style', 'pushbutton', 'String', 'Process', ...
            'Position', [20 20 100 30], 'Callback', {@processNormalROICallback, imrotate(horizontal,90), ROIfig, totalPixels, tolerance, newPosition});

        % Store hFreehandNormal in the UserData property of the figure or button
        set(hButton, 'UserData', hFreehandNormal);
        uiwait(gcf)

        % Add a listener to the freehand object to close the figure when the ROI is drawn
        if isvalid(hFreehandNormal)
            addlistener(hFreehandNormal, 'ROIMoved', @(src, evnt) closeDrawROIFigure(src));
        end

        fprintf('Sagittal Plane (Slice %d)\nArtifact ratio: %4f (artifact pixels/total image kilopixels)\n', finalslice, artifactRatio)
    case 3
        % Code for Horizontal
        % Initial sliceY value
        sliceY = dim(2)/2;

        % Ensure all GUI components are set up correctly
        hFig = figure('Name', 'MRI Slice Viewer', 'NumberTitle', 'off');
        set(hFig, 'Position', newPosition); % Make the figure full screen
        set(hFig, 'UserData', struct('currentSlice', sliceY, 'Va_prime', Va_prime));

        % Adjust slider setup
        hSlider = uicontrol('Style', 'slider', 'Min',1, 'Max',size(Va_prime,1), 'Value',sliceY, 'SliderStep', [1 10]./(size(Va_prime,3)-1), ...
            'Position', [20 20 300 20], 'Callback', @(src, evnt)displaySliceCallback(hFig, round(src.Value), dim, choice));

        % Add an event listener for mouse scroll wheel that updates the current slice
        set(hFig, 'WindowScrollWheelFcn', @(src, event) scrollWheelCallback(src, event, hSlider, choice));

        % Immediately display the initial slice
        displaySlice(hFig, sliceY, dim, choice); % This line ensures the initial slice is displayed

        % Button for processing the currently viewed slice and disabling the slider
        hButtonProcess = uicontrol('Style', 'pushbutton', 'String', 'Save Slice & Process', 'Position', [440 20 150 30], ...
            'Callback', @(src, evnt)processCurrentSlice(hFig));

        % Pause script execution waiting for user to select the slice and process it
        uiwait(hFig);
        userData = get(hFig, 'UserData');
        finalslice = userData.finalslice; % Get the finalslice from UserData
        close(hFig);

        horizontal = reshape(Va_prime(:,finalslice,:), [dim(1) dim(3)]);

        % Display the horizontal slice and allow user to draw a freehand ROI for normal brain tissue
        ROIfig = figure();
        imshow(imrotate(horizontal, 90));
        set(ROIfig, 'Position', newPosition); % Make the figure full screen
        title('Draw around normal brain tissue');
        % Let user draw the initial region
        hFreehandNormal = drawfreehand('Color', 'r');

        % Create a button to process the normal brain tissue ROI after drawing
        hButton = uicontrol('Style', 'pushbutton', 'String', 'Process', ...
            'Position', [20 20 100 30], 'Callback', {@processNormalROICallback, imrotate(horizontal,90), ROIfig, totalPixels, tolerance, newPosition});

        % Store hFreehandNormal in the UserData property of the figure or button
        set(hButton, 'UserData', hFreehandNormal);
        uiwait(gcf)

        % Add a listener to the freehand object to close the figure when the ROI is drawn
        if isvalid(hFreehandNormal)
            addlistener(hFreehandNormal, 'ROIMoved', @(src, evnt) closeDrawROIFigure(src));
        end

        fprintf('Horizontal Plane (Slice %d)\nArtifact ratio: %4f (artifact pixels/total image kilopixels)\n', finalslice, artifactRatio)
    case 4
    otherwise
        % Handle no selection or cancellation
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
function displaySliceCallback(hFig, sliceNum, dim, choice)
    displaySlice(hFig, sliceNum, dim, choice);
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
function displaySlice(hFig, sliceNum, dim, choice)
    data = get(hFig, 'UserData');
    if choice == 1
        horizontal = data.Va_prime(:,:,sliceNum);
        rotate = -90;
    elseif choice == 2
        horizontal = reshape(data.Va_prime(sliceNum,:,:), [dim(2) dim(3)]);
        rotate = 90;
    elseif choice == 3
        horizontal = reshape(data.Va_prime(:,sliceNum,:), [dim(1) dim(3)]);
        rotate = 90;
    end

    imshow(imrotate(horizontal, rotate), 'Parent', gca);
    title(['Slice: ', num2str(sliceNum)]);
    
    % Update currentSlice in figure UserData for consistency
    data.currentSlice = sliceNum;
    set(hFig, 'UserData', data);
end

% Callback function to close the "Draw ROI" figure
function closeDrawROIFigure(hRect)
    if isvalid(hRect)
        close(gcf); % Close the current figure
    end
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

% Function to be called when "Process" button is clicked
function processArtifactArea(src, ~)
    % Retrieve handles from the button's 'UserData'
    userData = get(src, 'UserData');
    hFig = userData.hFig;
    
    % Resume execution to continue with the analysis
    uiresume(hFig);
end

% Callback function to process the normal brain tissue ROI
function processNormalROICallback(src, ~, horizontalImage, hFig, totalPixels, tolerance, newPosition)
    global artifactRatio meanIntensity stdIntensity;
    
    % Retrieve hFreehandNormal from the UserData property of the src (button)
    hFreehand = get(src, 'UserData');
    
    % Proceed with the callback logic
    pos = round(hFreehand.Position);
    x = pos(:,1);
    y = pos(:,2);
    
    % Extract the normal brain tissue ROI from the horizontal image
    roiNormal = roipoly(horizontalImage, x, y);
    
    % Calculate mean intensity and standard deviation within the normal brain tissue ROI
    roiNormalValues = horizontalImage(roiNormal);
    meanIntensity = mean(roiNormalValues);
    stdIntensity = std(double(roiNormalValues));
    
    % Now, prompt the user to draw the area where they believe an artifact is located
    title('Outline the entire brain structure');
    hArtifact = drawfreehand('Color', 'b');

    % Create the "Process" button which, when clicked, will resume execution
    hButton2 = uicontrol('Style', 'pushbutton', 'String', 'Process', ...
        'Position', [20 20 100 30], 'Callback', @processArtifactArea);

    % Proceed with the callback logic
    artifactPos = round(hArtifact.Position);
    set(hButton2, 'UserData', struct('hFig', hFig, 'hArtifact', hArtifact, 'artifactPos', artifactPos));

    % Pause script execution waiting for user to process the artifact area
    uiwait(gcf);  % Wait for the current figure to be processed

    % Finding the artifact in the image
    artifactPos = round(hArtifact.Position);
    roiArtifact = roipoly(horizontalImage, artifactPos(:,1), artifactPos(:,2));
    lowerThreshold = meanIntensity - tolerance * stdIntensity;
    upperThreshold = meanIntensity + tolerance * stdIntensity;
    roiArtifactPixels = horizontalImage(roiArtifact);
    isArtifactWithinROI = (roiArtifactPixels < lowerThreshold) | (roiArtifactPixels > upperThreshold);
    artifactMask = false(size(horizontalImage));
    artifactMask(roiArtifact) = isArtifactWithinROI;

    % Quantifying the artifact
    artifactRatio = (sum(artifactMask(:) == 1) / totalPixels) * 1000; % Defined as how many artifact pixel over total pixels in the entire image (in kilopixels)

    % Retrieve artifact position from the UserData of the button
    userData = get(hButton2, 'UserData');
    artifactPos = userData.artifactPos;
    x_artifact = artifactPos(:,1);
    y_artifact = artifactPos(:,2);
    roiArtifact = roipoly(horizontalImage, x_artifact, y_artifact);

    % Define thresholds for detecting artifacts
    lowerThreshold = meanIntensity - tolerance * stdIntensity;
    upperThreshold = meanIntensity + tolerance * stdIntensity;

    % Extract the pixel values within the freehand ROI
    roiArtifactPixels = horizontalImage(roiArtifact);
    
    % Apply threshold only within the ROI to identify artifacts
    isArtifactWithinROI = (roiArtifactPixels < lowerThreshold) | (roiArtifactPixels > upperThreshold);

    % Now create a new binary image with the size of the original image
    artifactMask = false(size(horizontalImage));

    % Set the identified artifact pixels within the ROI in the new binary image
    artifactMask(roiArtifact) = isArtifactWithinROI;

    % Quantifying the artifact
    artifactRatio = (sum(artifactMask(:) == 1)/totalPixels)*1000; % Defined as how many artifact pixel over total pixels in the entire image (in kilopixels)

    % Overlay ROI and artifact boundaries on the original image
    overlayImage = overlayBoundaries(horizontalImage, artifactMask);
    
    % Close the figure
    close(gcf);
    
    % Display the image with overlays
    overlay= figure();
    imshow(overlayImage);
    set(overlay, 'Position', newPosition); % Make the figure full screen
    title('Original Image with Artifact Overlay');
    
    % Resume execution of the MATLAB script
    if isvalid(hFig)
        uiresume(hFig);
    end
end