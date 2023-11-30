# Android Application Installer Script (macOS)

This installer is designed for macOS users to add custom applications to an Android device. It's an open-source tool that's straightforward to use, facilitating the wireless installation of Android applications into the car's multimedia system.

## Pre-requisites

1. **APK Folder**: Create a folder named 'apk' in the same location as the installer. Place the APK files you wish to install inside this folder.

2. **Enable Wireless ADB via Developer Menu**:
> [!TIP]
> On BYD vehicles, navigate to Settings and tap on "Restore" 10 times to reveal the developer menu. Then, activate the wireless ADB option. If this feature is not available, you may need to install the 'Wireless ADB Switch' app, which can be downloaded [here](https://workupload.com/file/RsgTzvRKe6S) and installed using an USB drive.

5. **Wi-Fi Connection**: Ensure that your Mac device and the multimedia center are connected to the same Wi-Fi network.

6. **Android Device IP Address**: Know the current IP address of the device to establish the connection.

7. **Installer Execution Permissions**: Run `chmod +x <installer_name>.sh` in the terminal to grant execution permissions to the installer.

## How to Use

1. Open the terminal on your macOS device and execute the installer.
2. Follow the on-screen instructions, inputting the Android device IP address when prompted, to connect and install the chosen applications.

> [!IMPORTANT]
> This tool is designed to be user-friendly and does not require advanced technical knowledge.
> Verify the compatibility and safety of the APK applications you wish to install.

> [!WARNING]
> Modifying the a headunit software may impact the vehicle's warranty or functionality. It is advised to proceed with caution and under your own responsibility.
