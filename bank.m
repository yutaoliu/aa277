clear; close; clc;
dt = 0.05;
glider.n = 4; % gliders
glider.R = .20; % turning radius
glider.pos = [0,0;
    0,1;
    1,1;
    1,0]; % position (x,y)
glider.hdg = pi/2*[0 0 0 0]; % heading (psi)
glider.alt = 50*ones(glider.n,1); % altitude H
glider.v_s = zeros(glider.n,1); % vertical speed w
glider.hmin = 10;
glider.gam = 10; % glide ratio
landed = zeros(glider.n,1); % 1 once glider lands
W = zeros(glider.n,1); % wind
thermal.n = 9; % basis function Gaussian kernels
side = [-0.5 0.5 1.5];
[thermal.X, thermal.Y] = meshgrid(side, side);
thermal.x = reshape(thermal.X, 9,1);
thermal.y = reshape(thermal.Y, 9,1);
%%%%%%%%%%%%1
%           %
%  7  8  9  %
%           %
%  4  5  6  %
%           %
%  1  2  3  %
%           %
%%%%%%%%%%%%%
thermal.a = [10 1 1 1 1 1 1 1 5]*10;

filename = ['bank' num2str(glider.n) 'gam10.gif'];

figure('color','white',...
    'position',[500 500 1000 1000])

for t=0:dt:5
    % u = rand(glider.n,1); % control:[0(CCW-turn),1(CW-turn)]
    for i=1:glider.n
        % above threshold altitude
        if glider.alt(i) > glider.hmin
            % control policy: L/R
            % average descent rate on both sides of the flight path
            % turn towards the side with smaller average descent rate
            
            xi = glider.pos(i,1);
            yi = glider.pos(i,2);
            
            si = sin(glider.hdg(i));
            ci = cos(glider.hdg(i));
            
            
            L.n = 0; L.sum = 0; L.avg = 0;
            R.n = 0; R.sum = 0; R.avg = 0;
            
            for j=1:glider.n
                
                if j==i
                    continue;
                end
                
                xj = glider.pos(j,1);
                yj = glider.pos(j,2);
                
                % is glider j to the left of glider i?
                d = -si*(xj-xi) + ci*(yj-yi);
                if d > 0 % left
                    L.sum = L.sum + glider.v_s(j);
                    L.n = L.n + 1;
                else
                    R.sum = R.sum + glider.v_s(j);
                    R.n = R.n + 1;
                end
            end
            u = 0;
            % decision
            if L.n == 0 && R.n == 0
                continue
            elseif L.n == 0
                u = 0;
            elseif R.n == 0
                u = 1;
            else
                L.avg = L.sum/L.n;
                R.avg = R.sum/R.n;
                if L.avg > 0 && R.avg > 0
                    ratio = R.avg / L.avg;
                    if ratio > 1
                        ratio = 1;
                    end
                    u = ratio;
                elseif L.avg > 0 && R.avg < 0
                    u = 0;
                elseif L.avg < 0 && R.avg > 0
                    u = 1;
                elseif L.avg < 0 && R.avg < 0
                    ratio = R.avg / L.avg;
                    if ratio > 1
                        ratio = 1;
                    end
                    u = 1-ratio;
                end
            end
            
            
            
            % update position
            glider.hdg(i) = glider.hdg(i) + (1-2*u)*dt/glider.R;
            scatter(glider.pos(i,1),glider.pos(i,2),...
                glider.alt(i),[1-u 0 u],'filled');
            
            glider.pos(i,1) = glider.pos(i,1) + dt*ci; %x
            glider.pos(i,2) = glider.pos(i,2) + dt*si; %y
            % calculate wind velocity
            % sum induced velocity from each thermal
            w = 0;
            for k=1:thermal.n
                d2 = (glider.pos(i,1) - thermal.x(k))^2 +...
                    (glider.pos(i,2) - thermal.y(k))^2;
                wk = exp(-(d2));
                w = w + thermal.a(k) * wk;
            end
            glider.v_s(i) = w - glider.gam;
            % update altitude
            glider.alt(i) = glider.alt(i) + glider.v_s(i) * dt;
            % below threshold altitude
        else
            if landed(i) == 0
                plot(glider.pos(i,1), glider.pos(i,2),'kd','lineWidth',16);
                text(glider.pos(i,1), glider.pos(i,2),...
                    ['   landed: t= ' num2str(t)],'FontSize',16);
            end
            landed(i) = 1;
            continue
        end
        
        % plot thermal strengths
        for m=1:thermal.n
            scatter(thermal.x(m), thermal.y(m), 100*thermal.a(m),'g+','linewidth',5)
            scatter(thermal.x(m), thermal.y(m), 100*thermal.a(m),'go','linewidth',5)
        end
        xlabel(['Glider trajectories at t= ' num2str(t)],'FontSize',18);
    end
    hold on
    axis equal
    axis([-2 3 -2 3])
    box on
    drawnow
    frame = getframe(1);
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    if t == 0
        imwrite(imind,cm,filename,'gif', 'Loopcount',inf);
    else
        imwrite(imind,cm,filename,'gif','WriteMode','append');
    end
    
end