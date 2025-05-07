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
    __IO uint32_t TCR;
    __IO uint32_t TCNT;
    __IO uint32_t PSC;
    __IO uint32_t ARR;
} TIMER_TypeDef;

#define APB_BASEADDR    0x10000000
#define GPOA_BASEADDR   (APB_BASEADDR + 0x1000)
#define GPIB_BASEADDR   (APB_BASEADDR + 0x2000)
#define GPIOC_BASEADDR  (APB_BASEADDR + 0x3000)
#define GPIOD_BASEADDR  (APB_BASEADDR + 0x4000)
#define GPFND_BASEADDR  (APB_BASEADDR + 0x5000)
#define TIMER_BASEADDR  (APB_BASEADDR + 0x6000)

#define GPOA            ((GPO_TypeDef *) GPOA_BASEADDR)
#define GPIB            ((GPI_TypeDef *) GPIB_BASEADDR)
#define GPIOC           ((GPIO_TypeDef *) GPIOC_BASEADDR)
#define GPIOD           ((GPIO_TypeDef *) GPIOD_BASEADDR)
#define GPFND           ((GPFND_TypeDef *) GPFND_BASEADDR)
#define TIMER           ((TIMER_TypeDef *) TIMER_BASEADDR)

void delay(int n);

void LED_init(GPIO_TypeDef *GPIOx);
void LED_write(GPIO_TypeDef *GPIOx, uint32_t data);

void Switch_init(GPIO_TypeDef *GPIOx);
uint32_t Switch_read(GPIO_TypeDef *GPIOx);

void FND_init(GPFND_TypeDef *fnd, uint32_t ON_OFF);
void FND_writeData(GPFND_TypeDef *fnd, uint32_t data, uint32_t dp);

void TIM_init(TIMER_TypeDef *tim, uint32_t psc, uint32_t arr);
void TIM_start(TIMER_TypeDef *tim);
void TIM_stop(TIMER_TypeDef *tim);
void TIM_writePresacler(TIMER_TypeDef *tim, uint32_t psc);
void TIM_writeAutoReload(TIMER_TypeDef *tim, uint32_t arr);
void TIM_clear(TIMER_TypeDef *tim);
uint32_t TIM_readCounter(TIMER_TypeDef *tim);

uint32_t LED_DataSet(uint32_t sw,uint32_t* en0,uint32_t* en1,uint32_t* en2,uint32_t* en3,uint32_t*preCnt0,uint32_t*preCnt1,uint32_t*preCnt2,uint32_t*preCnt3,uint32_t* dtime,uint32_t* ledData);
void LED_ctrl(uint32_t arr_max, uint32_t en, uint32_t* preCnt, uint32_t* indicator, uint32_t Ontime, uint32_t led_num);
uint32_t count_ctrl(uint32_t max_count, uint32_t* preCnt, uint32_t Ontime);

int main(void)
{
    uint32_t psc_max = 100000 - 1;
    uint32_t arr_max = 3000 - 1;

    LED_init(GPIOC);
    Switch_init(GPIOD);
    TIM_init(TIMER,psc_max,arr_max);
    FND_init(GPFND,1);

    uint32_t dtime = 500;
    uint32_t en0 = 1;
    uint32_t en1 = 0;
    uint32_t en2 = 0;
    uint32_t en3 = 0;
    uint32_t preCnt0 = 0;
    uint32_t preCnt1 = 0;
    uint32_t preCnt2 = 0;
    uint32_t preCnt3 = 0;
    uint32_t led_data = 0b00000000;    
    TIM_start(TIMER);
    while(1)
    {
        FND_writeData(GPFND,TIM_readCounter(TIMER),0xf);
        LED_ctrl(arr_max , 1,&preCnt0, &led_data,500,0);
        LED_ctrl(arr_max , en1,&preCnt1, &led_data,dtime,1);
        LED_ctrl(arr_max , en2,&preCnt2, &led_data,dtime,2);
        LED_ctrl(arr_max , en3,&preCnt3, &led_data,dtime,3);
        LED_DataSet(Switch_read(GPIOD),&en0,&en1,&en2,&en3,&preCnt0,&preCnt1,&preCnt2,&preCnt3,&dtime,&led_data);
        LED_write(GPIOC, led_data);
    }
    return 0;
}

void delay(int n)
{
    uint32_t temp = 0;
    for (int i=0; i<n; i++){
        for (int j=0; j<1000; j++){
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
    fnd->DP = dp;
}

/* timer function */
void TIM_init(TIMER_TypeDef *tim, uint32_t psc, uint32_t arr)
{
	tim->TCR = 0b00; // set enable bit
    TIM_writePresacler(tim,psc);
    TIM_writeAutoReload(tim,arr);
}

void TIM_start(TIMER_TypeDef *tim)
{
	tim->TCR |= (1<<0); // set enable bit
}

void TIM_stop(TIMER_TypeDef *tim)
{
    tim->TCR &= ~(1<<0); // reset enable bit
}

void TIM_writePresacler(TIMER_TypeDef *tim, uint32_t psc)
{
    tim->PSC = psc;
}

void TIM_writeAutoReload(TIMER_TypeDef *tim, uint32_t arr)
{
    tim->ARR = arr;
}

void TIM_clear(TIMER_TypeDef *tim)
{
    tim->TCR |= (1<<1); // set clear bit;
	tim->TCR &= ~(1<<1); // reset clear bit;
}

uint32_t TIM_readCounter(TIMER_TypeDef *tim)
{
    return tim->TCNT;
}

uint32_t LED_DataSet(uint32_t sw,uint32_t* en0,uint32_t* en1,uint32_t* en2,uint32_t* en3,uint32_t*preCnt0,uint32_t*preCnt1,uint32_t*preCnt2,uint32_t*preCnt3,uint32_t* dtime,uint32_t* ledData){
    *en0 = 1;
    if(sw){
        *ledData = 0;
        *preCnt0 = TIM_readCounter(TIMER);
        *preCnt1 = TIM_readCounter(TIMER);
        *preCnt2 = TIM_readCounter(TIMER);
        *preCnt3 = TIM_readCounter(TIMER);
    }
    switch (sw)
    {
    case (1<<0):
        *dtime = 200;
        *en1 = 1;
        *en2 = 0;
        *en3 = 0;
        return 0;
    case (1<<1):
        *dtime = 500;
        *en1 = 0;
        *en2 = 1;
        *en3 = 0;
        return 0;
    case (1<<2):
        *dtime = 1000;
        *en1 = 0;
        *en2 = 0;
        *en3 = 1;
        return 0;
    case (1<<3):
        *dtime = 1500;
        *en1 = 1;
        *en2 = 1;
        *en3 = 1;
        return 0;
    }
}

void LED_ctrl(uint32_t max_count, uint32_t en, uint32_t* preCnt, uint32_t* indicator, uint32_t Ontime, uint32_t led_num) {
    uint32_t currCnt = TIM_readCounter(TIMER);
    int32_t gap = currCnt - *preCnt;
    if(gap < 0) gap = max_count + gap;
    if(gap < Ontime) return;
    if(!en) {
        *indicator &= ~(1<<led_num);
        return;
    }
    *indicator ^= 1<<led_num;
    *preCnt = currCnt;
}

uint32_t count_ctrl(uint32_t max_count, uint32_t* preCnt, uint32_t Ontime) {
    uint32_t currCnt = TIM_readCounter(TIMER);
    uint32_t gap = currCnt - *preCnt;
    if(gap < 0) gap = max_count + gap;
    if(gap < Ontime) return 0;
    *preCnt = currCnt;
    return 1;
}