#include "opencv2/objdetect/objdetect.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"

#include <iostream>
#include <stdio.h>
#include <sys/time.h>
#include <pthread.h>
#include <riffa.h>

using namespace std;
using namespace cv;


#define TIME_VAL_TO_MS(t) (((double)t.tv_sec*1000.0) + ((double)t.tv_usec/1000.0))
#define ELAPSED_TIME_MS(e, s) (TIME_VAL_TO_MS(e) - TIME_VAL_TO_MS(s))

CvCapture* capture = 0;
fpga_t * fpga;
int begin = 0;
int end = 0;
Mat origFrame;
int w, h;


void * sender_fxn(void *) {
	IplImage * bufImg = 0;
	unsigned char * buf = 0;
    Mat frame, frameGray;
	int sent;

    cout << "In capture ..." << endl;
    for(;;)
    {
        IplImage* iplImg = cvQueryFrame( capture );
        frame = iplImg;
        if( frame.empty() )
            break;
        if( iplImg->origin == IPL_ORIGIN_TL )
            frame.copyTo( origFrame );
        else
            flip( frame, origFrame, 0 );

		// Create the gray frame if necessary
		w = iplImg->width;
		h = iplImg->height;
		begin = 1;
		if (buf == NULL) {
			buf = (unsigned char *)malloc((w*h) + 8);
			bufImg = cvCreateImageHeader(cvSize(w,h), IPL_DEPTH_8U, 1);
			cvSetData(bufImg, (buf+8), w);
			frameGray = bufImg;
		}

		cvtColor(origFrame, frameGray, CV_RGB2GRAY, 1);
		int * hdrPtr = (int *)buf;
		hdrPtr[0] = w;
		hdrPtr[1] = h;

		sent = fpga_send(fpga, 0, buf, ((w*h)+8)/4, 0, 1, 2000);
		
		if (sent != ((w*h)+8)/4) {
			printf("Sent %d words, expecting %d. Exiting.\n", sent, ((w*h)+8)/4);
			end = 1;
		}			

		if (end)
			break;
    }

	if (buf != NULL)
		free(buf);
	if (bufImg != NULL)
		cvReleaseImageHeader(&bufImg); 
}


void * receiver_fxn(void *) {
	IplImage * bufImg = 0;
	unsigned char * buf = 0;
    Mat frame;
	int rc;
	long long frameCount = 0;
	double ttime = 0.0;
	struct timeval t1, t2;

 	cvNamedWindow( "orig", 1 );
 	cvNamedWindow( "filtered", 1 );

	while (!begin);

	// Create the receive buffer
	buf = (unsigned char *)malloc((w-2)*(h-2));
	bufImg = cvCreateImageHeader(cvSize(w-2,h-2), IPL_DEPTH_8U, 1);
	cvSetData(bufImg, buf, w-2);
	frame = bufImg;

	gettimeofday(&t1, NULL);
    for(;;)
    {
		// Wait for the filtered data to come back.
		rc = fpga_recv(fpga, 0, buf, ((w-2)*(h-2))/4, 2000);

		if (rc < ((w-2)*(h-2))/4) {
			printf("Received %d words, expecting %d. Exiting.\n", rc, ((w-2)*(h-2))/4);
			end = 1;
		}			

		cv::imshow( "orig", origFrame );
		cv::imshow( "filtered", frame );

		gettimeofday(&t2, NULL);
		ttime += ELAPSED_TIME_MS(t2, t1);
		frameCount++;
		printf("%sFPS: %f", "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b", ttime/frameCount);
		gettimeofday(&t1, NULL);

		rc = waitKey( 2 );
        if(rc >= 0)
			end = 1;

		if (end)
			break;
    }

	if (buf != NULL)
		free(buf);
	if (bufImg != NULL)
		cvReleaseImageHeader(&bufImg); 

    cvDestroyWindow("orig");
    cvDestroyWindow("filtered");
}


int main( int argc, const char** argv ) {
    Mat frame, frameCopy, frameGray, image;
	int w, h;
	pthread_t sender; 
	pthread_t receiver; 

	fpga = fpga_open(atoi(argv[1]));
    if(fpga == NULL)
    {
        cerr << "ERROR: Could not open FPGA " << atoi(argv[1]) << "!" << endl;
        return -1;
    }

    int c = 0;
    capture = cvCaptureFromCAM(c);
    if (!capture) {
		cout << "Capture from CAM " <<  c << " didn't work" << endl;
		return -1;
	}

	fpga_reset(fpga);

    pthread_create(&sender, NULL, sender_fxn, NULL);
    pthread_create(&receiver, NULL, receiver_fxn, NULL);
    pthread_join(sender, NULL);
    pthread_join(receiver, NULL);

    return 0;
}

