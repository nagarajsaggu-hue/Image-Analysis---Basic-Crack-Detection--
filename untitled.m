% ----------------------------------
% Folder Setup and Image Loading
% ----------------------------------
imageFolder = "C:\Users\r0nit\Desktop\re_proj\crack_images";  % Folder for original images
annotationFolder = "C:\Users\r0nit\Desktop\re_proj\crack_annotation";  % Folder for annotated images

imageFiles = dir(fullfile(imageFolder, '*.jpeg'));  % Assuming .jpeg format for images
annotationFiles = dir(fullfile(annotationFolder, '*.jpeg'));  % Assuming .jpeg for annotations

numImages = length(imageFiles);

% Check if the number of images is exactly 10
if numImages ~= 10
    error('Please ensure there are exactly 10 images in the folder.');
end

% ----------------------------------
% Data Augmentation
% ----------------------------------
outputFolders = {'aug_rot', 'aug_flip', 'aug_cont'};
annotationOutputFolders = {'aug_rot_ann', 'aug_flip_ann', 'aug_cont_ann'};
for i = 1:3
    if ~exist(outputFolders{i}, 'dir')
        mkdir(outputFolders{i});
    end
    if ~exist(annotationOutputFolders{i}, 'dir')
        mkdir(annotationOutputFolders{i});
    end
end

for i = 1:numImages
    originalImage = imread(fullfile(imageFolder, imageFiles(i).name));
    annotationImage = imread(fullfile(annotationFolder, annotationFiles(i).name));

    if i <= 4
        % Rotation
        augmentedImage = imrotate(originalImage, 45);
        augmentedAnnotation = imrotate(annotationImage, 45);
        imwrite(augmentedImage, fullfile('aug_rot', ['rot_' imageFiles(i).name]));
        imwrite(augmentedAnnotation, fullfile('aug_rot_ann', ['rot_' annotationFiles(i).name]));

    elseif i <= 7
        % Flipping
        augmentedImage = flip(originalImage, 2);
        augmentedAnnotation = flip(annotationImage, 2);
        imwrite(augmentedImage, fullfile('aug_flip', ['flip_' imageFiles(i).name]));
        imwrite(augmentedAnnotation, fullfile('aug_flip_ann', ['flip_' annotationFiles(i).name]));

    else
        % Contrast shrinking
        augmentedImage = imadjust(originalImage, [0.2 0.8], []);
        imwrite(augmentedImage, fullfile('aug_cont', ['cont_' imageFiles(i).name]));
        imwrite(annotationImage, fullfile('aug_cont_ann', ['cont_' annotationFiles(i).name]));
    end
end

fprintf('Data augmentation completed.\n');

% ----------------------------------
% Data Split (80% Train, 20% Test)
% ----------------------------------
splitRatio = 0.8;
numTrain = round(splitRatio * numImages);
indices = randperm(numImages);

trainIdx = indices(1:numTrain);
testIdx = indices(numTrain+1:end);

% ----------------------------------
% Dataset Statistics Calculation
% ----------------------------------
numPixels = 0;
crackPixels = 0;
intensityDistribution = [];

for i = 1:numImages
    image = imread(fullfile(imageFolder, imageFiles(i).name));
    annotation = imread(fullfile(annotationFolder, annotationFiles(i).name)); 

    numPixels = numPixels + numel(annotation);
    crackPixels = crackPixels + sum(annotation(:) == 255);

    intensityDistribution = [intensityDistribution; image(:)];
end

crackPercentage = (crackPixels / numPixels) * 100;

fprintf('Total images: %d\n', numImages);
fprintf('Total pixels: %d\n', numPixels);
fprintf('Crack pixels: %d (%.2f%%)\n', crackPixels, crackPercentage);

figure;
histogram(intensityDistribution, 256);
title('Intensity Distribution');
xlabel('Pixel Intensity');
ylabel('Frequency');

% ----------------------------------
% Task 2 - Crack Segmentation with Visualization
% ----------------------------------
connectedComponentsFolder = 'connected_components';
if ~exist(connectedComponentsFolder, 'dir')
    mkdir(connectedComponentsFolder);
end

features = [];
labels = [];

for i = 1:numImages
    image = imread(fullfile(imageFolder, imageFiles(i).name));

    % Convert to grayscale if necessary
    if size(image, 3) == 3
        grayImage = rgb2gray(image);
    else
        grayImage = image;
    end

    % Thresholding
    threshold = graythresh(grayImage);
    binaryMask = imbinarize(grayImage, threshold);
    binaryMask = ~binaryMask;

    % Visualization: Thresholded Image
    figure;
    subplot(1,3,1);
    imshow(binaryMask);
    title('Thresholded Image');

    % Morphological operations: area opening and closing
    cleanMask = bwareaopen(binaryMask, 50);  % Remove small objects
    cleanMask = imclose(cleanMask, strel('disk', 2));  % Close small holes

    % Visualization: After Morphological Operations
    subplot(1,3,2);
    imshow(cleanMask);
    title('After Morphological Operations');

    % Connected Components
    CC = bwconncomp(cleanMask);
    labeledImage = labelmatrix(CC);
    RGBLabel = label2rgb(labeledImage, 'jet', 'k', 'shuffle');

    % Visualization: Connected Components
    subplot(1,3,3);
    imshow(RGBLabel);
    title('Connected Components');
    
    pause(1);  % Pause to allow viewing the figure before continuing

    stats = regionprops(CC, 'Area', 'Perimeter', 'Eccentricity', 'MajorAxisLength', 'MinorAxisLength', 'Centroid');

    for j = 1:length(stats)
        area = stats(j).Area;
        perimeter = stats(j).Perimeter;
        eccentricity = stats(j).Eccentricity;
        majorAxis = stats(j).MajorAxisLength;
        minorAxis = stats(j).MinorAxisLength;
        aspectRatio = majorAxis / minorAxis;

        featureVector = [area, perimeter, eccentricity, majorAxis, minorAxis, aspectRatio];
        features = [features; featureVector];

        annotation = imread(fullfile(annotationFolder, annotationFiles(i).name));
        centroid = round(stats(j).Centroid);
        label = annotation(centroid(2), centroid(1));

        if label == 255
            labels = [labels; 1];
        else
            labels = [labels; 0];
        end
    end

    imwrite(RGBLabel, fullfile(connectedComponentsFolder, ['cc_' imageFiles(i).name]));
