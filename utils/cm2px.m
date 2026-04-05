function px = cm2px(cm, px_per_cm)
%CM2PX Convert centimeters to pixels.

px = round(cm .* px_per_cm);
end
