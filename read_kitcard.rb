=begin
read_kitcard.rb 既存のexeファイル felicaDump.exe から読み取ったカードデータから学生証番号と名前を読み取る
生協カード（大学）のプリペイド残高とミールカードの利用額（当日分）も見ることができる。
また、音声ファイルを用いると音を鳴らすことも可能（該当部分はコメントアウトした）

=end

﻿require "twitter"
require "open3"
require "time"
require "csv"
require "win32/sound"
require 'win32ole'
include Win32

item_ichiran = ["ボールペン", "化粧品", "扇子" , "シャーペン" , "鍵" , "腕時計" , "スマホ" , "筆箱" , "シャーペンの芯" , "充電器" , "オレンジジュース" , "酒" , "印鑑" , "タオル" , "バッグ" , "消しゴム" , "コンパス" , "トマトジュース" , "砂時計" , "ヘアスプレー" , "ぬいぐるみ" , "マカロン" , "ブックスタンド" , "本" , "ホッチキス" , "Lチキ"]
item_ichiran.push("りんご", "ファミチキ" , "電卓" , "牛乳" , "パンナコッタ" , "大学芋" , "ポカリスエット" , "電卓" , "ノート" , "教科書" , "スイカ" , "とんこつラーメン" , "醤油ラーメン","きびだんご","もみじ饅頭","かぼちゃ","チャーハン","チョコレート","かぼちゃ")
unsei_ichiran = ["大吉","中吉","小吉","吉","末吉","凶","大凶"]
unsei_color = ["白","黒","赤","青","緑","黄","オレンジ","ピンク","紫","茶","金","銀","虹"]


class Array
  def sum
    reduce(:+)
  end

  def mean
    sum.to_f / size
  end

  def var
    m = mean
    reduce(0) { |a,b| a + (b - m) ** 2 } / (size)
  end

  def sd
    Math.sqrt(var)
  end
end

def detail(point)
  kobetsu = (point / 10.0).round
  kobetsu = kobetsu + rand(5) - 2
  if point >= 95 && kobetsu < 10
    kobetsu = 10
  end
  if kobetsu >= 11 && rand(5) != 0
    kobetsu = 10
  elsif kobetsu <= -1 && rand(5) != 0
    kobetsu = 0
  end
  return kobetsu
end

def ketazoroe(num)
  if(num >= 100)
    return num.to_s
  elsif(num >= 10)
    return " " + num.to_s
  else
    return "  " + num.to_s
  end
end

def fugou(num)
  if(num >= 10)
    return "+" + num.to_s
  elsif(num >= 1)
    return "+" + num.to_s
  elsif(num == 0)
    return " " + num.to_s
  else
    return num.to_s
  end
end



def omikuji()
  score = rand(101)
  unsei = ""
  if score >= 95
    unsei = "☆大吉"
  elsif score >= 80
    unsei = "大吉"
  elsif score >= 60
    unsei = "中吉"
  elsif score >= 40
    unsei = "小吉"
  elsif score >= 25
    unsei = "吉"
  elsif score >= 10
    unsei = "末吉"
  elsif score >= 3
    unsei = "凶"
  else
    unsei = "大凶"
  end
  return score.to_s.rjust(3) + "点 (" + unsei + ")"
end

# 自分のTwitterアカウント
client = Twitter::REST::Client.new do |config|
  config.consumer_key = ''
  config.consumer_secret = ''
  config.access_token = ''
  config.access_token_secret = ''
end

client2 = Twitter::REST::Client.new do |config|
  config.consumer_key = ''
  config.consumer_secret = ''
  config.access_token = ''
  config.access_token_secret = ''
end

# 自分のTwitterID
myid1 = "" #ここにTwitterIDを入力


