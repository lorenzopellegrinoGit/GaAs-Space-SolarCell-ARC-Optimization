close all
clc
clear all

% 1. Parametri di Base
lambda = linspace(300, 2500, 1000); % Vettore lunghezze d'onda in nm
n_sub = 3.5; % Indice del GaAs 
n_air = 1.0; % Indice del vuoto/aria
lambda_0 = 500; % Lunghezza d'onda di progetto in nm

% 2. Design ARC Singolo Strato Ideale
% Condizione di zero-riflessione per singolo strato
n_ideal = sqrt(n_air * n_sub); 

% Spessore fisico per avere uno spessore ottico di lambda/4
d_ideal = lambda_0 / (4 * n_ideal); 

fprintf('--- Singolo Strato Ideale ---\n');
fprintf('Indice di rifrazione richiesto: %.3f\n', n_ideal);
fprintf('Spessore fisico: %.2f nm\n', d_ideal);

% 3. Calcolo e Plot
R_ideal = calc_reflectivity(n_ideal, d_ideal, n_sub, n_air, lambda);
%Gamma_ideal = mlayer([n_air, n_ideal, n_sub], n1_ideal, lambda);
%R_ideal = abs(Gamma_ideal).^2;
figure;
plot(lambda, R_ideal * 100, 'b', 'LineWidth', 1.5);
grid on;
xlabel('Lunghezza d''onda (nm)');
ylabel('Riflettività (%)');
title('Riflettività ARC Singolo Strato Ideale su GaAs');
xlim([300 2500]);

% 4. Importazione Spettro Solare e Calcolo R_eff
try
    % Legge il primo foglio
    data_full = readmatrix('AM0AM1_5.xls', 'Sheet', 1); 
catch
    dataTable = readtable('AM0AM1_5.xls', 'Sheet', 1, 'PreserveVariableNames', true);
    data_full = table2array(dataTable);
end

% colonne F (6) e G (7) che contengono lo standard E-490 AM0
data_AM0 = data_full(:, 6:7); 

% rimuove eventuali righe che contengono NaN (testo o celle vuote)
data_AM0(any(isnan(data_AM0), 2), :) = [];

% Assegnazione delle colonne
lambda_data = data_AM0(:, 1); % Ex colonna F 
AM0_data = data_AM0(:, 2);    % Ex colonna G

%lunghezze d'onda uniche e crescenti per l'interpolazione
[lambda_data, unique_idx] = unique(lambda_data);
AM0_data = AM0_data(unique_idx);

% Interpolazione dati di AM0 per farli coincidere con il vettore 'lambda'
AM0_interp = interp1(lambda_data, AM0_data, lambda, 'linear', 0);

% Calcolo R_eff
num_ideal = trapz(lambda, R_ideal .* AM0_interp); %integrazione numerica di matlab
den = trapz(lambda, AM0_interp);
Reff_ideal = num_ideal / den;

fprintf('\nRiflettività Efficace (R_eff) Singolo Strato Ideale: %.2f%%\n', Reff_ideal * 100);

% 5. Confronto con Singolo Strato Realistico
n_real = 2.0; % Indice approssimato del Si3N4
d_real = lambda_0 / (4 * n_real); % Spessore QWOT con il nuovo materiale

R_real = calc_reflectivity(n_real, d_real, n_sub, n_air, lambda);
%Gamma_real = mlayer([n_air, n_real, n_sub], d_real, lambda);
%R_real = abs(Gamma_ideal).^2;

% Calcolo R_eff per lo strato realistico
num_real = trapz(lambda, R_real .* AM0_interp);
Reff_real = num_real / den;

fprintf('\n--- Singolo Strato Realistico (n = %.1f) ---\n', n_real);
fprintf('Spessore fisico: %.2f nm\n', d_real);
fprintf('Riflettività Efficace (R_eff): %.2f%%\n', Reff_real * 100);

% 6. Plot di confronto
figure;

% ASSE SINISTRO (Riflettività)
yyaxis left;
plot(lambda, R_ideal * 100, 'b', 'LineWidth', 1.5); 
hold on;
plot(lambda, R_real * 100, 'r--', 'LineWidth', 1.5);
ylabel('Riflettività (%)');
ylim([0, 20]); 

% ASSE DESTRO (Spettro AM0) 
yyaxis right;
plot(lambda, AM0_interp, 'y:', 'LineWidth', 1.5); % Uso il nero puntinato per non confonderlo con il rosso
ylabel('Irradiamento AM0 (W/m^2/nm)');
grid on;
legend('Ideale', 'Realistico (Si_3N_4)', 'Spettro AM0'); 
xlabel('Lunghezza d''onda (nm)');
title('Confronto Singolo Strato ARC su GaAs');
xlim([300 1400]);

