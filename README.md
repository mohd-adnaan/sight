# SIGHT
## Vision-Guided Navigation Assistance for the Visually Impaired

#### About:
Autonomous Navigation Assistance for the Visually Impaired.

#### Introduction:
SIGHT is designed to revolutionize mobility for the visually impaired within urban environments. By leveraging advanced image recognition technologies, the app provides precise guidance to vital urban locations such as Montreal bus shelters, doorways, and intersection crossings.

#### Problem Statement:
Navigating complex urban environments poses significant challenges for visually impaired individuals. Existing solutions often fall short in efficiently and reliably identifying essential navigation points necessary for safe and independent mobility. SIGHT addresses this critical gap, enhancing the mobility of the visually impaired community with accurate navigational assistance.

### Solution Overview:
Project Amish utilizes the widespread availability and capabilities of smartphones, which may be carried on a neck-worn lanyard or integrated with external devices such as head-worn panoramic cameras. Key features of the application include:

1. **Bus Shelter Detection**: Guides users to important navigation features, such as bus shelters, with precision.
   
2. **Doorway Navigation**: Assists users in precisely navigating to doorways, especially in the last few meters of their approach.
   
3. **Cyber Guidance**: Helps visually impaired individuals reach daily groceries or scan QR codes, providing audio feedback and haptic signals from the bracelet to assist in navigating to the detected object.
   
4. **Intersection Safety**: Enhances safe passage across intersections by preventing veering, reducing stress and danger.
   
5. **Service Integration**: Seamlessly switches between various app services, including navigation, OCR (Optical Character Recognition), product identification, and environmental description. This integration is based on contextual information and personalization to enhance user experience.

## Application Architecture:
<img width="468" alt="Screenshot 2024-04-09 at 10 36 38 AM" src="https://github.com/Shared-Reality-Lab/BusShelterDetect/assets/68878155/5df70a5d-679a-4553-ad5f-0d272495080a">

## Requirements

- Xcode 10.3+
- iOS 13.0+

## How To Build and Run the Project

### 1. Clone the project

```shell
git clone https://github.com/Shared-Reality-Lab/cybersight/tree/sight
```

### 2. Prepare Core ML model

- You can download a pretrained Yolo model from the official wiki or alternatively you can train your own: [YoloV8 Ultralytics](https://github.com/ultralytics/ultralytics)

  #### Convert Yolo model (.pt) to coreml format:

```shell
yolo export model=yolov8n.pt format=coreml nms
```

### 3. Add the model to the project

By default, the project uses a bus shelter detecting `yolov8s` model. If you want to use another model, you can replace the model file in the project. Please navigate to to the "mlmodel" folder and paste your model.

### 4. Set model name properly in `ViewController.swift`

<img width="640" alt="image" src="https://user-images.githubusercontent.com/37643248/188249496-20ba838c-7f0f-4457-adac-2fa11344c7de.png">

### 5. Build and Run
