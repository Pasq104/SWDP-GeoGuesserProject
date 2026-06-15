#ifndef __MAGN_DRIVER_H__
#define __MAGN_DRIVER_H__

#include <stdint.h>
#include "main.h"

#define MAGN_I2C_ADDR          (0x1E << 1)

#define MAGN_WHO_AM_I_REG      0x4F
#define MAGN_WHO_AM_I_VAL      0x40

#define MAGN_CFG_REG_A         0x60
#define MAGN_CFG_REG_B         0x61
#define MAGN_CFG_REG_C         0x62
#define MAGN_STATUS_REG        0x67
#define MAGN_OUTX_L_REG        0x68

typedef struct {
    float x;
    float y;
    float z;
} MAGN_Data;

uint8_t MAGN_Init(void);
void MAGN_Config(void);
void MAGN_ReadMagnetometerData(MAGN_Data *magn_data, uint8_t *raw_data);

#endif