% 7. Punto 3: Doppio Strato QWOT Ideale e Dimostrazione Numerica

% 7.1 Design Ottimo, garantisce la banda più larga
n1_opt = n_sub^(1/4); 
n2_opt = n_sub^(3/4);

% Spessori QWOT
d1_opt = lambda_0 / (4 * n1_opt);
d2_opt = lambda_0 / (4 * n2_opt);

% La funzione calc_reflectivity accetta un vettore di indici e spessori
% Ordine: dall'aria verso il substrato [Top, Bottom]
R_opt_DL = calc_reflectivity([n1_opt, n2_opt], [d1_opt, d2_opt], n_sub, n_air, lambda);

% Calcolo R_eff
Reff_opt_DL = trapz(lambda, R_opt_DL .* AM0_interp) / den;

fprintf('\n--- Doppio Strato QWOT Ottimale (Banda Larga) ---\n');
fprintf('n1 (Top): %.3f, spessore: %.2f nm\n', n1_opt, d1_opt);
fprintf('n2 (Bottom): %.3f, spessore: %.2f nm\n', n2_opt, d2_opt);
fprintf('Riflettività Efficace (R_eff): %.2f%%\n', Reff_opt_DL * 100);

% 7.2 Design Sub-Ottimo (Test per dimostrazione numerica)
% Scelgo un n1 diverso (es. 1.6), e calcolo n2 per rispettare la condizione base
n1_test = 1.6; 
n2_test = sqrt(n_sub) * n1_test; % Questa è la relazione data dal problema

d1_test = lambda_0 / (4 * n1_test);
d2_test = lambda_0 / (4 * n2_test);

R_test_DL = calc_reflectivity([n1_test, n2_test], [d1_test, d2_test], n_sub, n_air, lambda);
%Gamma_opt = mlayer([n_air, n1_opt, n2_opt, n_sub], [d1_opt, d2_opt], lambda);
%Gamma_test = mlayer([n_air, n1_test, n2_test, n_sub], [d1_test, d2_test], lambda);

%R_opt = abs(Gamma_opt).^2;
%R_test = abs(Gamma_test).^2;

% 7.3 Plot per dimostrare l'allargamento di banda
figure;
plot(lambda, R_ideal * 100, 'y:', 'LineWidth', 1.5); hold on;
plot(lambda, R_test_DL * 100, 'r--', 'LineWidth', 1.5);
plot(lambda, R_opt_DL * 100, 'b', 'LineWidth', 2);

grid on;
legend('Singolo Strato Ideale', 'Doppio Strato (Test n1=1.6)', 'Doppio Strato Ottimale');
xlabel('Lunghezza d''onda (nm)');
ylabel('Riflettività (%)');
title('Dimostrazione Numerica: Banda del Doppio Strato');
xlim([300 1200]); 
ylim([0 15]);


% 8. Punto 4: Doppio Strato NON-QWOT con Materiali Realistici

