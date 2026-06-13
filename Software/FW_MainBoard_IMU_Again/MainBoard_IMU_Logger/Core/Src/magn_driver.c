#include "magn_driver.h"

extern I2C_HandleTypeDef hi2c3;

static float magn_sensitivity = 1.5f; // mGauss/LSB

uint8_t MAGN_Init(void)
{
    uint8_t who_am_i = 0;

    HAL_I2C_Mem_Read(
        &hi2c3,
        MAGN_I2C_ADDR,
        MAGN_WHO_AM_I_REG,
        I2C_MEMADD_SIZE_8BIT,
        &who_am_i,
        1,
        HAL_MAX_DELAY
    );

    return (who_am_i == MAGN_WHO_AM_I_VAL);
}

void MAGN_Config(void)
{
    uint8_t cfg_a = 0x00; // continuous mode, 10 Hz
    uint8_t cfg_b = 0x02; // offset cancellation enabled
    uint8_t cfg_c = 0x10; // block data update enabled

    HAL_I2C_Mem_Write(&hi2c3, MAGN_I2C_ADDR, MAGN_CFG_REG_A, I2C_MEMADD_SIZE_8BIT, &cfg_a, 1, HAL_MAX_DELAY);
    HAL_I2C_Mem_Write(&hi2c3, MAGN_I2C_ADDR, MAGN_CFG_REG_B, I2C_MEMADD_SIZE_8BIT, &cfg_b, 1, HAL_MAX_DELAY);
    HAL_I2C_Mem_Write(&hi2c3, MAGN_I2C_ADDR, MAGN_CFG_REG_C, I2C_MEMADD_SIZE_8BIT, &cfg_c, 1, HAL_MAX_DELAY);
}

void MAGN_ReadMagnetometerData(MAGN_Data *magn_data, uint8_t *raw_data)
{
    int16_t raw_x, raw_y, raw_z;

    HAL_I2C_Mem_Read(
        &hi2c3,
        MAGN_I2C_ADDR,
        MAGN_OUTX_L_REG,
        I2C_MEMADD_SIZE_8BIT,
        raw_data,
        6,
        HAL_MAX_DELAY
    );

    raw_x = (int16_t)(raw_data[1] << 8 | raw_data[0]);
    raw_y = (int16_t)(raw_data[3] << 8 | raw_data[2]);
    raw_z = (int16_t)(raw_data[5] << 8 | raw_data[4]);

    magn_data->x = raw_x * magn_sensitivity;
    magn_data->y = raw_y * magn_sensitivity;
    magn_data->z = raw_z * magn_sensitivity;
}