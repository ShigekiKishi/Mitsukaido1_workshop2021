
# Data Analyses on the workshop ---------------------------------------------------

# パッケージのインストール

install.packages("tidyverse")
install.packages("magrittr")
install.packages("tuneR")
install.packages("lubridate")
install.packages("patchwork")
install.packages("scales")
install.packages("colormap")

# パッケージの読み込み

library(tidyverse)
library(magrittr)
library(tuneR)
library(lubridate)
library(patchwork)
library(scales)
library(colormap)

# 温度＆湿度のグラフをつくる -----------------------------------------------------------


dat <- read.csv("DATALOG210707.csv", sep="\t", header=F)
dat %>% head()
# 列名を設定
dat %<>% set_colnames(c("Date", "Time", "Temp", "Humid", "Press"))
# 日付と時間を一つの列にして、時刻型に
dat$Date2 <- ymd_hms(paste(dat$Date, dat$Time))
# 最後の電池切れの変な部分をカット
dat <- na.omit(dat) 
dat %>% head()

# 温度と湿度の列を分解して数値型に
dat2 <- dat %>% separate(col=Temp, into = c("Temp", "unit"), sep=" ") %>% 
  select(-unit) %>% 
  separate(col=Humid, into = c("Humid", "unit"), sep=" ") %>% 
  select(-unit) %>%
  separate(col=Press, into = c("Press", "unit"), sep=" ") %>% 
  select(-unit) 

dat2[,3:5] %<>% apply(2,as.numeric)

dat2 %>% head()
dat2$Temp %>% mode()

# 温度のグラフ

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

library(gplots)

# ファイルを読み込む
sdat <- readChar("testsound3.txt", nchars=1000000, useBytes=T)
sdat2 <- sdat %>% str_replace_all(pattern="start\t.*\r\n", "_s_")
sdat2 %<>% str_replace_all(pattern="end\t.*\r\n", "_e_")

nchar(sdat2) # 184226
sdat3 <- sdat2 %>% str_split(pattern="_s_", simplify = T)
sdat3 %>% length() # 4 それぞれの記録音に分解
nchar(sdat3[1]) # 0
nchar(sdat3[2]) # 64261

# sdat3[1]を削除
sdat3 <- sdat3[-1]
sdat3 %>% length()

sdat3[1] %>% head()

# 一旦それぞれファイルとして保存してからバイナリとして読み込む

write.table(sdat3[2], file="sdat3.txt")
rdat3 <- file("sdat3.txt", "rb")

# バイナリデータを数値に変換する
bindat1 <- readBin(rdat3, integer(),  n = 100000, size=1L, signed=F) # 72500??
bindat1 %>% length() # 81322

# 音声の波を作図する
bindat1 %>% head()
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
mat1 <- matrix(bindat1[1:72000], ncol = 1000) # 1000records=about 0.1sec
max(mat1) # 239
min(mat1) # 10

# 8 bit なので１から256

# 頻度分布の行列に直す

freq1 <- mat1 %>% apply(1, function(x){
  res <- hist(x, plot=F, breaks=seq(0, 256, by=4))
  res$counts
})
freq1 %>% dim() #64 rows, 72 cols
freq1

# 作図していく

# 作図のための前準備
freq2 <- freq1 %>% as.data.frame() %>% mutate(sound=1:64) %>% 
  pivot_longer(cols=-sound)
freq2 %>% head()

# 作図
library(RColorBrewer)
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

