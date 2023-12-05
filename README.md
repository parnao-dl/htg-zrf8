# HTG-ZRF8-R2 Reference Design PetaLinux Project
This PetaLinux project serves as the core of PetaLinux support for the HTG-ZRF8-R2. This project can be built as is to generate the reference design image (HTG-ZRF8-REF), but also contains supporting scripts in order to automate BSP generation for customers. The instructions below focus on generating the reference design image, but please consult the *./doc* directory for more information on BSP generation and the assets that should be provided for customer use.

## Build Requirements
* Ubuntu Desktop/Server 18.04.1 LTS, 20.04 LTS, 22.04 LTS  or other Xilinx support Linux distro.
* PetaLinux 2023.1 Installation  

More details on specific PetaLinux setup and usage can be found in the 2023.1 version of UG1144:   
https://docs.xilinx.com/r/en-US/ug1144-petalinux-tools-reference-guide/Introduction

## Build and Programming Steps
1. Open a terminal in the project directory.   
2. Source PetaLinux environment.   
    ```
    source </path/to/petalinux/install/settings.sh>
    ```   
3. Run petalinux-build to build the project:  
    ```
    petalinux-build
    ```
4. Run petalinux-package to package the bootloader and PL logic:   
    ```
    petalinux-package --boot --u-boot --fpga --force
    ```
5. Run petalinux-package to package the image to WIC for an SD card.   
    ```
    petalinux-package --wic --wks support/sd-boot.wks
    ```
6. Insert an SD card of at least 2 GB in size into your PC.   
7. Using your tools of choice (dd, Balena Etcher, etc.), flash the WIC image (*./images/linux/petalinux-sdimage.wic*) to the SD card.   
8. Remove the card from the PC, and insert into the board. Ensure that the DIP switches in S1 are configured for SD boot (0101).   
9. Power up the board with a terminal connected to the USB micro to serial converter at 115200 8N1.  
