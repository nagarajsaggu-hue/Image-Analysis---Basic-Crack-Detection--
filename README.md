# Image Analysis Project – Basic Crack Detection

## Overview

This project implements a **basic automated crack detection pipeline** using classical image processing techniques in MATLAB. The goal is to detect and analyze cracks in concrete wall images without relying on deep learning or neural networks.

The system performs the following main tasks:

1. **Data engineering**
   - Image loading
   - Pixel-level annotation handling
   - Data augmentation
   - Train/test splitting
   - Dataset statistics calculation

2. **Crack segmentation**
   - Grayscale conversion
   - Threshold-based crack extraction
   - Morphological cleaning
   - Connected component analysis
   - Feature extraction
   - SVM-based crack/non-crack classification

3. **Crack analytics**
   - Intersection over Union evaluation
   - Crack thinning
   - Crack length computation
   - Intensity distribution analysis

The project is designed as a simple, understandable crack detection framework for civil engineering and structural inspection use cases.

---

## Project Motivation

Structural cracks in buildings, roads, bridges, and other civil infrastructure can indicate damage, aging, or possible safety risks. Traditional crack inspection is usually performed manually, which can be slow, subjective, and prone to human error.

This project explores how **classical image processing** can support automated crack detection. Instead of using neural networks, the system uses thresholding, morphological operations, connected components, feature engineering, and a Support Vector Machine classifier.

The project focuses on crack detection in **concrete wall images**.

---

## Dataset Description

The dataset used in this project contains:

- **10 original crack images**
- **10 corresponding annotated crack masks**
- Image format: `.jpeg`
- Annotation format: `.jpeg`

The annotation masks use pixel-level segmentation:

| Pixel Value | Meaning |
|---:|---|
| `255` | Crack region |
| `0` | Non-crack/background region |

The dataset was collected from urban wall surfaces. Each crack image was captured using a camera phone. The dataset is small, so augmentation is used to increase variation and improve robustness.

---

## Project Folder Structure

A recommended project structure is shown below:

```text
crack-detection-project/
│
├── README.md
├── untitled.m
│
├── crack_images/
│   ├── image1.jpeg
│   ├── image2.jpeg
│   └── ...
│
├── crack_annotation/
│   ├── annotation1.jpeg
│   ├── annotation2.jpeg
│   └── ...
│
├── aug_rot/
├── aug_flip/
├── aug_cont/
│
├── aug_rot_ann/
├── aug_flip_ann/
├── aug_cont_ann/
│
├── connected_components/
├── intensity_distribution/
├── thinning_results/
└── crack_length/
```

### Important

The MATLAB script currently contains absolute Windows paths:

```matlab
imageFolder = "C:\Users\r0nit\Desktop\re_proj\crack_images";
annotationFolder = "C:\Users\r0nit\Desktop\re_proj\crack_annotation";
```

Before running the script, update these paths according to your local computer.

For example:

```matlab
imageFolder = "C:\Users\YourName\Desktop\crack-detection-project\crack_images";
annotationFolder = "C:\Users\YourName\Desktop\crack-detection-project\crack_annotation";
```

---

## Requirements

### Software

- MATLAB
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox

### MATLAB functions used

The project uses functions such as:

- `imread`
- `imwrite`
- `rgb2gray`
- `graythresh`
- `imbinarize`
- `bwareaopen`
- `imclose`
- `strel`
- `bwconncomp`
- `labelmatrix`
- `label2rgb`
- `regionprops`
- `fitcsvm`
- `predict`
- `bwmorph`
- `histogram`

---

## How to Run the Project

### Step 1: Prepare the input folders

Create two main input folders:

```text
crack_images/
crack_annotation/
```

Place the original crack images inside `crack_images/`.

Place the corresponding annotation masks inside `crack_annotation/`.

Both folders must contain exactly **10 `.jpeg` files**.

---

### Step 2: Update the folder paths

Open `untitled.m` and update these two variables:

```matlab
imageFolder = "path_to_your_crack_images_folder";
annotationFolder = "path_to_your_crack_annotation_folder";
```

Example:

```matlab
imageFolder = "C:\Users\YourName\Desktop\crack-detection-project\crack_images";
annotationFolder = "C:\Users\YourName\Desktop\crack-detection-project\crack_annotation";
```

---

### Step 3: Run the MATLAB script

In MATLAB, open the project folder and run:

