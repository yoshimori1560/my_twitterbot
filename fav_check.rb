=begin

=end

require "twitter"
require "open3"
require "time"
require "csv"



# ツイートIDから時刻演算
def tweet_id2time(id)
  case id
  when Integer
    Time.at(((id >> 22) + 1288834974657) / 1000.0)
  else
    nil
  end
end
# Consumer key, Secretの設定
CONSUMER_KEY     = ''
CONSUMER_SECRET  = ''
# Access Token Key, Secretの設定
ACCESS_TOKEN_KEY = ''
ACCESS_SECRET    = ''



client = Twitter::REST::Client.new do |config|
    config.consumer_key       = CONSUMER_KEY
    config.consumer_secret    = CONSUMER_SECRET
    config.access_token        = ACCESS_TOKEN_KEY
    config.access_token_secret = ACCESS_SECRET
end

stream_client = Twitter::Streaming::Client.new do |config|
    config.consumer_key        = CONSUMER_KEY
    config.consumer_secret     = CONSUMER_SECRET
    config.access_token        = ACCESS_TOKEN_KEY
    config.access_token_secret = ACCESS_SECRET
end

shori_list_name = []
shori_list_id   = []
shori_list_name2 = []
shori_list_id2   = []
tweet_text = []
shori_naiyou = []
shori_screen_name = ""
shori_id = ""
wait_time = Time.now
lag = 0
#
# userstreamを表示する
cnt = 0
account1 = 0
account2 = 0
account3 = 0
account4 = 0
account5 = 0
error_time = Time.now
today_check = Time.now

