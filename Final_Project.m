% Final Project

%{ 

    Table of Contents (By Section):
    % Import Data
    % Check for 60 Hz noise and filter
    % Apply 60 Hz filter
    % Check fft filter
    % Checkpt 1
    % Looking at Flexion Data

%}

%% Import Data
%{
    Each subject has ECoG data set, a glove data set, and testing data set.
    
%}

% Subject 1
sesh_sub1_1 = IEEGSession('I521_A0012_D001', 'solbaby888', 'sol_ieeglogin.bin');
sesh_sub1_2 = IEEGSession('I521_A0012_D002', 'solbaby888', 'sol_ieeglogin.bin');
sesh_sub1_3 = IEEGSession('I521_A0012_D003', 'solbaby888', 'sol_ieeglogin.bin');
nr_1        = ceil((sesh_sub1_1.data(1).rawChannels(1).get_tsdetails.getEndTime)/...
                1e6*sesh_sub1_1.data(1).sampleRate);
% Subject 2
sesh_sub2_1 = IEEGSession('I521_A0013_D001', 'solbaby888', 'sol_ieeglogin.bin');
sesh_sub2_2 = IEEGSession('I521_A0013_D002', 'solbaby888', 'sol_ieeglogin.bin');
sesh_sub2_3 = IEEGSession('I521_A0013_D003', 'solbaby888', 'sol_ieeglogin.bin');
nr_2        = ceil((sesh_sub2_1.data(1).rawChannels(1).get_tsdetails.getEndTime)/...
                1e6*sesh_sub2_1.data(1).sampleRate);

% Subject 3
sesh_sub3_1 = IEEGSession('I521_A0014_D001', 'solbaby888', 'sol_ieeglogin.bin');
sesh_sub3_2 = IEEGSession('I521_A0014_D002', 'solbaby888', 'sol_ieeglogin.bin');
sesh_sub3_3 = IEEGSession('I521_A0014_D003', 'solbaby888', 'sol_ieeglogin.bin');
nr_3        = ceil((sesh_sub2_3.data(1).rawChannels(1).get_tsdetails.getEndTime)/...
                1e6*sesh_sub2_1.data(1).sampleRate);

%{
    TL_Comment: Loads pretty fast

%}

%% Check for 60 Hz noise and filter
%{
    Starting with subject 1 ECoG, Channel 1

%}

ECoG_Sub1_Chan1 = sesh_sub1_1.data(1).getvalues(1:nr_1, 1);
fs_Sub1         = sesh_sub1_1.data(1).sampleRate;

% FFT Code
%# Can comment out later
Y           = fft(ECoG_Sub1_Chan1);
L           = length(ECoG_Sub1_Chan1);
f           = fs_Sub1 *(0:(L/2))/L;
P2          = abs(Y/L);
P1          = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
figure;
plot(f,P1)
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

%{
    TL_Comment: As expectted, there is 60 Hz noise. Bandpass filter as per
    kubanek paper between 0.15 and 200 Hz
%}

%% Apply 60 Hz filter and Bandpass filter
%{
    Will eventually have to save as a function to run on all channels
%}

% 60 Hz Notch Filter
f0        = 60;         % notch frequency
fn        = fs_Sub1/2;  % Nyquist frequency
freqRatio = f0/fn;      % ratio of notch freq. to Nyquist freq.

notchWidth = 0.1;       % width of the notch

%#Compute zeros
zeross = [exp( sqrt(-1)*pi*freqRatio ), exp( -sqrt(-1)*pi*freqRatio )]; %two 's' on purpose

%#Compute poles
poles = (1-notchWidth) * zeross;

figure;
zplane(zeross.', poles.');

b = poly( zeross ); % Get moving average filter coefficients
a = poly( poles );  % Get autoregressive filter coefficients

figure;
freqz(b,a,32000,fs_Sub1 )

%#filter signal x
ECoG_Sub1_Chan1_filt_1 = filtfilt(b, a, ECoG_Sub1_Chan1);
figure;

