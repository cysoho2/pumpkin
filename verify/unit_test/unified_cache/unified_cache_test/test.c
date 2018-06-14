#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <string.h>

#define MEM_SIZE 64

#define CPU_DATA_LEN_IN_BITS 32
#define UNIFIED_CACHE_BLOCK_SIZE_IN_BITS 4*8
#define UNIFIED_CACHE_PACKET_TYPE_WIDTH 4
#define UNIFIED_CACHE_PACKET_BYTE_MASK_LENGTH 5
#define UNIFIED_CACHE_PACKET_PORT_ID_WIDTH 5

#define UNIFIED_CACHE_PACKET_ADDR_POS_LO 0
#define UNIFIED_CACHE_PACKET_ADDR_POS_HI        (UNIFIED_CACHE_PACKET_ADDR_POS_LO  + CPU_DATA_LEN_IN_BITS - 1)

#define UNIFIED_CACHE_PACKET_DATA_POS_LO        (UNIFIED_CACHE_PACKET_ADDR_POS_HI  + 1)
#define UNIFIED_CACHE_PACKET_DATA_POS_HI        (UNIFIED_CACHE_PACKET_DATA_POS_LO  + UNIFIED_CACHE_BLOCK_SIZE_IN_BITS - 1)

#define UNIFIED_CACHE_PACKET_TYPE_POS_LO        (UNIFIED_CACHE_PACKET_DATA_POS_HI  + 1)
#define UNIFIED_CACHE_PACKET_TYPE_POS_HI        (UNIFIED_CACHE_PACKET_TYPE_POS_LO + UNIFIED_CACHE_PACKET_TYPE_WIDTH - 1)

#define UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO   (UNIFIED_CACHE_PACKET_TYPE_POS_HI + 1)
#define UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI   (UNIFIED_CACHE_PACKET_BYTE_MASK_POS_LO + UNIFIED_CACHE_PACKET_BYTE_MASK_LENGTH - 1)

#define UNIFIED_CACHE_PACKET_PORT_NUM_LO        (UNIFIED_CACHE_PACKET_BYTE_MASK_POS_HI + 1)
#define UNIFIED_CACHE_PACKET_PORT_NUM_HI        (UNIFIED_CACHE_PACKET_PORT_NUM_LO  + UNIFIED_CACHE_PACKET_PORT_ID_WIDTH - 1)

#define UNIFIED_CACHE_PACKET_VALID_POS          (UNIFIED_CACHE_PACKET_PORT_NUM_HI  + 1)
#define UNIFIED_CACHE_PACKET_IS_WRITE_POS       (UNIFIED_CACHE_PACKET_VALID_POS  + 1)
#define UNIFIED_CACHE_PACKET_CACHEABLE_POS      (UNIFIED_CACHE_PACKET_IS_WRITE_POS + 1)

#define UNIFIED_CACHE_PACKET_WIDTH_IN_BITS      (UNIFIED_CACHE_PACKET_CACHEABLE_POS - UNIFIED_CACHE_PACKET_ADDR_POS_LO + 1)

char mem[MEM_SIZE][UNIFIED_CACHE_BLOCK_SIZE_IN_BITS + 1];

void create_sim_main_memory(char* path);
void create_request_read(char* path_request, char* path_correct, int *addresses, char mem[MEM_SIZE][UNIFIED_CACHE_BLOCK_SIZE_IN_BITS + 1]);
int itoa_bin(unsigned int data, int length, char *str);
void create_request_write(char *path_request_write, char *path_request_read, char *path_correct, int *addresses);

