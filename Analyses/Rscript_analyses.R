
# Data Analyses on the workshop ---------------------------------------------------


# Rってどんなもの？ ---------------------------------------------------------------

# 4則演算
1+1
3-1
3*2
4/3

# 少し複雑な計算
exp(3)
log(10)
exp(log(10))
sum(1:10)

# 代数（オブジェクト）を使ってみる

x <- 100 # xに100という値を入れたいときは <- を使います
x
# 実はRでも x = 100 と書けるのですが、たまに<- しか使えない場合があります。

# ベクトル代入
x <- c(1, 2, 3, 4) # == c(1:4)
x
x*x

# 行列代入
x <- matrix(1:4, nrow=2)
x
x+1
x*x
x %*% x

# データフレーム
x <- data.frame(a = 1:4, b = 11:14)
x
x$a
x$c <- x$a + x$b
x

# for 文, if 文
x <- 0
for(i in 1:100){ # i を1から100まで繰り返す
  if(i %% 2 == 0){ # iが2で割り切れる場合（偶数のとき）
    x <- x + i # xにiを足す
  }else{} # そうでないとき（奇数）はなにもしない
}
x # 2550
# でもこんなまわりくどいことをしなくても
x <- seq(2, 100, by =2)
sum(x)
# これでOK　コードはなるべくシンプルに

# こんなかんじでいろいろな計算ができます。
# Rは特に、統計解析に非常に強い言語です。
# みなさんも大学や企業に行ったら使うかもしれません。
# Rに慣れてしまうと、エクセルよりも計算は早いです。

# データロガーで記録したデータを解析してみよう --------------------------------------------------

# パッケージのインストール（ダウンロード）
# パッケージとは、道具を使いやすくしてまとめたものです

install.packages("tidyverse") # データ編集・グラフ作成のパッケージ
install.packages("magrittr") # データ編集のパッケージ２
install.packages("tuneR") # 音のデータを扱うためのパッケージ
install.packages("lubridate") # 時間のデータを扱うためのパッケージ
install.packages("scales") # 時間データを扱うためのパッケージ２
install.packages("patchwork") # グラフを並べるためのパッケージ
install.packages("gplots") # ヒートマップのグラフを作るのに便利なパッケージ
install.packages("colormap") # グラフの色を選ぶためのパッケージ
install.packages("RColorBrewer") # グラフの色を選ぶためのパッケージ


# パッケージの読み込み（使えるように準備します）

library(tidyverse)
library(magrittr)
library(tuneR)
library(lubridate)
library(scales)
library(patchwork)
library(gplots)
library(colormap)
library(RColorBrewer)


# 温度＆湿度のグラフをつくる -----------------------------------------------------------

# csvファイルの読み込み
dat <- read.csv("Analyses/DATALOG210707.CSV", sep="\t", header=F)
# 内容確認（%>%：パイプ　は{tidyverse}の特徴的記法で、読みやすく、書きやすくするものです）
dat %>% head() # head(dat)と同じです。
# 列名を設定　（%<>% は{magrittr}で定義されていて、結果を保存します）
dat %<>% set_colnames(c("Date", "Time", "Temp", "Humid", "CO2conc"))
dat %>% head() # %>% のショートカットはShift+Control+M です。
# 日付と時間を一つの列にして、時刻型にする
dat$Date2 <- ymd_hms(paste(dat$Date, dat$Time))
# 最後の電池切れの変な部分をカット
dat <- na.omit(dat) 
dat %>% head()

# 温度と湿度の列を分解して数値型に
dat$Temp %>% head() # 文字列になってますね、これを数値にしたい
# dat2 という別のオブジェクトを用意してそこに入れます。
dat2 <- dat %>% separate(col=Temp, into = c("Temp", "unit"), sep=" ") %>% 
  select(-unit) %>% 
  separate(col=Humid, into = c("Humid", "unit"), sep=" ") %>% 
  select(-unit) %>%
  separate(col=CO2conc, into = c("CO2", "unit"), sep=" ") %>% 
  select(-unit) 
dat2 %>% head()

# 3列目から5列目まで(Temp, Humid, Press)を文字列ではなく数値に変換します。
dat2[,3:5] %<>% apply(2,as.numeric)
dat2 %>% head()
dat2$Temp %>% mode() # 各要素の型を確認する
dat2$Date2 %>% class() # オブジェクトの型を確認する

# 温度のグラフ
# いちばん簡単な書き方(default)
plot(data=dat2, Temp~Date2, type="l")
# tidyverseの中にあるggplot2を使った書き方
pt <- ggplot(data=dat2, aes(x=Date2, y=Temp))+
  geom_line()