```matlab
untitled
```

The script will execute all project stages automatically.

---

## Workflow Explanation

## 1. Folder Setup and Image Loading

The script first defines the folder paths for original images and annotation masks:

```matlab
imageFolder = "...";
annotationFolder = "...";
```

It then reads all `.jpeg` files from both folders:

```matlab
imageFiles = dir(fullfile(imageFolder, '*.jpeg'));
annotationFiles = dir(fullfile(annotationFolder, '*.jpeg'));
```

The script checks whether exactly 10 images are available:

```matlab
if numImages ~= 10
    error('Please ensure there are exactly 10 images in the folder.');
end
```

This ensures that the project runs on the intended dataset size.

---

## 2. Data Augmentation

Because the dataset contains only 10 images, the script applies simple data augmentation techniques.

Three augmentation types are used:

| Image Range | Augmentation | Purpose |
|---|---|---|
| Images 1–4 | Rotation by 45 degrees | Simulates cracks appearing at different angles |
| Images 5–7 | Horizontal flipping | Simulates mirrored crack orientation |
| Images 8–10 | Contrast adjustment | Simulates lighting variation |

The generated augmented images are saved in separate folders:

```text
aug_rot/
aug_flip/
aug_cont/
```

The corresponding augmented annotations are saved in:

```text
aug_rot_ann/
aug_flip_ann/
aug_cont_ann/
```

This improves dataset diversity and helps the model become more robust to changes in crack orientation and illumination.

---

## 3. Train/Test Splitting

The dataset is split into:

| Set | Percentage |
|---|---:|
| Training set | 80% |
| Testing set | 20% |

The script uses:

```matlab
splitRatio = 0.8;
indices = randperm(numImages);
```

This random split helps evaluate how well the method performs on unseen data.

---

## 4. Dataset Statistics

The script calculates important dataset-level statistics:

- Total number of images
- Total number of pixels
- Number of crack pixels
- Percentage of crack pixels
- Pixel intensity distribution

The crack percentage is calculated as:

```matlab
crackPercentage = (crackPixels / numPixels) * 100;
```

The report results show:

| Statistic | Value |
|---|---:|
| Total images | 10 |
| Total pixels | 6,415,759 |
| Crack pixels | 95,066 |
| Crack pixel percentage | 1.48% |

This shows that the dataset is highly imbalanced because crack pixels are much fewer than background pixels.

---

## 5. Crack Segmentation

The segmentation stage attempts to separate crack pixels from the background.

### 5.1 Grayscale Conversion

If an image is RGB, it is converted to grayscale:

```matlab
grayImage = rgb2gray(image);
```

Cracks are usually darker than the surrounding wall surface, so grayscale intensity is useful for segmentation.

---

### 5.2 Thresholding

The script uses Otsu thresholding:

```matlab
threshold = graythresh(grayImage);
binaryMask = imbinarize(grayImage, threshold);
binaryMask = ~binaryMask;
```

The binary mask is inverted because cracks are usually dark and need to be represented as foreground objects.

---

### 5.3 Morphological Cleaning

After thresholding, the binary mask may contain noise. The script applies:

```matlab
cleanMask = bwareaopen(binaryMask, 50);
cleanMask = imclose(cleanMask, strel('disk', 2));
```

These operations perform two tasks:

| Operation | Purpose |
|---|---|
| `bwareaopen` | Removes small noisy regions |
| `imclose` | Connects nearby crack fragments and closes small gaps |

This makes the crack regions cleaner and more continuous.

---

## 6. Connected Component Analysis

Connected component analysis identifies separate crack-like regions in the binary image.

The script uses:

```matlab
CC = bwconncomp(cleanMask);
labeledImage = labelmatrix(CC);
RGBLabel = label2rgb(labeledImage, 'jet', 'k', 'shuffle');
```

Each connected region is treated as an individual candidate crack component.

The connected component visualization is saved in:

```text
connected_components/
```

---

## 7. Feature Engineering

For each connected component, the script extracts geometric features:

```matlab
stats = regionprops(CC, ...
    'Area', ...
    'Perimeter', ...
    'Eccentricity', ...
    'MajorAxisLength', ...
    'MinorAxisLength', ...
    'Centroid');
```

The extracted feature vector is:

```matlab
featureVector = [area, perimeter, eccentricity, majorAxis, minorAxis, aspectRatio];
```

