IP_adress = '138.246.133.175';
device = 'dev5094';
port = 8004;
API_Level = 6;
demods = ['0','1','2','3'];
transfer_rate = 10000;
ziDAQ('connect', IP_adress, port, API_Level) % 8004 for MFLI (see below)`
%ziSaveSettings(device, 'my_settings.xml');



% Create an API session; connect to the correct Data Server for the device.
[device, props] = ziCreateAPISession(device, API_Level);
ziLoadSettings(device, 'my_settings.xml');

%Change TransferRate for all demods
arrayfun(@(x) ziDAQ('setDouble', ['/' device '/demods/' x '/rate'], transfer_rate),demods);
%Turn on/off Data Transfer
%arrayfun(@(x) ziDAQ('setInt', ['/' device '/demods/' x '/enable'], 1),demods);
%Change Oscillator
%ziDAQ('setInt', ['/' device '/demods/1/oscselect'], 1);
%Change Input for Oscillator 0 for Signal1n 1 for CurrentIn
%ziDAQ('setInt', ['/' device '/demods/1/adcselect'], 0);

%Change TimeConstant
%ziDAQ('setDouble', ['/' device '/demods/1/timeconstant'], 1000);

%Change Oscillator Frequency
%ziDAQ('setDouble', ['/' device '/oscs/' 10000 '/freq'], 30e5); % [Hz]



data = cell(4,10000);
figure; hAxes(1) = gca;
hAnimatedLine(1) = animatedline( hAxes(1),'MaximumNumPoints',1e8);
figure; hAxes(2) = gca;
hAnimatedLine(2) = animatedline( hAxes(2),'MaximumNumPoints',1e8);
figure; hAxes(3) = gca;
hAnimatedLine(3) = animatedline( hAxes(3),'MaximumNumPoints',1e8);
figure; hAxes(4) = gca;
hAnimatedLine(4) = animatedline( hAxes(4),'MaximumNumPoints',1e8);

linkaxes(hAxes);
hAxes(1).XLim = [0 1000];
hAxes(1).YLim = [0 0.00002];

hAxes(1).Interactions = [zoomInteraction regionZoomInteraction rulerPanInteraction];
hAxes(1).Toolbar = [];

setappdata(hAxes(1),'LegendColorbarManualSpace',1);
setappdata(hAxes(1),'LegendColorbarReclaimSpace',1);

hasbehavior(hAnimatedLine(1),'legend',false);
hasbehavior(hAnimatedLine(2),'legend',false);
hasbehavior(hAnimatedLine(3),'legend',false);
hasbehavior(hAnimatedLine(4),'legend',false);


clockbase = double(ziDAQ('getInt', ['/' device '/clockbase']));

ziDAQ('sync');
ziDAQ('subscribe', ['/' device '/demods/'])
pause(1);
ziDAQpollData = ziDAQ('poll', 0.1, 500);
            r_cor = cell(6,1);

timer0 = clock;
time_meas = 2;
t0 = ziDAQpollData.dev5094.demods(1).sample.timestamp(end);
i = 1;
tic
while etime(clock, timer0) < time_meas  


ziDAQpollData = ziDAQ('poll', 0.5, 500); 


data(:,i) = arrayfun(@(x) struct(x.sample), ziDAQpollData.(device).demods, 'UniformOutput', false)';


r = cellfun(@(x) sqrt(x.x.^2 + x.y.^2), data(:,i), 'UniformOutput', false);


lengths = (cellfun('length', r));
[maxLength,maxLengthIndex] = max(lengths);
r_cor(1:4) = cellfun(@(x) [x NaN(1, maxLength - numel(x))], r, 'un', 0);

time = (double(data{maxLengthIndex,i}.timestamp) - double(t0))/clockbase;
% Time für jeden Plot einzeln berechnen.

addpoints(hAnimatedLine(1), time,r_cor{1})
addpoints(hAnimatedLine(2), time,r_cor{2})
addpoints(hAnimatedLine(3), time,r_cor{3})
addpoints(hAnimatedLine(4), time,r_cor{4})
i = i + 1;
drawnow
end
toc
measurementData(6,1) = struct("time",[], "r_cor", []);
for i = 1:s
[measurementData(1).time, measurementData(1,2)] = getpoints(hAnimatedLine(1));
[measurementData(2,1), measurementData(2,2)] = getpoints(hAnimatedLine(2));
[measurementData(3,1), measurementData(3,2)] = getpoints(hAnimatedLine(3));
[measurementData(4,1), measurementData(4,2)] = getpoints(hAnimatedLine(4));
ziDAQ('unsubscribe', '*');