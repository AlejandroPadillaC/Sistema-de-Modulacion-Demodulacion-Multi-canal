%%SISTEMA DE MULTIPLEXACIÓN 
clear; clc; close all;
ver_pasos_internos = true; 

%% 1. Parámetros generales
fs_audio = 48000; %%Frecuencia de muestreo ideal
L = 6;            %%Valor de sobremuestreo
fs = fs_audio * L;
W = 24000;       %%Ancho de banda   

%% 2. Cargar, acondicionar y sobremuestrear (10 segundos de cada pista)
disp('Cargando y procesando pistas de audio');
m1u = preparar_senal_audio('El Estoico.mp3', fs_audio, L); 
m2u = preparar_senal_audio('PainKiller.mp3', fs_audio, L);
m3u = preparar_senal_audio('BeMine.mp3', fs_audio, L); 

%% 3. Igualar longitudes
N = min([length(m1u), length(m2u), length(m3u)]);
m1u = m1u(1:N);
m2u = m2u(1:N);
m3u = m3u(1:N);
t = (0:N-1)'/fs;        
disp('Señales acondicionadas y listas');

%% 4. Modulación
w1 = W/2;                        % 12 kHz 
wM1 = 30000; w2_1 = wM1 + W/2;   % 42 kHz 
wM2 = 60000; w2_2 = wM2 + W/2;   % 72 kHz
wM3 = 90000; w2_3 = wM3 + W/2;   % 102 kHz

disp('Modulando canales y generando gráficos');
mx1 = modulador(m1u, t, w1, w2_1, fs, 'Canal 1', ver_pasos_internos); 
mx2 = modulador(m2u, t, w1, w2_2, fs, 'Canal 2', ver_pasos_internos);
mx3 = modulador(m3u, t, w1, w2_3, fs, 'Canal 3', ver_pasos_internos);

% Señal total a transmitir (Multiplexación)
m_t = mx1 + mx2 + mx3;   

%% 5. Demodulación de los 3 canales
disp('Demodulando canales y generando gráficos');
fc_final = 24000;   
s1u = demodulador(m_t, t, 'lp', 57000, [], wM1, fs, fc_final, 'Canal 1', ver_pasos_internos); %%Demodulador con filtro pasa Bajos
s2u = demodulador(m_t, t, 'bp', 57000, 87000, wM2, fs, fc_final, 'Canal 2', ver_pasos_internos); %%Demodulador con filtro Pasabandas
s3u = demodulador(m_t, t, 'hp', 87000, [], wM3, fs, fc_final, 'Canal 3', ver_pasos_internos); %% Demodulador con filtro pasa Altos

%% 6. Bajar la frecuencia de muestreo a 48 kHz para escuchar
s1 = s1u(1:L:end);
s2 = s2u(1:L:end);
s3 = s3u(1:L:end);

%% 7. Gráficas Generales 
disp('Generando gráficos');
c_c1 = [0, 0.4470, 0.7410];      
c_c2 = [0.8500, 0.3250, 0.0980]; 
c_c3 = [0.4660, 0.6740, 0.1880]; 
c_mt = [0.4940, 0.1840, 0.5560]; 
limite_bb = [-30, 30];           
limite_tb = [-144, 144];         

% === VENTANA 1: SEGUIMIENTO COMPLETO CANAL 1
figure('Name','Ciclo de Vida General - Canal 1 (Azul)','NumberTitle','off');
subplot(3,1,1); graficar_espectro(m1u, fs, '1. Espectro Original (Banda Base)', c_c1, limite_bb);
subplot(3,1,2); graficar_espectro(mx1, fs, '4. Espectro Modulado (Centrado en 42 kHz)', c_c1, limite_tb);
subplot(3,1,3); graficar_espectro(s1u, fs, '8. Espectro Demodulado (Señal Recuperada)', c_c1, limite_bb);

% === VENTANA 2: SEGUIMIENTO COMPLETO CANAL 2
figure('Name','Ciclo de Vida General - Canal 2 (Naranja)','NumberTitle','off');
subplot(3,1,1); graficar_espectro(m2u, fs, '2. Espectro Original (Banda Base)', c_c2, limite_bb);
subplot(3,1,2); graficar_espectro(mx2, fs, '5. Espectro Modulado (Centrado en 72 kHz)', c_c2, limite_tb);
subplot(3,1,3); graficar_espectro(s2u, fs, '9. Espectro Demodulado (Señal Recuperada)', c_c2, limite_bb);