### Feature meaning

| Feature | Meaning |
|---|---|
| Area | Number of pixels in the detected region |
| Perimeter | Boundary length of the region |
| Eccentricity | Measures how elongated the region is |
| Major axis length | Length of the longest axis |
| Minor axis length | Length of the shortest axis |
| Aspect ratio | Ratio between major axis and minor axis |

Cracks are usually long, thin, and irregular. These features help distinguish cracks from non-crack noise.

---

## 8. Label Assignment

For each connected component, the centroid is used to check the corresponding annotation mask:

```matlab
centroid = round(stats(j).Centroid);
label = annotation(centroid(2), centroid(1));
```

If the annotation pixel value at the centroid is `255`, the component is labeled as a crack:

```matlab
labels = [labels; 1];
```

Otherwise, it is labeled as non-crack:

```matlab
labels = [labels; 0];
```

---

## 9. SVM Classifier

After feature extraction, the features are normalized:

```matlab
features = normalize(features);
```

The feature dataset is split into training and testing sets:

```matlab
trainFeatures = features(1:numTrain, :);
trainLabels = labels(1:numTrain);
testFeatures = features(numTrain+1:end, :);
testLabels = labels(numTrain+1:end);
```

A linear SVM classifier is trained:

```matlab
svmModel = fitcsvm(trainFeatures, trainLabels, ...
    'KernelFunction', 'linear', ...
    'Standardize', true);
```

Predictions are generated using:

```matlab
predictedLabels = predict(svmModel, testFeatures);
```

Accuracy is calculated as:

```matlab
accuracy = sum(predictedLabels == testLabels) / length(testLabels) * 100;
```

The report result shows:

```text
SVM Classifier Accuracy: 60.00%
```

This indicates that the classifier works at a basic level but still needs improvement.

---

## 10. IoU Evaluation

The project uses **Intersection over Union**, also called **IoU**, to evaluate segmentation quality.

IoU measures the overlap between the predicted crack mask and the ground truth annotation mask.

The formula is:

```text
IoU = Intersection / Union
```

In MATLAB, it is implemented as:

```matlab
intersection = sum((binaryMask == 1) & (annotation == 255), 'all');
union = sum((binaryMask == 1) | (annotation == 255), 'all');
IoU = intersection / union;
```

### IoU Results

| Image | IoU |
|---|---:|
| Image 1 | 0.26 |
| Image 2 | 0.44 |
| Image 3 | 0.39 |
| Image 4 | 0.01 |
| Image 5 | 0.58 |
| Image 6 | 0.41 |
| Image 7 | 0.05 |
| Image 8 | 0.43 |
| Image 9 | 0.34 |
| Image 10 | 0.59 |

Mean IoU:

```text
0.35
```

The low IoU for Images 4 and 7 indicates that the algorithm struggles with complex cracks, noisy regions, or cases where thinning and segmentation fail to match the ground truth accurately.

---

## 11. Crack Thinning

After segmentation, the crack mask is thinned using:

```matlab
thinnedCrack = bwmorph(cleanMask, 'thin', Inf);
```

Thinning reduces crack regions to a one-pixel-wide skeleton.

This is useful because it preserves the central structure of the crack and makes crack length calculation easier.

The thinned crack images are saved in:

```text
thinning_results/
```

---

## 12. Crack Length Calculation

After thinning, connected components are extracted again:

```matlab
CC = bwconncomp(thinnedCrack);
stats = regionprops(CC, 'Perimeter');
```

For each component, the perimeter is used as an approximate crack length:

```matlab
crackLength = stats(j).Perimeter;
```

The total crack length per image is calculated by summing all detected crack component lengths.

### Crack Length Results

| Image | Total Crack Length (pixels) |
|---|---:|
| Image 1 | 503.51 |
| Image 2 | 525.61 |
| Image 3 | 1729.89 |
| Image 4 | 7409.04 |
| Image 5 | 1102.85 |
| Image 6 | 410.97 |
| Image 7 | 995.07 |
| Image 8 | 1551.47 |
| Image 9 | 824.91 |
| Image 10 | 2852.54 |

Mean crack length:

```text
1790.59 pixels
```

The crack length text files are saved in:

```text
crack_length/
```

Each output file contains the total crack length for one image.

---

## 13. Intensity Distribution

The script creates intensity distribution histograms for the images:

```matlab
histogram(intensityDist, 256);
```

