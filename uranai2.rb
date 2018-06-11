require 'twitter'
require 'time'
require 'rubygems'
require 'URI'
require "csv"
require 'weather-report'

# ログイン
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

client3 = Twitter::REST::Client.new do |config|
  config.consumer_key = ''
  config.consumer_secret = ''
  config.access_token = ''
  config.access_token_secret = ''
end

#ラッキーアイテム、運勢を設定（ここをいじると運勢が変わる）

item_ichiran = ["ボールペン", "化粧品", "扇子" , "シャーペン" , "鍵" , "腕時計" , "スマホ" , "ダークチョコレート" , "シャーペンの芯" , "充電器" , "オレンジジュース" , "酒" , "印鑑" , "タオル" , "バッグ" , "消しゴム" , "コンパス" , "トマトジュース" , "砂時計" , "ヘアスプレー" , "ぬいぐるみ" , "マカロン" , "ブックスタンド" , "本" , "ホッチキス" , "Lチキ"]
item_ichiran.push("りんご", "ファミチキ" , "電卓" , "牛乳" , "パンナコッタ" , "ミルクチョコレート" , "ホワイトチョコレート" , "電卓" , "ノート" , "教科書" , "スイカ" , "とんこつラーメン" , "醤油ラーメン","きびだんご","もみじ饅頭","ケーキ","チャーハン","チョコレート","かぼちゃ")
unsei_ichiran = ["大吉","中吉","小吉","吉","末吉","凶","大凶"]
unsei_color = ["白","黒","赤","青","緑","黄","オレンジ","ピンク","紫","茶","金","銀","虹"]

#TLの過去100ツイートをチェック。ネットワークがだめなら更新しない
begin
  #client.user_timeline(search_cc, { count: search } )
  mytl = client.home_timeline({ count: 100 })
rescue
  print("通信エラーが発生しました")
  mytl = []
end
hist = [] #過去のTL
people = 0 #ランキング出力
toukei_score = [] #その日の平均値を計算する専用配列
yushou = ""
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


#全角数字を半角に
def full_to_half(str)
  str.tr('０-９ａ-ｚＡ-Ｚ', '0-9a-zA-Z')
end

#その日の総合得点から金運とかの点数を出す。
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

#2桁とか1桁のときに数字をきれいにそろえる
def ketazoroe(num)
  if(num >= 100)
    return num.to_s
  elsif(num >= 10)
    return " " + num.to_s
  else
    return "  " + num.to_s
  end
end

#前回と比べて上昇したら＋,減少したら➖
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

#ツイートidからツイート時刻を割り出す
def tweet_id2time(id)
  case id
  when Integer
    Time.at(((id >> 22) + 1288834974657) / 1000.0)
  else
    nil
  end
end

#運勢からランクを出す。（現在未使用）
def kobetsu_unsei(rate)
  if(rate == 6)
    return "S"
  elsif(rate == 5)
    return "A"
  elsif(rate == 4)
    return "B"
  elsif(rate == 3)
    return "C"
  elsif(rate == 2)
    return "D"
  else
    return "E"
  end
end
#yasumi = (Time.parse("00:00") + 86310 - Time.now).to_i
#print(yasumi,"秒\n")
#sleep(yasumi)

#アカウント登録
myaccount = "@    " # @ + 自分のTwitterID
myid1 = "" # TwitterID
#アカウント登録おわり
today_toukei_score = []
ninzu = 0
sum = 0
max = -1
min = 105
final = 50000
execute_frag = 1
today_report_frag = 0

#実行時に連続実行回数を入れる
puts "実行回数を入力してください。"
jikkouyotei = gets.to_i

#実行予定回数を入れる
if jikkouyotei != 0
  final = jikkouyotei
end
print("予定実行回数 ", final," 回\n")
client.create_direct_message(myid1,"運勢起動をしました。\n予定実行回数は #{final.to_i} 回です。") #起動時に通知
unsei_data_list = CSV.read("unsei_report.csv", encoding: "UTF-8")
unsei_datanum = unsei_data_list.flatten.count / 10
if unsei_data_list.flatten.include?(Time.now.strftime("%4Y/%2m/%2d"))
  rireki = 1
  report = unsei_data_list.flatten.index(Time.now.strftime("%4Y/%2m/%2d")) / 10
  print("AAAAA\n")
else
  rireki = 0
  print("BBBBB\n")
end
if(rireki == 1)
  people = unsei_datanum - report
else
  people = 0
end
if(rireki == 1)
  for j in report..unsei_datanum - 1 do
    toukei_score[j-report] = unsei_data_list[j][3].to_i
    if max < unsei_data_list[j][3].to_i
      max = unsei_data_list[j][3].to_i
      yushou = "本日の最高得点者: " +  unsei_data_list[j][2]
    end
  end
end

