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

X = mixMat * src.'; % 音声ファイル合成 列数2

% soundsc(X, fs); % 音源を再生

% 必要な値の入力
signalLength = length(src); % 音声データの信号数
stepSize = 0.05; % ステップサイズの入力
doCount = 1000; % 反復回数の入力

% 計算
W = eye(2); % 単位行列で分離行列W(2*2)を初期化
I = eye(2); % 自然勾配法の計算用に(2*2)の単位行列Iを定義
for l = 0 : doCount - 1 % 反復回数分繰り返し
    E = zeros(2); % 経験期待値の計算用に(2*2)のゼロ行列Eを定義
    Y = W * X; % Yのサイズは(2*1)
    p = tanh(Y); % スコア関数の生成 pのサイズは(2*1)
    R = p * Y.'; % Rのサイズは(2*2)
    E = (1 / signalLength) * R; % 経験期待値の計算
    W = W - stepSize * (E - I) * W; % 目的関数を最小化する変数Wの計算
end

Y = W * X; % 変数Wを乗じて音声を分離

soundsc(Y(2, :), fs); % 音源を再生