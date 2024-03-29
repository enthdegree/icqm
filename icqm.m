function [v_opt, d_opt] = ICQM(mtx_M, v_v, d_cc)
%% ICQM Integer Convex Quadratic Minimizer 
% Find a solution to the following problem:
% 
% minimize:      x'*mtx_M*x + 2*v_v'*x + d_cc
% subject to:    x with integer components
%
% This function implements a translation of the Schnorr-Euchner algorithm 
% for ordinary integer least squares to the described integer convex 
% quadratic minimzation problem. 
% 
% Taken from Algorithm 5, Figure 2 in:
% GHASEMMEHDI AND AGRELL: FASTER RECURSIONS IN SPHERE DECODING.
%
% Inputs:
%    mtx_M = K*K real positive-semidefinite matrix
%    v_v = K*1 real vector
%    d_cc = real scalar
%
% Outputs: 
%    v_opt = K*1 integer vector, optimal point 
%    d_opt = real scalar, optimal value
%

%% Setup
	n_dim = size(mtx_M,1); 

	% Stated problem is equivalent to instead minimizing:
	% ||v_r - mtx_G*v_u||^2 + (some constant)
	mtx_G = chol(mtx_M)';
	v_r = -pinv(mtx_G')*v_v;

%% Algorithm 5
	% Globals
	STATE = 'LOOP';

	d_C = inf;
	n_i = n_dim+1;
	v_d = n_dim*ones(n_dim,1);
	v_lambda = nan(n_dim+1,1);
    v_lambda(n_dim+1) = 0;

	mtx_F = nan(n_dim,n_dim);
	mtx_F(n_dim,:) = v_r;

	% Extra globals needed 
	n_m = nan;
	v_p = nan(n_dim,1);
	v_u = nan(n_dim,1);
	v_hatu = nan(n_dim,1);
	v_Delta = nan(n_dim,1);

	while(1)
	if(strcmp(STATE,'LOOP')) % LOOP
		if(n_i ~= 1)
			n_i = n_i-1;
			v_idx_j = v_d(n_i):(-1):(n_i+1);
            for jj=v_idx_j
                mtx_F(jj-1,n_i) = ... 
                    mtx_F(jj,n_i) - ...
                    v_u(jj)*mtx_G(jj,n_i);
            end
			v_p(n_i) = mtx_F(n_i,n_i)/mtx_G(n_i,n_i);
			v_u(n_i) = round(v_p(n_i));
			d_y = (v_p(n_i)-v_u(n_i))*mtx_G(n_i,n_i);
			v_Delta(n_i) = ICMQ_sign(d_y);
			v_lambda(n_i) = v_lambda(n_i+1) + d_y^2;
		else
			v_hatu = v_u;
			d_C = v_lambda(1);
        end
        if( ~(v_lambda(n_i) < d_C) )
			STATE = 'LOOP2';
            n_m = n_i;	
        end
        
	elseif(strcmp(STATE,'LOOP2')) % Code after "LOOP"
        if(n_i == n_dim)
            STATE = 'RETURN';
        else
            n_i = n_i+1;
            v_u(n_i) = v_u(n_i) + v_Delta(n_i);
            v_Delta(n_i) = -v_Delta(n_i) - ICMQ_sign(v_Delta(n_i));
            d_y = (v_p(n_i) - v_u(n_i))*mtx_G(n_i,n_i);
            v_lambda(n_i) = v_lambda(n_i+1) + d_y^2;
        end
        if(~(v_lambda(n_i) >= d_C))
            STATE = 'POST_LOOP2';
        end
        
    elseif(strcmp(STATE,'POST_LOOP2'))   
		v_idx_j = n_m:(n_i-1);
		v_d(v_idx_j) = n_i;
		for jj=(n_m-1):(-1):1
			if(v_d(jj) < n_i)
				v_d(jj) = n_i;	
			else
				break;
			end
        end
        STATE = 'LOOP';
        
	elseif(strcmp(STATE,'RETURN')) % "Return v_hatu and exit"
		break;	
	end
	end 

%% Translate
	v_opt = v_hatu;
	d_opt = v_opt'*mtx_M*v_opt + 2*v_v'*v_opt + d_cc;
	return;
end

function s = ICMQ_sign(d)
%% Corrected sign
    s = sign(d);
	if(s == 0)
		s = -1;
	end
	return;
end
