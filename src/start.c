
#define PUBLIC 
#define PRIVATE static

#define GDT_SIZE 128

typedef unsigned int t_32;
typedef unsigned short t_16;
typedef unsigned char t_8;

/*�洢�������� ϵͳ��������*/
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
  memcpy(&gdt, /*Ҫ���Ƶ���Ŀ�ĵ� -- �µ�gdt*/
         (void*)(*((t_32*) (&gdt_ptr[2]))), /*�λ�ַ ��ʾҪ���Ƶ���ʼ��ַ*/
		 *((t_16*)(&gdt_ptr[0]))+1 /*�ν���+1 ��ʾҪ���Ƶĳ���*/
		);
  
  t_16* p_gdt_limit = (t_16*)(&gdt_ptr[0]); /*�ν��� ��2���ֽ�*/
  t_32* p_gdt_base  = (t_32*)(&gdt_ptr[2]); /*�λ�ַ ��4���ֽ�*/
  *p_gdt_limit = GDT_SIZE * sizeof(DESCRIPTOR) - 1; /*��gdt�Ķν���*/
  *p_gdt_base  = (t_32)&gdt; /*��gdt�Ķλ�ַ*/
  
  disp_str("------\"cstart\"  finished------\n");
} 