% Bandpass filter
A_stop1 = 60;		% Attenuation in the first stopband = 60 dB
F_stop1 = 0.1;		% Edge of the stopband = 8400 Hz
F_pass1 = 0.15;     % Edge of the passband = 10800 Hz
F_pass2 = 200;      % Closing edge of the passband = 15600 Hz
F_stop2 = 201;      % Edge of the second stopband = 18000 Hz
N_order = 100;

BandPassSpecObj = ...
   fdesign.bandpass('N,Fst1,Fp1,Fp2,Fst2', ...
		N_order, F_stop1, F_pass1, F_pass2, F_stop2, fs_Sub1)
   Hd = design(BandPassSpecObj,'equiripple');
   ECoG_Sub1_Chan1_filt_2 = filtfilt(Hd.Numerator,1,ECoG_Sub1_Chan1_filt_1);

%{
    TL_comment: Not sure if this is the best way to filter the data. Should check if
    filtering between .15 and 200 is right. Need to check if we should only
    use channels 48, 63, 47, 64, 61
%}

%% Check fft filter
% FFT Code on filtered
%# Can comment out later
Y           = fft(ECoG_Sub1_Chan1_filt_2);
L           = length(ECoG_Sub1_Chan1_filt_2);
f           = fs_Sub1 *(0:(L/2))/L;
P2          = abs(Y/L);
P1          = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
figure;
plot(f,P1)
title('Single-Sided Amplitude Spectrum of X(t)')
xlabel('f (Hz)')
ylabel('|P1(f)|')

% Plot filtered data
figure;
plot(ECoG_Sub1_Chan1_filt_2)
hold on;
plot(ECoG_Sub1_Chan1),....
legend('Filtered', 'Raw')

%% Checkpt 1
%{ 
    window of 100 ms; overlap of 50 ms
%}

% ====== Function handle to calculate number of windows ================= %
    NumWins = @(xLen, fs, winLen, winDisp) 1+floor((xLen-fs*winLen)/(winDisp*fs));  
    % winLen and winDisp are in secs, xLen are in samples
% ======================================================================= %

% Number of Windows for Subj1
window_time = 100*10^-3;                                 % (secs)
overlap     = 50*10^-3;                                  % (secs)
windowLen   = window_time * fs_Sub1;                     % number of pts per window 
L           = length(ECoG_Sub1_Chan1_filt_2);
NoW         = NumWins(L, fs_Sub1, window_time, overlap); % caclulate number of windows; not sure if we need this atm

% ======= Features ====================================================== %
    % Feature 1 - Line Length
    LLFn  = @(x) sum(abs(diff(x))); 
    % Feature 2 - Area
    AreaFn = @(x) sum(abs(x));
    % Feature 3 - Energy
    EnergyFn = @(x) sum(x.^2);
    % Feature 4 - Amplitude (maybe?)
    % Feature 5 - FFT (maybe?)
    % Feature 6 - ???
% ======================================================================= %

% Calculate Features over windows
Sub1_LL     = MovingWinFeats(ECoG_Sub1_Chan1_filt_2, fs_Sub1, window_time, overlap, LLFn);
Sub1_Area   = MovingWinFeats(ECoG_Sub1_Chan1_filt_2, fs_Sub1, window_time, overlap, AreaFn);
Sub1_Energy = MovingWinFeats(ECoG_Sub1_Chan1_filt_2, fs_Sub1, window_time, overlap, AreaFn);

Feat_Mat(:,1) = Sub1_LL;
Feat_Mat(:,2) = Sub1_Area;
Feat_Mat(:,3) = Sub1_Energy;
% ofcourse will have to add more columns as we choose what features to use

%% Looking at Flexion Data
nr        = ceil((sesh_sub1_2.data(1).rawChannels(1).get_tsdetails.getEndTime)/...
                1e6*sesh_sub1_2.data(1).sampleRate);
Glove_Sub1_Chan1 = sesh_sub1_2.data(1).getvalues(1:nr, 1:5);
