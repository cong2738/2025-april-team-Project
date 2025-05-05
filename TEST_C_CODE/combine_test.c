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

typedef struct{
    __IO uint32_t RH;
    __IO uint32_t TEM;
} DHT11_TypeDef;

typedef struct{
    __IO uint32_t msec;
    __IO uint32_t sec;
    __IO uint32_t min;
    __IO uint32_t hour;
    __IO uint32_t set_msec;
    __IO uint32_t set_sec;
    __IO uint32_t set_min;
    __IO uint32_t set_hour;
} WATCH_TypeDef;

#define APB_BASEADDR     0x10000000
#define GPI_BASEADDR     (APB_BASEADDR + 0x1000)
#define LED_BASEADDR     (APB_BASEADDR + 0x2000)
#define TIMER_BASEADDR   (APB_BASEADDR + 0x3000)
#define GPFND_BASEADDR   (APB_BASEADDR + 0x4000)
#define GPUART_BASEADDR  (APB_BASEADDR + 0x5000)
#define HCSR04_BASEADDR  (APB_BASEADDR + 0x6000)
#define GPCAL_BASEADDR   (APB_BASEADDR + 0x7000)
#define DHT11_BASEADDR   (APB_BASEADDR + 0x8000)
#define WATCH_BASEADDR   (APB_BASEADDR + 0x9000)

#define GPI              ((GPIO_TypeDef *) GPI_BASEADDR)
#define LED              ((GPIO_TypeDef *) LED_BASEADDR)
#define TIMER            ((TIMER_TypeDef *) TIMER_BASEADDR)
#define GPFND            ((GPFND_TypeDef *) GPFND_BASEADDR)
#define GPUART           ((GPUART_TypeDef *) GPUART_BASEADDR)
#define HCSR04           ((HCSR04_TypeDef *) HCSR04_BASEADDR)
#define GPCAL            ((GPCAL_TypeDef *) GPCAL_BASEADDR)
#define DHT11            ((DHT11_TypeDef *) DHT11_BASEADDR)
#define WATCH            ((WATCH_TypeDef *) WATCH_BASEADDR)

void delay(int n);

void LED_init(GPIO_TypeDef *GPIOx);
void LED_write(GPIO_TypeDef *GPIOx, uint32_t data);

void Switch_init(GPIO_TypeDef *GPIOx);
uint32_t Switch_read(GPIO_TypeDef *GPIOx);

void FND_init(GPFND_TypeDef *fnd, uint32_t ON_OFF, uint32_t dp);
void FND_writeData(GPFND_TypeDef *fnd, uint32_t data, uint32_t dp);

uint32_t UART_isFUll(GPUART_TypeDef* UART);
uint32_t UART_isEMPTY(GPUART_TypeDef* UART);
void UART_trans(GPUART_TypeDef* UART, uint32_t data);
uint32_t UART_read(GPUART_TypeDef* UART);
uint32_t HCSR04_READ(HCSR04_TypeDef* hc_sr04);

void TIM_init(TIMER_TypeDef *tim, uint32_t psc, uint32_t arr);
void TIM_start(TIMER_TypeDef *tim);
void TIM_stop(TIMER_TypeDef *tim);
void TIM_writePresacler(TIMER_TypeDef *tim, uint32_t psc);
void TIM_writeAutoReload(TIMER_TypeDef *tim, uint32_t arr);
void TIM_clear(TIMER_TypeDef *tim);
uint32_t TIM_readCounter(TIMER_TypeDef *tim);
uint32_t time_ctrl(TIMER_TypeDef* timer,uint32_t max_count, uint32_t* preCnt, uint32_t Ontime);

void set_cal(GPCAL_TypeDef* calculator, uint32_t mod, uint32_t data, uint32_t opdata);
uint32_t cal_result(GPCAL_TypeDef* calculator);

void convertData(GPCAL_TypeDef* calculator, uint32_t data, uint32_t* string, uint32_t length);
void transString(GPUART_TypeDef* uart, uint32_t* string, uint32_t length);