main()
{
    int i, j,k ,index;
    char *temp; 
    
    int addresses[MEM_SIZE];
    int random_addresses_1[MEM_SIZE / 2] = {0};
    int interleaved_bank_addresses_1[MEM_SIZE / 2] = {0};
    int same_bank_addresses_1[MEM_SIZE / 2] = {0};
    int same_set_addresses_1[MEM_SIZE / 2] = {0};
    
    int random_addresses_2[MEM_SIZE / 2] = {0};
    int interleaved_bank_addresses_2[MEM_SIZE / 2] = {0};
    int same_bank_addresses_2[MEM_SIZE / 2] = {0};
    int same_set_addresses_2[MEM_SIZE / 2] = {0};
        
    //random_addresses

   for (i = 0; i < MEM_SIZE; i++)
    {
        addresses[i] = i;
    }

    srand((unsigned int) time(NULL));
    for (i = 0; i < MEM_SIZE; i++)
    {
	printf("%d", rand());
        index = 1+(int)((63 - i)*rand()/(RAND_MAX+1.0));
	    
	    temp = addresses[index];
	    addresses[index] = addresses[i];	
    
	    if(i < MEM_SIZE / 2)
	    {
	        random_addresses_1[i] = temp;
	    }
	    else
	    {
	        random_addresses_2[i - MEM_SIZE / 2] = temp;
	    }

    }    
  

    //interleaved_bank_addresses
    for (i = 0; i < MEM_SIZE; i++)
    {
        if (i < MEM_SIZE / 2)
        {
            interleaved_bank_addresses_1[i] = i;
        }
        else
        {
            interleaved_bank_addresses_2[i - MEM_SIZE / 2] = i;
        }
    
    }

    //same_bank_addresses
    j = 0;
    k = 0;
    for (i = 0; i < MEM_SIZE; i++)
    {
        if (i % 4 == 0 || i % 4 == 1)
        {
            same_bank_addresses_1[j++] = i; 
        }
        else
        {
            same_bank_addresses_2[k++] = i;
        }
        
    }

    //same_set_addresses
    for (i = 0; i < MEM_SIZE / 2; i++)
    {   
        same_set_addresses_1[i] = 0; 
        same_set_addresses_2[i] = 1;   
    }

    
    create_sim_main_memory("sim_main_mem");
    


    create_request_read("case_0/way1_request_pool", "case_0/way1_correct_result_mem", random_addresses_1, mem);  
    create_request_write("case_1/way1_request_pool_write", "case_1/way1_request_pool_read", "case_1/way1_correct_result_mem", random_addresses_1);
    
   create_request_read("case_2/way1_request_pool", "case_2/way1_correct_result_mem", interleaved_bank_addresses_1, mem);  
    create_request_write("case_3/way1_request_pool_write", "case_3/way1_request_pool_read", "case_3/way1_correct_result_mem", interleaved_bank_addresses_1);
    
    create_request_read("case_4/way1_request_pool", "case_4/way1_correct_result_mem", same_bank_addresses_1, mem);  
    create_request_write("case_5/way1_request_pool_write", "case_5/way1_request_pool_read", "case_5/way1_correct_result_mem", same_bank_addresses_1);
    
    create_request_read("case_6/way1_request_pool", "case_6/way1_correct_result_mem", same_set_addresses_1, mem);  
    create_request_write("case_7/way1_request_pool_write", "case_7/way1_request_pool_read", "case_7/way1_correct_result_mem", same_set_addresses_1);
    
    
    create_request_read("case_0/way2_request_pool", "case_0/way2_correct_result_mem", random_addresses_2, mem);  
    create_request_write("case_1/way2_request_pool_write", "case_1/way2_request_pool_read", "case_1/way2_correct_result_mem", random_addresses_2);
    
    create_request_read("case_2/way2_request_pool", "case_2/way2_correct_result_mem", interleaved_bank_addresses_2, mem);  
    create_request_write("case_3/way2_request_pool_write", "case_3/way2_request_pool_read", "case_3/way2_correct_result_mem", interleaved_bank_addresses_2);
    
    create_request_read("case_4/way2_request_pool", "case_4/way2_correct_result_mem", same_bank_addresses_2, mem);  
    create_request_write("case_5/way2_request_pool_write", "case_5/way2_request_pool_read", "case_5/way2_correct_result_mem", same_bank_addresses_2);
    
    create_request_read("case_6/way2_request_pool", "case_6/way2_correct_result_mem", same_set_addresses_2, mem);  
    create_request_write("case_7/way2_request_pool_write", "case_7/way2_request_pool_read", "case_7/way2_correct_result_mem", same_set_addresses_2);

    
}

int itoa_bin(unsigned int data, int length, char *str)
{

    char *low, *high, temp;    
    int i = 0;
    
	if(str == NULL)
		return -1;
	
	char *start = str;

	while(data)
	{
		if(data & 0x1)
			*str++ = 0x31;
		else
			*str++ = 0x30;

		data >>= 1;
		i ++;
	}

    for (; i < length; i++)
    {
	    *str++ = 0x30;
	}
	*str = 0;
	
	//reverse the order
	low = start, high = str - 1;
	
	while(low < high)
	{
		temp = *low;
		*low = *high;
		*high = temp;

		++low; 
		--high;
	}

	return 0;
}


void create_sim_main_memory(char *path)
{
    int i, j, k = 1;
    int fd = open(path,O_WRONLY|O_CREAT|O_TRUNC,0644);
    char buffer[UNIFIED_CACHE_BLOCK_SIZE_IN_BITS + 1];
    if(fd < 0){
        perror("network open ");
        exit(1);
    }
    
    for (i = 0; i < MEM_SIZE; i++)
    {
        for (j = 0; j < UNIFIED_CACHE_BLOCK_SIZE_IN_BITS; j++)
        {
           if (rand() % 2 == 1)
           {
                buffer[j] = 49;
                mem[i][j] = '1';
           }
            else
            {
                buffer[j] = 48;
                mem[i][j] = '0';
            }
        }

        k =~ k;
        buffer[UNIFIED_CACHE_BLOCK_SIZE_IN_BITS] = 0;
        mem[i][UNIFIED_CACHE_BLOCK_SIZE_IN_BITS] = 0;
	//strcpy(mem[i], buffer);
        write(fd, buffer, UNIFIED_CACHE_BLOCK_SIZE_IN_BITS);
	write(fd, "\n", 1);
        //*buffer = 0;
    }

    close(fd);
}

