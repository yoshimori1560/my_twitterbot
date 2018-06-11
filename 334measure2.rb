=begin
334measure2.rb  334とつぶやかれた時間を1/1000単位で表示するだけのbot。
ちなみに332,333,335の場合も処理される。

また、ランキング、フライングかどうかを判定する機能も搭載。

=end

require 'twitter'
require 'time'
require 'rubygems'
require 'URI'
require "csv"
require 'weather-report'
def fugou(num)
  if(num >= 0)
    return "+" + sprintf("%.3f",num)
  else
    return sprintf("%.3f",num)
  end
end

# ツイート時刻をツイートIDから算出
def tweet_id2time(id)
  case id
  when Integer
    Time.at(((id >> 22) + 1288834974657) / 1000.0)
  else
    nil
  end
end

# Twitterへのログイン　自分のIDを入れましょう
CONSUMER_KEY     = ''
CONSUMER_SECRET  = ''
# Access Token Key, Secretの設定
ACCESS_TOKEN_KEY = ''
ACCESS_SECRET    = ''


# Twitterへのログイン
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
rank = 0
day_change = Time.now
cfrag = 1
while 1 do
  begin
    stream_client.user do |object|
      if object.is_a?(Twitter::Tweet)
        if day_change.day != Time.now.day
          rank = 0
          day_change = Time.now
        end

        #一応自分自身のアカウントからは強制終了コマンドを打ち込めば強制終了される
        if object.text.include?("@sumimura334") && object.user.screen_name == "sumimura334" && object.text.include?("334強制終了")
          puts "334 botを強制終了しました。"
          client.create_direct_message("yoshimori1560", "334botを強制終了しました\n")
          cfrag = 0
          break
        end
        passline_time = Time.parse("03:34") # 334botなので午前3時34分がフライングかそうでないかの基準点
        # 午前3時30分から午前3時40分までに打ち込まれた334だけはランキングやフライング判定の対象
        if object.text == "334" && Time.parse("03:40") >= Time.now && Time.parse("03:30") <= Time.now
          answer = tweet_id2time(object.id)
          time_data_list = CSV.read("time_result.csv", encoding: "UTF-8")
          #ここから履歴チェック　334を過去にやっていれば前回の日時と前回からのタイムの変化を表示
          if time_data_list.flatten.include?("@" + object.user.screen_name.to_s)
            basho = time_data_list.flatten.rindex('@' + object.user.screen_name.to_s) / 3
          else
            basho = nil
          end
          if ! basho.nil?
            previous_time = Time.parse(time_data_list[basho][2])
            sa = answer - previous_time
            previous_report = "  前回比: " + fugou(sa) + "sec)\n" + "前回の334実施日: " +  time_data_list[basho][0] + "\n"
          else
            previous_report = ")\n"
          end
          jikoku = answer.strftime("%H:%M:%S.%L")
          tweet_naiyou = object.user.name + "さんの334ツイート時刻 : " + jikoku
          if answer >= passline_time
            rank += 1
            print(tweet_naiyou + "\n" + "(ﾌｫﾛｰ内 " , rank , "位" + previous_report)
            begin
              client.update(tweet_naiyou + "\n" + "(ﾌｫﾛｰ内 " + rank.to_s + " 位" + previous_report)
            rescue
              puts "出力エラー\n"
            end
          else
            print(tweet_naiyou + "\n" + "(フライング" + previous_report)
            begin
              client.update(tweet_naiyou + "\n" + "(フライング" + previous_report)
            rescue
              puts "出力エラー\n"
            end
          end
          CSV.open('time_result.csv','a') do |test|
           test << [tweet_id2time(object.id).strftime("%4Y/%2m/%2d"),'@'+ object.user.screen_name.to_s,tweet_id2time(object.id).strftime("%H:%M:%S.%L")]
          end
        elsif object.text == "334" || object.text == "333" || object.text == "332" || object.text == "335"
          answer = tweet_id2time(object.id)
          jikoku = answer.strftime("%H:%M:%S.%L")
          tweet_naiyou = object.user.name + "さんの#{object.text}ツイート時刻 : " + jikoku
          print(tweet_naiyou + "\n")
          begin
            client.update(tweet_naiyou)
          rescue
            puts "エラー\n"
          end
        end
        if cfrag == 0
          break
        end
      end
      if cfrag == 0
        break
      end
    end
  rescue => ex
    a = ""
    a = ex.backtrace.first + ": #{ex.message} (#{ex.class})"
    puts ex.backtrace.first + ": #{ex.message} (#{ex.class})"
    ex.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }
    begin
      if a.length <= 220
        client.update(a)
      else
        client.update(ex)
      end
    rescue => ex
      puts "エラーメッセージ送信エラー"
    end
  end
  if cfrag == 0
    break
  end
end
