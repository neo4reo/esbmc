#include<assert.h>

int main()
{
  float a[] =  {

   1.000000000000000,   1.593750000000000,   1.750000000000000,   1.031250000000000,   0.312500000000000


};
 float b[] =  {

   0.031250000000000,  -0.093750000000000,   0.156250000000000 , -0.093750000000000,   0.031250000000000
   };
  assert(__ESBMC_check_stability(a, b));
  return 0;
}