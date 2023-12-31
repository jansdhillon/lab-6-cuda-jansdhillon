
/* Julia_set_serial.cu
*  Created on: Mar 3, 2018
*      Julia set code by Abdallah Mohamed
*      Other files by EasyBMP (see BSD_(revised)_license.txt)
*/


#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include "EasyBMP.h"

//Complex number definition
struct Complex {	// typedef is not required for C++
	float x; 		// real part is represented on x-axis in output image
	float y; 		// imaginary part is represented by y-axis in output image
};

//Function declarations
void compute_julia(const char*, int, int);
void save_image(uchar4*, const char*, int, int);
Complex add(Complex, Complex);
Complex mul(Complex, Complex);
float mag(Complex);

//main function
int main(void) {
	char* name = "test.bmp";
	compute_julia(name, 3000, 3000);	//width x height
	printf("Finished creating %s.\n", name);
	return 0;
}

// serial implementation of Julia set
void compute_julia(const char* filename, int width, int height) {
	//create output image
	uchar4 *pixels = (uchar4*)malloc(width * height * sizeof(uchar4));	//uchar4 is a CUDA type representing a vector of 4 chars

	//PROBLEM SETTINGS (marked by '******')
	// **** Accuracy ****: lower values give less accuracy but faster performance
	int max_iterations = 400;
	int infinity = 20;													//used to check if z goes towards infinity

	// ***** Shape ****: other values produce different patterns. See https://en.wikipedia.org/wiki/Julia_set
	Complex c = { 0.285, 0.01 }; 										//the constant in z = z^2 + c

	// ***** Size ****: higher w means smaller size
	float w = 4;
	float h = w * height / width;										//preserve aspect ratio

	// LIMITS for each pixel
	float x_min = -w / 2, y_min = -h / 2;
	float x_incr = w / width, y_incr = h / height;
	
	//****************************************************
	//REQ: Parallelize the following for loop using CUDA 
	//****************************************************
	for (int row = 0; row < height; row++) {						// For each pixel in image, compute pixel color
		for (int col = 0; col < width; col++) {
			Complex z;
			z.x = x_min + col * x_incr;
			z.y = y_min + row * y_incr;

			//iteratively compute z = z^2 + c and check if z goes to infinity
			int n = 0;
			do{
				z = add(mul(z, z), c);								// z = z^2 + c
			} while (mag(z) < infinity && n++ < max_iterations);	// keep looping until z->infinity or we reach max_iterations
			
			// color each pixel based on above loop
			if (n == max_iterations) {								// if we reach max_iterations before z reaches infinity, pixel is black 
				pixels[col + row * width] = { 0,0,0,0 };
			} else {												// if z reaches infinity, pixel color is based on how long it takes z to go to infinity
				unsigned char hue = (unsigned char)(255 * sqrt((float)n / max_iterations));
				pixels[col + row * width] = { hue,hue,hue,255 };
			}
		}
	}
	
	//Write output image to a file (DO NOT parallelize this function)
	save_image(pixels, filename, width, height);

	//free memory
	free(pixels);
}

void save_image(uchar4* pixels, const char* filename, int width, int height) {
	BMP output;
	output.SetSize(width, height);
	output.SetBitDepth(24);
	// save each pixel to output image
	for (int row = 0; row < height; row++) {
		for (int col = 0; col < width; col++) {
			uchar4 color = pixels[col + row * width];
			output(col, row)->Red = color.x;
			output(col, row)->Green = color.y;
			output(col, row)->Blue = color.z;
		}
	}
	output.WriteToFile(filename);
}

Complex add(Complex c1, Complex c2) {
	return{ c1.x + c2.x, c1.y + c2.y };
}

Complex mul(Complex c1, Complex c2) {
	return{ c1.x * c2.x - c1.y * c2.y, c1.x * c2.y + c2.x * c1.y };
}

float mag(Complex c) {
	return (float)sqrt((double)(c.x * c.x + c.y * c.y));
}