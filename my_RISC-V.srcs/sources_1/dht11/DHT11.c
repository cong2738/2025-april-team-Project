#include <stdint.h>

#define __IO             volatile

typedef struct{
    __IO uint32_t MODER;
    __IO uint32_t ODR;
} GPO_TypeDef;

typedef struct{
    __IO uint32_t MODER;
    __IO uint32_t IDR;
} GPI_TypeDef;

typedef struct{
    __IO uint32_t MODER;
    __IO uint32_t IDR;
    __IO uint32_t ODR;
} GPIO_TypeDef;

typedef struct{
    __IO uint32_t FCR;
    __IO uint32_t FDR;
    __IO uint32_t DP;
} GPFND_TypeDef;

typedef struct{
    __IO uint32_t rh_int;
    __IO uint32_t t_int;
    __IO uint32_t finish_int;
} DHT11_TypeDef;

#define APB_BASEADDR    0x10000000
#define GPOA_BASEADDR   (APB_BASEADDR + 0x1000)
#define GPIB_BASEADDR   (APB_BASEADDR + 0x2000)
#define GPIOC_BASEADDR  (APB_BASEADDR + 0x3000)
#define GPIOD_BASEADDR  (APB_BASEADDR + 0x4000)
#define GPFND_BASEADDR  (APB_BASEADDR + 0x5000)
#define DHT11_BASEADDR  (APB_BASEADDR + 0x6000)

#define GPOA            ((GPO_TypeDef *) GPOA_BASEADDR)
#define GPIB            ((GPI_TypeDef *) GPIB_BASEADDR)
#define GPIOC           ((GPIO_TypeDef *) GPIOC_BASEADDR)
#define GPIOD           ((GPIO_TypeDef *) GPIOD_BASEADDR)
#define GPFND           ((GPFND_TypeDef *) GPFND_BASEADDR)
#define DHT11           ((DHT11_TypeDef *) DHT11_BASEADDR)


void delay(int n);

void LED_init(GPIO_TypeDef *GPIOx);
void LED_write(GPIO_TypeDef *GPIOx, uint32_t data);

void Switch_init(GPIO_TypeDef *GPIOx);
uint32_t Switch_read(GPIO_TypeDef *GPIOx);

void FND_init(GPFND_TypeDef *fnd, uint32_t ON_OFF);
void FND_writeData(GPFND_TypeDef *fnd, uint32_t data, uint32_t dp);

#define FND_OFF     0
#define FND_ON      1

uint32_t dht11_read_RH(DHT11_TypeDef *dht11);
uint32_t dht11_read_T(DHT11_TypeDef *dht11);
uint32_t dht11_read_FINISH(DHT11_TypeDef *dht11);


int main(void)
{
    FND_init(GPFND, FND_ON);

    while (1)
    {
        // 가끔 t가 00으로 나오는 경우가 있다.
        uint32_t rh = dht11_read_RH(DHT11) & 0xFF;
        uint32_t t  = dht11_read_T (DHT11) & 0xFF;
        uint32_t comb = (rh<<6) + (rh<<5) + (rh<<2) +  t;
        FND_writeData(GPFND, comb, 0xB);
        delay(1);

        
        // test: finish가 들어올때 read -> 실패 -> 측정 주기 매우 길어짐
        // uint32_t finish = dht11_read_FINISH(DHT11) & 1;
        // if (finish) {
        //     uint32_t rh = dht11_read_RH(DHT11) & 0xFF;
        //     uint32_t t  = dht11_read_T(DHT11)  & 0xFF;
        //     uint32_t comb = (rh<<6) + (rh<<5) + (rh<<2) + t;
        //     FND_writeData(GPFND, comb, 0xB);
        // }
        // delay(1);

    }
    return 0;
}

void delay(int n)
{
    volatile uint32_t temp = 0;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < 1000; j++) {
            temp++;
        }
    }
}

void LED_init(GPIO_TypeDef *GPIOx)
{
    GPIOx->MODER = 0xff;
}

void LED_write(GPIO_TypeDef *GPIOx, uint32_t data)
{
    GPIOx->ODR = data;
}

void Switch_init(GPIO_TypeDef *GPIOx)
{
    GPIOx->MODER = 0x00;
}

uint32_t Switch_read(GPIO_TypeDef *GPIOx)
{
    return GPIOx->IDR;
}

void FND_init(GPFND_TypeDef *fnd, uint32_t ON_OFF)
{
    fnd->FCR = ON_OFF;
}

void FND_writeData(GPFND_TypeDef *fnd, uint32_t data, uint32_t dp)
{
    fnd->FDR = data;
    fnd->DP  = dp;
}

uint32_t dht11_read_RH(DHT11_TypeDef *dht11)
{
    return dht11->rh_int;
}

uint32_t dht11_read_T(DHT11_TypeDef *dht11)
{
    return dht11->t_int;
}

uint32_t dht11_read_FINISH(DHT11_TypeDef *dht11)
{
    return dht11->finish_int;
}