cfrag = 1
#自分のアカウントたちを登録
myaccount = "@ " # ここに自分のIDを入力
myid1 = ""
myid2 = ""
myid3 = ""
#登録おわり
while cfrag do
  begin
    stream_client.user do |object|
        if object.is_a?(Twitter::Tweet)
          puts "#{object.user.screen_name}: #{object.text}"
          # 自分のエゴサbot　エゴサを見つけると自分の別のアカウントにDMを送信
          if (object.text.include?("よしもり") || object.text.include?("すみっぴ") || object.text.include?("よつばうさぎ") ) && ! object.text.include?("#よしもり") # エゴサしたいワード
            output = "名前がツイートされました\n" + "ツイート者ID: " + object.user.screen_name + "\nツイート者　: " + client.user(object.user.screen_name).name
            output = output + "\nツイート日　: " + tweet_id2time(object.id).strftime("%4Y/%2m/%2d") + "\nツイート時刻: " + tweet_id2time(object.id).strftime("%H:%M:%S.%L")
            output = output + "\n\n" + object.text
            puts output
            client.create_direct_message(myid3, output)
          end
            if today_check.day != Time.now.day
              total_tweet = account1 + account2 + account3 + account4 + account5
              client.update(today_check.strftime("%-m/%-d") + "'s total Tweet: #{total_tweet}\n")
              out_dm = sprintf("よしもり　：%3d\n",account1) + sprintf("すみっぴい：%3d\n",account2) + sprintf("ゆきうさぎ：%3d\n",account3) + sprintf("しげもり　：%3d\n",account4)
              out_dm = out_dm + sprintf("静よしもり：%3d\n",account5) + sprintf("合計　　　：%3d\n",total_tweet)
              client.create_direct_message(myid2, "☆#{today_check.strftime("%-m月%-d日")}のツイート数☆\n\n" + out_dm)
              today_check = Time.now
              account1 = 0
              account2 = 0
              account3 = 0
              account4 = 0
              account5 = 0
            end

            # 自分のアカウントかどうかを判定　一応5つまで対応
            if object.user.screen_name == ""
              account1 += 1
            elsif object.user.screen_name == ""
              account2 += 1
            elsif object.user.screen_name == ""
              account3 += 1
            elsif object.user.screen_name == ""
              account4 += 1
            elsif object.user.screen_name == ""
              account5 += 1
            end

            hannou1 = (object.text.include?("いいね") || object.text.include?("ふぁぼ")) && object.text.include?("分析")
            hannou2 = (object.text.include?("犯罪係数") || object.text.include?("はんざいけいす")) && (object.text.include?("測") || object.text.include?("分析") )
            if object.text.include?("RT")
              puts "リツイートなのでスキップ"
              next
            end
            if object.text.include?(myaccount) && hannou1
              shori_list_name.push(object.user.screen_name)
              shori_list_id.push(object.id)
              shori_naiyou.push(1)
              lag = (wait_time - Time.now).to_i
              if lag < 0
                lag = 0
              end
              begin
                  if wait_time > Time.now
                    client.update("@#{object.user.screen_name}" + "いいね分 析処理を受け付けました。\n" + ((shori_list_name.count+shori_list_name2.count-1) * 5 + 1 + lag / 60).to_s + "分ほどお待ちください。\n" ,in_reply_to_status_id: object.id)
                  end
              rescue

              end
            end
            # 現在の時刻を出力するだけのbot　ほぼチェック用
            if object.text.include?(myaccount) && ((object.text.include?("現w在") || object.text.include?("今") || object.text.include?("hat") ) && (object.text.include?("時刻") || (object.text.include?("時") || object.text.include?("time"))))
              client.favorite(object.id)
              if object.text.include?("time")
                out = "The time is now at " + Time.now.strftime("%-I:%M  %p.\n")
              elsif Time.now.strftime("%p") == "AM"
                out = "時刻は　午前 " + Time.now.strftime("%-I時%M分です。\n")
              else
                out = "時刻は　午後 " + Time.now.strftime("%-I時%M分です。\n")
              end
              puts out
              begin
                client.update("@#{object.user.screen_name}\n" + out,in_reply_to_status_id: object.id)
              rescue

              end
            end

            if object.text.include?(myaccount) && ((object.text.include?("今w日") || object.text.include?("今") || object.text.include?("What") ) && (object.text.include?("何曜日") || (object.text.include?("何日") || object.text.include?("da"))))
              client.favorite(object.id)
              day_num = ["日","月","火","水","木","金","土"]
              out = "今日は " + Time.now.strftime("%-m月%-d日、" + day_num[Time.now.wday] + "曜日です。\n")
              puts out
              begin
                client.update("@#{object.user.screen_name}\n" + out,in_reply_to_status_id: object.id)
              rescue

              end
            end

            if object.text.include?(myaccount) && hannou2
              shori_list_name2.push(object.user.screen_name)
              shori_list_id2.push(object.id)
              tweet_text.push(object.text)
              shori_naiyou.push(2)
              lag = (wait_time - Time.now).to_i
              if lag < 0
                lag = 0
              end
              begin
                if wait_time > Time.now
                  client.update("@#{object.user.screen_name}" + "犯罪係 数処理を受け付けました。\n" + ((shori_list_name.count+shori_list_name2.count-1) / 2 + 1 + lag / 60).to_s + "分ほどお待ちください。\n" ,in_reply_to_status_id: object.id)
                end
              rescue

              end
            end
            shori = 0
            if wait_time <= Time.now
              shori = shori_naiyou.shift
            end
            if ! shori_list_name.empty? && wait_time <= Time.now && shori == 1
              shori_screen_name = shori_list_name.shift
              shori_id          = shori_list_id.shift
              client.favorite(shori_id)
              search_tweets = 200 # 過去200ツイートを対象に分析（いいね）
              fav_list = Array.new(2) {Array.new}

              start = Time.now
              finish   = Time.now
              cnt = 0
              begin
                fav_list_ind = client.favorites(shori_screen_name,{ count: search_tweets })
                fav_list_ind.each do |timeline|
                  cnt += 1
                  if cnt == 1
                    start = tweet_id2time(timeline.id)
                  end
                  finish = tweet_id2time(timeline.id)
                #  puts "\e[H\e[2J"
                #  print "分析中… " + (cnt * 100.0 / search_tweets).to_i.to_s + "%\n"
                  if ! fav_list[0].include?(timeline.user.screen_name)
                    fav_list[0].push(timeline.user.screen_name)
                    fav_list[1].push(1)
                  else
                    num = fav_list[0].index((timeline.user.screen_name))
                    fav_list[1][num] += 1
                  end
                  #puts client.status(timeline.id).user.screen_name + "  " + client.status(timeline.id).text
                  #puts tweet_id2time(client.status(timeline.id).id).strftime("%4Y/%2m/%2d %H:%M:%S")
                end
              rescue
                client.create_direct_message("大変申し訳ありません。送信時に何らかのエラーが発生しました。\n")
                shori_list_name.push(shori_screen_name)
                shori_list_id.push(shori_id)
                next
              end
              fav_list_sort = fav_list.transpose.sort { |a, b| b[1] <=> a[1] }
              sec = (start - finish) * 1.0 / search_tweets
              if sec >= 86400
                freq = (Time.parse("1/1") + sec - (day = sec.to_i / 86400) * 86400).strftime("#{day}日%H時間%M分")
              elsif sec >= 3600
                freq = (Time.parse("1/1") + sec - (day = sec.to_i / 86400) * 86400).strftime("%k時間%M分%S秒")
              elsif sec >= 60
                freq = (Time.parse("1/1") + sec - (day = sec.to_i / 86400) * 86400).strftime("%^-M分%S秒")
              else
                freq = (Time.parse("1/1") + sec - (day = sec.to_i / 86400) * 86400).strftime("%^-M分%S秒")
              end
              print(freq + "\n")



              rank = 1
              out_twitter = "☆いいねランキング☆\n"
              for i in 0..(fav_list_sort.flatten.count / 2) - 1 do
                if i == 0 || fav_list_sort[i][1] != fav_list_sort[i-1][1]
                  rank = i + 1
                else

                end
                print(rank.to_s + "位　" + fav_list_sort[i][0] + "　" + fav_list_sort[i][1].to_s + "\n")
                if rank <= 5 && out_twitter.length <= 100
                  out_twitter = out_twitter + rank.to_s + "位　" + fav_list_sort[i][0] + "　" + fav_list_sort[i][1].to_s + "\n"
                end
              end
              out_twitter = out_twitter + "いいね間隔: " + freq + "/いいね\n"
              if search_tweets - cnt != 0
                out_twitter = out_twitter + "鍵アカウント" + (search_tweets - cnt).to_s + "件あり\n"
              end

              print(out_twitter)

              p(out_twitter.length)
              begin
                client.update("@#{shori_screen_name}" + out_twitter + "\n" + "#いいね解析\n",in_reply_to_status_id: shori_id)
              rescue
                client.create_direct_message(shori_screen_name, "大変申し訳ありません。送信時に何らかのエラーが発生しました。\n\n" + out_twitter)
              end
              wait_time = Time.now + 30
            end



            bunseki = ""
            error_bunseki = ""
            # 犯罪係数計測　あの PSYCHO-PASSに出てくる犯罪係数を調べる
            if ! shori_list_name2.empty? && wait_time <= Time.now && shori == 2
              shori_screen_name = shori_list_name2.shift
              shori_id          = shori_list_id2.shift
              bunseki           = tweet_text.shift
              border = 0
              if bunseki.include?("「") && bunseki.include?("」")
                search_cc = bunseki.slice(bunseki.index("「")+1..bunseki.index("」")-1)
                search_cc.slice!("@")
                search_cc.slice!(" ")
                search_cc.slice!("　")
                begin
                  error_bunseki = "##{client.user(shori_screen_name).name}ドミネーター\n"
                rescue
                  error_bunseki = "※ﾕｰｻﾞｰ認証できませんでした。\n"
                  search_cc = shori_screen_name
                end
              else
                search_cc = shori_screen_name
              end
              client.favorite(shori_id)
              tweet_point    = 0.0
              fav_point = 0.0
              follow_point   = 0.0

              start  = Time.now
              finish = Time.now
              cnt =  0
              secure = 100.0
              search = 200
              before = 0
              after = 0
              # hanzai_list は、反応するワードリストである。（中身は秘密）
              hanzai_list = CSV.read("hanzai_words.csv", encoding: "UTF-8")
              list_num = hanzai_list.flatten.count / 2
              # いいねリスト200個から特定ワードを検知する。
              client.favorites(shori_screen_name,{ count: search }).each do |fav_list|
                cnt += 1
                before = fav_point
                for i in 0..(list_num-1) do
                  if fav_list.text.include?(hanzai_list[i][0])
                    fav_point += hanzai_list[i][1].to_i / 2
                  end
                end
                after = fav_point
                secure -= (after - before) * 0.3
                before = fav_point
                if cnt == 1
                  finish = tweet_id2time(fav_list.id)
                end
                start = tweet_id2time(fav_list.id)

              #  puts fav_list.text
              end

              fav_per_day = 86400 / (finish - start) * search
              # いいね頻度が多い人には多少の犯罪係数を足す
              print fav_per_day.to_s + "いいね/日\n"
              if fav_per_day >= 200
                fav_point += fav_per_day * 0.2
              elsif fav_per_day >= 100
                fav_point += fav_per_day * 0.15
              elsif fav_per_day >= 70
                fav_point += fav_per_day * 0.10
              elsif fav_per_day >= 50
                fav_point += fav_per_day * 0.08
              elsif fav_per_day >= 30
                fav_point += fav_per_day * 0.05
              end

              cnt = 0
              after = 0

              # 過去200ツイートのつぶやきから、該当するワードがあった場合は加点
              client.user_timeline(search_cc, { count: search } ).each do |timeline|
                before = tweet_point
                for i in 0..(list_num-1) do
                  if timeline.text.include?(hanzai_list[i][0])
                    tweet_point += hanzai_list[i][1].to_i
                  end
                end
                after = tweet_point
                secure -= (after - before) * 0.5

                #tweet = client.status(timeline.id)
                if cnt == 1
                  finish = tweet_id2time(timeline.id)
                end
                start = tweet_id2time(timeline.id)
                border = tweet_point / 2
                if timeline.favorite_count >= 5 && timeline.retweet_count <= 10
                  tweet_point -= 0.5
                end
                #print ("いいね: " + timeline.favorite_count.to_s + "件\n")
                #puts tweet_id2time(timeline.id).strftime("%H:%M:%S.%L")
                #puts timeline.text
              end



              tweet_per_day = 86400 / (finish - start) * search
              print tweet_per_day.to_s + "ツイート/日\n"
              # ツイート頻度が多い人には犯罪係数を加算
              if tweet_per_day >= 100
                tweet_point += tweet_per_day * 0.3
              elsif tweet_per_day >= 70
                tweet_point += tweet_per_day * 0.25
              elsif tweet_per_day >= 50
                tweet_point += tweet_per_day * 0.20
              elsif tweet_per_day >= 30
                tweet_point += tweet_per_day * 0.15
              elsif tweet_per_day >= 10
                tweet_point += tweet_per_day * 0.10
              end

              friends =  client.user(search_cc).friends_count    #フォロー

              followers =  client.user(search_cc).followers_count  #フォロワー

              ff_ratio = friends * 1.0 / followers
              fav_point = fav_point.round(2)
              tweet_point = tweet_point.round(2)
              if tweet_point <= border
                tweet_point = border
              end
              kasan = fav_point + tweet_point
              # FF比（フォロー ÷ フォロワー）が一定値以上なら一定値の犯罪係数を割り増しする
              if ff_ratio >= 1.2
                follow_point = kasan * Math.log10(ff_ratio - 0.2)
                follow_point.round(2)
              end

              crime_coefficient = tweet_point + fav_point + follow_point
              color = ""
              if crime_coefficient >= 500
                color = "黒"
              elsif crime_coefficient >= 400
                color = "茶"
              elsif crime_coefficient >= 300
                color = "赤"
              elsif crime_coefficient >= 250
                color = "紫"
              elsif crime_coefficient >= 200
                color = "橙"
              elsif crime_coefficient >= 160
                color = "黄"
              elsif crime_coefficient >= 130
                color = "黄緑"
              elsif crime_coefficient >= 110
                color = "緑"
              elsif crime_coefficient >= 70
                color = "深緑"
              elsif crime_coefficient >= 50
                color = "青"
              elsif crime_coefficient >= 30
                color = "深青"
              elsif crime_coefficient >= 10
                color = "水"
              else
                color = "白"
              end


              output = client.user(search_cc).name + sprintf("さんの犯罪係数\n" + "%6.2f",tweet_point) + " + " + sprintf("%6.2f",fav_point) + " + " + sprintf("%6.2f",follow_point) + " = " + sprintf("%6.2f\n",crime_coefficient) + "色相: " + color + "\n"
              if    crime_coefficient >= 500
                output = output + "犯罪係数 " + sprintf("%3.0f",crime_coefficient) + " 。完全にアウトです。ネットの世界から少し離れることをおすすめします。\n"
              elsif crime_coefficient >= 300
                output = output + "犯罪係数 " + sprintf("%3.0f",crime_coefficient) + " 。アウトです。少しツイッターを休まれてはいかがですか？\n"
              elsif crime_coefficient >= 200
                output = output + "犯罪係数 " + sprintf("%3.0f",crime_coefficient) + " 。警告レベルです。ツイート内容を見直すことを強くお勧めします。\n"
              elsif crime_coefficient >= 100
                output = output + "犯罪係数 " + sprintf("%3.0f",crime_coefficient) + " 。警告レベルです。ツイート内容を見直してもいいかもしれません。\n"
              elsif crime_coefficient >=  70
                output = output + "犯罪係数 " + sprintf("%3.0f",crime_coefficient) + " 。正常ですが、若干犯罪係数が高めです。気をつけましょう。\n"
              elsif crime_coefficient >=  30
                output = output + "犯罪係数 " + sprintf("%3.0f",crime_coefficient) + " 。正常です。これからも快適なツイッターライフを送ってください。\n"
              else
                output = output + "犯罪係数 " + sprintf("%3.0f",crime_coefficient) + " 。正常です。模範的なツイッタラーですね。\n"
              end
              output = output + "安全度: " +  sprintf("%4.2f",secure) + "%\n"
              print (output)
              p(output.length)
              begin
                client.update("@#{shori_screen_name}" + "\n"   + output + "\n" + "#よしもりドミネーター\n" + error_bunseki ,in_reply_to_status_id: shori_id)
              rescue
                client.create_direct_message(output, "大変申し訳ありません。送信時に何らかのエラーが発生しました。\n\n" + output)
              end

              begin
                CSV.open('coefficient.csv','a') do |test|
                 test << [shori_screen_name,sprintf("%6.2f",tweet_point),sprintf("%6.2f",fav_point),sprintf("%6.2f",follow_point),sprintf("%6.2f",crime_coefficient)]
                end
              rescue

              end
              wait_time = Time.now + 10
            end
            if object.text.include?(myaccount) && (object.text.include?("性別") || object.text.include?("男女")) && (object.text.include?("判定") || object.text.include?("測定")) && object.text.length <= 40
              shori_screen_name = object.user.screen_name
              shori_id          = object.id
              client.favorite(shori_id)
              search_tweets = 200
              fav_list = Array.new(2) {Array.new}

              start = Time.now
              finish   = Time.now
              cnt = 0
              begin
                male = 0
                female = 0
                gender = 0
                today_tweet = Time.now
                tweet_list = client.user_timeline(shori_screen_name,{ count: search_tweets })
                hantei_list = CSV.read("gender.csv", encoding: "UTF-8") # 男女判定するためのワードリスト　これも秘密
                tweet_list.each do |tweets|
                  for i in 0..(hantei_list.flatten.count / 2 - 1) do
                    if tweets.text.include?(hantei_list[i][0]) && ! tweets.text.include?("RT")
                      if hantei_list[i][1].to_i > 0
                        puts "fe"
                        female += hantei_list[i][1].to_i
                      else
                        puts "ma"
                        male   -= hantei_list[i][1].to_i
                      end
                    end
                  end
                end

              rescue => ex
                puts ex.backtrace.first + ": #{ex.message} (#{ex.class})"
                ex.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }
              end
              gender = female - male
              out_twitter = ""
              out_twitter = out_twitter + "☆男女判定☆\n" + "男性度: " + sprintf("%4d\n",male) + "女性度: " + sprintf("%4d\n",female)
              out_twitter = out_twitter + "合計値: " + sprintf("%4d\n\n",gender) + "※合計値が低ければ低いほど男性、高ければ高いほど女性です。\n"

              print(out_twitter)

              p(out_twitter.length)
              begin
                client.update("@#{shori_screen_name}" + "\n"   + out_twitter,in_reply_to_status_id: shori_id)
              rescue
                client.create_direct_message(out_twitter, "大変申し訳ありません。送信時に何らかのエラーが発生しました。\n\n" + output)
              end
            end
            if object.text.include?(myaccount) && (object.text.include?("リプ") || object.text.include?("返信")) && (object.text.include?("分析") || object.text.include?("解析"))
              # リプライランキングを出す。それだけ
              shori_screen_name = object.user.screen_name
              shori_id          = object.id
              client.favorite(shori_id)
              search_tweets = 200
              fav_list = Array.new(2) {Array.new}

              start = Time.now
              finish   = Time.now
              cnt = 0
              begin
                reply_count = 0
                cnt = 0
                reply_list_ind = client.user_timeline(shori_screen_name,{ count: search_tweets })
                reply_list_ind.each do |tweets|
                  cnt += 1
                  #p cnt
                  if cnt == 1
                    start = tweet_id2time(tweets.id)
                  end
                  finish = tweet_id2time(tweets.id)
                  if ! tweets.in_reply_to_screen_name.nil?
                    reply_count += 1
                  end
                  #p tweets.in_reply_to_screen_name
                end

                freq2 = ""
                sec2 = (start - finish) * 1.0 / search_tweets
                if sec2 >= 86400
                  freq2 = (Time.parse("1/1") + sec2 - (day = sec2.to_i / 86400) * 86400).strftime("#{day}日%H時間%M分")
                elsif sec2 >= 3600
                  freq2 = (Time.parse("1/1") + sec2 - (day = sec2.to_i / 86400) * 86400).strftime("%k時間%M分%S秒")
                elsif sec2 >= 60
                  freq2 = (Time.parse("1/1") + sec2 - (day = sec2.to_i / 86400) * 86400).strftime("%^-M分%S秒")
                else
                  freq2 = (Time.parse("1/1") + sec2 - (day = sec2.to_i / 86400) * 86400).strftime("%^-M分%S秒")
                end
                print(freq2 + "\n")
                reply_list_ind.each do |tweets|
                  if ! tweets.in_reply_to_screen_name.nil?
                    if ! fav_list[0].include?(tweets.in_reply_to_screen_name)
                      fav_list[0].push(tweets.in_reply_to_screen_name)
                      fav_list[1].push(1)
                    else
                      num = fav_list[0].index((tweets.in_reply_to_screen_name))
                      fav_list[1][num] += 1
                    end
                  end
                end
              rescue => ex
                puts ex.backtrace.first + ": #{ex.message} (#{ex.class})"
                ex.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }
              end
              fav_list_sort = fav_list.transpose.sort { |a, b| b[1] <=> a[1] }
              rank = 1
              out_twitter = "☆リプライランキング☆\n"
              for i in 0..(fav_list_sort.flatten.count / 2) - 1 do
                if i == 0 || fav_list_sort[i][1] != fav_list_sort[i-1][1]
                  rank = i + 1
                else

                end
                print(rank.to_s + "位　" + fav_list_sort[i][0] + "　" + fav_list_sort[i][1].to_s + "\n")
                if rank <= 5 && out_twitter.length <= 120
                  out_twitter = out_twitter + rank.to_s + "位　" + fav_list_sort[i][0] + " " + sprintf("%3d",fav_list_sort[i][1]) + "\n"
                end
              end
              out_twitter = out_twitter + "リプ回数 :" + sprintf("%3d",reply_count) + " / " + sprintf("%3d",cnt) +sprintf("  (%6.2f％)\n",reply_count * 100.0 / cnt)
              out_twitter = out_twitter + "ツイート間隔: " + freq2 + "/tweet\n"


              print(out_twitter)

              p(out_twitter.length)
              begin
                client.update("@#{shori_screen_name}" + "\n"   + out_twitter,in_reply_to_status_id: shori_id)
              rescue
                client.create_direct_message(out_twitter, "大変申し訳ありません。送信時に何らかのエラーが発生しました。\n\n" + output)
              end

              wait_time = Time.now + 15
            end
            #｢kaya_natsuyoru ｣ ｢nise_kit｣ 両思い
            abool = object.text.count("「") == 2 #|| object.text.count("｢") == 2
            bbool = object.text.count("」") == 2 #|| object.text.count("｣") == 2

            # 2人の相性を調べるbot　コマンドが若干連動　　　コマンド例：　「kaya_natsuyoru」 「nise_kit」　両想い
            if(object.text.include?(myaccount) && (object.text.include?("両思い") || object.text.include?("両想い")) && abool && bbool)
              shori_screen_name = object.user.screen_name
              shori_id          = object.id
              bunseki_text      = object.text.dup
              latter = bunseki_text.index("」") + 1
              search_cc1 = bunseki_text.slice(bunseki_text.index("「")+1..bunseki_text.index("」")-1)
              search_cc1.slice!("@")
              search_cc1.slice!(" ")
              search_cc1.slice!("　")

              search_cc2 = bunseki_text.slice(bunseki_text.index("「",latter)+1..bunseki_text.index("」",latter)-1)
              search_cc2.slice!("@")
              search_cc2.slice!(" ")
              search_cc2.slice!("　")
              puts search_cc1
              puts search_cc2
              client.favorite(shori_id)
              search_tweets = 200
              fav_list = Array.new(2) {Array.new}

              start = Time.now
              finish   = Time.now
              cnt = 0
              begin
                client.user(search_cc1).name
                client.user(search_cc2).name
              rescue
                client.update("@#{shori_screen_name}" + "\n"   + "ユーザー指定エラーです\nIDを確認してください。\n",in_reply_to_status_id: shori_id)
                next
              end
              begin
                reply_count1  = 0
                reply_count2  = 0
                p_reply1 = 0
                p_reply2 = 0
                cnt = 0
                refav_count = 0
                today_tweet = Time.now
                tweet_list1 = client.user_timeline(search_cc1,{ count: search_tweets })
                # ツイートの対象者へのリプライがあったら加点
                tweet_list1.each do |tweets|
                  cnt += 1
                  if ! tweets.in_reply_to_screen_name.nil?
                    reply_count1 += 1
                  end
                  if tweets.text.include?("@#{search_cc2}")
                    p_reply1 += 1
                  end
                end
                p_reply1 *= (cnt * 1.0 / reply_count1)
                p reply_count1
                tweet_list2 = client.user_timeline(search_cc2,{ count: search_tweets })
                tweet_list2.each do |tweets|
                  cnt += 1
                  if ! tweets.in_reply_to_screen_name.nil?
                      reply_count2 += 1
                  end
                  if tweets.text.include?("@#{search_cc1}")
                    p_reply2 += 1
                  end
                end
                p_reply2 *= (cnt * 1.0 / reply_count2)
                p reply_count2


                p1_fav = 0
                p2_fav = 0
                # ツイートの対象者へのいいねがあったら加点
                fav_list1 = client.favorites(search_cc1,{ count: search_tweets })
                fav_list1.each do |tweets|
                  cnt += 1
                  #puts  tweets.user.screen_name
                  if tweets.user.screen_name == search_cc2
                    p1_fav += 2.5
                  end
                end
                fav_list2 = client.favorites(search_cc2,{ count: search_tweets })
                fav_list2.each do |tweets|
                  cnt += 1
                  #puts  tweets.user.screen_name
                  if tweets.user.screen_name == search_cc1
                    p2_fav += 2.5
                  end
                end
                ave_fav = search_tweets / ((start - finish) / 86400.0)
              rescue => ex
                puts ex.backtrace.first + ": #{ex.message} (#{ex.class})"
                ex.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }
              end
              puts p_reply1
              puts p_reply2
              puts p1_fav
              puts p2_fav

              omoi_from = p_reply1 + p1_fav
              if omoi_from >= 100
                omoi_from = 100
              end
              omoi_to   = p_reply2 + p2_fav
              if omoi_to   >= 100
                omoi_to   = 100
              end
              sa = omoi_from - omoi_to
              isRyo = ""
              ryou_omoi = ((omoi_from * omoi_to) / 10000) ** 0.5
              aishou = omoi_from * 0.2 + omoi_to * 0.2 + ryou_omoi * 80
              if(aishou >= 50 && -30 < sa && sa < 30)
                isRyo = "両想い"
              elsif(aishou >= 20 && sa >= 0)
                isRyo = "#{client.user(search_cc1).name}さんの片想い"
              elsif(aishou >= 20 && sa <= 0)
                isRyo = "#{client.user(search_cc2).name}さんの片想い"
              end
              naka = ""
              if aishou >= 100
                naka = "親友を超える仲"
              elsif aishou >= 80
                naka = "親友"
              elsif aishou >= 50
                naka = "友達"
              elsif aishou >= 20
                naka = "知人"
              end


              puts sprintf("%4.2f",omoi_from * 0.2) + " + " + sprintf("%4.2f",omoi_to * 0.2) + " + " + sprintf("%4.2f",ryou_omoi * 80) + " = " + sprintf("%4.2f",aishou)
              out_twitter = "#{client.user(search_cc1).name}さんと#{client.user(search_cc2).name}さんの仲良し度: " + sprintf("%4.2f％\n",aishou)
              out_twitter = out_twitter + "判定: " + isRyo + "\n状態: "  + naka + "\n"

              print(out_twitter)

              p(out_twitter.length)

              begin
                client.update("@#{shori_screen_name}" + "\n"   + out_twitter,in_reply_to_status_id: shori_id)
              rescue
                client.create_direct_message(out_twitter, "大変申し訳ありません。送信時に何らかのエラーが発生しました。\n\n" + output)
              end

            end
            if object.text.include?(myaccount) && object.user.screen_name == myid1 && object.text.include?("bot強制終了")
              puts "fav botを強制終了しました。"
              client.create_direct_message(myid1, "favbotを強制終了しました\n")
              cfrag = 0
              break
            end
            if object.text.include?(myaccount) && (object.text.include?("ツイート") && (object.text.include?("分析") || object.text.include?("解析")))
              # 今までのツイートを解析　いいねした数とかね
              shori_screen_name = object.user.screen_name
              shori_id          = object.id
              client.favorite(shori_id)
              search_tweets = 200
              fav_list = Array.new(2) {Array.new}
              over200tweet = ""
              over200fav   = ""
              start = Time.now
              finish   = Time.now
              cnt = 0
              begin
                reply_count = 0
                cnt = 0
                fav_1over = 0 #1ファボ以上されたツイートの個数
                today_tweet_count = 0
                today_refav_count = 0
                refav_count = 0
                authority = 0.0 # ツイート影響力（いいねされた数とリツイートされた数に応じて加点）
                today_tweet = Time.now
                reply_list_ind = client.user_timeline(shori_screen_name,{ count: search_tweets })
                reply_list_ind.each do |tweets|

                  if tweets.favorite_count >= 1
                    authority += tweets.favorite_count * 2.0 * (1.0 + tweets.favorite_count / 5.0 * 0.5) + tweets.retweet_count * 20
                    fav_1over += 1
                  end
                  cnt += 1
                  #p cnt
                  if cnt == 1
                    start = tweet_id2time(tweets.id)
                    today_tweet = Time.parse(start.strftime("%Y-%m-%d 00:00:00"))
                  end
                  finish = tweet_id2time(tweets.id)
                  if finish >= today_tweet
                    today_tweet_count += 1
                    today_refav_count += tweets.favorite_count
                  end
                  refav_count += tweets.favorite_count
                  if ! tweets.in_reply_to_screen_name.nil?
                    reply_count += 1
                  end
                end
                fav_persentage = fav_1over * 100.0 / cnt
                ave_tweet = search_tweets / ((start - finish) / 86400.0)
                if cnt == today_tweet_count
                  over200tweet = "↑" # 200ツイート以上は検知できないのでオーバー表示とする
                end
                today_fav_count = 0
                fav_list_ind = client.favorites(shori_screen_name,{ count: search_tweets })
                fav_list_ind.each do |timeline|
                  cnt += 1
                  if cnt == 1
                    start = tweet_id2time(timeline.id)
                  end
                  finish = tweet_id2time(timeline.id)
                  if finish >= today_tweet
                    today_fav_count += 1
                  end
                end
                if cnt == today_fav_count
                  over200fav = "↑"
                end
                ave_fav = search_tweets / ((start - finish) / 86400.0)
              rescue => ex
                puts ex.backtrace.first + ": #{ex.message} (#{ex.class})"
                ex.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }
              end
              puts today_tweet_count
              puts today_fav_count
              puts ave_tweet
              puts ave_fav
              puts authority
              # ツイッター廃人度を同時に測定　ツイートといいね頻度から測定
              tsuihai_point = ave_tweet * 3.0 + ave_fav * 1.0
              tsuihai_rank = ""
              if tsuihai_point >= 1500
                tsuihai_rank = "レベル皆伝"
              elsif tsuihai_point >= 1000
                tsuihai_rank = "レベル10"
              elsif tsuihai_point >= 900
                tsuihai_rank = "レベル 9"
              elsif tsuihai_point >= 800
                tsuihai_rank = "レベル 8"
              elsif tsuihai_point >= 700
                tsuihai_rank = "レベル 7"
              elsif tsuihai_point >= 500
                tsuihai_rank = "レベル 6+"
              elsif tsuihai_point >= 400
                tsuihai_rank = "レベル 6-"
              elsif tsuihai_point >= 300
                tsuihai_rank = "レベル 5+"
              elsif tsuihai_point >= 200
                tsuihai_rank = "レベル 5-"
              elsif tsuihai_point >= 150
                tsuihai_rank = "レベル 4"
              elsif tsuihai_point >= 100
                tsuihai_rank = "レベル 3"
              elsif tsuihai_point >= 60
                tsuihai_rank = "レベル 2"
              elsif tsuihai_point >= 20
                tsuihai_rank = "レベル 1"
              else
                tsuihai_rank = "レベル 0"
              end



              out_twitter = ""
              out_twitter = out_twitter + "☆#{Time.now.strftime("%2m月%2d日")}の情報☆\n" + "ツイート量: " + sprintf("%2d",today_tweet_count) + over200tweet + "\n" + "いいねした数: " + sprintf("%2d",today_fav_count) + over200fav + "\n"
              out_twitter = out_twitter + "いいねされた数 :" + sprintf("%2d\n\n",today_refav_count)
              out_twitter = out_twitter + "☆過去200ツイートから☆\n" + "ツイート量: " + sprintf("%4.2f/日\n",ave_tweet) + "いいねした数: " + sprintf("%4.2f/日\n",ave_fav)
              out_twitter = out_twitter + "いいねされた数: " + sprintf("%3d\n",refav_count) + "ツイート影響力: " + sprintf("%5.2f\n",authority)
              out_twitter = out_twitter + "ツイ廃" + tsuihai_rank + sprintf(" (%6.2fpts)",tsuihai_point) + "\n反応率: " + sprintf("%4.2f",fav_persentage) + "%\n"


              print(out_twitter)

              p(out_twitter.length)
              begin
                client.update("@#{shori_screen_name}" + "\n"   + out_twitter,in_reply_to_status_id: shori_id)
              rescue
                client.create_direct_message(out_twitter, "大変申し訳ありません。送信時に何らかのエラーが発生しました。\n\n" + output)
              end

              wait_time = Time.now + 15
            end

            if object.text.include?(myaccount) && (object.text.include?("仲良し") || object.text.include?("なかよし")) && (object.text.include?("ランキング") || object.text.include?("らんきんぐ"))
              # 仲良しランキング片思いバージョン
              # いいね分析＋リプライ分析をあわせたもの
              shori_screen_name = object.user.screen_name
              shori_id          = object.id
              client.favorite(shori_id)
              search_tweets = 200
              fav_list = Array.new(2) {Array.new}

              start = Time.now
              finish   = Time.now
              cnt = 0
              begin
                fav_list_ind = client.favorites(shori_screen_name,{ count: search_tweets })
                fav_list_ind.each do |timeline|
                  cnt += 1
                  if cnt == 1
                    start = tweet_id2time(timeline.id)
                  end
                  finish = tweet_id2time(timeline.id)

                  if ! fav_list[0].include?(timeline.user.screen_name)
                    fav_list[0].push(timeline.user.screen_name)
                    fav_list[1].push(1)
                  else
                    num = fav_list[0].index((timeline.user.screen_name))
                    fav_list[1][num] += 2
                  end

                end

                sec = (start - finish) * 1.0 / search_tweets
                if sec >= 86400
                  freq = (Time.parse("1/1") + sec - (day = sec.to_i / 86400) * 86400).strftime("#{day}日%H時間%M分")
                elsif sec >= 3600
                  freq = (Time.parse("1/1") + sec - (day = sec.to_i / 86400) * 86400).strftime("%k時間%M分%S秒")
                elsif sec >= 60
                  freq = (Time.parse("1/1") + sec - (day = sec.to_i / 86400) * 86400).strftime("%^-M分%S秒")
                else
                  freq = (Time.parse("1/1") + sec - (day = sec.to_i / 86400) * 86400).strftime("%^-M分%S秒")
                end
                print(freq + "\n")
                reply_count = 0
                cnt = 0
                reply_list_ind = client.user_timeline(shori_screen_name,{ count: search_tweets })
                reply_list_ind.each do |tweets|
                  cnt += 1
                  #p cnt
                  if cnt == 1
                    start = tweet_id2time(tweets.id)
                  end
                  finish = tweet_id2time(tweets.id)
                  if ! tweets.in_reply_to_screen_name.nil?
                    reply_count += 1
                  end
                  #p tweets.in_reply_to_screen_name
                end

                freq2 = ""
                sec2 = (start - finish) * 1.0 / search_tweets
                if sec2 >= 86400
                  freq2 = (Time.parse("1/1") + sec2 - (day = sec2.to_i / 86400) * 86400).strftime("#{day}日%H時間%M分")
                elsif sec2 >= 3600
                  freq2 = (Time.parse("1/1") + sec2 - (day = sec2.to_i / 86400) * 86400).strftime("%k時間%M分%S秒")
                elsif sec2 >= 60
                  freq2 = (Time.parse("1/1") + sec2 - (day = sec2.to_i / 86400) * 86400).strftime("%^-M分%S秒")
                else
                  freq2 = (Time.parse("1/1") + sec2 - (day = sec2.to_i / 86400) * 86400).strftime("%^-M分%S秒")
                end
                print(freq2 + "\n")

                bairitsu = 5.0 * (search_tweets / 5.0 / reply_count)
                if bairitsu <= 2.0
                  bairitsu = 2.0
                elsif bairitsu >= 20
                  bairitsu = 20
                end
                p bairitsu
                reply_list_ind.each do |tweets|
                  if ! tweets.in_reply_to_screen_name.nil?
                    if ! fav_list[0].include?(tweets.in_reply_to_screen_name)
                      fav_list[0].push(tweets.in_reply_to_screen_name)
                      fav_list[1].push(1)
                    else
                      num = fav_list[0].index((tweets.in_reply_to_screen_name))
                      fav_list[1][num] += bairitsu
                    end
                  end

                end
              rescue => ex
                puts ex.backtrace.first + ": #{ex.message} (#{ex.class})"
                ex.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }

              end
              fav_list_sort = fav_list.transpose.sort { |a, b| b[1] <=> a[1] }






              rank = 1
              out_twitter = "☆仲良しランキング　片思い☆\n"
              for i in 0..(fav_list_sort.flatten.count / 2) - 1 do
                if i == 0 || fav_list_sort[i][1] != fav_list_sort[i-1][1]
                  rank = i + 1
                else

                end
                print(rank.to_s + "位　" + fav_list_sort[i][0] + "　" + fav_list_sort[i][1].to_s + "\n")
                if rank <= 5 && out_twitter.length <= 100
                  out_twitter = out_twitter + rank.to_s + "位　" + fav_list_sort[i][0] + "　" + sprintf("%4.1f",fav_list_sort[i][1]) + "\n"
                end
              end
              out_twitter = out_twitter + "いいね間隔: " + freq + "/fav\n"
              out_twitter = out_twitter + "ツイート間隔: " + freq2 + "/tweet\n"


              print(out_twitter)

              p(out_twitter.length)
              begin
                client.update("@#{shori_screen_name}" + "\n"   + out_twitter,in_reply_to_status_id: shori_id)
              rescue
                client.create_direct_message(out_twitter, "大変申し訳ありません。送信時に何らかのエラーが発生しました。\n\n" + output)
              end
              wait_time = Time.now + 15
            end
          if cfrag == 0
            break
          end
        end
    end
  rescue => ex
    a = ""
    a = ex.backtrace.first + ": #{ex.message} (#{ex.class})"
    puts ex.backtrace.first + ": #{ex.message} (#{ex.class})"
    ex.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }
    if Time.now - error_time <= 10
      client.update("エラーが多発したため、botを停止します。\n")
      sleep(600)
    end
    error_time = Time.now
    sleep(2)
    begin
      if a.length <= 250
        client.update(a)
      else
        client.update(ex)
      end
    rescue => ex
      sleep(2)
      puts "エラーメッセージ送信エラー"
    end
  end
  if cfrag == 0
    break
  end
end
