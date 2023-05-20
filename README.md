# :star2: Elipse&Animation in Assembly :star2:
### :sparkles: :sparkles: Program written with patience, love and pride :sparkles: :sparkles:

#### I am pleased to present my program written in assembler language which draws an ellipse.
#### This program takes as arguments the size of the ellipse (2 numbers - X size, Y size) in the range from 0 to 200

### What my program can do?
Once you run the program and an ellipse is drawn, you can use the arrows to enlarge and reduce the size of the ellipse: \
:arrow_up: - ellipse increases in size on the Y-axis\
:arrow_down: - ellipse shrinks out on Y-axis\
:arrow_right: - ellipse increases in size on X-axis\
:arrow_left: - ellipse shrinks on X-axis

Moreover, you can change elipse colors using:\
1 - :purple_circle: \
2 - :large_blue_circle: \
3 - :green_circle: \
4 - :yellow_circle: \
5 - :orange_circle: \
6 - :red_circle: \
7 - :white_circle:

Also, when you click CTRL + C, elipse switch mode to circle animation! :star2: 

To return to elipse mode, click CTRL + E

To close the program, click ESC

### What input does the program accept?
The program accepts 2 numbers from 0 to 200 (for X size and Y size).
NOTE: the arguments are given when starting the program

#### Examples:
Input: *elipse 20 200* \
Output: cute purple elipse \

#### Moreover, my program handles exceptions and errors as *bad input* data:
Input: *elipse 20 350*\
Output: bad input data\
\
Input: *elipse 20*\
Output: bad input data

### How to run?
*for Linux OS*
1. Install dosbox:
    ```bash
    # For Debian/Ubuntu-based systems:
    sudo apt install dosbox
    # For Fedora/RHEL/CentOS systems:
    sudo dnf install dosbox
    # For Arch-based systems:
    sudo pacman -S dosbox
2. Run dosbox
    ```bash
    dosbox
    ```
3. Mount C in *elipse-animation-asm* directory:
    ```bash
    Z:\> mount c <path-to-directory>
    Z:\> c:
    ```
4. Do this:
    ```bash
    C:\> masm elipse;
    C:\> link elipse;
    C:\> elipse 200 120
    ```
   or
    ```bash
    C:\> ml elipse.asm
    C:\> elipse 200 120
    ```
5. Now you admire and play with the elipse :full_moon_with_face:
