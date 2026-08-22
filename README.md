# 📻 Sistema de Modulación y Demodulación FDM en MATLAB - Análisis de Fourier

![MATLAB](https://img.shields.io/badge/MATLAB-R2023b%2B-blue?style=for-the-badge&logo=mathworks)
![Signal Processing](https://img.shields.io/badge/Area-Procesamiento_de_Señales-green?style=for-the-badge)

Este repositorio contiene la simulación en MATLAB de un sistema multiplexado por división de frecuencia (FDM) para la transmisión simultánea de 3 canales de audio. El proyecto abarca el diseño del modulador quadrature/SSB, canal multiplexado, y la etapa de demodulación y recuperación en el dominio del tiempo y la frecuencia.



## 1. Descripción del Proyecto

El sistema toma 3 señales de audio monofónicas independientes muestreadas a $48\text{ kHz}$, las remuestra a una frecuencia de procesado superior ($288\text{ kHz}$), las modula individualmente en portadoras de $30\text{ kHz}$, $60\text{ kHz}$ y $90\text{ kHz}$, y las combina en una única señal canalizada $m(t)$. En el receptor, mediante etapas de filtrado y demodulación, se recuperan las señales originales de audio para su reproducción a $48\text{ kHz}$.


## 3. Arquitectura del Sistema

![Etapa de modulación](.png)