pt
# いろいろ設定を変えて美しく
pt <- ggplot(data=dat2, aes(x=Date2, y=Temp))+
  theme_classic()+
  theme(
    axis.title.y = element_text(size=20, color="black"),
    axis.text.y = element_text(size=20, color="black"),
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    plot.margin = margin(0.5,0.5,0.5,0.5, "cm")
  )+
  geom_line(color="steelblue4")+
  xlab("Date")+ylab("Temp(C-deg.)")+ylim(c(20,33))+
  scale_x_datetime(date_labels = "%m/%d")
pt

# Rでグラフを作るときは、デフォルトのplotでもいいのですが、
# ggplot2だとより美しいグラフを作ることができます。

# 湿度のグラフ

ph <- ggplot(data=dat2, aes(x=Date2, y=Humid))+
  theme_classic()+
  theme(
    axis.title = element_text(size=20, color="black"),
    axis.text = element_text(size=20, color="black"),
    plot.margin = margin(0.5,0.5,0.5,0.5, "cm")
  )+
  geom_line(color="steelblue4")+
  xlab("Date (2021.7)")+ylab("Humidity (%)")+
  scale_x_datetime(date_labels = "/%d", breaks = date_breaks("1 day"))
ph

# ２つのグラフを積み重ねる
p_unit <- pt+ph+plot_layout(ncol=1)
p_unit

# 保存する
ggsave(p_unit, filename="p_unit.png", width=8, height=8)



# 音声データを解析する --------------------------------------------------------------

# ファイルを読み込む
# testsound3.txt を読み込み。1000000文字まで、バイト文字
sdat <- readChar("Analyses/testsound3.txt", nchars=1000000, useBytes=T)
# 記録した時間の部分を置き換える
sdat2 <- sdat %>% str_replace_all(pattern="start\t.*\r\n", "_s_")
sdat2 %<>% str_replace_all(pattern="end\t.*\r\n", "_e_")

# 文字数
nchar(sdat2) # 133648
# _S_ でsdat2を分割する
sdat3 <- sdat2 %>% str_split(pattern="_s_", simplify = T)
sdat3 %>% length() # 4 それぞれの記録音源に分解
nchar(sdat3[1]) # 0 最初はなにも入っていない
nchar(sdat3[2]) # 46839

# sdat3[1]を削除
sdat3 <- sdat3[-1]
sdat3 %>% length()

sdat3[1] %>% head()

# 一旦それぞれファイルとして保存してからバイナリとして読み込む
# txtファイルとして保存
write.table(sdat3[2], file="sdat3.txt")
# バイナリとして読み込み
rdat3 <- file("sdat3.txt", "rb")

# バイナリデータを数値に変換する
bindat1 <- readBin(rdat3, integer(),  n = 100000, size=1L, signed=F)
bindat1 %>% length() # 67609

hist(bindat1)

# 音声の波を作図する
bindat1 %>% head()
# 最初の101から300個目までの音を抜き出す（200records == 0.025 sec）
waved <- data.frame(time = 101:300, wave = bindat1[101:300])

pw <- ggplot(data = waved, aes(x=time, y=wave))+
  theme_classic()+
  theme(
    axis.title.x = element_text(size=20, color="black"),
    axis.text.x = element_blank(),
    axis.title.y = element_text(size=20, color="black"),
    axis.text.y = element_blank(),
    legend.position="none",
    panel.grid = element_blank(),
    plot.margin = margin(0.5,0.5,0.5,0.5, "cm")
  )+
  geom_line()+
  ylab("Wave length")+xlab(">> Time >>")
pw

ggsave(pw, filename="wave1.png", height=8, width=8)


# 0.1秒ごとの行列に変換する
mat1 <- matrix(bindat1[1:46000], ncol = 1000) # 1000records=about 0.1sec
max(mat1) # 239
min(mat1) # 10

# 8 bit なので１から256

# 頻度分布の行列に直す

freq1 <- mat1 %>% apply(1, function(x){
  res <- hist(x, plot=F, breaks=seq(0, 256, by=4))
  res$counts
})
freq1 %>% dim() #64 rows, 80 cols
freq1

# 作図していく

# 作図のための前準備
# 行列を長いデータフレームに直す
freq2 <- freq1 %>% as.data.frame() %>% mutate(sound=1:64) %>% 
  pivot_longer(cols=-sound)
freq2 %>% head()

# 作図
p <- ggplot(data=freq2, aes(x=name, y=sound, fill=value %>% sqrt()))+
  theme_minimal()+
  theme(
    axis.title.x = element_text(size=20, color="black"),
    axis.text.x = element_blank(),
    axis.title.y = element_text(size=20, color="black"),
    axis.text.y = element_blank(),
    legend.position="none",
    panel.grid = element_blank(),
    plot.margin = margin(0.5,0.5,0.5,0.5, "cm")
  )+
  geom_tile()+
  scale_fill_gradientn("value", colours = rev(brewer.pal(11, "Spectral")))+
  ylab("Wave length")+xlab(">> Time >>")
p


ggsave(p, filename="spectrogram.png", height=8, width=8)

## おわり