uint32_t dht11_readRH(DHT11_TypeDef* dht11);
uint32_t dht11_readTEM(DHT11_TypeDef* dht11);

uint16_t combineData(uint32_t data1, uint32_t data2, uint32_t sep);

void printRes(uint32_t* distance_data, uint32_t* RH_data, uint32_t* TEM_data);
void printTime(uint32_t* hour_data, uint32_t* min_data, uint32_t* sec_data);

uint32_t RxDataCheck(uint32_t* receiveData);
uint32_t TimeStringInit(uint32_t* rxString);

uint32_t ButtonRead(GPIO_TypeDef* button);
void ButtonInit(GPIO_TypeDef* button);
void ButtonPush(uint32_t sw, uint32_t swNum, uint32_t *push);
void ButtonRelease(uint32_t sw, uint32_t swNum, uint32_t *push, uint32_t *release);
void ButtonReleaseEvent(uint32_t sw, uint32_t swNum, uint32_t *push, uint32_t *release, uint32_t *led_data);

void getTime(WATCH_TypeDef*watch, uint32_t* msec, uint32_t* sec, uint32_t* min, uint32_t* hour);
uint32_t StringToInt(uint32_t* time);

/* main */
int main(void)
{
    uint32_t psc = 100000-1, arr = 10000-1; // 단위시간 100_000/100_000_000 = 1msec, maxcount: 9999
    LED_init(LED);
    ButtonInit(GPI);
    FND_init(GPFND, 1, 0x0);
    TIM_init(TIMER,psc,arr);
    TIM_start(TIMER);
    uint32_t fnd_mode = 0;
    uint32_t fndData = 0;
    uint32_t watchPreCnt = 0;
    uint32_t printResPreCnt = 0;
    uint32_t rxPreCnt = 0;
    uint32_t readIdx = 0;
    uint32_t rxString[5]; // S00:00:00
    TimeStringInit(rxString);
    uint32_t push = 0, release = 0;
    uint32_t distance_data[3];
    uint32_t TEM_data[3];
    uint32_t RH_data[3];
    uint32_t hour_data[2];
    uint32_t min_data[2];
    uint32_t sec_data[2];
    uint32_t msec, sec, min, hour;
    while (1)
    {  
        getTime(WATCH,&msec,&sec,&min,&hour);

        uint32_t distance = HCSR04_READ(HCSR04);
        uint32_t RH = dht11_readRH(DHT11);
        uint32_t TEM = dht11_readTEM(DHT11);

        uint32_t h_m = combineData(hour,min,100);
        uint32_t s_m = combineData(sec,msec,100);
        uint32_t T_RH = combineData(TEM,RH,100);
        
        convertData(GPCAL,distance,distance_data,3);
        convertData(GPCAL,RH,RH_data,3);
        convertData(GPCAL,TEM,TEM_data,3);
        
        convertData(GPCAL,hour,hour_data,2);
        convertData(GPCAL,min,min_data,2);
        convertData(GPCAL,sec,sec_data,2);

        if(time_ctrl(TIMER, arr, &printResPreCnt, 500)) {
            printTime(hour_data,min_data,sec_data);
            printRes(distance_data,RH_data,TEM_data);
        }
        if(!UART_isEMPTY(GPUART)) {
            rxString[readIdx] = UART_read(GPUART); // read from input buffer
            readIdx = readIdx + 1;
            if(readIdx == 5) { // if string is full
                if(RxDataCheck(rxString)) {
                    fndData = StringToInt(rxString);
                    transString(GPUART,rxString,5);
                    UART_trans(GPUART,'\n');
                } else {
                    delay(10);
                    while(!UART_isEMPTY(GPUART)) UART_read(GPUART); //flush buffer
                }
                readIdx = 0; // reset idx
            }
        }

        uint32_t bt = ButtonRead(GPI);
        ButtonReleaseEvent(bt,0,&push,&release,&fnd_mode);
        FND_writeData(GPFND,fndData,0b1111);
    }
    
    return 0;
}
///////////////////////////////////////////////////////////////////////////////

