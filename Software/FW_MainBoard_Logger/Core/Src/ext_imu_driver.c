#include "ext_imu_driver.h"

extern I2C_HandleTypeDef hi2c3;

static float acc_sensitivity = 0.061f;
static float gyro_sensitivity = 8.75f;

uint8_t EXT_IMU_Init(void)
{
    uint8_t who_am_i = 0;

    HAL_I2C_Mem_Read(
        &hi2c3,
        EXT_IMU_I2C_ADDR,
        EXT_IMU_WHO_AM_I_REG,
        I2C_MEMADD_SIZE_8BIT,
        &who_am_i,
        1,
        HAL_MAX_DELAY
    );

    return (who_am_i == EXT_IMU_WHO_AM_I_VAL);
}

void EXT_IMU_Config(void)
{
    uint8_t ctrl3 = 0x44;   // BDU=1, IF_INC=1
    uint8_t acc_cfg = 0x05; // HP mode, 60 Hz
    uint8_t gyro_cfg = 0x05; // HP mode, 60 Hz

    HAL_I2C_Mem_Write(&hi2c3, EXT_IMU_I2C_ADDR, 0x12,
                      I2C_MEMADD_SIZE_8BIT, &ctrl3, 1, HAL_MAX_DELAY);

    HAL_I2C_Mem_Write(&hi2c3, EXT_IMU_I2C_ADDR, EXT_IMU_CTRL1_XL,
                      I2C_MEMADD_SIZE_8BIT, &acc_cfg, 1, HAL_MAX_DELAY);

    HAL_I2C_Mem_Write(&hi2c3, EXT_IMU_I2C_ADDR, EXT_IMU_CTRL2_G,
                      I2C_MEMADD_SIZE_8BIT, &gyro_cfg, 1, HAL_MAX_DELAY);
}

void EXT_IMU_ReadAccelerometerData(
    EXT_IMU_Data *acc_data,
    uint8_t *raw_data
)
{
    int16_t raw_x, raw_y, raw_z;

    HAL_I2C_Mem_Read(
        &hi2c3,
        EXT_IMU_I2C_ADDR,
        EXT_IMU_OUTX_L_A,
        I2C_MEMADD_SIZE_8BIT,
        raw_data,
        6,
        HAL_MAX_DELAY
    );

    raw_x = (int16_t)(raw_data[1] << 8 | raw_data[0]);
    raw_y = (int16_t)(raw_data[3] << 8 | raw_data[2]);
    raw_z = (int16_t)(raw_data[5] << 8 | raw_data[4]);

    acc_data->x = raw_x * acc_sensitivity;
    acc_data->y = raw_y * acc_sensitivity;
    acc_data->z = raw_z * acc_sensitivity;
}

void EXT_IMU_ReadGyroscopeData(
    EXT_IMU_Data *gyro_data,
    uint8_t *raw_data
)
{
    int16_t raw_x, raw_y, raw_z;

    HAL_I2C_Mem_Read(
        &hi2c3,
        EXT_IMU_I2C_ADDR,
        EXT_IMU_OUTX_L_G,
        I2C_MEMADD_SIZE_8BIT,
        raw_data,
        6,
        HAL_MAX_DELAY
    );

    raw_x = (int16_t)(raw_data[1] << 8 | raw_data[0]);
    raw_y = (int16_t)(raw_data[3] << 8 | raw_data[2]);
    raw_z = (int16_t)(raw_data[5] << 8 | raw_data[4]);

    gyro_data->x = raw_x * gyro_sensitivity;
    gyro_data->y = raw_y * gyro_sensitivity;
    gyro_data->z = raw_z * gyro_sensitivity;
}