These plots help understand the brightness and contrast distribution of each image.

The plots are saved in:

```text
intensity_distribution/
```

Intensity distribution is useful because cracks usually appear darker than the background, but lighting variations can make threshold-based detection difficult.

---

## Output Folders

After running the script, the following output folders are created automatically:

| Folder | Description |
|---|---|
| `aug_rot/` | Rotated augmented images |
| `aug_flip/` | Flipped augmented images |
| `aug_cont/` | Contrast-adjusted augmented images |
| `aug_rot_ann/` | Rotated annotation masks |
| `aug_flip_ann/` | Flipped annotation masks |
| `aug_cont_ann/` | Contrast-adjusted annotation masks |
| `connected_components/` | Connected component visualizations |
| `intensity_distribution/` | Histogram plots |
| `thinning_results/` | Thinned crack skeleton images |
| `crack_length/` | Text files containing crack length results |

---

## Final Results Summary

| Metric | Result |
|---|---:|
| Total images | 10 |
| Total pixels | 6,415,759 |
| Crack pixels | 95,066 |
| Crack pixel percentage | 1.48% |
| Mean IoU | 0.35 |
| Mean crack length | 1790.59 pixels |
| SVM classifier accuracy | 60.00% |

---

## Discussion

The project shows that classical image processing can detect visible cracks in simple cases. Thresholding and morphological operations are useful for extracting dark crack-like structures from wall images.

However, the results also show limitations:

- The mean IoU is relatively low.
- The SVM accuracy is only 60%.
- Images with complex crack structures perform poorly.
- Background textures can be falsely detected as cracks.
- Lighting variation affects threshold-based segmentation.
- Thin cracks and noisy cracks are difficult to separate reliably.

The low IoU values for Images 4 and 7 show that the method does not always capture the true crack structure correctly.

---

## Limitations

1. **Small dataset**
   - Only 10 images were used.
   - This limits generalization.

2. **Lighting sensitivity**
   - Thresholding can fail when images have shadows, bright regions, or uneven illumination.

3. **False positives**
   - Dark textures, stains, and rough wall surfaces may be detected as cracks.

4. **Basic classifier**
   - A linear SVM may not be powerful enough for complex crack/non-crack separation.

5. **Centroid-based labeling**
   - Labeling connected components using only the centroid may be inaccurate when a component partially overlaps with crack regions.

6. **Length approximation**
   - Crack length is estimated using perimeter after thinning, which may not always represent the exact centerline length.

---

## Possible Improvements

The project can be improved in several ways:

1. **Use adaptive thresholding**
   - Adaptive thresholding can handle uneven lighting better than global Otsu thresholding.

2. **Improve preprocessing**
   - Apply contrast enhancement, denoising, or illumination correction before segmentation.

3. **Use better feature selection**
   - Add features such as orientation, solidity, compactness, bounding box ratio, and skeleton length.

4. **Improve classifier**
   - Try decision trees, random forests, k-nearest neighbors, or nonlinear SVM kernels.

5. **Use deep learning**
   - CNN-based segmentation models such as U-Net could improve accuracy significantly.

6. **Increase dataset size**
   - More images from different wall surfaces, crack types, and lighting conditions would improve robustness.

7. **Improve annotation consistency**
   - More accurate and consistent pixel-level annotation can improve evaluation reliability.

---

## Conclusion

This project successfully implements a complete crack detection and analysis pipeline using traditional image processing methods in MATLAB. The system performs image augmentation, crack segmentation, connected component analysis, feature extraction, SVM classification, IoU evaluation, crack thinning, and crack length computation.

The results show that the method can identify basic crack structures, but it struggles with complex cracks, noisy backgrounds, and difficult lighting conditions. The final mean IoU of **0.35** and SVM accuracy of **60.00%** indicate that this is a useful baseline system, but further improvements are needed for real-world crack detection applications.

Future work should focus on better preprocessing, adaptive thresholding, larger datasets, stronger classifiers, and eventually deep learning-based segmentation models.

---

## References

- GIMP: https://www.gimp.org
- CVAT: https://www.cvat.ai
- MATLAB Image Processing Toolbox documentation
- MATLAB Statistics and Machine Learning Toolbox documentation
- Course materials on SVMs and decision trees

---

## Author

**Nagaraju Saggu**

Project: **Image Analysis Project – Basic Crack Detection**
