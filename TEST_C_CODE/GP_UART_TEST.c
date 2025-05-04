#include <stdint.h>

#define __IO             volatile

typedef struct{
    __IO uint32_t MODER;
    __IO uint32_t IDR;
    __IO uint32_t ODR;
} GPIO_TypeDef;

typedef struct{
    __IO uint32_t TCR;
    __IO uint32_t TCNT;
    __IO uint32_t PSC;
    __IO uint32_t ARR;
} TIMER_TypeDef;

typedef struct{
    __IO uint32_t FCR;
    __IO uint32_t FDR;
    __IO uint32_t DP;
} GPFND_TypeDef;

typedef struct{
    __IO uint32_t TXD;
    __IO uint32_t RXD;
    __IO uint32_t tx_full;
    __IO uint32_t rx_empty;
} GPUART_TypeDef;

typedef struct{
    __IO uint32_t IDR;
} HCSR04_TypeDef;

typedef struct{
    __IO uint32_t MOD;
    __IO uint32_t DATA;
    __IO uint32_t OPDATA;
    __IO uint32_t RESULT;
} GPCAL_TypeDef;

#define APB_BASEADDR     0x10000000
#define SWITCH_BASEADDR  (APB_BASEADDR + 0x1000)
#define LED_BASEADDR     (APB_BASEADDR + 0x2000)
#define TIMER_BASEADDR   (APB_BASEADDR + 0x3000)
#define GPFND_BASEADDR   (APB_BASEADDR + 0x4000)
#define GPUART_BASEADDR  (APB_BASEADDR + 0x5000)
#define HCSR04_BASEADDR  (APB_BASEADDR + 0x6000)
#define GPCAL_BASEADDR   (APB_BASEADDR + 0x7000)

#define SWITCH           ((GPIO_TypeDef *) SWITCH_BASEADDR)
#define LED              ((GPIO_TypeDef *) LED_BASEADDR)
#define TIMER            ((TIMER_TypeDef *) TIMER_BASEADDR)
#define GPFND            ((GPFND_TypeDef *) GPFND_BASEADDR)
#define GPUART           ((GPUART_TypeDef *) GPUART_BASEADDR)
#define HCSR04           ((HCSR04_TypeDef *) HCSR04_BASEADDR)
#define GPCAL            ((GPCAL_TypeDef *) GPCAL_BASEADDR)

void delay(int n);

void LED_init(GPIO_TypeDef *GPIOx);
void LED_write(GPIO_TypeDef *GPIOx, uint32_t data);

void Switch_init(GPIO_TypeDef *GPIOx);
uint32_t Switch_read(GPIO_TypeDef *GPIOx);

void FND_init(GPFND_TypeDef *fnd, uint32_t ON_OFF);
void FND_writeData(GPFND_TypeDef *fnd, uint32_t data, uint32_t dp);

uint32_t UART_isFUll(GPUART_TypeDef* UART);
uint32_t UART_isEMPTY(GPUART_TypeDef* UART);
void UART_trans(GPUART_TypeDef* UART, uint32_t data);
uint32_t UART_read(GPUART_TypeDef* UART);
uint32_t HCSR04_READ(HCSR04_TypeDef* hc_sr04);

int main(void)
{
    FND_init(GPFND, 1);
    uint32_t readData = 0;
    while (1)
    {  
        readData = UART_read(GPUART);
        if(readData != 0) UART_trans(GPUART, readData);
        FND_writeData(GPFND, readData,0xf);
        delay(1000);
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

uint32_t UART_isFUll(GPUART_TypeDef* UART) {
    return UART->tx_full;
}

uint32_t UART_isEMPTY(GPUART_TypeDef* UART) {
    return UART->rx_empty;
}

void UART_trans(GPUART_TypeDef* UART, uint32_t data) {
    UART->TXD = data;
}

uint32_t UART_read(GPUART_TypeDef* UART) {
    return UART->RXD;
}

uint32_t HCSR04_READ(HCSR04_TypeDef* hc_sr04) {
    return hc_sr04->IDR;
}