today_toukei_score = []
out, err, status = Open3.capture3("FelicaDump.exe")
i = status.exitstatus
student_id = ""
while 1
  while i == 1
    puts "\e[H\e[2J"
    print "学生証を置いてください\n"
    if Time.now.sec % 2 == 0
      print "現在時刻 : " + Time.now.strftime("%H:%M\n")
    else
      print "現在時刻 : " + Time.now.strftime("%H %M\n")
    end
    out, err,status = Open3.capture3("FelicaDump.exe")
    if status.exitstatus == 0
      puts "カードを読み込んでいます…　離さないでください…"
    end
    #sleep(1)
    i = status.exitstatus.to_i
  end

  card_code = 0 #読まれたのが何のカードか判定
  num_line = ""
  name_line = ""
  previous_id = student_id
  count_line = 0
  out.each_line do |line|
    count_line += 1
    if line.include?("# System code: 809E") && count_line == 4
      #puts "学生証判定OK"
      card_code = 1
    elsif line.include?("# System code: 8E4B") && count_line == 4
      # Serivce code = 50CB : Random Access Read only
      card_code = 2
    end
  end
  #puts count_line
  if card_code == 1 && count_line == 276#学生証の場合
    out.each_line do |line|
      if line.include?("1A8B:0000")
        #line.slice!("abc")
    #    puts line
        num_line = line
      end

      if line.include?("1A8B:0001")
    #    puts line
        name_line = line
      end
    end
    num_line.slice!("1A8B:0000 ")
    name_line.slice!("1A8B:0001 ")

    #puts num_line
    #puts name_line

    for i in 0..9 do
      num_line.gsub!((30+i).to_s,i.to_s)
    end
    num_line.gsub!(" ","")
    student_id = num_line.slice(2, 8) ##ここで学生番号を取得

    #1バイトの文字を　ひらがな　に置き換え
    name_line.gsub!("A0","　")
    name_line.gsub!("A1","。")
    name_line.gsub!("A2","「")
    name_line.gsub!("A3","」")
    name_line.gsub!("A4","、")
    name_line.gsub!("A5","・")
    name_line.gsub!("A6","を")
    name_line.gsub!("A7","ぁ")
    name_line.gsub!("A8","ぃ")
    name_line.gsub!("A9","ぅ")
    name_line.gsub!("AA","ぇ")
    name_line.gsub!("AB","ぉ")
    name_line.gsub!("AC","ゃ")
    name_line.gsub!("AD","ゅ")
    name_line.gsub!("AE","ょ")
    name_line.gsub!("AF","っ")
    name_line.gsub!("B0","ー")
    name_line.gsub!("B1","あ")
    name_line.gsub!("B2","い")
    name_line.gsub!("B3","う")
    name_line.gsub!("B4","え")
    name_line.gsub!("B5","お")
    name_line.gsub!("B6","か")
    name_line.gsub!("B7","き")
    name_line.gsub!("B8","く")
    name_line.gsub!("B9","け")
    name_line.gsub!("BA","こ")
    name_line.gsub!("BB","さ")
    name_line.gsub!("BC","し")
    name_line.gsub!("BD","す")
    name_line.gsub!("BE","せ")
    name_line.gsub!("BF","そ")
    name_line.gsub!("C0","た")
    name_line.gsub!("C1","ち")
    name_line.gsub!("C2","つ")
    name_line.gsub!("C3","て")
    name_line.gsub!("C4","と")
    name_line.gsub!("C5","な")
    name_line.gsub!("C6","に")
    name_line.gsub!("C7","ぬ")
    name_line.gsub!("C8","ね")
    name_line.gsub!("C9","の")
    name_line.gsub!("CA","は")
    name_line.gsub!("CB","ひ")
    name_line.gsub!("CC","ふ")
    name_line.gsub!("CD","へ")
    name_line.gsub!("CE","ほ")
    name_line.gsub!("CF","ま")
    name_line.gsub!("D0","み")
    name_line.gsub!("D1","む")
    name_line.gsub!("D2","め")
    name_line.gsub!("D3","も")
    name_line.gsub!("D4","や")
    name_line.gsub!("D5","ゆ")
    name_line.gsub!("D6","よ")
    name_line.gsub!("D7","ら")
    name_line.gsub!("D8","り")
    name_line.gsub!("D9","る")
    name_line.gsub!("DA","れ")
    name_line.gsub!("DB","ろ")
    name_line.gsub!("DC","わ")
    name_line.gsub!("DD","ん")
    name_line.gsub!("DE","゛")
    name_line.gsub!("DF","゜")
    name_line.gsub!(" ","")
    name_line.gsub!("00","")

    #濁点と半濁点をまとめる
    name_line.gsub!("か゛","が")
    name_line.gsub!("き゛","ぎ")
    name_line.gsub!("く゛","ぐ")
    name_line.gsub!("け゛","げ")
    name_line.gsub!("こ゛","ご")
    name_line.gsub!("さ゛","ざ")
    name_line.gsub!("し゛","じ")
    name_line.gsub!("す゛","ず")
    name_line.gsub!("せ゛","ぜ")
    name_line.gsub!("そ゛","ぞ")
    name_line.gsub!("た゛","だ")
    name_line.gsub!("ち゛","ぢ")
    name_line.gsub!("つ゛","づ")
    name_line.gsub!("て゛","で")
    name_line.gsub!("と゛","ど")
    name_line.gsub!("は゛","ば")
    name_line.gsub!("ひ゛","び")
    name_line.gsub!("ふ゛","ぶ")
    name_line.gsub!("へ゛","べ")
    name_line.gsub!("ほ゛","ぼ")
    name_line.gsub!("は゜","ぱ")
    name_line.gsub!("ひ゜","ぴ")
    name_line.gsub!("ふ゜","ぷ")
    name_line.gsub!("へ゜","ぺ")
    name_line.gsub!("ほ゜","ぽ")


    #puts name_line
    read_time = Time.now
    family_name = name_line.slice(0, name_line.index("20")) ##ここで学生番号を取得
    first_name = name_line.slice(name_line.index("20")+2,name_line.length) ##ここで学生番号を取得
    #puts family_name
    #puts first_name
    full_name = family_name + "　" + first_name

    grade = 0
    #何回生かを算出
    if read_time.month >= 4
      grade = read_time.year - 2000 - student_id.slice(0..1).to_i + 1
    else
      grade = read_time.year - 2000 - student_id.slice(0..1).to_i
    end
    #算出終了


    #学科を算出
    department = ""
    if student_id.slice(4..5) == "10"
      department = "知能情報工学科"
    elsif student_id.slice(4..5) == "20"
      department = "電子情報工学科"
    elsif student_id.slice(4..5) == "60"
      department = "システム創生情報工学科"
    elsif student_id.slice(4..5) == "70"
      department = "機械情報工学科"
    elsif student_id.slice(4..5) == "80"
      department = "生命情報工学科"
    else
      department = "不明な学科"
    end
    #学科判別終了
    unsei = omikuji()

    outdm = ""
    #Twitter出力内容
    outdm = outdm + "読取月日：" + read_time.strftime("%Y年%m月%d日\n")
    outdm = outdm + "読取時刻：" + read_time.strftime("%k:%M:%S.%L\n")
    outdm = outdm + "学籍番号：" + student_id + "\n"
    outdm = outdm + "名前　　：" + full_name
    outdm = outdm + "学年　　：" + grade.to_s + "回生" + "\n"
    outdm = outdm + "学科　　：" + department + "\n"
    outdm = outdm + "運勢　　：" + unsei + "\n"
    #出力内容終了


    attendance = ""
    lesson = 0
    late   = 0
    border = 0
    #出席判定
    if Time.parse("09:01") >= read_time && read_time >= Time.parse("07:29")
      lesson = 1
      late   = 0
      attendance = "1限　出席"
      border = Time.parse("08:50") - read_time
    elsif Time.parse("09:31") >= read_time && read_time > Time.parse("09:01")
      lesson = 1
      late   = 1
      attendance = "1限　遅刻"
      border = Time.parse("08:50") - read_time
    elsif Time.parse("10:41") >= read_time && read_time >= Time.parse("10:19")
      lesson = 2
      late   = 0
      attendance = "2限　出席"
      border = Time.parse("10:30") - read_time
    elsif Time.parse("11:11") >= read_time && read_time > Time.parse("10:41")
      lesson = 2
      late   = 1
      attendance = "2限　遅刻"
      border = Time.parse("10:30") - read_time
    elsif Time.parse("13:11") >= read_time && read_time >= Time.parse("12:39")
      lesson = 3
      late   = 0
      attendance = "3限　出席"
      border = Time.parse("13:00") - read_time
    elsif Time.parse("13:41") >= read_time && read_time > Time.parse("13:11")
      lesson = 3
      late   = 1
      attendance = "3限　遅刻"
      border = Time.parse("13:00") - read_time
    elsif Time.parse("14:51") >= read_time && read_time >= Time.parse("14:29")
      lesson = 4
      late   = 0
      attendance = "4限　出席"
      border = Time.parse("14:40") - read_time
    elsif Time.parse("15:21") >= read_time && read_time > Time.parse("14:51")
      lesson = 4
      late   = 1
      attendance = "4限　遅刻"
      border = Time.parse("14:40") - read_time
    elsif Time.parse("16:31") >= read_time && read_time >= Time.parse("16:09")
      lesson = 5
      late   = 0
      attendance = "5限　出席"
      border = Time.parse("16:20") - read_time
    elsif Time.parse("17:01") >= read_time && read_time > Time.parse("16:31")
      lesson = 5
      late   = 1
      attendance = "5限　遅刻"
      border = Time.parse("16:20") - read_time
    end
    soushin_hantei = ""
    jikan =  sprintf("%2d",border.to_i / 60) + ":" + sprintf("%06.3f",border % 60)
    if(border >= -600)
      soushin_hantei = "出席"
    elsif border >= -1800
      soushin_hantei = "遅刻"
    else
      soushin_hantei = "欠席"
    end
    #出席判定終了
    st = ""
    if late == 0
      st = "出席"
    elsif late == 1
      st = "遅刻"
    end


    #Twitter連携判定
    twitter_id = ""
    id_list = CSV.read("id_list.csv", encoding: "UTF-8")
    for line in 1..(id_list.flatten.count / 2 - 1) do
      #print(id_list[line][0],"-",student_id.to_s,"\n")
      if id_list[line][0] == student_id.to_s
        twitter_id = id_list[line][1]
        break
      end
    end
    #Twitter連携判定終了
    attend = 0
    delay  = 0
    absent = 0

    send_dm = 0
    dm_attendance  = ""
    shukketsu_list = [[""],[""]]
    hantei_list    = [[""],[""]]
    #出欠判定
    finish_shusseki = 0
    aisatsu = "こんにちは"
    if lesson != 0
      begin
        shukketsu_list = CSV.read(student_id.to_s + "-" + read_time.wday.to_s + lesson.to_s + ".csv", encoding: "UTF-8")
      rescue
        puts "データがありません"
      end
        if shukketsu_list.flatten.include?(read_time.strftime("%4Y/%2m/%2d"))
          puts "出席登録済です！"
          aisatsu = "カード読み込み済みです"
          finish_shusseki = 1
        else
          CSV.open(student_id.to_s + "-" + read_time.wday.to_s + lesson.to_s + ".csv" ,'a') do |test|
           test << [read_time.strftime("%4Y/%2m/%2d"),st]
          end
          if twitter_id != ""
            send_dm = 1
          end
        end
        begin
          hantei_list = CSV.read("16231040-" + read_time.wday.to_s + lesson.to_s + ".csv", encoding: "UTF-8")
        rescue
          puts "16231040のデータがありません。"
        end
        total_class = hantei_list.flatten.count("出席")
        shukketsu_list = CSV.read(student_id.to_s + "-" + read_time.wday.to_s + lesson.to_s + ".csv", encoding: "UTF-8")
        attend = shukketsu_list.flatten.count("出席")
        delay  = shukketsu_list.flatten.count("遅刻")
        absent = total_class - (attend + delay)
        if finish_shusseki == 0
          dm_attendance = dm_attendance + "カード読込時刻：" + read_time.strftime("%H:%M:%S.%L\n")
          dm_attendance = dm_attendance + "授業との誤差　：" + jikan + "\n"
          dm_attendance = dm_attendance + "出欠判定　　　：" + soushin_hantei + "\n\n"
        end
        dm_attendance = dm_attendance + "ーーー☆出席状況☆ーーー\n"
        dm_attendance = dm_attendance + "出席 : " + attend.to_s + "\n"
        dm_attendance = dm_attendance + "遅刻 : " + delay.to_s  + "\n"
        dm_attendance = dm_attendance + "欠席 : " + absent.to_s + "\n"
        dm_attendance = dm_attendance + "ーーーーーーーーーーーー\n"
        if absent == 0 && delay == 0
          dm_attendance = dm_attendance + "現在無遅刻無欠席です！\n"
        elsif (absent + delay / 2) >= 3
          dm_attendance = dm_attendance + "出席状況にご注意ください\n"
        else
          dm_attendance = dm_attendance + "今日も頑張りましょう！\n"
        end

    end
    #出欠判定終了




    #運勢bot部分
    today_read_card = 0

    begin
      card_unsei_data_list = CSV.read("card_unsei_report.csv", encoding: "UTF-8")
    rescue
      card_unsei_data_list = [[],[]]
    end

    begin
      for k in 1..(card_unsei_data_list.flatten.count / 10) do
        if card_unsei_data_list[k][0] == read_time.strftime("%4Y/%2m/%2d") && card_unsei_data_list[k][2] == student_id
          today_read_card = 1
          today_score = card_unsei_data_list[k][3].to_i
          today_unsei = card_unsei_data_list[k][4]
          today_kane  = card_unsei_data_list[k][7]
          today_renai = card_unsei_data_list[k][8]
          today_shigoto = card_unsei_data_list[k][9]
          break
        end
      end
    rescue

    end

    if 1
      rank = 1
      if Time.now.wday == 0 || Time.now.wday == 6 #休日のとき
        hurry = read_time.strftime("%H:%M:%S") + "\n#よしもり神社"
      elsif Time.now <= Time.parse("08:50")
        left = Time.parse("08:50") - Time.now
        left = left.to_i / 60 - 1
        hurry = "1限開始まで"+ ketazoroe(left) + "分" + "\n#よしもり神社"
      elsif Time.now <= Time.parse("09:10")
        left = Time.now - Time.parse("08:50")
        left = left.to_i / 60
        hurry = "1限開始から約"+ ketazoroe(left) + "分経過" + "\n#よしもり神社"
      elsif Time.now <= Time.parse("10:30")
        left = Time.parse("10:30") - Time.now
        left = left.to_i / 60 - 1
        hurry = "2限開始まで約"+ ketazoroe(left) + "分" + "\n#よしもり神社"
      elsif Time.now <= Time.parse("11:00")
        left = Time.now - Time.parse("10:30")
        left = left.to_i / 60
        hurry = "2限開始から約"+ ketazoroe(left) + "分経過" + "\n#よしもり神社"
      else
        hurry = read_time.strftime("%H:%M:%S") + "\n#よしもり神社"
      end
      #運勢ポイント算出
      weather_result = ""
      unsei_point = rand(103)

      #if unsei_point < 30
      #  unsei_point = rand(103)
      #end

      if unsei_point > 100 && rand(5) != 0
        unsei_point = 100
      elsif unsei_point > 100 && rand(5) != 4
        unsei_point = 100 - rand(6)
      end


      #unsei_point1 = rand(101)
      #unsei_point2 = rand(101)
      #unsei_point3 = rand(101)
      #print("u1 = " ,unsei_point1,"; zu2= ",unsei_point2,"; zu3= ",unsei_point3,";\n")


      #unsei_point = ((unsei_point + unsei_point3) / 2.0).ceil


      if unsei_point >= 95
        unsei = "☆大吉"
        kane    = rand(2) + 5
        ren_ai  = rand(2) + 5
        shigoto = rand(2) + 5
      elsif unsei_point >= 80
        unsei = "大吉"
        kane    = rand(3) + 4
        ren_ai  = rand(3) + 4
        shigoto = rand(3) + 4
      elsif unsei_point >= 60
        unsei = "中吉"
        kane    = rand(4) + 3
        ren_ai  = rand(4) + 3
        shigoto = rand(4) + 3
      elsif unsei_point >= 40
        unsei = "小吉"
        kane    = rand(4) + 2
        ren_ai  = rand(4) + 2
        shigoto = rand(4) + 2
      elsif unsei_point >= 25
        unsei = "吉　"
        kane    = rand(3) + 2
        ren_ai  = rand(3) + 2
        shigoto = rand(3) + 2
      elsif unsei_point >= 12
        unsei = "末吉"
        kane    = rand(2) + 2
        ren_ai  = rand(2) + 2
        shigoto = rand(2) + 2
      elsif unsei_point >= 3
        unsei = "凶　"
        kane    = rand(3) + 1
        ren_ai  = rand(3) + 1
        shigoto = rand(3) + 1
      else
        unsei = "大凶"
        kane    = rand(2) + 1
        ren_ai  = 1
        shigoto = rand(2) + 1
      end
      unsei_limit =   Time.local(2017,12,25,0,0,0) - Time.now
      #unsei_limit_point = 23 -  unsei_limit / 86400
      plus_minus = - rand(2)
      kane = detail(unsei_point)
      ren_ai = detail(unsei_point) + plus_minus
      shigoto = detail(unsei_point)
      kenkou = detail(unsei_point)


      ## 条件の抽出　一定時間以内の投稿は認めない

      lucky_code  = rand(45)
      lucky_color = rand(13)

      shosai = "金運 " + kane.to_s + " 恋愛運 " + ren_ai.to_s + " 仕事運 " + shigoto.to_s + " 健康運 " +  kenkou.to_s
      unsei_data_list = CSV.read("../unsei_report.csv", encoding: "UTF-8")
      begin
        card_unsei_data_list = CSV.read("card_unsei_report.csv", encoding: "UTF-8")
      rescue
        card_unsei_data_list = [[],[]]
      end
      if card_unsei_data_list.flatten.include?(student_id)
        basho = card_unsei_data_list.flatten.rindex(student_id) / 10
      else
        basho = nil
      end
      #print("@" + twitter_id, " Location: ",basho,"\n")
      if ! basho.nil?
          previous_score = card_unsei_data_list[basho][3].to_i
          sa = unsei_point - previous_score
          previous_report = "(" + fugou(sa) +")"

      else
        previous_report = ""
      end
      if today_read_card == 0
        CSV.open('../unsei_report.csv','a') do |test|
         test << [read_time.strftime("%4Y/%2m/%2d"),read_time.strftime("%H:%M:%S.%L"),"カードリーダー",ketazoroe(unsei_point),unsei,item_ichiran[lucky_code],unsei_color[lucky_color],kane,ren_ai,shigoto]
        end
      else
        unsei_point = today_score
        unsei = today_unsei
        kane = today_kane.to_i
        ren_ai = today_renai.to_i
        shigoto = today_shigoto.to_i
        kenkou = detail(unsei_point)
        shosai = "金運 " + kane.to_s + " 恋愛運 " + ren_ai.to_s + " 仕事運 " + shigoto.to_s + " 健康運 " +  kenkou.to_s
        previous_report = ""
      end
      #履歴参照か


      if unsei_data_list.flatten.include?(Time.now.strftime("%4Y/%2m/%2d"))
        rireki = 1
        report = unsei_data_list.flatten.index(Time.now.strftime("%4Y/%2m/%2d")) / 10
        #print("AAAAA\n")
      else
        rireki = 0
        #print("BBBBB\n")
      end
      toukei_score = []

      unsei_datanum = unsei_data_list.flatten.count / 10
      #print("report = ",report,"rireki=",rireki,"data=",unsei_datanum,"\n")
      if(rireki == 1)
        people = unsei_datanum - report + 1
      else
        people = 1
      end
      if(rireki == 1)
        for j in report..unsei_datanum - 1 do
          toukei_score[j-report] = unsei_data_list[j][3].to_i
          if unsei_point < unsei_data_list[j][3].to_i
            rank += 1
          end
        end
      end
      if today_read_card == 0
        toukei_score.push(unsei_point)
      else
        people -= 1
      end
      averge = toukei_score.sum * 1.0 / toukei_score.count
      if(toukei_score.sd != 0)
        hensachi = (unsei_point - (toukei_score.sum * 1.0 / toukei_score.count)) / toukei_score.sd * 10 + 50
      else
        hensachi = 50.0
      end
      toukei_info = ("偏差値: " + sprintf("%.2f",hensachi) + " (平均: " + sprintf("%.2f",averge) +" 点)")

      today_toukei_score.push(unsei_point)


      #ninzu += 1
      omikuji_id = "\nNo. " + people.to_s + " (暫定 " + rank.to_s + "位)\n"
      #sum += unsei_point
      #print("bbb\n")

      jikoku = Time.now.strftime("%H:%M")
      #print('@'+twitter_id)
      hagemashi = ""
      #print("\n")
      #print(omikuji_id + "得点: " + unsei_point.to_s +  " 点 " + previous_report  + "　" + unsei + "\n" + toukei_info +  "\nLA: " + item_ichiran[lucky_code] + "\nLC: " + unsei_color[lucky_color] + "\n" + shosai + "\n" + hagemashi + "\n" + hurry + "\n")
      if today_read_card == 0
        CSV.open('card_unsei_report.csv','a') do |test|
          test << [read_time.strftime("%4Y/%2m/%2d"),read_time.strftime("%H:%M:%S.%L"),student_id,ketazoroe(unsei_point),unsei,item_ichiran[lucky_code],unsei_color[lucky_color],kane,ren_ai,shigoto]
        end
      end
      shutsuryoku = omikuji_id + "得点: " + unsei_point.to_s + " 点" +previous_report+ "　" + unsei + "\n" + toukei_info + "\nラッキーアイテム: " + item_ichiran[lucky_code] + "\nラッキーカラー: " + unsei_color[lucky_color] + "\n" + shosai + "\n" + hagemashi
    end
    #運勢bot終了



    puts "カード読み取り成功！"
    #print "\a"
    puts "\nーーーーーーーーーー☆カード情報☆ーーーーーーーーーーー"
    puts ("読取月日：" + read_time.strftime("%Y年%m月%d日\n"))
    puts ("読取時刻：" + read_time.strftime("%k:%M:%S.%L\n"))
    puts ("学籍番号：" + student_id)
    puts ("名前　　：" + full_name)
    puts ("学年　　：" + grade.to_s + "回生")
    puts ("学科　　：" + department)
    #puts ("運勢　　：" + unsei)
    #puts ("出席判定：" + attendance)
    puts ("Twit連携：" + twitter_id)
    puts "ーーーーーーーーーーーーーーーーーーーーーーーーーーーー\n"
    puts "学籍番号のことを学生番号と言う人もいます\n\n"


    puts "\nーーーーー☆運勢情報☆ーーーーーー"
    puts shutsuryoku
    puts "ーーーーーーーーーーーーーーーーーー\n\n"

    puts dm_attendance
    wsh = WIN32OLE.new('WScript.Shell')
    if absent == 0 && delay == 0
    #  Sound.play("b_046.wav")
    else
    #  Sound.play("readok1.wav")
    end
    wsh.Popup(full_name + " さん\n" + aisatsu + "\n" + dm_attendance, 0, "出席状況", 64)
  elsif card_code == 2 && count_line == 6257  #生協カードの場合
    seikyo_id_line = ""
    coop_id = ""
    meal_line = ""
    prepaid_line = ""
    out.each_line do |line|
      if line.include?("50CB:0000")
        #line.slice!("abc")
    #    puts line
        seikyo_id_line = line
      end
      if line.include?("50CB:0001")
    #    puts line
        meal_line = line
      end
      if line.include?("50CF:0000")
        prepaid_line = line
      end
    end
    puts
    read_time = Time.now
    seikyo_id_line.slice!("50CB:0000 ")
    seikyo_id_line.gsub!(" ","")
    coop_id = seikyo_id_line[0,12]
    meal_use = 0
    outdm = ""
    meal_line.slice!("50CB:0001 ")
    meal_line.gsub!(" ","")
    if meal_line[0..1] == "01"
      if meal_line[4..5] + "/" + meal_line[6..7] + "/" + meal_line[8..9] == read_time.strftime("%y/%m/%d")
        meal_use = meal_line[12,4].to_i
      else
        meal_use = 0
      end
      balance_1people_w = 1150 - meal_use
      balance_1people_h =  600 - meal_use
      balance_home      =  550 - meal_use
      outdm = outdm + "ーーーー☆ミール情報☆ーーーー\n"
      outdm = outdm + "平日残高　　：" + sprintf("%5d",balance_1people_w) + "円\n"
      puts "ーーーーーー☆ミール情報☆ーーーーーー"
      puts "今日の利用額：" + sprintf("%5d",meal_use) + "円"
      puts "平日残高　　：" + sprintf("%5d",balance_1people_w) + "円"
      if balance_1people_h >= 0
        puts "休日残高　　：" + sprintf("%5d",balance_1people_h) + "円"
        outdm = outdm + "休日残高　　：" + sprintf("%5d",balance_1people_h) + "円\n"
      end
      if balance_home      >= 0
        puts "自宅生残高　：" + sprintf("%5d",balance_home) + "円"
        outdm = outdm + "自宅生残高　：" + sprintf("%5d",balance_home) + "円\n"
      end
      print "ーーーーーーーーーーーーーーーーーーー\n\n"
      outdm = outdm + "ーーーーーーーーーーーーーーー\n\n"
    else
    end

    coop_id = seikyo_id_line[0,12]
    prepaid_line.slice!("50CF:0000 ")
    prepaid_line.gsub!(" ","")
    card_balance = prepaid_line[22,6].to_i
    puts "ーーーーーー☆プリペイド情報☆ーーーーーー"
    print "カード番号　　："  + coop_id + "\n"
    print "残高　　　　　： " + sprintf("%5d",card_balance) + "円\n"
    puts "ーーーーーーーーーーーーーーーーーーーーー\n\n"

    outdm = outdm + "ーーー☆プリペイド情報☆ーーー\n"
    outdm = outdm + "カード番号　　："  + coop_id + "\n"
    outdm = outdm + "残高　　　　　： " + sprintf("%5d",card_balance) + "円\n"
    outdm = outdm + "ーーーーーーーーーーーーーーー\n"
  #  Sound.play("readok2.wav")
  else #謎のカードの場合
    if card_code == 0
      puts "エラー！　学生証以外のカードが読み込まれました！"
    else
      puts "カード読み込み異常　しっかりとカードをタッチしてください"
    end
  #  Sound.play("error.wav")
  end

  sleep(1)
  out, err, status = Open3.capture3("FelicaDump.exe")
  print("カードを離してください\n")
  print("DM送信中…\n")
  begin
    if card_code != 0
      client.create_direct_message(myid1, outdm) #DM送信
    end
  rescue
    puts "DM送信エラー\n"
  end
  begin
    if today_read_card == 0
      client.create_direct_message(twitter_id, shutsuryoku)
    end
  rescue
    puts "DM送信エラー\n"
  end
  out, err, status = Open3.capture3("cls")
  if send_dm == 1
    begin
      client.create_direct_message(twitter_id, dm_attendance) #DM送信
      client2.update("学生証が読み込まれました。確認してください。")
    rescue
      puts "DM送信エラー\n"
    end
  end
  print "送信完了\n"

  i = status.exitstatus
  while i == 0
    #print "kokoOK"
    sleep(1)
    out, err, status = Open3.capture3("FelicaDump.exe")
    i = status.exitstatus.to_i
  end
  puts "\e[H\e[2J"
end
  #print out               #=> "a\n"
  #p err               #=> "bar\nbaz\nfoo\n"
  #p status.exitstatus #=> 0
