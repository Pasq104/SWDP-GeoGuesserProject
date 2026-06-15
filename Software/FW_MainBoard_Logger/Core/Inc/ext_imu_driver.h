#ifndef __EXT_IMU_DRIVER_H__
#define __EXT_IMU_DRIVER_H__

#include <stdint.h>
#include "main.h"

#define EXT_IMU_I2C_ADDR         (0x6A << 1)

#define EXT_IMU_WHO_AM_I_REG     0x0F
#define EXT_IMU_WHO_AM_I_VAL     0x71

#define EXT_IMU_CTRL1_XL         0x10
#define EXT_IMU_CTRL2_G          0x11

#define EXT_IMU_OUTX_L_G         0x22
#define EXT_IMU_OUTX_L_A         0x28

typedef struct {
    float x;
    float y;
    float z;
} EXT_IMU_Data;

uint8_t EXT_IMU_Init(void);
void EXT_IMU_Config(void);

void EXT_IMU_ReadAccelerometerData(
    EXT_IMU_Data *acc_data,
    uint8_t *raw_data
);

void EXT_IMU_ReadGyroscopeData(
    EXT_IMU_Data *gyro_data,
    uint8_t *raw_data
);

#endif