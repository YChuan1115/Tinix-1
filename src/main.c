
#include "type.h"

PUBLIC PROCESS proc_table[NR_TASKS];

PUBLIC int tinix_main()
{
  disp_str("------\"tinix_main\" begins------");
  while (1) {}
}

void delay(int time)
{
  int i, j, k;
  for (i=0; i<time; i++)
    for (j=0; j<10000; j++)
      for (k=0; k<10000; k++){}
}

void TestA()
{
  while (1) {
    disp_str("A.");
    delay(10);
  }
}

void TestB()
{
  while (1) {
    disp_str("B.");
    delay(10);
  }
}

void TestC()
{
  while (1) {
    disp_str("C.");
    delay(10);
  }
}

