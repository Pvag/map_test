#include <stdio.h>

#define SEP_LINE_LENGTH 20

typedef struct gridTopology
{
  dim3 blockSize;
  dim3 gridSize;
} gridTopology;

typedef struct pixelCoords
{
  int x, y;
} pixelCoords;

gridTopology initGridTopology2D(int r, int c);
void gridDataReport(gridTopology t, int nRows, int nCols);
void printLineOf(char c);
__device__ int validThread(gridTopology t);
__global__ void testInvalidThreads(int r, int c);

int main(int argc, char *argv[])
{
  int nRows = 10, nCols = 10;
  gridTopology t = initGridTopology2D(nRows, nCols);
  // gridDataReport(t, nRows, nCols);

  testInvalidThreads<<<t.gridSize, t.blockSize>>>(nRows, nCols);

  cudaDeviceSynchronize(); // flush the printf of threads !

  // cudaDeviceReset();

  return EXIT_SUCCESS;
}

gridTopology initGridTopology2D(int nRows, int nCols)
{
  cudaDeviceProp deviceProp;
  int dev = 0;
  cudaGetDeviceProperties(&deviceProp, dev);
  int maxGridSizeX = deviceProp.maxGridSize[0];
  int maxGridSizeY = deviceProp.maxGridSize[1];
  int maxThreadsX = deviceProp.maxThreadsDim[0];
  int maxThreadsY = deviceProp.maxThreadsDim[1];

  gridTopology t;

  int blockSizeX = sqrt(deviceProp.maxThreadsPerBlock);
  if (blockSizeX > maxThreadsX) perror("! Error");
  int blockSizeY = blockSizeX;
  if (blockSizeY > maxThreadsY) { }
  int nBlocksX = (nCols + blockSizeX - 1) / blockSizeX;
  if (nBlocksX > maxGridSizeX) { }
  int nBlocksY = (nRows + blockSizeY - 1) / blockSizeY;
  if (nBlocksY > maxGridSizeY) { }

  t.blockSize = dim3(blockSizeX, blockSizeY, 0);
  t.gridSize = dim3(nBlocksX, nBlocksY, 0);
  return t;
}

void gridDataReport(gridTopology t, int nRows, int nCols)
{
  printLineOf('*');
  printf("Sizes of blocks: x:%d, y:%d\n", t.blockSize.x,
      t.blockSize.y);
  printf("Sizes of grid: x:%d, y:%d\n", t.gridSize.x,
      t.gridSize.y);
  printf("nRows: %d, nCols: %d; total pixels: %d\n",
      nRows, nCols, nRows * nCols);
  printf("number of threads: %d\n",
      t.blockSize.x * t.blockSize.y //
      * t.gridSize.x * t.gridSize.y);
  printf("number of threads - 1 block in x - 1 block in y: %d\n",
      t.blockSize.x * t.blockSize.y //
      * (t.gridSize.x - 1) * (t.gridSize.y - 1) );
  printLineOf('*');
}

__device__ int validThread(pixelCoords p)
{
  // Checks if the thread should compute or not,
  // according to its position in the CUDA grid,
  // with respect to the original 2D matrix size - e.g. an image.
  return (p.x > -1 && p.y > -1) ? 1 : 0;
}

__device__ pixelCoords computeThread2DCoordinates(int r, int c)
{
  // Each function that uses this function MUST check
  // that both pixelX and pixelY are != -1 .

  int pixelX = blockIdx.x * blockDim.x + threadIdx.x;
  int pixelY = blockIdx.y * blockDim.y + threadIdx.y;
  // NOTE: row and column of the matrix have +1 w.r.t. thread
  //       x and y coordinates !
  if (pixelX >= c) pixelX = -1; // this thread is out of bounds
  if (pixelY >= r) pixelY = -1; // this thread is out of bounds

  pixelCoords p = {pixelX, pixelY};
  return p;
}

__global__ void testInvalidThreads(int r, int c)
{
  printf("ok\n");
//  pixelCoords p = computeThread2DCoordinates(r, c);
//  if (!validThread(p))
//    printf("Thread x:%d y:%d has nothing to do here.\n",
//      p.x, p.y);
//  else printf("ciao\n");
}

void printLineOf(const char c)
{
  int i;
  for (i = 0; i < SEP_LINE_LENGTH; i++)
  {
    printf(" %c", c);
  }
  printf("\n");
}
