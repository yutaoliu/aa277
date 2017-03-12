clear; close; clc;
dt = 0.05;
glider.n = 4; % gliders
glider.R = .20; % turning radius
glider.pos = [0,0;
              0,1;
              1,1;
              1,0]; % position (x,y)
glider.hdg = pi/2*[-1 0 1 2]; % heading (psi)
glider.alt = 50*ones(glider.n,1); % altitude H
glider.v_s = zeros(glider.n,1); % vertical speed w
glider.hmin = 10;
glider.gam = 20; % glide ratio
landed = zeros(glider.n,1); % 1 once glider lands
W = zeros(glider.n,1); % wind
thermal.n = 9; % basis function Gaussian kernels
side = [-1.5 0.5 2.5];
[thermal.x, thermal.y] = meshgrid(side, side);
thermal.x = reshape(thermal.y, 9,1);
thermal.y = reshape(thermal.x, 9,1);
%%%%%%%%%%%%1
%           %
%  7  8  9  %
%           %
%  4  5  6  %
%           %
%  1  2  3  %
%           %
%%%%%%%%%%%%%
thermal.a = [10 0 0 0 0 0 0 0 5]*10;

filename = ['test' num2str(glider.n) '.gif'];

figure('color','white',...
    'position',[500 500 1000 1000])

for t=0:dt:5
    u = randi([0 1],glider.n,1); % control=0(CCW-turn),1(CW-turn)
    for i=1:glider.n
        % above threshold altitude
        if glider.alt(i) > glider.hmin
            % control policy:
            % average descent rate on both sides of the flight path
            % turn towards the side with smaller average descent rate
            
            % calculate flight path
            glider.hdg(i) = wrapToPi(glider.hdg(i));
            L.n = 0; L.sum = 0;
            R.n = 0; R.sum = 0;
            for j=1:glider.n
                if j==i
                    continue;
                end
                % is glider j to the left of glider i?
                angle = atan2((glider.pos(j,2) - glider.pos(i,2)),...
                              (glider.pos(j,1) - glider.pos(i,1)));
                if angle > glider.hdg(i) % left
                    L.sum = L.sum + glider.v_s(j);
                    L.n = L.n + 1;
                else
                    R.sum = R.sum + glider.v_s(j);
                    R.n = R.n + 1;
                end
            end
            
            L.avg = L.sum/L.n;
            R.avg = R.sum/R.n;
            
            % decision
            if L.avg > R.avg
                u(i) = 1;
            else
                u(i) = 0;
            end
            
            % update position
            switch(u(i)) 
                case 0 % right
                    glider.hdg(i) = glider.hdg(i) - dt/glider.R;
                    scatter(glider.pos(:,1),glider.pos(:,2),...
                        glider.alt(i),'r','filled');
                case 1 % left
                    glider.hdg(i) = glider.hdg(i) + dt/glider.R;
                    scatter(glider.pos(:,1),glider.pos(:,2),...
                        glider.alt(i),'b','filled');
            end
            glider.pos(i,1) = glider.pos(i,1) + dt*cos(glider.hdg(i)); %x
            glider.pos(i,2) = glider.pos(i,2) + dt*sin(glider.hdg(i)); %y
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
            scatter(thermal.x(m), thermal.y(m), 100*thermal.a(m),'g+')
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