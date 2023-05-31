This is a convolution example that uses RIFFA 2.0 to send video frames to the
FPGA and receives a convolved version of the frame back on the PC. The design
requires a webcam to capture video frames (though you can alter the design to 
send any data you'd like, from any source). It also requires OpenCV 2.4+ and 
RIFFA 2.0+. The design is built for a Xilinx ML605 development board. 

This convolution design convolves the input image using a sobel filter. The data
is returned on channel 0. Input data is sent only on channel 0.

A prebuilt design is ready for download in the devl/projnav folder.