% materiali realistici ad alto e basso indice
n1_real = 1.45; % SiO2 (Top layer, a contatto con l'aria)
n2_real = 2.40; % TiO2 (Bottom layer, a contatto col GaAs)

fprintf('\n--- Punto 4: Doppio Strato NON-QWOT (SiO2 / TiO2) ---\n');

% l'algoritmo deve trovare i valori del vettore spessori 'd' che rendono 
% la Reff il più bassa possibile. Uso abs(d) per evitare spessori negativi.
calc_Reff_obj = @(d) trapz(lambda, calc_reflectivity([n1_real, n2_real], abs(d), n_sub, n_air, lambda) .* AM0_interp) / den;
%Gamma_real= mlayer([n_air, n1_real, n2_real, n_sub], abd(d), lambda);
%R_real = abs(Gamma_real).^2;
%calc_Reff_obj = @(d) trapz(lambda, R_real .* AM0_interp) / den;

% 2. Punto di partenza (Initial guess): parto dagli spessori QWOT a 500 nm
d1_guess = lambda_0 / (4 * n1_real);
d2_guess = lambda_0 / (4 * n2_real);
d0 = [d1_guess, d2_guess];

fprintf('Ottimizzazione in corso tramite fminsearch... \n');

% 3. Eseguo l'ottimizzazione
options = optimset('Display', 'off', 'TolX', 1e-4, 'TolFun', 1e-4);
d_ottimizzati = fminsearch(calc_Reff_obj, d0, options);

%valori finali siano positivi ed estraiamoli
d_ottimizzati = abs(d_ottimizzati);
d1_non_qwot = d_ottimizzati(1);
d2_non_qwot = d_ottimizzati(2);

% 4. Calcolo la riflettività e la Reff finali con i nuovi spessori ottimizzati
R_non_qwot = calc_reflectivity([n1_real, n2_real], [d1_non_qwot, d2_non_qwot], n_sub, n_air, lambda);
Reff_non_qwot = calc_Reff_obj(d_ottimizzati);
%Gamma_non_qwot= mlayer([n_air, n1_real, n2_real, n_sub], [d1_non_qwot, d2_non_qwot], lambda);
%R_non_qwot = abs(Gamma_non_qwot).^2;


fprintf('Spessore ottimizzato SiO2 (Top): %.2f nm\n', d1_non_qwot);
fprintf('Spessore ottimizzato TiO2 (Bottom): %.2f nm\n', d2_non_qwot);
fprintf('Riflettività Efficace (R_eff) minimizzata: %.2f%%\n', Reff_non_qwot * 100);

% 5. Plot di confronto finale
figure;
plot(lambda, R_ideal * 100, 'y:', 'LineWidth', 1.5); hold on;
plot(lambda, R_opt_DL * 100, 'b--', 'LineWidth', 1.5);
plot(lambda, R_non_qwot * 100, 'r-', 'LineWidth', 2);
plot(lambda, (AM0_interp / max(AM0_interp)) * 10, 'g-', 'Color', [0 0.8 0 0.3], 'LineWidth', 1);

grid on;
legend('Singolo Ideale (QWOT)', 'Doppio Ideale (QWOT)', 'Doppio Realistico (NON-QWOT SiO2/TiO2)', 'Spettro AM0');
xlabel('Lunghezza d''onda (nm)');
ylabel('Riflettività (%)');
title('Confronto: ARC QWOT vs Ottimizzato (NON-QWOT)');
xlim([300 2000]);
ylim([0 15]);

% 9. Punto 5: Multi-layer (Tre Strati) NON-QWOT

% i tre materiali realistici
n1_3L = 1.45; % SiO2 (Top)
n2_3L = 2.00; % Si3N4 (Middle)
n3_3L = 2.40; % TiO2 (Bottom)

fprintf('\n--- Punto 5: ARC a Tre Strati Ottimizzato ---\n');

% 1. Funzione obiettivo per 3 strati
calc_Reff_3L = @(d) trapz(lambda, calc_reflectivity([n1_3L, n2_3L, n3_3L], abs(d), n_sub, n_air, lambda) .* AM0_interp) / den;
%Gamma_3L= mlayer([n_air, n1_3L, n2_3L, n3_3L, n_sub], abs(d), lambda);
%R_3L = abs(Gamma_3L).^2;
%calc_Reff_3L = @(d) trapz(lambda,R_3L .* AM0_interp) / den;

% 2. Initial guess (Punto di partenza unendo Approccio A e C)
% Top e Bottom partono come QWOT (lambda/4), il Middle parte come Half-Wave (lambda/2)
d1_guess_3L = lambda_0 / (4 * n1_3L);
d2_guess_3L = lambda_0 / (2 * n2_3L);
d3_guess_3L = lambda_0 / (4 * n3_3L);

d0_3L = [d1_guess_3L, d2_guess_3L, d3_guess_3L];

fprintf('Ottimizzazione 3-layer in corso tramite fminsearch... \n');

% 3. Ottimizzazione
d_opt_3L = fminsearch(calc_Reff_3L, d0_3L, options);
d_opt_3L = abs(d_opt_3L); % spessori siano positivi

d1_final = d_opt_3L(1);
d2_final = d_opt_3L(2);
d3_final = d_opt_3L(3);

% 4. Calcoli finali
R_3L = calc_reflectivity([n1_3L, n2_3L, n3_3L], [d1_final, d2_final, d3_final], n_sub, n_air, lambda);
Reff_3L = calc_Reff_3L(d_opt_3L);
%Gamma_3Lfinale= mlayer([n_air, n1_3L, n2_3L, n3_3L, n_sub], [d1_final, d2_final, d3_final], lambda);
%R_3Lfinale = abs(Gamma_3Lfinale).^2;
%calc_Reff_3L = @(d) trapz(lambda,R_3Lfinale .* AM0_interp) / den;


fprintf('Spessore SiO2 (Top): %.2f nm\n', d1_final);
fprintf('Spessore Si3N4 (Middle): %.2f nm\n', d2_final);
fprintf('Spessore TiO2 (Bottom): %.2f nm\n', d3_final);
fprintf('Riflettività Efficace (R_eff) 3-Layer: %.2f%%\n', Reff_3L * 100);

% 5. Plot Comparativo
figure;
plot(lambda, R_non_qwot * 100, 'r-', 'LineWidth', 1.5); hold on;
plot(lambda, R_3L * 100, 'm-', 'LineWidth', 2);
plot(lambda, (AM0_interp / max(AM0_interp)) * 10, 'g-', 'Color', [0 0.8 0 0.3], 'LineWidth', 1);

grid on;
legend('Doppio Strato (NON-QWOT)', 'Tre Strati (Ottimizzato)', 'Spettro AM0 (Norm)');
xlabel('Lunghezza d''onda (nm)');
ylabel('Riflettività (%)');
title('Confronto: Doppio Strato vs Tre Strati');
xlim([300 2000]);
ylim([0 15]);

% Plot Confronto Totale (SLARC vs DLARC vs TLARC)
figure;
plot(lambda, R_real * 100, 'g-', 'LineWidth', 1.5); hold on;
plot(lambda, R_non_qwot * 100, 'r-', 'LineWidth', 1.5);
plot(lambda, R_3L * 100, 'm-', 'LineWidth', 2);
grid on;
legend('Singolo Strato (Si_3N_4)', 'Doppio Strato Ottimizzato', 'Triplo Strato Ottimizzato');
xlabel('Lunghezza d''onda (nm)');
ylabel('Riflettività (%)');
title('Confronto Globale: SLARC vs DLARC vs TLARC');
xlim(); 
ylim();

% 10. Punto 7: Analisi delle Tolleranze di Fabbricazione (Monte Carlo)
% Seleziono il design migliore: l'ARC a 3 strati (Multi-layer)

tolleranza = 0.03; % Tolleranza massima del 3%
num_simulazioni = 1000; % Numero di varianti da fabbricare virtualmente

fprintf('\n--- Punto 7: Analisi Tolleranze (3%% Variazione Spessore) ---\n');
fprintf('Simulazione Monte Carlo con %d iterazioni...\n', num_simulazioni);

%matrice per salvare tutte le Reff calcolate
Reff_mc = zeros(1, num_simulazioni);

figure;
hold on;
grid on;

% 1. Ciclo Monte Carlo
for i = 1:num_simulazioni
    % Genero un errore casuale per ogni strato tra -3% e +3%
    % La formula (2*rand - 1) genera un numero tra -1 e +1
    errore_d1 = 1 + tolleranza * (2 * rand() - 1);
    errore_d2 = 1 + tolleranza * (2 * rand() - 1);
    errore_d3 = 1 + tolleranza * (2 * rand() - 1);
    
    % Applico l'errore agli spessori ideali calcolati al Punto 5
    d1_err = d1_final * errore_d1;
    d2_err = d2_final * errore_d2;
    d3_err = d3_final * errore_d3;
    
    % Calcolo la nuova riflettività "sbagliata"
    R_err = calc_reflectivity([n1_3L, n2_3L, n3_3L], [d1_err, d2_err, d3_err], n_sub, n_air, lambda);
    
    % Plot della singola curva con molta trasparenza (grigio chiaro)
    plot(lambda, R_err * 100, 'Color', [0.5 0.5 0.5 0.3], 'LineWidth', 0.5);
    
    % Calcolo e salvo la Reff di questa specifica iterazione
    num_err = trapz(lambda, R_err .* AM0_interp);
    Reff_mc(i) = num_err / den;
end

% 2. Plotto sopra a tutto il design 
plot(lambda, R_3L * 100, 'm-', 'LineWidth', 2);

xlabel('Lunghezza d''onda (nm)');
ylabel('Riflettività (%)');
title('Impatto Tolleranze 3% sul Design 3-Layer');
xlim([300 2000]);
ylim([0 15]);
legend('Variazioni di Fabbricazione', 'Design Nominale Ottimizzato');

% 3. Statistiche Finali
Reff_media = mean(Reff_mc);
Reff_max = max(Reff_mc);
Reff_min = min(Reff_mc);

fprintf('Riflettività Efficace Nominale (Senza Errori): %.2f%%\n', Reff_3L * 100);
fprintf('Riflettività Efficace Media (Con Tolleranze): %.2f%%\n', Reff_media * 100);
fprintf('Riflettività Efficace Peggiore: %.2f%%\n', Reff_max * 100);