end

% ----------------------------------
% Train Classifier (SVM)
% ----------------------------------
features = normalize(features);

numFeatures = size(features, 1);
numTrain = round(splitRatio * numFeatures);
trainFeatures = features(1:numTrain, :);
trainLabels = labels(1:numTrain);
testFeatures = features(numTrain+1:end, :);
testLabels = labels(numTrain+1:end);

svmModel = fitcsvm(trainFeatures, trainLabels, 'KernelFunction', 'linear', 'Standardize', true);

predictedLabels = predict(svmModel, testFeatures);

accuracy = sum(predictedLabels == testLabels) / length(testLabels) * 100;
fprintf('SVM Classifier Accuracy: %.2f%%\n', accuracy);

% ----------------------------------
% Task 3 - Crack Analytics (IoU for all images)
% ----------------------------------
IoU_scores = [];
for i = 1:numImages
    image = imread(fullfile(imageFolder, imageFiles(i).name));
    annotation = imread(fullfile(annotationFolder, annotationFiles(i).name));

    if size(image, 3) == 3
        grayImage = rgb2gray(image);
    else
        grayImage = image;
    end

    threshold = graythresh(grayImage);
    binaryMask = imbinarize(grayImage, threshold);
    binaryMask = ~binaryMask;
    cleanMask = bwareaopen(binaryMask, 50);
    cleanMask = imclose(cleanMask, strel('disk', 2));

    IoU = calcIoU(cleanMask, annotation);
    IoU_scores = [IoU_scores; IoU];

    fprintf('Image %d IoU: %.2f\n', i, IoU);
end

mean_IoU = mean(IoU_scores);
fprintf('Mean IoU on all images: %.2f\n', mean_IoU);

% ----------------------------------
% Intensity Distribution and Crack Length Calculation
% ----------------------------------

intensityDistFolder = 'intensity_distribution';
if ~exist(intensityDistFolder, 'dir')
    mkdir(intensityDistFolder);
end

thinningFolder = 'thinning_results';
if ~exist(thinningFolder, 'dir')
    mkdir(thinningFolder);
end

crackLengthFolder = 'crack_length';
if ~exist(crackLengthFolder, 'dir')
    mkdir(crackLengthFolder);
end

crackLengths = [];
totalCrackLengths = [];

for i = 1:numImages
    image = imread(fullfile(imageFolder, imageFiles(i).name));
    
    if size(image, 3) == 3
        grayImage = rgb2gray(image);
    else
        grayImage = image;
    end
    
    % Thresholding and Cleaning
    threshold = graythresh(grayImage);
    binaryMask = imbinarize(grayImage, threshold);
    binaryMask = ~binaryMask;
    cleanMask = bwareaopen(binaryMask, 50);
    cleanMask = imclose(cleanMask, strel('disk', 2));
    thinnedCrack = bwmorph(cleanMask, 'thin', Inf);
    
    imwrite(thinnedCrack, fullfile(thinningFolder, ['thin_' imageFiles(i).name]));

    % Calculate Crack Length
    CC = bwconncomp(thinnedCrack);
    stats = regionprops(CC, 'Perimeter');

    imageTotalCrackLength = 0;
    for j = 1:length(stats)
        crackLength = stats(j).Perimeter;
        imageTotalCrackLength = imageTotalCrackLength + crackLength;
        fprintf('Image %d, Crack %d Length: %.2f pixels\n', i, j, crackLength);
    end
    totalCrackLengths = [totalCrackLengths; imageTotalCrackLength];
    
    % Save total crack length to file
    crackLengthFile = fullfile(crackLengthFolder, ['crack_length_' imageFiles(i).name '.txt']);
    fid = fopen(crackLengthFile, 'w');
    fprintf(fid, 'Total Crack Length: %.2f pixels\n', imageTotalCrackLength);
    fclose(fid);

    % Intensity Distribution Plot
    intensityDist = image(:);
    figure;
    histogram(intensityDist, 256);
    title(['Intensity Distribution: ' imageFiles(i).name]);
    xlabel('Pixel Intensity');
    ylabel('Frequency');

    % Save Intensity Distribution Plot
    saveas(gcf, fullfile(intensityDistFolder, ['intensity_' imageFiles(i).name '.png']));
end

meanCrackLength = mean(totalCrackLengths);
fprintf('Mean Crack Length on all images: %.2f pixels\n', meanCrackLength);

% ----------------------------------
% Function Definitions
% ----------------------------------
function IoU = calcIoU(binaryMask, annotation)
    intersection = sum((binaryMask == 1) & (annotation == 255), 'all');
    union = sum((binaryMask == 1) | (annotation == 255), 'all');
    IoU = intersection / union;
end
