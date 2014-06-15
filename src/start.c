
#define PUBLIC 
#define PRIVATE static

#define GDT_SIZE 128

typedef unsigned int t_32;
typedef unsigned short t_16;
typedef unsigned char t_8;

/*存储段描述符 系统段描述符*/
typedef struct s_descriptor
{
  t_16 limit_low;
  t_16 base_low;
  t_8 base_mid;
  t_8 attr1;
  t_8 limit_high_attr2;
  t_8 base_high;
}DESCRIPTOR;

PUBLIC void* memcpy(void* pDest, void* pSrc, int iSize);
PUBLIC void disp_str(char* pszInfo);
PUBLIC t_8 gdt_ptr[6];
PUBLIC DESCRIPTOR gdt[GDT_SIZE];

PUBLIC void cstart()
{
  disp_str("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n------\"cstart\"  begins------\n");
  memcpy(&gdt, /*要复制到的目的地 -- 新的gdt*/
         (void*)(*((t_32*) (&gdt_ptr[2]))), /*段基址 表示要复制的起始地址*/
		 *((t_16*)(&gdt_ptr[0]))+1 /*段界限+1 表示要复制的长度*/
		);
  
  t_16* p_gdt_limit = (t_16*)(&gdt_ptr[0]); /*段界限 低2个字节*/
  t_32* p_gdt_base  = (t_32*)(&gdt_ptr[2]); /*段基址 高4个字节*/
  *p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1; /*新gdt的段界限*/
  *p_gdt_base  = (t_32)&gdt; /*新gdt的段基址*/
  
  disp_str("------\"cstart\"  finished------\n");
} 
