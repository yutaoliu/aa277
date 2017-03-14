% banking control
side = -1:0.1:1;
[L,R] = meshgrid(side,side);
l = reshape(L,1,numel(L));
r = reshape(R,1,numel(L));
hold on
for i = 1:numel(L)
    if l(i) == 0 && r(i) == 0
        continue
    elseif l(i) == 0
        u = 0;
    elseif r(i) == 0
        u = 1;
    elseif l(i) > 0 && r(i) > 0
        ratio = r(i) / l(i);
        if ratio > 1
            ratio = 1;
        end
        u = ratio;
    elseif l(i) > 0 && r(i) < 0
        u = 0;
    elseif l(i) < 0 && r(i) > 0
        u = 1;
    elseif l(i) < 0 && r(i) < 0
        ratio = r(i) / l(i);
        if ratio > 1
            ratio = 1;
        end
        u = 1-ratio;
    end
    scatter(l(i),r(i),150,[1-u 0 u],'s','filled');
end