% === VENTANA 3: SEGUIMIENTO COMPLETO CANAL 3
figure('Name','Ciclo de Vida General - Canal 3 (Verde)','NumberTitle','off');
subplot(3,1,1); graficar_espectro(m3u, fs, '3. Espectro Original (Banda Base)', c_c3, limite_bb);
subplot(3,1,2); graficar_espectro(mx3, fs, '6. Espectro Modulado (Centrado en 102 kHz)', c_c3, limite_tb);
subplot(3,1,3); graficar_espectro(s3u, fs, '10. Espectro Demodulado (Señal Recuperada)', c_c3, limite_bb);

% === VENTANA 4: SEÑAL MULTIPLEXADA COMPLETA
figure('Name','Espectro de la Señal Multiplexada FDM','NumberTitle','off');
graficar_espectro(m_t, fs, '7. Espectro de la Señal Transmitida m(t) - 3 Canales Juntos', c_mt, limite_tb);
drawnow;

%% 8. Reproducción
disp(' ');
disp('Reproduciendo resultados demodulados');
disp(' ');
disp('Escuchando Canal 1.'); soundsc(s1, fs_audio); pause(10.5);
disp('Escuchando Canal 2.'); soundsc(s2, fs_audio); pause(10.5);
disp('Escuchando Canal 3.'); soundsc(s3, fs_audio);
disp('Proceso finalizado con éxito.');

%% =========================================================================
%% FUNCIONES IMPLEMENTADAS
%% =========================================================================

function mu = preparar_senal_audio(nombre_archivo, fs_esperada, factor_L)
    segundos_deseados = 10; 
    if ~exist(nombre_archivo, 'file')
        error('El archivo "%s" no existe en la ruta actual.', nombre_archivo);
    end
    info = audioinfo(nombre_archivo); 
    fs_original = info.SampleRate; 
    muestras_a_leer = round(segundos_deseados * fs_original); 
    limite_lectura = min(muestras_a_leer, info.TotalSamples);
    [m, ~] = audioread(nombre_archivo, [1, limite_lectura]);
    
    if size(m, 2) > 1 
        m = m(:, 1);
    end
    
    if fs_original ~= fs_esperada 
        t_original = (0:length(m)-1)' / fs_original;
        t_nuevo = (0 : 1/fs_esperada : t_original(end))';
        m = interp1(t_original, m, t_nuevo, 'spline', 0); 
    end
    
    fs_final = fs_esperada * factor_L; 
    t_actual = (0:length(m)-1)' / fs_esperada;
    t_final = (0 : 1/fs_final : t_actual(end))';
    mu = interp1(t_actual, m, t_final, 'spline', 0); 
    
    if size(mu, 2) > 1
        mu = mu';
    end
    mu(isnan(mu)) = 0;
end

