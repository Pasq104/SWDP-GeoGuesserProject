/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2025 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */

#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32u5xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "../../USB_Device/App/usb_device.h"
#include <bluetooth.h>
/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */
uint8_t CDC_Transmit_FS(uint8_t* Buf, uint16_t Len);
/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define IMU_IS_INT1_Pin GPIO_PIN_13
#define IMU_IS_INT1_GPIO_Port GPIOC
#define IMU_IS_INT1_EXTI_IRQn EXTI13_IRQn
#define IMU_IS_INT2_Pin GPIO_PIN_0
#define IMU_IS_INT2_GPIO_Port GPIOA
#define IMU_IS_INT2_EXTI_IRQn EXTI0_IRQn
#define SPI3_CS_NAND_Pin GPIO_PIN_4
#define SPI3_CS_NAND_GPIO_Port GPIOA
#define USER_BUTTON_Pin GPIO_PIN_10
#define USER_BUTTON_GPIO_Port GPIOB
#define USER_BUTTON_EXTI_IRQn EXTI10_IRQn
#define BLE_P0_0_Pin GPIO_PIN_6
#define BLE_P0_0_GPIO_Port GPIOC
#define BLE_P3_6_Pin GPIO_PIN_7
#define BLE_P3_6_GPIO_Port GPIOC
#define BLE_UART_RX_IND_Pin GPIO_PIN_8
#define BLE_UART_RX_IND_GPIO_Port GPIOC
#define BLE_RESET_Pin GPIO_PIN_9
#define BLE_RESET_GPIO_Port GPIOC
#define BLE_CONFIG_Pin GPIO_PIN_15
#define BLE_CONFIG_GPIO_Port GPIOA
#define MCU_I_O_2_Pin GPIO_PIN_4
#define MCU_I_O_2_GPIO_Port GPIOB
#define MCU_I_O_2_EXTI_IRQn EXTI4_IRQn
#define MCU_I_O_1_Pin GPIO_PIN_5
#define MCU_I_O_1_GPIO_Port GPIOB
#define MCU_I_O_1_EXTI_IRQn EXTI5_IRQn
#define MCU_GREEN_LED_Pin GPIO_PIN_6
#define MCU_GREEN_LED_GPIO_Port GPIOB
#define MCU_RED_LED_Pin GPIO_PIN_7
#define MCU_RED_LED_GPIO_Port GPIOB

/* USER CODE BEGIN Private defines */

#define I2C_TIMEOUT 100

// ============================================================================
// APPLICATION STATE MACHINE
// ============================================================================
// Current firmware mode:
// - waits for a BLE/UART command from the app
// - starts realtime streaming only after command 'S'
// - stops realtime streaming after command 'P'
//
// Legacy states are kept available for future standalone data logger,
// USB VCP download or button-driven acquisition applications.
// ============================================================================

typedef enum {

    // Main states used by the current head-controller firmware
    STATE_IDLE,              // Generic idle state / fallback
    STATE_WAIT_BLE_COMMAND,  // BLE initialized, waiting for app command
    STATE_STREAMING,         // Realtime BLE sensor streaming active

    // Optional future features kept available
    STATE_ACQUISITION,       // Legacy standalone acquisition mode
    STATE_USB_CONNECTED,     // Legacy USB communication mode
    STATE_DOWNLOAD           // Legacy NAND download mode

} AppState;

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
