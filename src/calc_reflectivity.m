function R = calc_reflectivity(n_layers, d_layers, n_sub, n_air, lambda)
    % Inizializza il vettore della riflettività
    R = zeros(size(lambda));
    
    for i = 1:length(lambda)
        lam = lambda(i);
        M = [1 0; 0 1]; % Matrice di base (identità)
        
        % Moltiplica le matrici per ogni strato (dal top al bottom)
        for k = 1:length(n_layers)
            % Sfasamento ottico dello strato k
            delta = (2 * pi / lam) * n_layers(k) * d_layers(k); 
            
            % Matrice caratteristica dello strato k
            m11 = cos(delta);
            m12 = 1i * sin(delta) / n_layers(k);
            m21 = 1i * n_layers(k) * sin(delta);
            m22 = cos(delta);
            
            M = M * [m11, m12; m21, m22];
        end
        
        % Calcolo dell'ammettenza ottica equivalente e della riflettività
        B = M(1,1) + M(1,2) * n_sub;
        C = M(2,1) + M(2,2) * n_sub;
        Y = C / B; % Ammettenza ottica del sistema
        
        R(i) = abs((n_air - Y) / (n_air + Y))^2;
    end
end