function mx = modulador(s, t, w1, w2, fs, nombre_canal, ver_pasos)
    % RAMA SUPERIOR (COSENO - COMPONENTE I) 
    r1 = s .* (2*cos(2*pi*w1*t)); 
    r1f = filtro_ideal(r1, fs, 'lp', w1); 
    r1out = r1f .* cos(2*pi*w2*t); 
    
    % RAMA INFERIOR (SENO - COMPONENTE Q) 
    r2 = s .* (2*sin(2*pi*w1*t));
    r2f = filtro_ideal(r2, fs, 'lp', w1); 
    r2out = r2f .* sin(2*pi*w2*t);
    
    % Sumatoria
    mx = r1out + r2out; 
    
    %Gráficos Comparativos del Paso a Paso Interno 
    if ver_pasos
        figure('Name', ['Pasos Internos Modulación Completa: ' nombre_canal], 'NumberTitle', 'off');
        
        % Fila 1: Entrada en Banda Base (Ocupa ambas columnas para claridad)
        subplot(4, 2, 1:2); 
        graficar_espectro(s, fs, '1. Señal en Banda Base de Entrada (Común)', [0 0.44 0.74], [-30, 30]);
        
        % Fila 2: Primera Multiplicación (Desplazamiento a frecuencia intermedia w1)
        subplot(4, 2, 3); 
        graficar_espectro(r1, fs, '2A. Rama Sup: Post primer Coseno (\omega_1)', [0.85 0.32 0.1], [-144, 144]);
        subplot(4, 2, 4); 
        graficar_espectro(r2, fs, '2B. Rama Inf: Post primer Seno (\omega_1)', [0.93 0.69 0.13], [-144, 144]);
        
        % Fila 3: Filtrado Pasabajos Ideal
        subplot(4, 2, 5); 
        graficar_espectro(r1f, fs, '3A. Rama Sup: Post Filtro Pasabajos', [0.46 0.67 0.18], [-144, 144]);
        subplot(4, 2, 6); 
        graficar_espectro(r2f, fs, '3B. Rama Inf: Post Filtro Pasabajos', [0.27 0.51 0.71], [-144, 144]);
        
        % Fila 4: Segunda Multiplicación (Desplazamiento a portadora final w2)
        subplot(4, 2, 7); 
        graficar_espectro(r1out, fs, '4A. Rama Sup: Post Coseno Final (\omega_2)', [0.49 0.18 0.55], [-144, 144]);
        subplot(4, 2, 8); 
        graficar_espectro(r2out, fs, '4B. Rama Inf: Post Seno Final (\omega_2)', [0.64 0.08 0.18], [-144, 144]);
    end
end

function y = filtro_ideal(x, fs, tipo, fc1, fc2)
    N = length(x); 
    X = fft(x); %%Transformada de fourier de la señal
    f = (0:N-1)*(fs/N);          
    f(f > fs/2) = f(f > fs/2) - fs;  
    switch tipo 
        case 'lp' %% Tipo Pasa bajos
            H = abs(f) <= fc1;
        case 'hp'
            H = abs(f) >= fc1; % Tipo pasa altos
        case 'bp'
            H = (abs(f) >= fc1) & (abs(f) <= fc2); %Tipo pasa banda
    end
    Y = X .* H(:); 
    y = real(ifft(Y)); 
end

function s = demodulador(m, t, filtro_tipo, fc1, fc2, wi, fs, fc_final, nombre_canal, ver_pasos)
    %% El bloque demodulador consiste en el paso por 2 filtros y una multiplicacion por una señal coseno 
    mf = filtro_ideal(m, fs, filtro_tipo, fc1, fc2); 
    r = mf .* (2*cos(2*pi*wi*t)); 
    s = filtro_ideal(r, fs, 'lp', fc_final); 
    
    if ver_pasos
        figure('Name', ['Pasos Internos Demodulación: ' nombre_canal], 'NumberTitle', 'off');
        
        subplot(3,1,1); 
        graficar_espectro(mf, fs, '1. Canal Aislado por Filtro del Receptor (LP / BP / HP)', [0.49 0.18 0.55], [-144, 144]);
        
        subplot(3,1,2); 
        graficar_espectro(r, fs, '2. Tras multiplicar por el Coseno Local (Aparece réplica en Banda Base)', [0.85 0.32 0.1], [-144, 144]);
        
        subplot(3,1,3); 
        graficar_espectro(s, fs, '3. Tras Filtro Pasabajos Final (Señal de Audio Recuperada)', [0 0.44 0.74], [-30, 30]);
    end
end

function graficar_espectro(x, fs, titulo_str, color_linea, limite_x)
    N = length(x);
    X = fftshift(fft(x));
    f = (-N/2:N/2-1)*(fs/N);
    
    plot(f/1000, abs(X)/N, 'Color', color_linea, 'LineWidth', 1.2);
    
    xlabel('Frecuencia (kHz)', 'FontWeight', 'bold');
    ylabel('Magnitud |X(f)|', 'FontWeight', 'bold');
    title(titulo_str, 'FontSize', 10);
    
    grid on;
    set(gca, 'GridAlpha', 0.4, 'MinorGridAlpha', 0.5);
    
    if nargin > 4 && ~isempty(limite_x)
        xlim(limite_x);
    else
        xlim([-fs/(2*1000), fs/(2*1000)]); 
    end
end