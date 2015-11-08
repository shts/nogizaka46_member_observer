
#---------------------------------------------------------------
# メンバー情報を公式サイトから取得しParse.comのサーバーへ登録するスクリプト
# TODO: メンバー情報の中に定期的に更新される情報があるので、定期的にアップデートする必要がある
# parse-ruby-client Doc
# http://www.rubydoc.info/gems/parse-ruby-client/0.3.0
#---------------------------------------------------------------

# URLにアクセスするためのライブラリを読み込む
require 'open-uri'

# HTMLをパースするためのライブラリを読み込む
require 'nokogiri'

# Parseライブラリの読み込み
require 'parse-ruby-client'

# TODO: Windowsのみで発生する証明書問題によりSSL認証エラーの暫定回避策
#ENV['SSL_CERT_FILE'] = File.expand_path('C:\rumix\ruby\2.1\i386-mingw32\lib\ruby\2.1.0\rubygems\ssl_certs\cert.pem')

# Parseライブラリの初期化
Parse.init :application_id => ENV['PARSE_APP_ID'],
           :api_key        => ENV['PARSE_API_KEY']

BaseUrl = "http://www.nogizaka46.com/member/"

def registration_member
  doc = Nokogiri::HTML(open(BaseUrl))
  #puts doc.css('div.unit').inner_html
  doc.css('div.unit').each do |e|
    parse_member_page(BaseUrl + e.css('a')[0][:href].gsub("./", "")) { |data|
      insert_or_update_member(data)
    }
  end
end

def insert_or_update_member(data)
  # RSSのURLは各メンバー一意のはず
  query = Parse::Query.new("Member").eq("rss_url", data[:rss_url])
  member = query.get.first
  if member == nil then
    puts 'new Record'
    # 登録されていないのであれば新規作成(insert)
    new_member = Parse::Object.new("Member")
    data.each { |key, val|
      new_member[key] = val
    }
    puts new_member.save
  else
    puts 'update Record'
    # 登録されていれば更新
    # statusの情報くらいしか更新されないと思う
    #new_member['name_main'] = data[:name_main]
    #new_member['name_sub'] = data[:name_sub]
    #new_member['blog_url'] = data[:blog_url]
    #new_member['rss_url'] = data[:rss_url]
    member['status'] = data[:status]
    #new_member['image_url'] = data[:image_url]
    #new_member['birthday'] = data[:birthday]
    #new_member['blood_type'] = data[:blood_type]
    #new_member['constellation'] = data[:constellation]
    #new_member['height'] = data[:height]
    puts member.save
  end

end

def parse_member_page(url)
  # http://www.nogizaka46.com/member/detail/akimotomanatsu.php
  doc = Nokogiri::HTML(open(url))

  data = { :name_main => nil,
           :name_sub => nil,
           :blog_url => nil,
           :rss_url => nil,
           :status => nil,
           :image_url => nil,
           :birthday => nil,
           :blood_type => nil,
           :constellation => nil,
           :height => 0
  }

  # ブログ一覧URL
  # http://blog.nogizaka46.com/manatsu.akimoto/
  data[:blog_url] = doc.css('div.more').css('a.iepngfix')[2][:href]
  all_blog_page = Nokogiri::HTML(open(data[:blog_url]))
  # ブログフィードURL
  data[:rss_url] = all_blog_page.css('#rss').css('a')[0][:href]

  profile = doc.css('#profile')
  # ひらがな
  data[:name_sub] = profile.css('h2').css('span').text
  # 漢字
  data[:name_main] = profile.css('h2').text.gsub(profile.css('h2').css('span').text, "")
  # プロフィール画像
  data[:image_url] = profile.css('img')[0][:src]
  # タグ
  data[:status] = Array.new()
  profile.css('div.status > div').each do |detail|
    data[:status].push(detail.text)
  end
  # 詳細情報
  counter = 0
  profile.css('dl > dd').each do |dd|
    if counter == 0 then
      # 生年月日
      data[:birthday] = dd.text.gsub("年", "/").gsub("月", "/").gsub("日", "")
    elsif counter == 1
      # 血液型
      data[:blood_type] = dd.text
    elsif counter == 2
      # 星座
      data[:constellation] = dd.text
    elsif counter == 3
      # 身長(cm)
      data[:height] = dd.text.gsub("cm", "")
    end
    counter = counter + 1
  end

  yield(data)
end

# Debug用
#def find_member(rss_url)
#  query = Parse::Query.new("Member").eq("rss_url", rss_url)
#  member = query.get.first
#  puts member['objectId']
#end

#find_member("http://blog.nogizaka46.com/miona.hori/atom.xml")
#registration_member
#parse_detail("http://www.nogizaka46.com/member/detail/akimotomanatsu.php")
registration_member