void create_request_write(char *path_request_write, char *path_request_read, char *path_correct, int *addresses)
{
    int i, j, k = 1;
    
    int fd_request_write = open(path_request_write, O_WRONLY|O_CREAT|O_TRUNC, 0644);

    char temp_mem [MEM_SIZE][UNIFIED_CACHE_BLOCK_SIZE_IN_BITS + 1];
    char buffer[UNIFIED_CACHE_PACKET_WIDTH_IN_BITS + 1];
    char str[32];
    int address;
    long write_content = 0xffffffff;
    
    if(fd_request_write < 0){
        perror("network open ");
        exit(1);
    }
    
    for (i = 0; i < MEM_SIZE; i ++)
    {
	for (j = 0; j < UNIFIED_CACHE_BLOCK_SIZE_IN_BITS + 1; j++)
        {
            temp_mem[i][j] = mem[i][j];         
        }
    }
    

    for (i = 0; i < MEM_SIZE / 2; i ++)
	{
        for (j = 0; j < UNIFIED_CACHE_PACKET_WIDTH_IN_BITS + 1; j ++)
        {
            buffer[j] = 0;
        }
	
            
        //requests
        /*addr*/itoa_bin(addresses[i], CPU_DATA_LEN_IN_BITS, str);
        write(fd_request_write, str, CPU_DATA_LEN_IN_BITS);
	
     	/*data*/itoa_bin(write_content, CPU_DATA_LEN_IN_BITS, str);
     	write(fd_request_write, str, UNIFIED_CACHE_BLOCK_SIZE_IN_BITS);

     	/*type*/itoa_bin(0, UNIFIED_CACHE_BLOCK_SIZE_IN_BITS, str);
        write(fd_request_write, str, UNIFIED_CACHE_BLOCK_SIZE_IN_BITS);

        /*byte mask*/itoa_bin(0, UNIFIED_CACHE_PACKET_BYTE_MASK_LENGTH, str);
        write(fd_request_write, str, UNIFIED_CACHE_PACKET_BYTE_MASK_LENGTH);

        /*port num*/itoa_bin(0, UNIFIED_CACHE_PACKET_PORT_ID_WIDTH, str);
        write(fd_request_write, str, UNIFIED_CACHE_PACKET_PORT_ID_WIDTH);

        /*valid*/write(fd_request_write, "1", 1);

      	/*write*/write(fd_request_write, 1, 1);

      	/*cacheable*/write(fd_request_write, "0", 1); 

	itoa_bin(write_content--, CPU_DATA_LEN_IN_BITS, str);
        strcpy(temp_mem[addresses[i]], str); 	    

        write(fd_request_write, "\n", 1);
	  
	}
	
	
	create_request_read(path_request_read, path_correct, addresses, temp_mem);
	
    close(fd_request_write);
}

void create_request_read(char *path_request, char *path_correct, int *addresses, char mem[MEM_SIZE][UNIFIED_CACHE_BLOCK_SIZE_IN_BITS + 1])
{
    int i, j, k = 1;
    
    int fd_request = open(path_request,O_WRONLY|O_CREAT|O_TRUNC,0644);
    int fd_correct = open(path_correct,O_WRONLY|O_CREAT|O_TRUNC,0644);
    
    char buffer[UNIFIED_CACHE_PACKET_WIDTH_IN_BITS + 1];
    char str[32];
    int address;
    long write_content = 0;
    
    if(fd_request < 0 | fd_correct < 0){
        perror("network open ");
        exit(1);
    }

    
	for (i = 0; i < MEM_SIZE / 2; i ++)
	{
        for (j = 0; j < UNIFIED_CACHE_PACKET_WIDTH_IN_BITS + 1; j ++)
        {
            buffer[j] = 0;
        }
	
            
	    //requests
        /*addr*/itoa_bin(addresses[i], CPU_DATA_LEN_IN_BITS, str);
        write(fd_request, str, CPU_DATA_LEN_IN_BITS);
	
     	/*data*/itoa_bin(write_content, CPU_DATA_LEN_IN_BITS, str);
     	write(fd_request, str, UNIFIED_CACHE_BLOCK_SIZE_IN_BITS);

     	/*type*/itoa_bin(0, UNIFIED_CACHE_BLOCK_SIZE_IN_BITS, str);
        write(fd_request, str, UNIFIED_CACHE_BLOCK_SIZE_IN_BITS);

        /*byte mask*/itoa_bin(0, UNIFIED_CACHE_PACKET_BYTE_MASK_LENGTH, str);
        write(fd_request, str, UNIFIED_CACHE_PACKET_BYTE_MASK_LENGTH);

        /*port num*/itoa_bin(0, UNIFIED_CACHE_PACKET_PORT_ID_WIDTH, str);
        write(fd_request, str, UNIFIED_CACHE_PACKET_PORT_ID_WIDTH);

        /*valid*/write(fd_request, "1", 1);

      	/*write*/write(fd_request, "0", 1);

      	/*cacheable*/write(fd_request, "0", 1); 


	    write(fd_correct, mem[addresses[i]], UNIFIED_CACHE_BLOCK_SIZE_IN_BITS);

        write(fd_correct, "\n", 1);
        write(fd_request, "\n", 1);
	    printf("%s\n", mem[addresses[i]]);
	}
	

	
    close(fd_request);
    close(fd_correct);

}
