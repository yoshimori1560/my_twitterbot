# my_twitterbot
botファイルの説明
※各ファイルは独立しているので、独立して起動が可能

各ファイルの機能
機能　[]内が起動に必要な言葉（この言葉をリプすると返ってくる）

# 1. uranai2.rb
1. 運勢を送る [運勢]
2. 食堂のメニューから、指定された金額以内でおすすめを選ぶ [食堂　(半角数値)円]
3. 模擬店のメニューから、指定された金額以内でおすすめを選ぶ（現在機能停止中）
4. サイコロを振る　[サイコロ　（個数)d（サイコロの面の数）]
5. 運勢履歴（過去30日）を見る　[履歴]
6. 天気予報をツイートする（リプ機能ではない）　1日4回

# 2. 334measure2.rb
1. 334とだけツイートされたものに対して、ツイートされた時刻を計算し、それをツイートする。
2. また、午前3時34分付近にツイートされたものに対しては、ランキングおよびフライングチェックを行う。

# 3. read_kitcard.rb
1. 学生証の学生番号と名前を読み取る（疑似出席判定プログラム付き）
2. 生協カード（大学）のプリペイド残高とミール残高を読み取る

# 4. fav_check.rb
1. 自分の名前をツイートすると検知し、自分のDMにツイート情報を送信する
2. 過去200個のいいねから、誰によくいいねしているかを調べる[いいね　分析]
3. 過去200個のツイートから、誰によくリプを飛ばしているかを調べる[リプライ　分析]
4. 過去200個のいいねやツイートから、仲良しランキングを調べる[仲良し　ランキング]
5. 過去200個のいいねやツイートから、2人の相性を調べる[両想い　「(1人めのID)」「(2人めのID)」]
6. 過去200個のいいねやツイートから、自分の犯罪係数を調べる[犯罪係数　計測]
7. 過去200個のいいねやツイートから、いいね頻度、ツイート頻度、ツイート影響力、ツイッター廃人度を計測する[ツイート　分析]
