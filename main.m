clear; close all; clc;

seed = 1; % 乱数生成のため
inputDir = "./input/"; % ファイルの位置指定に使用
inputFiles = ["s1.wav", "s2.wav"]; % 2つの音声ファイルを行列にまとめる

% Set pseudorandom seed
rng(seed); % 乱数生成

mixMat = ... % 音声ファイル合成に使用する行列
    [0.8, -0.5;
    -0.7, 0.9];

for iData = 1:numel(inputFiles) % 音声ファイルの数分繰り返し
    inputPath = inputDir + inputFiles(iData); % ファイルの位置指定
    [src(:, iData), fs] = audioread(inputPath); % データ取り出し srcの列数は2
end

N = size(src, 2); % 音源数
signalLength = length(src); % 音声データの信号数T

srcImg = zeros(signalLength, N, N); % 信号長×音源×ch
for i = 1:N % 音源の番号
    for j = 1:N % chの番号
    srcImg(:, i, j) = mixMat(i, j) * src(:, i); % ソースイメージを計算
    end
end

obsSig = squeeze(sum(srcImg, 2)); % ソースイメージを合成
X = obsSig.'; % 計算用に転置した行列を用意しておく

refMic = 1; % 参照するマイクの番号
refSig(:, 1) = srcImg(:, 1, refMic); % 指定のマイクで録音したS1を行列の一行目に代入
refSig(:, 2) = srcImg(:, 2, refMic); % 指定のマイクで録音したS2を行列の二行目に代入

% soundsc(X1, fs); % 音源を再生

% 必要な値の入力
stepSize = 0.05; % ステップサイズの入力
doCount = 1000; % 反復回数の入力

% 計算
W = eye(2); % 単位行列で分離行列W(2*2)を初期化
I = eye(2); % 自然勾配法の計算用に(2*2)の単位行列Iを定義
for l = 0 : doCount - 1 % 反復回数分繰り返し
    E = zeros(2); % 経験期待値の計算用に(2*2)のゼロ行列Eを定義
    Y = W * X; % Yのサイズは(2*T)
    p = tanh(Y); % スコア関数の生成 pのサイズは(2*T)
    R = p * Y.'; % Rのサイズは(2*2)
    E = (1 / signalLength) * R; % 経験期待値の計算
    W = W - stepSize * (E - I) * W; % 目的関数を最小化する変数Wの計算
end

% スケール補正
invW = inv(W); % スケール補正に必要なWの逆行列を定義
Y = W * X; % 変数Wを乗じて音源を分離
estSig(:, 1) = invW(refMic, 1) * Y(1, :); % ch1にスケールを合わせた音源1を計算
estSig(:, 2) = invW(refMic, 2) * Y(2, :); % ch1にスケールを合わせた音源2を計算

% SDR、SIRの計算
addpath("./bss_eval/"); % フォルダの中身の関数を使えるようにする
[inSdr, inSir] = bss_eval_sources(X, refSig.'); % 元の音源のsdrとsirを計算
[outSdr, outSir, sar] = bss_eval_sources(estSig.', refSig.'); % スケール補正後のsdrとsirを計算
impSdr = outSdr - inSdr; % sdrを比較
impSir = outSir - inSir; % sirを比較

% SDR、SIRの出力
disp("--- SDR improvement ---")
for s = 1:N
    fprintf("S%d: %.10f [dB]\n",s, impSdr(s)); % sdrを表示
end
disp("--- SIR improvement ---")
for s = 1:N
    fprintf("S%d: %.10f [dB]\n",s, impSir(s)); % sirを表示
end

% 音の出力
outputDir = "./output/"; % 出力先を指定
if ~exist(outputDir, 'dir') %指定のフォルダがなければ作る
    mkdir(outputDir);
end

audiowrite(outputDir+"estimatedSignal1.wav", estSig(:, 1), fs); % スケール補正した音源1
audiowrite(outputDir+"estimatedSignal2.wav", estSig(:, 2), fs); % スケール補正した音源2
audiowrite(outputDir+"referenceSignal1.wav", refSig(:, 1), fs); % S1のソースイメージ
audiowrite(outputDir+"referenceSignal2.wav", refSig(:, 2), fs); % S2のソースイメージ
audiowrite(outputDir+"observedSignal.wav", obsSig(:, refMic), fs); % 合成した音源