/* delay function */
void delay(int n)
{
    uint32_t temp = 0;
    for (int i=0; i<n; i++){
        for (int j=0; j<1000; j++){
            temp++;
        }
    }
}
///////////////////////////////////////////////////////////////////////////////

/* led function */
void LED_init(GPIO_TypeDef *GPIOx)
{
    GPIOx->MODER = 0xff;
}

void LED_write(GPIO_TypeDef *GPIOx, uint32_t data)
{
    GPIOx->ODR = data;
}
///////////////////////////////////////////////////////////////////////////////

/* switch function */
void Switch_init(GPIO_TypeDef *GPIOx)
{
    GPIOx->MODER = 0x00;
}

uint32_t Switch_read(GPIO_TypeDef *GPIOx)
{
    return GPIOx->IDR;
}
///////////////////////////////////////////////////////////////////////////////


/* fnd function */
void FND_init(GPFND_TypeDef *fnd, uint32_t ON_OFF, uint32_t dp)
{
    fnd->FCR = ON_OFF;
    fnd->DP = dp;
}

void FND_writeData(GPFND_TypeDef *fnd, uint32_t data, uint32_t dp)
{
    fnd->FDR = data;
    fnd->DP = dp;
}
///////////////////////////////////////////////////////////////////////////////

/* uart function */
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
///////////////////////////////////////////////////////////////////////////////

/* hcsr04 function */
uint32_t HCSR04_READ(HCSR04_TypeDef* hc_sr04) {
    return hc_sr04->IDR;
}
///////////////////////////////////////////////////////////////////////////////

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

uint32_t time_ctrl(TIMER_TypeDef* timer,uint32_t max_count, uint32_t* preCnt, uint32_t Ontime) {
    uint32_t currCnt = TIM_readCounter(timer);
    uint32_t gap = currCnt - *preCnt;
    if(gap < 0) gap = max_count + gap;
    if(gap < Ontime) return 0;
    *preCnt = currCnt;
    return 1;
}
///////////////////////////////////////////////////////////////////////////////

/* cal function */
void set_cal(GPCAL_TypeDef* calculator, uint32_t mod, uint32_t data, uint32_t opdata) {
    calculator->MOD = mod;
    calculator->DATA = data;
    calculator->OPDATA = opdata;
}
uint32_t cal_result(GPCAL_TypeDef* calculator) {
    return calculator->RESULT;
}
///////////////////////////////////////////////////////////////////////////////

/* convertData function */
void convertData(GPCAL_TypeDef* calculator, uint32_t data, uint32_t* string, uint32_t length) {
    for (int i = 0; i < length; i++)
    {
        set_cal(calculator,'%',data,10);
        string[i] = cal_result(calculator) + '0';
        
        set_cal(calculator,'/',data,10);
        data = cal_result(calculator);
    }
}
///////////////////////////////////////////////////////////////////////////////

/* transString function */
void transString(GPUART_TypeDef* uart, uint32_t* string, uint32_t length) {
    int i = length;
    while (i != 0)
    {
        i--;
        UART_trans(uart, string[i]);
    }
}
///////////////////////////////////////////////////////////////////////////////

/* dht11 function */
uint32_t dht11_readRH(DHT11_TypeDef* dht11) {
    uint32_t data[4];
    return dht11->RH;
}
uint32_t dht11_readTEM(DHT11_TypeDef* dht11) {
    uint32_t data[4];
    return dht11->TEM;
}
///////////////////////////////////////////////////////////////////////////////

/* combineData function */
uint16_t combineData(uint32_t data1, uint32_t data2, uint32_t sep) {
    set_cal(GPCAL,'*',data1,sep);
    return cal_result(GPCAL) + data2;
}
///////////////////////////////////////////////////////////////////////////////