for jikkou_kaisu in 1..final do
  print("占い処理実行中" , jikkou_kaisu , "回目 / ", final ," \n")
  update = mytl - hist
  num = update.length - 1

  num.downto(0) do |i|

    if  update[i].text.include?(myid1) #リプライ先がtoday_pi_bot
      hantei1 = update[i].text.include?("運") || update[i].text.include?("占") || update[i].text.include?("う") || update[i].text.include?("ウ")
      hantei2 = update[i].text.include?("運") || update[i].text.include?("占") || update[i].text.include?("ん") || update[i].text.include?("ン")
      hantei3 = update[i].text.include?("勢") || update[i].text.include?("い") || update[i].text.include?("せ") || update[i].text.include?("セ")
      hantei4 = update[i].text.include?("勢") || update[i].text.include?("命") || update[i].text.include?("い") || update[i].text.include?("イ") || update[i].text.include?("せ")
      #ここで返信するかどうかを決める。返信条件は複雑
      print(update[i].text,"\n")
      p(update[i].text.include?("サイコロ"))
      foreign = update[i].text.include?("운세") || update[i].text.include?("ortune") || update[i].text.include?("ORTUNE")
      if (hantei1 && hantei2 && (hantei3 || update[i].text.include?("命"))   && hantei4 && update[i].text.length <= 50 || update[i].text.include?("おみくじ") || update[i].text.include?("nsei")) || update[i].text.include?("ｳﾝｾｲ") || foreign
        rank = 1
        if Time.now.wday == 0 || Time.now.wday == 6 #休日のとき
          hurry = tweet_id2time(update[i].id).strftime("%H:%M:%S") + "\n#よしもり神社"
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
          hurry = tweet_id2time(update[i].id).strftime("%H:%M:%S") + "\n#よしもり神社"
        end
        #運勢ポイント算出
        location_list = CSV.read("island_location.csv", encoding: "UTF-8")
        if location_list.flatten.include?("@" + update[i].user.screen_name.to_s)
          basho = location_list.flatten.rindex('@' + update[i].user.screen_name.to_s) / 2
          place = location_list[basho][1]
          location = WeatherReport.get(place)
        else
          place = "飯塚"
          location = WeatherReport.get(place)
        end
        weather_result = ""
        unsei_point = rand(102)

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
        #締切とかで
        #unsei_limit =   Time.local(2017,12,25,0,0,0) - Time.now
        #unsei_limit_point = 23 -  unsei_limit / 86400
        kane = detail(unsei_point)
        ren_ai = detail(unsei_point)
        shigoto = detail(unsei_point)
        kenkou = detail(unsei_point)
        previous_day = "" #前回の運勢実施日

        if update[i].text.include?("karasuma1333") # もうないアカウント
          hagemashi = "IDの打ち間違いに注意！\n"
        elsif unsei_point >= 100
          hagemashi = unsei_point.to_s + "点だよ！\n" + weather_result
        elsif update[i].text.include?("明日") || update[i].text.include?("あした") || update[i].text.include?("omorrow") || update[i].text.include?("OMORROW")
          hagemashi = "明日もがんばって!!"
        elsif update[i].text.include?("明後日") || update[i].text.include?("あさって")
          hagemashi = "明後日はがんばって!!"
        else
          hagemashi = ""
        end
        ## 条件の抽出　一定時間以内の投稿は認めない

        lucky_code  = rand(45)
        lucky_color = rand(13)

        shosai = "金運 " + kane.to_s + " 恋愛運 " + ren_ai.to_s + " 仕事運 " + shigoto.to_s + " 健康運 " +  kenkou.to_s

        unsei_data_list = CSV.read("unsei_report.csv", encoding: "UTF-8")
        if unsei_data_list.flatten.include?("@" + update[i].user.screen_name.to_s)
          basho = unsei_data_list.flatten.rindex('@' + update[i].user.screen_name.to_s) / 10
        else
          basho = nil
        end
        print("@" + update[i].user.screen_name.to_s, " Location: ",basho,"\n")
        if ! basho.nil?
            if (Time.parse(unsei_data_list[basho][0] + " " + unsei_data_list[basho][1]) >= Time.now - 60*60*3 && Time.parse(unsei_data_list[basho][0]).day == Time.now.day) || (Time.now.day != tweet_id2time(update[i].id).day)
              next
            end
            previous_score = unsei_data_list[basho][3].to_i
            previous_day   = "前回の運勢: " + unsei_data_list[basho][0]
            sa = unsei_point - previous_score
            previous_report = "(" + fugou(sa) +")"

        else
          previous_report = ""
        end

        CSV.open('unsei_report.csv','a') do |test|
         test << [tweet_id2time(update[i].id).strftime("%4Y/%2m/%2d"),tweet_id2time(update[i].id).strftime("%H:%M:%S.%L"),'@'+ update[i].user.screen_name.to_s,ketazoroe(unsei_point),unsei,item_ichiran[lucky_code],unsei_color[lucky_color],kane,ren_ai,shigoto]
        end
        #ここから運勢の履歴を参照
        if unsei_data_list.flatten.include?(Time.now.strftime("%4Y/%2m/%2d"))
          rireki = 1
          report = unsei_data_list.flatten.index(Time.now.strftime("%4Y/%2m/%2d")) / 10
          print("AAAAA\n")
        else
          rireki = 0
          print("BBBBB\n")
        end
        toukei_score = []

        unsei_datanum = unsei_data_list.flatten.count / 10
        print("report = ",report,"rireki=",rireki,"data=",unsei_datanum,"\n")
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
            if max < unsei_data_list[j][3].to_i
              max = unsei_data_list[j][3].to_i
              yushou = "本日の最高得点者: " +  unsei_data_list[j][2]
            end
          end
        end
        print(yushou + "\n")
        toukei_score.push(unsei_point)

        averge = toukei_score.sum * 1.0 / toukei_score.count
        if(toukei_score.sd != 0)
          hensachi = (unsei_point - (toukei_score.sum * 1.0 / toukei_score.count)) / toukei_score.sd * 10 + 50
        else
          hensachi = 50.0
        end
        toukei_info = ("偏差値: " + sprintf("%.2f",hensachi) + " (平均: " + sprintf("%.2f",averge) +" 点)")

        today_toukei_score.push(unsei_point)

        #月の累計を計算
        unsei_data_list = CSV.read("unsei_report.csv", encoding: "UTF-8")
        sum_data = unsei_data_list.flatten.count / 10 - 1
        debt = 1
        while unsei_data_list.flatten.index("#{Time.now.year}/#{sprintf("%02d", Time.now.month)}/#{sprintf("%02d",debt)}").nil?
          debt += 1
        end
        first = unsei_data_list.flatten.index("#{Time.now.year}/#{sprintf("%02d", Time.now.month)}/#{sprintf("%02d",debt)}") / 10

        search = "@#{update[i].user.screen_name}"

        subpoint = 0
        read_frag = 1 #その日運勢やったか判定
        count = 0
        today_unseicount = 0
        total_unseipoint = 0
        add = ""
        if (1)
          add = "Lucky No: " + rand(10).to_s + "\n"
        end
        uranai_date = unsei_data_list[first][0]
        for lp in first..sum_data do
          if uranai_date != unsei_data_list[first][0]
            total_unseipoint += subpoint
            subpoint = 0
            read_frag = 1
          end
          if unsei_data_list[lp][2] == search
            if read_frag == 1
              count += 1
              read_frag = 0
            end
            if unsei_data_list[lp][3].to_i > subpoint
              subpoint = unsei_data_list[lp][3].to_i
            end
            uranai_date = unsei_data_list[lp][0]
            if "#{Time.now.year}/#{sprintf("%02d", Time.now.month)}/#{sprintf("%02d",Time.now.day)}" == unsei_data_list[lp][0]
              today_unseicount += 1
            end
          end
        end
        total_unseipoint += subpoint
        if today_unseicount >= 2
          previous_day = "本日運勢 " + today_unseicount.to_s + "回目"
        end
        month_rireki = Time.now.month.to_s + "月の合計点: " + total_unseipoint.to_s + "\n運勢 " + count.to_s  + "回\n" + previous_day + "\n" + add + "\n"
        #ここまで
        ninzu += 1
        omikuji_id = "\nNo. " + people.to_s + " (暫定 " + rank.to_s + "位)\n"
        sum += unsei_point
        #print("bbb\n")

        jikoku = Time.now.strftime("%H:%M")
        print('@'+update[i].user.screen_name.to_s)

        print("\n")
        print(omikuji_id + "得点: " + unsei_point.to_s +  " 点 " + previous_report  + "　" + unsei + "\n" + toukei_info +  "\nLA: " + item_ichiran[lucky_code] + "\nLC: " + unsei_color[lucky_color] + "\n" + shosai + "\n" + hagemashi + "\n" + hurry + "\n" + month_rireki)
        shutsuryoku = omikuji_id + "得点: " + unsei_point.to_s + " 点" +previous_report+ "　" + unsei + "\n" + toukei_info + "\nアイテム: " + item_ichiran[lucky_code] + "\nカラー: " + unsei_color[lucky_color] + "\n" + shosai + "\n" + hagemashi + "\n" + month_rireki
        if update[i].text.include?("yotsuba_rb1543")
          client2.favorite(update[i].id)
        else
          client.favorite(update[i].id)
        end

        if update[i].text.include?("詳細")
          unsei_point_detail = unsei_point + (rand(9) - 4) / 10.0
          shosai_data = "Score: " + sprintf("%.1f",unsei_point_detail) + " pts\n偏差値: " + sprintf("%.3f\n",hensachi)
          client.create_direct_message(update[i].user.screen_name,shosai_data + "\n" + "何か質問があればどうぞ\n")
        end

        begin
          if update[i].text.include?("yotsuba_rb1543")
            client2.update("@#{update[i].user.screen_name}" + shutsuryoku + "\n" + hurry ,in_reply_to_status_id: update[i].id)
          else
            client.update("@#{update[i].user.screen_name}" + shutsuryoku + "\n" + hurry ,in_reply_to_status_id: update[i].id)
          end

        rescue
          begin
            if update[i].text.include?("yotsuba_rb1543")
              client2.update("@#{update[i].user.screen_name}" + "送信時にエラーが発生しました。\nツイート主に連絡をお願いします。\n[エラーコード: 101]",in_reply_to_status_id: update[i].id)
              print("エラーが発生したのでDMで送信しています。")
              client2.create_direct_message(update[i].user.screen_name,"ツイートが140文字を超えたため、DMでお知らせします。\n" + shutsuryoku + "\n" + hurry)
            else
              client.update("@#{update[i].user.screen_name}" + "送信時にエラーが発生しました。\nツイート主に連絡をお願いします。\n[エラーコード: 101]",in_reply_to_status_id: update[i].id)
              print("エラーが発生したのでDMで送信しています。")
              client.create_direct_message(update[i].user.screen_name,"ツイートが140文字を超えたため、DMでお知らせします。\n" + shutsuryoku + "\n" + hurry)
            end
          rescue
            print("エラーが発生しています。DMの送信も出来ませんでした。")
          end
          #print("378")
        end
        #print("380")


    #運勢の履歴を出力
    elsif (update[i].text.include?("履歴") || update[i].text.include?("りれき") )
      print("383")
      rireki_list = CSV.read("unsei_rireki.csv", encoding: "UTF-8")
      if rireki_list.flatten.include?("@" + update[i].user.screen_name.to_s)
        basho = rireki_list.flatten.rindex('@' + update[i].user.screen_name.to_s) / 3
      else
        basho = nil
      end
      print("@" + update[i].user.screen_name.to_s, " Location: ",basho,"\n")
      #print(dice_report_list[basho][0],dice_report_list[basho][1],"\n")
      #jikan = dice_report_list[basho][0] + " " +
      #p(Time.parse(jikan),tweet_id2time(update[i].id))
      if ! basho.nil?
          if Time.parse(rireki_list[basho][0] + " " + rireki_list[basho][1]).strftime("%Y-%m-%d %H:%M:%S") == tweet_id2time(update[i].id).strftime("%Y-%m-%d %H:%M:%S")
            next
          end
      end

      client.favorite(update[i].id)
      #print("abc")
      score_string = ""
      count = 0
      unsei_data_list = CSV.read("unsei_report.csv", encoding: "UTF-8")
      score = 0
      kensaku = 30
      jissai = kensaku
      for past in 0..kensaku do

        if unsei_data_list.flatten.include?((Time.now - (kensaku-past)*86400).strftime("%4Y/%2m/%2d"))

          first = unsei_data_list.flatten.index((Time.now - (kensaku-past)*86400).strftime("%4Y/%2m/%2d")) / 10
          last  = unsei_data_list.flatten.rindex((Time.now - (kensaku-past)*86400).strftime("%4Y/%2m/%2d")) / 10
          #p(first,last)
          #shitei =  unsei_data_list.flatten.slice(first * 10, last * 10 -1)
          for location in (first)..(last) do

            #p(location,unsei_data_list[location][2])
            if unsei_data_list[location][2] == ('@' + update[i].user.screen_name.to_s)
              score_string = score_string + (Time.now - (kensaku-past)*86400).strftime("%2m月%2d日 : ") + unsei_data_list[location][3] + "点\n"
              score        += unsei_data_list[location][3].to_i
              count += 1
              break
            elsif location == last
              score_string = score_string + (Time.now - (kensaku-past)*86400).strftime("%2m月%2d日 : ") + " --" + "点\n"
            end
          end
        else
          jissai -= 1
        end
      end
      average = score * 1.0 / count
      kekka = update[i].user.name + " さん、こんにちは\n" + "運勢実施回数 " + count.to_s + " / " + jissai.to_s + " 回\n平均: " + sprintf("%.2f 点",average) + "\n詳細はDMをご覧ください。\n"
      print(kekka)
      client.update("@#{update[i].user.screen_name}" + kekka ,in_reply_to_status_id: update[i].id)
      print(score_string)
      client.create_direct_message(update[i].user.screen_name,update[i].user.name + "さんの\n過去30日間の点数\n" + score_string)
      CSV.open('unsei_rireki.csv','a') do |test|
        test << [tweet_id2time(update[i].id).strftime("%4Y/%2m/%2d"),tweet_id2time(update[i].id).strftime("%H:%M:%S.%L"),'@'+ update[i].user.screen_name.to_s]
      end
    elsif update[i].text.include?("食堂") && (update[i].text.include?("円") || update[i].text.include?("えん"))
      #大学の食堂のメニューから、指定された金額以内で選択できるメニューを検索する
      cafe_data_list = CSV.read("cafeteria_report.csv", encoding: "UTF-8")
      if cafe_data_list.flatten.include?("@" + update[i].user.screen_name.to_s)
        basho = cafe_data_list.flatten.rindex('@' + update[i].user.screen_name.to_s) / 11
      else
        basho = nil
      end
      print("@" + update[i].user.screen_name.to_s, " Location: ",basho,"\n")
      if ! basho.nil?
         #p(Time.parse(cafe_data_list[basho][0] + " " + cafe_data_list[basho][1]),tweet_id2time(update[i].id))
          if Time.parse(cafe_data_list[basho][0] + " " + cafe_data_list[basho][1]).strftime("%Y-%m-%d %H:%M:%S") == tweet_id2time(update[i].id).strftime("%Y-%m-%d %H:%M:%S")
            next
          end
      end


      client.favorite(update[i].id)
      soushin = update[i].user.screen_name
      soushin_id = update[i].id
      kensaku = update[i].text.dup
      kensaku = full_to_half(kensaku)
      kensaku.slice!(myaccount)


      cafeteria_menu_list = CSV.read("cafeteria_menu.csv", encoding: "UTF-8")
      # 省略したときにどのサイズになるかを判定。
      if kensaku.include?("小") || (soushin == '') || soushin == ''
        cap = 1
      elsif kensaku.include?("大")
        cap = 3
      elsif kensaku.include?("メガ")
        cap = 4
      else
        cap = 2
      end
      limit = kensaku.delete("^0-9").to_i
      # 40円以下のメニューはないのでエラー
      if limit < 41
          client.update("@#{soushin}" + "金額エラー[エラーコード:104]\n",in_reply_to_status_id: soushin_id)
          next
      end
      # 基本ルール　700円ごとに1品の主食を決め、さらにご飯系を追加。丼や麺類のときはご飯系は追加しない。
      # 端数は小鉢系の商品で埋めていく
      time_frag = 0
      frag = 0
      sum_menu = []
      total_count = 0
      total_cost    = 0
      total_kcal    = 0.0
      total_nacl     = 0.0
      total_red     = 0.0
      total_green   = 0.0
      total_yellow  = 0.0
      total_vege    = 0.0


      main_dish = limit / 700 + 1

      start1 = Time.now
      for k in 1..main_dish do
        if Time.now - start1 > 3
          break
        end
        left = limit - total_cost
        if limit < 185 || (left < 210 && Time.now >= Time.parse("14:05"))
          break
        end
        frag = 0
        if left < 210
          genre = 3
        elsif left < 268
          genre = 2 + rand(2)
        elsif left < 373
          genre = 2 + rand(3)
        else
          genre = rand(4) + 1
        end
        if genre == 3 && Time.now >= Time.parse("14:05")
          genre = 4
        end
        for hyou in 1..999 do
          if cafeteria_menu_list[hyou][0].to_i == genre && frag == 0
            first = hyou
            frag = 1
            #print(cafeteria_menu_list[hyou][0].to_i,"\n")
          elsif cafeteria_menu_list[hyou][0].to_i != genre && frag == 1
            last = hyou - 1
            #print("zako")
            break
          end
        end

        your_menu = Random.rand(first..last)
        while left - cafeteria_menu_list[your_menu][2].to_i < 0  do
          your_menu = Random.rand(first..last)
        end
        while cafeteria_menu_list[your_menu][9].to_i > cap && your_menu < last
          your_menu += 1
        end
        while cafeteria_menu_list[your_menu][9].to_i < cap && left - cafeteria_menu_list[your_menu-1][2].to_i >= 0 && your_menu > first
          your_menu -= 1
        end
        sum_menu.push(cafeteria_menu_list[your_menu][1])
        total_cost += cafeteria_menu_list[your_menu][2].to_i
        total_kcal += cafeteria_menu_list[your_menu][3].to_f
        total_nacl += cafeteria_menu_list[your_menu][4].to_f
        total_red += cafeteria_menu_list[your_menu][5].to_f
        total_green += cafeteria_menu_list[your_menu][6].to_f
        total_yellow += cafeteria_menu_list[your_menu][7].to_f
        total_vege += cafeteria_menu_list[your_menu][8].to_f
        total_count += 1
        frag = 0
        if genre == 4
          for hyou in 1..999 do
            if cafeteria_menu_list[hyou][0].to_i == 5 && frag == 0
              first = hyou
              frag = 1
              print(cafeteria_menu_list[hyou][0].to_i,"\n")
            elsif cafeteria_menu_list[hyou][0].to_i != 5 && frag == 1
              last = hyou - 1
              #print("zako")
              break
            end
          #  print(first,last,"\n")
          end
        #  print(first,last,"\n")
          your_menu = Random.rand(first..last)
          while left - cafeteria_menu_list[your_menu][2].to_i < 0  do
            your_menu = Random.rand(first..last)
          end
          while cafeteria_menu_list[your_menu][9].to_i > cap && your_menu < last
            your_menu += 1
          end
          while cafeteria_menu_list[your_menu][9].to_i < cap && cap != 1 && left - cafeteria_menu_list[your_menu-1][2].to_i >= 0 && your_menu > first
            your_menu -= 1
          end
          sum_menu.push(cafeteria_menu_list[your_menu][1])
          total_cost += cafeteria_menu_list[your_menu][2].to_i
          total_kcal += cafeteria_menu_list[your_menu][3].to_f
          total_nacl += cafeteria_menu_list[your_menu][4].to_f
          total_red += cafeteria_menu_list[your_menu][5].to_f
          total_green += cafeteria_menu_list[your_menu][6].to_f
          total_yellow += cafeteria_menu_list[your_menu][7].to_f
          total_vege += cafeteria_menu_list[your_menu][8].to_f
          total_count += 1
        end
      end

      start2 = Time.now
      left = limit - total_cost
      while left >= 49  do
        if Time.now - start2 > 3
          time_frag = 1
          break
        end
        if left >= 147
            genre = 6 + rand(5)
            if left < 206 && genre == 9
              genre = 7
            end
        elsif left >= 78
          genre = 7 + rand(2)
        else
          genre = 8
        end
        frag = 0
        hyou2 = 1
        for hyou2 in 1..999 do
          if cafeteria_menu_list[hyou2][0].to_i == genre && frag == 0
            print("err","\n")
            first = hyou2
            frag = 1
            print(cafeteria_menu_list[hyou2][0].to_i,"\n")
          elsif cafeteria_menu_list[hyou2][0].to_i != genre && frag == 1
            print("bug","\n")
            last = hyou2 - 1
            #print("zako")
            break
          end
        end
        print("left = ",first," right = ",last,"\n")
        your_menu2 = Random.rand(first..last)
        sum_menu.push(cafeteria_menu_list[your_menu2][1])
        total_cost += cafeteria_menu_list[your_menu2][2].to_i
        total_kcal += cafeteria_menu_list[your_menu2][3].to_f
        total_nacl += cafeteria_menu_list[your_menu2][4].to_f
        total_red += cafeteria_menu_list[your_menu2][5].to_f
        total_green += cafeteria_menu_list[your_menu2][6].to_f
        total_yellow += cafeteria_menu_list[your_menu2][7].to_f
        total_vege += cafeteria_menu_list[your_menu2][8].to_f
        total_count += 1
        left = limit - total_cost
        print("残り " , left ,"円\n")
      end

      if left >= 41 #味噌汁が最安の商品なので困ったら味噌汁で埋める
        sum_menu.push("味噌汁")
        total_cost += 41
        total_kcal += 50
        total_nacl += 1.0
        total_red += 0.0
        total_green += 0.1
        total_yellow += 0.3
        total_vege += 10
        left = limit - total_cost
        total_count += 1
      end

      if time_frag == 1
        kakeru = limit * 1.0 / total_cost
        p(kakeru)
        total_cost = (total_cost * kakeru).to_i
        total_kcal *= kakeru
        total_nacl *= kakeru
        total_red *= kakeru
        total_green *= kakeru
        total_yellow *= kakeru
        total_vege *= kakeru
        total_count = (total_count * kakeru).to_i
        left = limit - total_cost
      end
      if total_cost >= 160000
        sum_menu = ["省略"]
      end

      out = "メニュー: " + sum_menu.join(',') + "\n値段: " + total_cost.to_s + "円\n" + sprintf("%.1f",total_kcal) + "kcal　NaCl: " + sprintf("%.1f",total_nacl) + "g　" + total_count.to_s + "品\n"
      out = out + "赤: " + sprintf("%.1f",total_red) + + "　緑: " + sprintf("%.1f",total_green) +  "　黄: " + sprintf("%.1f",total_yellow) + "\n野菜: "  + sprintf("%.1fg",total_vege)
      if out.length >= 125 && total_cost >= 160000
        out = "値段: " + sprintf("%.3e",total_cost) + "円\n" + sprintf("%.3e",total_kcal) + "kcal　塩: " + sprintf("%.3e",total_nacl) + "g　" + sprintf("%.3e",total_count) + "品\n"
        out = out + "赤: " + sprintf("%.3e",total_red) + + "　緑: " + sprintf("%.3e",total_green) +  "　黄: " + sprintf("%.3e",total_yellow) + "\n野菜: "  + sprintf("%.3eg\n",total_vege)
        out = out + "※e+xは10のx乗"
      end
      out2 = "値段: " + total_cost.to_s + "円\n" + sprintf("%.1f",total_kcal) + "kcal　塩: " + sprintf("%.1f",total_nacl) + "g　" + total_count.to_s + "品\n"
      out2 = out2 + "赤: " + sprintf("%.1f",total_red) + + "　緑: " + sprintf("%.1f",total_green) +  "　黄: " + sprintf("%.1f",total_yellow) + "\n野菜: "  + sprintf("%.1fg",total_vege)
      begin
        client.update("@#{soushin}" + out,in_reply_to_status_id: soushin_id)
      rescue

        begin
            client.update("@#{soushin}" + "文字数オーバー\nDMを確認してください。\n" + out2,in_reply_to_status_id: soushin_id)
          client.create_direct_message(soushin,"文字数オーバーによりこちらでお知らせします\n" + out)
        rescue
          client.create_direct_message(soushin,"大変申し訳ございません。\n深刻なエラーが発生しました。\nツイート主に報告してください。")
        end
      end
      print(out)
      CSV.open('cafeteria_report.csv','a') do |rep|
       rep << [tweet_id2time(soushin_id).strftime("%4Y/%2m/%2d"),tweet_id2time(soushin_id).strftime("%H:%M:%S.%L"),'@'+ soushin.to_s,total_cost,sprintf("%.1f",total_kcal),sprintf("%.1f",total_nacl),total_count,sprintf("%.1f",total_red),sprintf("%.1f",total_green),sprintf("%.1f",total_yellow), sprintf("%.1f",total_vege)]
      end

    elsif (update[i].text.include?("サイコロ") || update[i].text.include?("さいころ"))
      # ただサイコロを振るbot。正直使いみちがない
      soushin = update[i].user.screen_name
      soushin_id = update[i].id
      dice_report_list = CSV.read("dice_report.csv", encoding: "UTF-8")
      if dice_report_list.flatten.include?("@" + update[i].user.screen_name.to_s)
        basho = dice_report_list.flatten.rindex('@' + update[i].user.screen_name.to_s) / 7
      else
        basho = nil
      end
      print("@" + update[i].user.screen_name.to_s, " Location: ",basho,"\n")
      #print(dice_report_list[basho][0],dice_report_list[basho][1],"\n")
      #jikan = dice_report_list[basho][0] + " " +
      #p(Time.parse(jikan),tweet_id2time(update[i].id))
      if ! basho.nil?
          if Time.parse(dice_report_list[basho][0] + " " + dice_report_list[basho][1]).strftime("%Y-%m-%d %H:%M:%S") == tweet_id2time(soushin_id).strftime("%Y-%m-%d %H:%M:%S")
            next
          end
      end
      client.favorite(update[i].id)

      b = update[i].text.dup
      a = b
      b = full_to_half(b)
      a.slice!("サイコロ")
      a.slice!("さいころ")
      a.slice!(myaccount)
      a.delete!("　")
      a.delete!(" ")
      print(a,"\n")
      sum = 0
      #print("送信先: " + soushin)
      quantity = a.to_i
      data = []
      rireki = []
      p(quantity)
      if a.include?("d") || a.include?("D")
        if quantity >= 1
          delete = Math.log10(quantity)
        end
        a.slice!("d")
        a.slice!("D")
        print(a + "\n")
        if quantity >= 1
          a.slice!(0,delete.floor + 1)
        end
        print(a + "\n")
        if quantity >= 1
          range = a.to_i
        end
      else
        client.create_direct_message(soushin,"dを省略しているので出目の範囲を1～6としています")
        range = 6
      end

      if (quantity <= 0 || range <= 0 || quantity >= 12000 || range >= 12000)

        client.update("@#{soushin}" + "引数エラー[エラーコード:102]\nサイコロの数と範囲は1以上10000以下で指定してください",in_reply_to_status_id: soushin_id)
        next
      end
      for i in 1..quantity do
        result = rand(range) + 1
        rireki.push(result)
        sum += result
      end
      for i in 1..range do
        data.push(i)
      end
      tweet = ""
      average = data.mean * quantity
      output_result = "結果: " + rireki.join(", ") + "\n"
      if output_result.length <= 40
        tweet = output_result
      elsif output_result.length <= 2000
        client.create_direct_message(soushin,"出力数が多いのでDMでお知らせします\n" + output_result)
      else
        client.create_direct_message(soushin,"出力数が多すぎるので出目の詳細結果を省略します")
      end
      stdevp = (data.var * quantity)**(1.0/2)
      hensachi = (sum - average) / stdevp * 10.0 + 50
      #seiki = 1.0 / ((2 * Math::PI)**(1.0/2) * stdevp) * Math.exp((-(sum - data.mean)**(2))/(2 * stdevp**(2)))
      tweet = "個数: " + quantity.to_s + "　範囲: " + range.to_s + "\n" + tweet + "出目: " + sum.to_s  + "\n期待値: " + sprintf("%.2f",average)  + " 標準偏差: " + sprintf("%.2f",stdevp) + "\n偏差値: " + sprintf("%.2f\n",hensachi)
      print(tweet)
      client.update("@#{soushin}" + tweet,in_reply_to_status_id: soushin_id)
      CSV.open('dice_report.csv','a') do |rep|
       rep << [tweet_id2time(soushin_id).strftime("%4Y/%2m/%2d"),tweet_id2time(soushin_id).strftime("%H:%M:%S.%L"),'@'+ soushin.to_s,quantity,range,sum,sprintf("%.2f",hensachi)]
      end

    elsif update[i].text.include?("222模") && update[i].text.include?("店341241")
        # 大学の模擬店で、決められた金額以内から商品を選んでくるbot　食堂botの亜種
        # 現在はコマンドが判定されないようにしている
        client.favorite(update[i].id)
        mogi_rireki_list = CSV.read("mogi_rireki.csv", encoding: "UTF-8")
        if mogi_rireki_list.flatten.include?("@" + update[i].user.screen_name.to_s)
          basho = mogi_rireki_list.flatten.rindex('@' + update[i].user.screen_name.to_s) / 3
        else
          basho = nil
        end
        print("@" + update[i].user.screen_name.to_s, " Location: ",basho,"\n")
        #print(dice_report_list[basho][0],dice_report_list[basho][1],"\n")
        #jikan = dice_report_list[basho][0] + " " +
        #p(Time.parse(jikan),tweet_id2time(update[i].id))
        if ! basho.nil?
            if Time.parse(mogi_rireki_list[basho][0] + " " + mogi_rireki_list[basho][1]).strftime("%Y-%m-%d %H:%M:%S") == tweet_id2time(update[i].id).strftime("%Y-%m-%d %H:%M:%S")
              next
            end
        end
        soushin = update[i].user.screen_name
        frag = 0
        product_quantity = 0
        sum_quantity = 0
        sum_cost = 0
        limit = 0
        sum_out = ""
        soushin_id = update[i].id
        kensaku = update[i].text.dup
        kensaku = full_to_half(kensaku)
        kensaku.slice!(myaccount)
        if kensaku.include?("円")
          limit = kensaku.delete("^0-9").to_i
        elsif (kensaku.delete("^0-9").to_i <= 0)
          product_quantity = 1
        else
          product_quantity = kensaku.delete("^0-9").to_i
        end
        if (product_quantity >= 450 || limit >= 125000)
          client.update("@#{update[i].user.screen_name}" + "大変もうしわけございません。\n引数の入力が間違えているか上限値をオーバーしています。\n確認の上、再度リプを送ってください。\n" ,in_reply_to_status_id: update[i].id)
          CSV.open('mogi_rireki.csv','a') do |test|
            test << [tweet_id2time(update[i].id).strftime("%4Y/%2m/%2d"),tweet_id2time(update[i].id).strftime("%H:%M:%S.%L"),'@'+ update[i].user.screen_name.to_s]
          end
            next
        end

        mogi_menu_list = CSV.read("mogi_menu.csv", encoding: "UTF-8")

        while (product_quantity >= 1 || (limit >= 1 && kensaku.include?("円")))
          frag = 0
          shouhin_id = rand(32) + 1
          print("shouhinid ",shouhin_id,"\n")
          while shouhin_id == 22 || shouhin_id == 23 || shouhin_id == 27 do
            shouhin_id = rand(32) + 1
          end
          for hyou in 1..70 do
            if mogi_menu_list[hyou][0].to_i == shouhin_id && frag == 0
              first = hyou
              frag = 1
              #print(mogi_menu_list[hyou][0].to_i,"\n")
            elsif mogi_menu_list[hyou][0].to_i != shouhin_id && frag == 1
              last = hyou - 1
              #print("zako")
              break
            end
          end
          your_menu = Random.rand(first..last)
          out = mogi_menu_list[your_menu][1] + "(" + mogi_menu_list[your_menu][2] + ")　"  + mogi_menu_list[your_menu][4] + "円\n"
          sum_quantity += 1
          sum_cost += mogi_menu_list[your_menu][4].to_i
          sum_out = sum_out + out
          if kensaku.include?("円")
            limit -= mogi_menu_list[your_menu][4].to_i
          else
            product_quantity -= 1
          end
        end
        print(out)
        info = sum_quantity.to_s + "品　" + sum_cost.to_s + "円\n"
        print(info)
        begin
          client.update("@#{update[i].user.screen_name}" + sum_out + info +"#kit_festa_i\n" ,in_reply_to_status_id: update[i].id)
        rescue
          client.create_direct_message(update[i].user.screen_name,"文字数オーバーにより検索結果をこちらに表示します。\n" + sum_out + info)
          client.update("@#{update[i].user.screen_name}" + "文字数オーバーのため、結果をDMに送信しました。確認してください。\n" + info + "#kit_festa_i\n",in_reply_to_status_id: update[i].id)
        end
        CSV.open('mogi_rireki.csv','a') do |test|
          test << [tweet_id2time(update[i].id).strftime("%4Y/%2m/%2d"),tweet_id2time(update[i].id).strftime("%H:%M:%S.%L"),'@'+ update[i].user.screen_name.to_s]
        end
      elsif update[i].text.include?("お年玉") &&  (update[i].text.include?("ガチャ") || update[i].text.include?("ガシャ") )
        # お年玉ガチャ　おまけ
          otoshidama_rireki_list = [[],[]]
          begin
            otoshidama_rireki_list = CSV.read("otoshidama.csv", encoding: "UTF-8")
          rescue
            otoshidama_rireki_list = [[],[]]
            puts "otoshidamaのリストがありません"
          end
          if otoshidama_rireki_list.flatten.include?("@" + update[i].user.screen_name.to_s)
            basho = otoshidama_rireki_list.flatten.rindex('@' + update[i].user.screen_name.to_s) / 4
          else
            basho = nil
          end
          print("@" + update[i].user.screen_name.to_s, " Location: ",basho,"\n")
          #print(dice_report_list[basho][0],dice_report_list[basho][1],"\n")
          #jikan = dice_report_list[basho][0] + " " +
          #p(Time.parse(jikan),tweet_id2time(update[i].id))
          begin
            if ! basho.nil?
                if Time.parse(otoshidama_rireki_list[basho][0] + " " + otoshidama_rireki_list([basho][1]).strftime("%Y-%m-%d %H:%M:%S") == tweet_id2time(update[i].id).strftime("%Y-%m-%d %H:%M:%S"))
                  next
                end
            end
          rescue
            next
            puts "エラー\n"
          end
          total = 0
          output = "☆2018年お年玉11連ガチャ☆\n"
          ur  = 0
          ssr = 0
          sr  = 0
          r   = 0
          for k in 1..11 do
            unsei = rand(10000) + 1 # 1 - 10000 の範囲の乱数を出す
            p unsei
            if unsei >= 9900 # UR 1% 9900 - 10000
              total += 10000
              ur    += 1
            elsif unsei >= 9500 # SSR 4% 9500 - 9899
              total += 5000
              ssr   += 1
            elsif unsei >= 8000 # SR 15% 8000 - 9499
              total += 1000
              sr    += 1
            else  # R  0 - 7999
              total += 100
              r     += 1
            end
          end
          output = output + "UR :" + sprintf("%2d枚",ur) + "×10000＝" + sprintf("%5d円\n",ur*10000)
          output = output + "SSR:" + sprintf("%2d枚",ssr)+ "× 5000＝" + sprintf("%5d円\n",ssr*5000)
          output = output + "SR :" + sprintf("%2d枚",sr) +"× 1000＝" + sprintf("%5d円\n",sr*1000)
          output = output + "R  :" + sprintf("%2d枚",r) +"×  100＝" + sprintf("%5d円\n",r*100)
          average = 5300
          stdevp  = 13700.7
          hensachi = (total - 5300) / stdevp * 10.0 + 50.0
          output = output + "合計　:" + sprintf("%5d",total) + "円！\n"
          output = output + "偏差値: " +  sprintf("%.2f\n",hensachi)
          print(output)

          begin
            client.update("@#{update[i].user.screen_name}" + output ,in_reply_to_status_id: update[i].id)
            client.favorite(update[i].id)
          rescue
            client.create_direct_message(update[i].user.screen_name,"文字数オーバーにより検索結果をこちらに表示します。\n" + output)
            client.update("@#{update[i].user.screen_name}" + "文字数オーバーのため、結果をDMに送信しました。確認してください。\n" + output + "合計　:" + sprintf("%5d",total) + "円！\n",in_reply_to_status_id: update[i].id)
          end

          CSV.open('otoshidama.csv','a') do |test|
            test << [tweet_id2time(update[i].id).strftime("%4Y/%2m/%2d"),tweet_id2time(update[i].id).strftime("%H:%M:%S.%L"),'@'+ update[i].user.screen_name.to_s,total]
          end

        end
              #print("382")




    end #リプの終わり
    #print("384")
  end
  hist = mytl
  if jikkou_kaisu % 20 == 0
    execute_frag = 1
    today_report_frag = 1
    hist = []
  end

  # 一定時間ごとに天気予報を表示。福岡県民なので福岡系のものが多い。
  uranai_hour = (Time.now.hour == 0 || Time.now.hour == 5 || Time.now.hour == 9 || Time.now.hour == 12 || Time.now.hour == 18)
  if (uranai_hour && Time.now.min == 0 && execute_frag == 1) || jikkou_kaisu == 2
    fukuoka_weather = ""
    if Time.parse("15:00") >= Time.now
      location = WeatherReport.get("飯塚")
      fukuoka_weather = fukuoka_weather + "\n今日の天気\n" + "飯塚　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃ / " + location.today.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("福岡")
      fukuoka_weather = fukuoka_weather + "福岡　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃ / " + location.today.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("八幡")
      fukuoka_weather = fukuoka_weather + "北九州 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃ / " + location.today.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("久留米")
      fukuoka_weather = fukuoka_weather + "久留米 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃ / " + location.today.temperature_min.to_s + "℃\n"
      koudaisai_limit =   Time.local(2017,11,18,9,0,0) - Time.now
      koudaisai_limit_day = koudaisai_limit / 86400
      fukuoka_weather = fukuoka_weather + ""
      if Time.parse("05:00") <= Time.now && Time.parse("15:00") >= Time.now
        fukuoka_weather = ""
        location = WeatherReport.get("飯塚")
        fukuoka_weather = fukuoka_weather + "\n今日の天気\n" + "飯塚　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃\n"
        location = WeatherReport.get("福岡")
        fukuoka_weather = fukuoka_weather + "福岡　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃\n"
        location = WeatherReport.get("八幡")
        fukuoka_weather = fukuoka_weather + "北九州 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃\n"
        location = WeatherReport.get("久留米")
        fukuoka_weather = fukuoka_weather + "久留米 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃\n"
        koudaisai_limit =   Time.local(2018,7,14,9,0,0) - Time.now
        koudaisai_limit_day = koudaisai_limit / 86400
        fukuoka_weather = fukuoka_weather + "ｵｰﾌﾟﾝｷｬﾝﾊﾟｽまであと " + koudaisai_limit_day.to_i.to_s + " 日\n"
      else

      end
    else
      location = WeatherReport.get("飯塚")
      fukuoka_weather = fukuoka_weather + "\n明日の天気\n" + "飯塚　 " +  location.tomorrow.telop + " " + location.tomorrow.temperature_max.to_s + "℃ / " + location.tomorrow.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("福岡")
      fukuoka_weather = fukuoka_weather + "福岡　 " +  location.tomorrow.telop + " " + location.tomorrow.temperature_max.to_s + "℃ / " + location.tomorrow.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("八幡")
      fukuoka_weather = fukuoka_weather + "北九州 " +  location.tomorrow.telop + " " + location.tomorrow.temperature_max.to_s + "℃ / " + location.tomorrow.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("久留米")
      fukuoka_weather = fukuoka_weather + "久留米 " +  location.tomorrow.telop + " " + location.tomorrow.temperature_max.to_s + "℃ / " + location.tomorrow.temperature_min.to_s + "℃\n"
    end

    client.update("運勢,食堂,サイコロbot起動中\n現在時刻: " + Time.now.strftime("%H時%M分\n") + fukuoka_weather )
    execute_frag == 0
  end

  if ((Time.now.hour == 10) && Time.now.min == 0 && execute_frag == 1)
    fukuoka_weather = ""
    if Time.parse("15:00") >= Time.now
      location = WeatherReport.get("飯塚")
      fukuoka_weather = fukuoka_weather + "\n今日の天気\n" + "飯塚　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃ / " + location.today.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("広島")
      fukuoka_weather = fukuoka_weather + "広島　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃ / " + location.today.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("大阪")
      fukuoka_weather = fukuoka_weather + "大阪　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃ / " + location.today.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("東京")
      fukuoka_weather = fukuoka_weather + "東京　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃ / " + location.today.temperature_min.to_s + "℃\n"
      koudaisai_limit =   Time.local(2019,1,1,0,0,0) - Time.now
      koudaisai_limit_day = koudaisai_limit / 86400
      fukuoka_weather = fukuoka_weather + "今年はあと " + koudaisai_limit_day.to_i.to_s + " 日\n"
      if Time.parse("05:00") <= Time.now && Time.parse("15:00") >= Time.now
        fukuoka_weather = ""
        location = WeatherReport.get("飯塚")
        fukuoka_weather = fukuoka_weather + "\n今日の天気\n" + "飯塚　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃\n"
        location = WeatherReport.get("広島")
        fukuoka_weather = fukuoka_weather + "広島　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃\n"
        location = WeatherReport.get("大阪")
        fukuoka_weather = fukuoka_weather + "大阪　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃\n"
        location = WeatherReport.get("東京")
        fukuoka_weather = fukuoka_weather + "東京　 " +  location.today.telop + " " + location.today.temperature_max.to_s + "℃\n"
        koudaisai_limit =   Time.local(2019,1,1,0,0,0) - Time.now
        koudaisai_limit_day = koudaisai_limit / 86400
        fukuoka_weather = fukuoka_weather + "今年はあと " + koudaisai_limit_day.to_i.to_s + " 日\n"
      else

      end
    else
      location = WeatherReport.get("飯塚")
      fukuoka_weather = fukuoka_weather + "\n明日の天気\n" + "飯塚　 " +  location.tomorrow.telop + " " + location.tomorrow.temperature_max.to_s + "℃ / " + location.tomorrow.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("広島")
      fukuoka_weather = fukuoka_weather + "広島　 " +  location.tomorrow.telop + " " + location.tomorrow.temperature_max.to_s + "℃ / " + location.tomorrow.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("大阪")
      fukuoka_weather = fukuoka_weather + "大阪　 " +  location.tomorrow.telop + " " + location.tomorrow.temperature_max.to_s + "℃ / " + location.tomorrow.temperature_min.to_s + "℃\n"
      location = WeatherReport.get("東京")
      fukuoka_weather = fukuoka_weather + "東京　 " +  location.tomorrow.telop + " " + location.tomorrow.temperature_max.to_s + "℃ / " + location.tomorrow.temperature_min.to_s + "℃\n"
    end
    execute_frag == 0
    client2.update("こちらでも運勢botを起動しています。\n現在時刻: " + Time.now.strftime("%H時%M分\n") + fukuoka_weather)
  end




  if jikkou_kaisu != final
    for wait in 0..5
      print("待機中 あと",30 - wait * 5 , "秒 , ")
      sleep(5)
    end
    print("\n")
    begin
      if jikkou_kaisu % 3 == 0
        mytl = client.home_timeline({ count: 100 })
      elsif jikkou_kaisu % 3 == 1
        mytl = client2.home_timeline
      else
        mytl = client3.home_timeline
      end
    rescue
      print("通信エラーです\n")
    end
  end

  #自動集計
  if Time.now.hour == 23 && Time.now.min == 59 && today_report_frag == 1
    p(toukei_score)

    range = toukei_score.count / 70 + 1
    enc = "得点分布図(1の位四捨五入) " + "※*は" + range.to_s + "人　合計: " + people.to_s + " 人\n" + "#よしもり神社\n"
    for d in 0..10 do
      youso = toukei_score.select{ |n| n >= (10 - d) * 10 - 5 && n < (10 - d + 1) * 10 - 5}.count
      enc = enc + sprintf("%3d ",(10 - d) * 10)
      for no in 1..(youso / range) do
        enc = enc + "*"
      end
    enc = enc + "\n"
    end

    average = sum * 1.0 / people
    if people >= 1
      sogo_info = "統計データ\n最高　" + ketazoroe(toukei_score.max) + "点　最低　" + ketazoroe(toukei_score.min) + "点　\n平均　" + sprintf("%.2f",toukei_score.mean) + "点" + " 標準偏差　" + sprintf("%6.2f",toukei_score.sd) + "点\n" + "#よしもり神社\n" + yushou
    else
      sogo_info = ""
    end
    print(Time.now.strftime("%m月%d日 (%a) の運勢結果") + "\n" + sogo_info + "\n")
    print(enc)
    begin
      client.update(Time.now.strftime("%m月%d日 (%a) の運勢結果") +"\n" + sogo_info)
      client.update(enc)
    rescue
      begin
        client.update("出力エラーが発生しました\n")
      rescue
        print("出力エラーが発生しました\n")
      end
    end
    today_report_frag = 0
    ninzu = 0
    sum = 0
    max = -1
    min = 105
  end


end

p(toukei_score)

range = toukei_score.count / 70 + 1
enc = "得点分布図(1の位四捨五入) " + "※*は" + range.to_s + "人　合計: " + people.to_s + " 人\n" + "#よしもり神社\n"
for d in 0..10 do
  youso = toukei_score.select{ |n| n >= (10 - d) * 10 - 5 && n < (10 - d + 1) * 10 - 5}.count
  enc = enc + sprintf("%3d ",(10 - d) * 10)
  for no in 1..(youso / range) do
    enc = enc + "*"
  end
enc = enc + "\n"
end

average = sum * 1.0 / people
if people >= 1
  sogo_info = "統計データ\n最高 " + ketazoroe(toukei_score.max) + "点　最低 " + ketazoroe(toukei_score.min) + "点　\n平均 " + sprintf("%.2f",toukei_score.mean) + "点" + " 標準偏差 " + sprintf("%6.2f",toukei_score.sd) + "点\n" + "#よしもり神社\n" + yushou
else
  sogo_info = ""
end
print("自動占い受付終了\n" + sogo_info + "\n")
print(enc)
#client.update("自動占い受付終了\n" + sogo_info)
#client.update(enc)