/* print function */
void printRes(uint32_t* distance_data, uint32_t* RH_data, uint32_t* TEM_data){
    UART_trans(GPUART,'D');
    UART_trans(GPUART,'I');
    UART_trans(GPUART,'S');
    UART_trans(GPUART,':');
    UART_trans(GPUART,' ');
    transString(GPUART,distance_data,3);
    UART_trans(GPUART,'\n');
    UART_trans(GPUART,'R');
    UART_trans(GPUART,'H');
    UART_trans(GPUART,' ');
    UART_trans(GPUART,':');
    UART_trans(GPUART,' ');
    transString(GPUART,RH_data,3);
    UART_trans(GPUART,'\n');
    UART_trans(GPUART,'T');
    UART_trans(GPUART,'E');
    UART_trans(GPUART,'M');
    UART_trans(GPUART,':');
    UART_trans(GPUART,' ');
    transString(GPUART,TEM_data,3);
    UART_trans(GPUART,'\n');
    UART_trans(GPUART,'\n');
}
void printTime(uint32_t* hour_data, uint32_t* min_data, uint32_t* sec_data){
    UART_trans(GPUART,'T');
    UART_trans(GPUART,'I');
    UART_trans(GPUART,'M');
    UART_trans(GPUART,'E');
    UART_trans(GPUART,'-');
    transString(GPUART,hour_data,2);
    UART_trans(GPUART,':');
    transString(GPUART,min_data,2);
    UART_trans(GPUART,':');
    transString(GPUART,sec_data,2);
    UART_trans(GPUART,'\n');
}
///////////////////////////////////////////////////////////////////////////////

/* readString function */
uint32_t RxDataCheck(uint32_t* receiveData){
    if(!(receiveData[0] == 'S')) return 0;
    if(!((receiveData[1] >= '0') & (receiveData[1] <= '9'))) return 0;
    if(!((receiveData[2] >= '0') & (receiveData[2] <= '9'))) return 0;
    if(!((receiveData[3] >= '0') & (receiveData[3] <= '9'))) return 0;
    if(!((receiveData[4] >= '0') & (receiveData[4] <= '9'))) return 0;
    if(!(receiveData[5] == 'E')) return 0;
    return 1;
}
///////////////////////////////////////////////////////////////////////////////

/* readString function */
uint32_t TimeStringInit(uint32_t* rxString){
    rxString[0] = 'S';
    rxString[1] = '0';
    rxString[2] = '0';
    rxString[3] = '0';
    rxString[4] = '0';
    rxString[4] = 'E';
}
///////////////////////////////////////////////////////////////////////////////

/* button function */
void ButtonInit(GPIO_TypeDef* button) {
    button->MODER = 0x00;
}

uint32_t ButtonRead(GPIO_TypeDef* button) {
    return button->IDR;
}

void ButtonPush(uint32_t sw, uint32_t swNum, uint32_t *push){
    if(sw & (1<<swNum)){
        *push = 1;
    }
}

void ButtonRelease(uint32_t sw, uint32_t swNum, uint32_t *push, uint32_t *release){
    if(*push & ~(sw & (1<<swNum))){
        *release = 1;
        *push = 0;
    }
}

void ButtonReleaseEvent(uint32_t sw, uint32_t swNum, uint32_t *push, uint32_t *release, uint32_t *mode){
    ButtonPush(sw,swNum,push);
    ButtonRelease(sw,swNum,push,release);
    if(*release) {
        *mode += 1;
        if(mode == 5) mode = 0;
        *release = 0;
    }
}
///////////////////////////////////////////////////////////////////////////////

/* watch function */
void getTime(WATCH_TypeDef*watch, uint32_t* msec, uint32_t* sec, uint32_t* min, uint32_t* hour) {
    *msec = watch->msec;
    *sec = watch->sec;
    *min = watch->min;
    *hour = watch->hour;
}
///////////////////////////////////////////////////////////////////////////////

uint32_t StringToInt(uint32_t* time){    
    uint32_t data = 0;
    data = combineData(data,time[1]-'0',10);
    data = combineData(data,time[2]-'0',10);
    data = combineData(data,time[3]-'0',10);
    data = combineData(data,time[4]-'0',10);
    return data;
}